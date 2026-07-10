import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { WeatherService } from './weather.service';
import { SafetyService } from './safety.service';
import { isHeatwave } from './heatwave.util';

const KST = 'Asia/Seoul';

/**
 * 폭염 자동 알림 스케줄러 (모두 Asia/Seoul).
 *  - 06:00: 활성 연결 사업장 좌표 기준 최고기온 조회 → 33°C↑ 폭염 경고.
 *  - 14:00: 같은 날 폭염 감지된 사업장에 휴식 안내.
 *  - 기상청 키 없으면 WeatherService 가 null 반환 → 스킵(로그만).
 */
@Injectable()
export class HeatwaveScheduler {
  private readonly logger = new Logger('HeatwaveScheduler');

  constructor(
    private readonly prisma: PrismaService,
    private readonly weather: WeatherService,
    private readonly safety: SafetyService,
  ) {}

  @Cron('0 6 * * *', { name: 'heatwave-morning', timeZone: KST })
  async handleMorningScan(): Promise<number> {
    return this.runHeatScan();
  }

  @Cron('0 14 * * *', { name: 'heatwave-rest', timeZone: KST })
  async handleRestScan(): Promise<number> {
    return this.runRestScan();
  }

  /** 활성 사업장 폭염 스캔. 발송한 사업장 수 반환. */
  async runHeatScan(now: Date = new Date()): Promise<number> {
    if (!this.weather.isEnabled()) {
      this.logger.log('폭염 스캔 건너뜀: 기상청 API 비활성.');
      return 0;
    }
    const businesses = await this.prisma.business.findMany({
      where: {
        lat: { not: null },
        lng: { not: null },
        connections: { some: { status: 'ACCEPTED' } },
      },
      select: { id: true, lat: true, lng: true },
    });
    let hit = 0;
    for (const b of businesses) {
      if (b.lat === null || b.lng === null) continue;
      const reading = await this.weather.getReading(b.lat, b.lng);
      if (!reading) continue;
      if (!isHeatwave(reading)) continue;
      const res = await this.safety.processHeatForBusiness(
        b.id,
        {
          maxTempC: reading.maxTempC,
          feelsLikeC: reading.feelsLikeC,
          simulated: false,
        },
        now,
      );
      if (!res.skipped) hit += 1;
    }
    this.logger.log(`폭염 스캔 완료: 대상 ${businesses.length} · 발송 ${hit}`);
    return hit;
  }

  /** 폭염 감지 사업장 휴식 안내 스캔. 발송 사업장 수 반환. */
  async runRestScan(now: Date = new Date()): Promise<number> {
    const ids = await this.safety.businessesWithHeatToday(now);
    let hit = 0;
    for (const id of ids) {
      const res = await this.safety.processRestGuide(id, now);
      if (!res.skipped) hit += 1;
    }
    this.logger.log(`휴식 안내 스캔 완료: 대상 ${ids.length} · 발송 ${hit}`);
    return hit;
  }
}
