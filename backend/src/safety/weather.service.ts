import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HeatReading, latLngToGrid } from './heatwave.util';

/**
 * 기상청 단기예보(공공데이터포털) 조회 서비스.
 *  - KMA_SERVICE_KEY 미설정 시 비활성(로그만) → getReading 은 null 반환.
 *  - 활성 시 위경도 → 격자 변환 후 getVilageFcst 조회, 당일 최고기온(TMX)/기온(TMP) 추출.
 */
@Injectable()
export class WeatherService {
  private readonly logger = new Logger('WeatherService');
  private readonly serviceKey: string;
  private readonly baseUrl =
    'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst';

  constructor(private readonly config: ConfigService) {
    this.serviceKey = (config.get<string>('KMA_SERVICE_KEY') ?? '').trim();
    if (!this.serviceKey) {
      this.logger.log(
        '기상청 API 비활성: KMA_SERVICE_KEY 미설정 — 폭염 조회는 건너뜁니다(로그만).',
      );
    }
  }

  isEnabled(): boolean {
    return this.serviceKey.length > 0;
  }

  /** 좌표 기준 당일 최고기온/기온 조회. 비활성/실패 시 null 필드. */
  async getReading(lat: number, lng: number): Promise<HeatReading | null> {
    if (!this.isEnabled()) return null;
    try {
      const { nx, ny } = latLngToGrid(lat, lng);
      const { baseDate, baseTime } = this.latestBaseDateTime(new Date());
      const params = new URLSearchParams({
        serviceKey: this.serviceKey,
        pageNo: '1',
        numOfRows: '1000',
        dataType: 'JSON',
        base_date: baseDate,
        base_time: baseTime,
        nx: String(nx),
        ny: String(ny),
      });
      const res = await fetch(`${this.baseUrl}?${params.toString()}`, {
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) {
        this.logger.warn(`기상청 응답 오류: HTTP ${res.status}`);
        return { maxTempC: null };
      }
      const json = (await res.json()) as KmaResponse;
      const items = json?.response?.body?.items?.item ?? [];
      let maxTemp: number | null = null;
      let tmp: number | null = null;
      for (const it of items) {
        if (it.category === 'TMX') {
          const v = parseFloat(it.fcstValue);
          if (Number.isFinite(v))
            maxTemp = maxTemp === null ? v : Math.max(maxTemp, v);
        }
        if (it.category === 'TMP') {
          const v = parseFloat(it.fcstValue);
          if (Number.isFinite(v)) tmp = tmp === null ? v : Math.max(tmp, v);
        }
      }
      return { maxTempC: maxTemp ?? tmp, feelsLikeC: null };
    } catch (e) {
      this.logger.warn(`기상청 조회 실패: ${(e as Error).message}`);
      return { maxTempC: null };
    }
  }

  /** 단기예보 발표 시각(02,05,08,11,14,17,20,23시) 중 직전 값을 고른다. */
  private latestBaseDateTime(now: Date): {
    baseDate: string;
    baseTime: string;
  } {
    // KST 기준
    const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
    const hour = kst.getUTCHours();
    const slots = [23, 20, 17, 14, 11, 8, 5, 2];
    let chosen = slots.find((h) => hour >= h);
    let dateShift = 0;
    if (chosen === undefined) {
      chosen = 23;
      dateShift = -1;
    }
    const d = new Date(kst.getTime() + dateShift * 24 * 60 * 60 * 1000);
    const baseDate = d.toISOString().slice(0, 10).replace(/-/g, '');
    const baseTime = String(chosen).padStart(2, '0') + '00';
    return { baseDate, baseTime };
  }
}

interface KmaItem {
  category: string;
  fcstValue: string;
  fcstDate?: string;
  fcstTime?: string;
}
interface KmaResponse {
  response?: { body?: { items?: { item?: KmaItem[] } } };
}
