import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import {
  ConnectionStatus,
  NotificationType,
  Prisma,
  SafetyLogType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { NotificationsService } from '../notifications/notifications.service';
import { kstDayRange } from './kst-day.util';

export interface HeatContext {
  maxTempC: number | null;
  feelsLikeC?: number | null;
  simulated?: boolean;
}

/**
 * 안전 도메인 서비스 — 폭염 경고/휴식 안내 기록·발송, 작업자 확인(ack).
 *  - safety_log 는 append-only. ackAt 만 최초 1회 UPDATE 허용(재확인 409).
 */
@Injectable()
export class SafetyService {
  private readonly logger = new Logger('SafetyService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  /**
   * 사업장 단위 폭염 경고 처리.
   *  - 연결(ACCEPTED) 작업자 전원 + 사업주에게 알림.
   *  - 작업자별 safety_log(HEAT_ALERT, businessId) 기록.
   *  - 같은 날 이미 폭염 기록이 있으면 건너뜀(중복 방지).
   */
  async processHeatForBusiness(
    businessId: string,
    ctx: HeatContext,
    now: Date = new Date(),
  ): Promise<{ created: number; skipped: boolean }> {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      select: { id: true, name: true, ownerId: true },
    });
    if (!business) return { created: 0, skipped: true };

    // 같은 날 중복 방지
    const { start, end } = kstDayRange(now);
    const dup = await this.prisma.safetyLog.findFirst({
      where: {
        businessId,
        type: SafetyLogType.HEAT_ALERT,
        createdAt: { gte: start, lt: end },
      },
    });
    if (dup) return { created: 0, skipped: true };

    const workers = await this.connectedWorkerIds(businessId);
    const temp = ctx.maxTempC ?? ctx.feelsLikeC ?? null;
    const body = `${business.name} 현장 폭염 경고${
      temp !== null ? ` (최고 ${temp}°C)` : ''
    }. 충분한 수분 섭취와 그늘 휴식을 지키세요.`;

    const payload = {
      maxTempC: ctx.maxTempC,
      feelsLikeC: ctx.feelsLikeC ?? null,
      simulated: ctx.simulated ?? false,
      threshold: 33,
    } as unknown as Prisma.InputJsonValue;

    let created = 0;
    for (const workerId of workers) {
      const log = await this.prisma.safetyLog.create({
        data: {
          type: SafetyLogType.HEAT_ALERT,
          targetProfileId: workerId,
          businessId,
          payload,
          sentAt: now,
        },
      });
      await this.notifications.create({
        profileId: workerId,
        type: NotificationType.HEAT_ALERT,
        title: '폭염 경고',
        body,
        data: { businessId, kind: 'HEAT_ALERT', safetyLogId: log.id },
        // 푸시 미도달 시 알림톡 fallback(미설치 작업자 우선)
        alimtalk: {
          templateKey: 'HEAT_ALERT',
          variables: { site: business.name },
        },
      });
      created += 1;
    }

    // 사업주에게도 폭염 로그 + 알림 (증거/현장관리)
    await this.prisma.safetyLog.create({
      data: {
        type: SafetyLogType.HEAT_ALERT,
        targetProfileId: business.ownerId,
        businessId,
        payload,
        sentAt: now,
      },
    });
    await this.notifications.create({
      profileId: business.ownerId,
      type: NotificationType.HEAT_ALERT,
      title: '폭염 경고 (현장)',
      body,
      data: { businessId, kind: 'HEAT_ALERT' },
    });
    created += 1;

    this.logger.log(
      `폭염 경고 발송: business=${businessId}, 대상 ${created}명 (simulated=${ctx.simulated ?? false})`,
    );
    return { created, skipped: false };
  }

  /**
   * 폭염 감지된 사업장에 14:00 휴식 안내.
   *  - 같은 날 폭염 로그가 있는 사업장만 대상.
   *  - 작업자별 REST_GUIDE safety_log + 알림. 중복 방지.
   */
  async processRestGuide(
    businessId: string,
    now: Date = new Date(),
  ): Promise<{ created: number; skipped: boolean }> {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      select: { name: true, ownerId: true },
    });
    if (!business) return { created: 0, skipped: true };

    const { start, end } = kstDayRange(now);
    const restDup = await this.prisma.safetyLog.findFirst({
      where: {
        businessId,
        type: SafetyLogType.REST_GUIDE,
        createdAt: { gte: start, lt: end },
      },
    });
    if (restDup) return { created: 0, skipped: true };

    const workers = await this.connectedWorkerIds(businessId);
    const body = `${business.name} 현장 폭염 휴식 안내: 14:00~17:00 무더위 시간대에는 옥외작업을 중단하고 그늘에서 휴식하세요.`;
    let created = 0;
    for (const workerId of [...workers, business.ownerId]) {
      const log = await this.prisma.safetyLog.create({
        data: {
          type: SafetyLogType.REST_GUIDE,
          targetProfileId: workerId,
          businessId,
          payload: { hour: 14 } as unknown as Prisma.InputJsonValue,
          sentAt: now,
        },
      });
      await this.notifications.create({
        profileId: workerId,
        type: NotificationType.HEAT_ALERT,
        title: '폭염 휴식 안내',
        body,
        data: { businessId, kind: 'REST_GUIDE', safetyLogId: log.id },
      });
      created += 1;
    }
    return { created, skipped: false };
  }

  /** 오늘(KST) 폭염 감지된 사업장 id 목록. */
  async businessesWithHeatToday(now: Date = new Date()): Promise<string[]> {
    const { start, end } = kstDayRange(now);
    const rows = await this.prisma.safetyLog.findMany({
      where: {
        type: SafetyLogType.HEAT_ALERT,
        businessId: { not: null },
        createdAt: { gte: start, lt: end },
      },
      select: { businessId: true },
      distinct: ['businessId'],
    });
    return rows
      .map((r) => r.businessId)
      .filter((id): id is string => id !== null);
  }

  /**
   * 작업자 "확인"(ack) — safety_log.ackAt 최초 1회 UPDATE.
   *  - 대상 작업자 본인만. 이미 ackAt 있으면 409.
   */
  async ack(userId: string, logId: string) {
    const log = await this.prisma.safetyLog.findUnique({
      where: { id: logId },
    });
    if (!log || log.targetProfileId !== userId) {
      throw new AppException(
        'SAFETY_LOG_NOT_FOUND',
        '안전 알림을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (log.ackAt) {
      throw new AppException(
        'ALREADY_ACKED',
        '이미 확인한 안전 알림입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.prisma.safetyLog.update({
      where: { id: logId },
      data: { ackAt: new Date() },
    });
    return { acked: true, ackAt: updated.ackAt };
  }

  /**
   * 개발 검증용 폭염 시뮬레이션 — 기상청 응답 없이 폭염 플로우 트리거.
   *  - 호출자가 소유한 사업장(또는 지정 businessId) 대상.
   *  - simulated=true, 최고기온 35°C 로 processHeatForBusiness 실행.
   */
  async simulateHeatwave(
    userId: string,
    businessId?: string,
    now: Date = new Date(),
  ) {
    let targetIds: string[];
    if (businessId) {
      const b = await this.prisma.business.findUnique({
        where: { id: businessId },
        select: { ownerId: true },
      });
      if (!b || b.ownerId !== userId) {
        throw new AppException(
          'BUSINESS_NOT_FOUND',
          '내 사업장을 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      targetIds = [businessId];
    } else {
      const owned = await this.prisma.business.findMany({
        where: { ownerId: userId },
        select: { id: true },
      });
      targetIds = owned.map((b) => b.id);
    }

    const results: Array<{
      businessId: string;
      created: number;
      skipped: boolean;
    }> = [];
    let totalCreated = 0;
    for (const id of targetIds) {
      const res = await this.processHeatForBusiness(
        id,
        { maxTempC: 35, feelsLikeC: 37, simulated: true },
        now,
      );
      results.push({ businessId: id, ...res });
      totalCreated += res.created;
    }
    return { simulated: true, totalCreated, businesses: results };
  }

  private async connectedWorkerIds(businessId: string): Promise<string[]> {
    const conns = await this.prisma.connection.findMany({
      where: { businessId, status: ConnectionStatus.ACCEPTED },
      select: { profileId: true },
    });
    return [...new Set(conns.map((c) => c.profileId))];
  }
}
