import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppException } from '../../common/errors';

const NTS_VALIDATE_URL =
  'https://api.odcloud.kr/api/nts-businessman/v1/validate';

export interface BizVerifyInput {
  businessNumber: string; // b_no (숫자 10자리)
  openingDate: string; // start_dt (YYYYMMDD)
  representativeName: string; // p_nm (대표자 성명)
  businessName?: string; // b_nm (상호, 선택)
}

export interface BizVerifyResult {
  result: 'VALID' | 'INVALID';
  valid: boolean; // 국세청 valid 코드 "01"(일치) 여부
  matchCode: string; // "01" | "02" ...
  raw: unknown; // 원본 응답(감사/디버깅용)
  checkedAt: string;
}

/**
 * 사업자등록 진위확인 (공공데이터포털 국세청 API) 연동.
 *  - GOV_DATA_SERVICE_KEY 미설정이면 isEnabled()=false → 호출부에서 501 스텁 처리.
 *  - 설정 시 https://api.odcloud.kr/api/nts-businessman/v1/validate 실호출.
 */
@Injectable()
export class BizVerifyService {
  private readonly logger = new Logger('BizVerifyService');

  constructor(private readonly config: ConfigService) {}

  isEnabled(): boolean {
    const key = this.config.get<string>('GOV_DATA_SERVICE_KEY');
    return !!key && key.trim().length > 0;
  }

  private serviceKey(): string {
    const key = this.config.get<string>('GOV_DATA_SERVICE_KEY') ?? '';
    return key.trim();
  }

  /**
   * 진위확인 실호출. isEnabled()=false 면 501.
   * 입력 필드(b_no/start_dt/p_nm)가 없으면 400.
   */
  async validate(input: BizVerifyInput): Promise<BizVerifyResult> {
    if (!this.isEnabled()) {
      throw new AppException(
        'NOT_IMPLEMENTED',
        '사업자등록 진위확인이 아직 활성화되지 않았습니다. (GOV_DATA_SERVICE_KEY 필요)',
        HttpStatus.NOT_IMPLEMENTED,
      );
    }

    const bNo = (input.businessNumber ?? '').replace(/[^0-9]/g, '');
    const startDt = (input.openingDate ?? '').replace(/[^0-9]/g, '');
    const pNm = (input.representativeName ?? '').trim();
    if (bNo.length !== 10 || startDt.length !== 8 || !pNm) {
      throw new AppException(
        'VERIFY_INPUT_REQUIRED',
        '진위확인에는 사업자번호(10자리), 개업일자(YYYYMMDD), 대표자명이 필요합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }

    const url = `${NTS_VALIDATE_URL}?serviceKey=${encodeURIComponent(
      this.serviceKey(),
    )}`;
    const body = {
      businesses: [
        {
          b_no: bNo,
          start_dt: startDt,
          p_nm: pNm,
          ...(input.businessName ? { b_nm: input.businessName } : {}),
        },
      ],
    };

    let json: unknown;
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => '');
        this.logger.warn(
          `국세청 API 오류 ${res.status}: ${text.slice(0, 200)}`,
        );
        throw new AppException(
          'VERIFY_UPSTREAM_ERROR',
          `진위확인 서비스 오류 (status ${res.status}).`,
          HttpStatus.BAD_GATEWAY,
        );
      }
      json = await res.json();
    } catch (e) {
      if (e instanceof AppException) throw e;
      this.logger.warn(`국세청 API 호출 실패: ${(e as Error).message}`);
      throw new AppException(
        'VERIFY_UPSTREAM_ERROR',
        '진위확인 서비스에 연결할 수 없습니다.',
        HttpStatus.BAD_GATEWAY,
      );
    }

    const matchCode = this.extractValidCode(json);
    return {
      result: matchCode === '01' ? 'VALID' : 'INVALID',
      valid: matchCode === '01',
      matchCode,
      raw: json,
      checkedAt: new Date().toISOString(),
    };
  }

  /** 응답 data[0].valid 코드 추출 ("01" 일치 / "02" 불일치). */
  private extractValidCode(json: unknown): string {
    const data = (json as { data?: Array<{ valid?: string }> })?.data;
    if (Array.isArray(data) && data[0] && typeof data[0].valid === 'string') {
      return data[0].valid;
    }
    return 'UNKNOWN';
  }
}
