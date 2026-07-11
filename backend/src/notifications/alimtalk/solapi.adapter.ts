import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomBytes } from 'crypto';
import {
  AlimtalkSendResult,
  AlimtalkService,
  AlimtalkTemplateKey,
} from './alimtalk.types';
import { ALIMTALK_TEMPLATES, renderAlimtalkText } from './alimtalk.templates';

/**
 * Solapi(구 CoolSMS) 카카오 알림톡 어댑터.
 *  - 활성 조건: SOLAPI_API_KEY / SOLAPI_API_SECRET / ALIMTALK_SENDER / ALIMTALK_PFID 모두 설정.
 *  - 템플릿 승인 후 발급된 templateId 는 ALIMTALK_TEMPLATE_* 로 주입(템플릿별).
 *  - 키/설정이 없으면 비활성(로그만) — FCM/KMA 어댑터와 동일한 안전 동작.
 *  - 실호출 코드는 포함하되, 운영 전 카카오 비즈메시지 템플릿 승인이 필요하다(주석 참고).
 */
@Injectable()
export class SolapiAdapter implements AlimtalkService, OnModuleInit {
  private readonly logger = new Logger('SolapiAlimtalk');
  private readonly apiUrl = 'https://api.solapi.com/messages/v4/send';

  private apiKey = '';
  private apiSecret = '';
  private sender = ''; // 발신번호(사전 등록된 발신번호)
  private pfId = ''; // 카카오 발신 프로필 ID(채널)
  private enabled = false;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    this.apiKey = (this.config.get<string>('SOLAPI_API_KEY') ?? '').trim();
    this.apiSecret = (
      this.config.get<string>('SOLAPI_API_SECRET') ?? ''
    ).trim();
    this.sender = (this.config.get<string>('ALIMTALK_SENDER') ?? '').trim();
    this.pfId = (this.config.get<string>('ALIMTALK_PFID') ?? '').trim();
    this.enabled = !!(
      this.apiKey &&
      this.apiSecret &&
      this.sender &&
      this.pfId
    );
    if (!this.enabled) {
      this.logger.log(
        '알림톡 비활성: SOLAPI_API_KEY/SECRET·ALIMTALK_SENDER·ALIMTALK_PFID 미설정 — 발송은 로그로만 남깁니다.',
      );
    } else {
      this.logger.log('알림톡 활성: Solapi 어댑터 초기화 완료.');
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  /** 승인 템플릿 id (env). 없으면 발송 불가(승인 대기). */
  private templateId(key: AlimtalkTemplateKey): string {
    return (
      this.config.get<string>(ALIMTALK_TEMPLATES[key].envKey) ?? ''
    ).trim();
  }

  private normalizePhone(phone: string): string {
    return (phone ?? '').replace(/[^0-9]/g, '');
  }

  async send(
    to: string,
    templateKey: AlimtalkTemplateKey,
    variables: Record<string, string>,
  ): Promise<AlimtalkSendResult> {
    const phone = this.normalizePhone(to);
    const preview = renderAlimtalkText(templateKey, variables);

    if (!this.enabled) {
      this.logger.debug(
        `[alimtalk-disabled] ${phone || '(no-phone)'} ${templateKey} (로그만): ${preview.replace(/\n/g, ' ')}`,
      );
      return { enabled: false, sent: false, reason: 'DISABLED' };
    }
    if (!phone) {
      return { enabled: true, sent: false, reason: 'NO_PHONE' };
    }
    const templateId = this.templateId(templateKey);
    if (!templateId) {
      // 승인된 templateId 미주입 — 운영 전 카카오 비즈메시지 템플릿 승인 필요.
      this.logger.warn(
        `[alimtalk] ${templateKey} templateId 미설정(${ALIMTALK_TEMPLATES[templateKey].envKey}) — 발송 건너뜀.`,
      );
      return { enabled: true, sent: false, reason: 'NO_TEMPLATE_ID' };
    }

    try {
      // Solapi 변수는 "#{key}" 형태의 키로 전달한다.
      const solapiVars: Record<string, string> = {};
      for (const [k, v] of Object.entries(variables)) {
        solapiVars[`#{${k}}`] = v;
      }
      const body = {
        message: {
          to: phone,
          from: this.normalizePhone(this.sender),
          type: 'ATA', // 알림톡
          kakaoOptions: {
            pfId: this.pfId,
            templateId,
            variables: solapiVars,
            disableSms: false, // 실패 시 대체문자 허용
          },
        },
      };
      const res = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          Authorization: this.authHeader(),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) {
        const t = await res.text().catch(() => '');
        this.logger.warn(
          `알림톡 발송 실패: HTTP ${res.status} ${t.slice(0, 200)}`,
        );
        return { enabled: true, sent: false, reason: `HTTP_${res.status}` };
      }
      this.logger.debug(`[alimtalk-sent] ${phone} ${templateKey}`);
      return { enabled: true, sent: true };
    } catch (e) {
      this.logger.warn(`알림톡 발송 예외: ${(e as Error).message}`);
      return { enabled: true, sent: false, reason: 'EXCEPTION' };
    }
  }

  /** Solapi HMAC-SHA256 인증 헤더 생성. signature = HMAC(date+salt, apiSecret). */
  private authHeader(): string {
    const date = new Date().toISOString();
    const salt = randomBytes(32).toString('hex');
    const signature = createHmac('sha256', this.apiSecret)
      .update(date + salt)
      .digest('hex');
    return `HMAC-SHA256 apiKey=${this.apiKey}, date=${date}, salt=${salt}, signature=${signature}`;
  }
}
