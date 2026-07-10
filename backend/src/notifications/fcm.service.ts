import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'fs';

export interface FcmMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface FcmSendResult {
  enabled: boolean;
  successCount: number;
  failureCount: number;
  invalidTokens: string[]; // 등록취소/무효 토큰 (정리 대상)
}

/**
 * FCM 실발송 서비스.
 *  - FCM_SERVICE_ACCOUNT_PATH 로 firebase-admin 초기화.
 *  - 키가 없으면 비활성(로그만) — 현재 서비스계정 키 미보유 상태에서도 안전 동작.
 *  - firebase-admin 은 지연 로드(런타임에 미설치여도 부팅 실패하지 않도록).
 */
@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger('FcmService');
  private enabled = false;
  // firebase-admin messaging 인스턴스 (활성 시에만)
  private messaging: {
    sendEachForMulticast: (msg: unknown) => Promise<{
      successCount: number;
      failureCount: number;
      responses: Array<{ success: boolean; error?: { code?: string } }>;
    }>;
  } | null = null;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const keyPath = this.config.get<string>('FCM_SERVICE_ACCOUNT_PATH');
    if (!keyPath || keyPath.trim() === '') {
      this.logger.log(
        'FCM 비활성화: FCM_SERVICE_ACCOUNT_PATH 미설정 — 푸시는 로그로만 남깁니다.',
      );
      return;
    }
    try {
      const raw = await fs.readFile(keyPath.trim(), 'utf-8');
      const serviceAccount = JSON.parse(raw) as Record<string, unknown>;
      // 지연 로드 (미설치/키없음 환경에서 부팅 안전)
      const appMod =
        (await import('firebase-admin/app')) as typeof import('firebase-admin/app');
      const msgMod =
        (await import('firebase-admin/messaging')) as typeof import('firebase-admin/messaging');
      const app =
        appMod.getApps().length > 0
          ? appMod.getApps()[0]
          : appMod.initializeApp({
              credential: appMod.cert(
                serviceAccount as unknown as import('firebase-admin/app').ServiceAccount,
              ),
            });
      this.messaging = msgMod.getMessaging(
        app,
      ) as unknown as typeof this.messaging;
      this.enabled = true;
      this.logger.log('FCM 활성화: firebase-admin 초기화 완료.');
    } catch (e) {
      this.logger.error(
        `FCM 초기화 실패 (비활성으로 진행): ${(e as Error).message}`,
      );
      this.enabled = false;
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  /** 다중 토큰 발송. 비활성이면 로그만 남기고 successCount=0. */
  async sendToTokens(
    tokens: string[],
    msg: FcmMessage,
  ): Promise<FcmSendResult> {
    const uniq = [...new Set(tokens.filter((t) => t && t.length > 0))];
    if (!this.enabled || !this.messaging || uniq.length === 0) {
      if (!this.enabled) {
        this.logger.debug(
          `[fcm-disabled] ${uniq.length} 토큰 대상 "${msg.title}" (로그만)`,
        );
      }
      return {
        enabled: this.enabled,
        successCount: 0,
        failureCount: 0,
        invalidTokens: [],
      };
    }
    try {
      const res = await this.messaging.sendEachForMulticast({
        tokens: uniq,
        notification: { title: msg.title, body: msg.body },
        data: msg.data ?? {},
      });
      const invalidTokens: string[] = [];
      res.responses.forEach((r, i) => {
        const code = r.error?.code;
        if (
          !r.success &&
          (code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token')
        ) {
          invalidTokens.push(uniq[i]);
        }
      });
      return {
        enabled: true,
        successCount: res.successCount,
        failureCount: res.failureCount,
        invalidTokens,
      };
    } catch (e) {
      this.logger.warn(`FCM 발송 실패: ${(e as Error).message}`);
      return {
        enabled: true,
        successCount: 0,
        failureCount: uniq.length,
        invalidTokens: [],
      };
    }
  }
}
