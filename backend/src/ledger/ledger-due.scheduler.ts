import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { LedgerStatus, NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { computeDday } from '../common/dday.util';
import { sumPayments } from './ledger.util';

const TARGET_DDAYS = [1, 0]; // D-1 / D-0

/**
 * 수금 예정일 알림 스케줄러.
 *  - 매일 09:00 (KST) 실행. (기존 서류 만료 스케줄러와 동일 크론 시간)
 *  - 미수(완납 아님) 장부 중 수금예정 D-1/D-0 → Notification 생성.
 *  - 같은 장부·같은 D-day 중복 생성 방지(하루 2회 실행 대비).
 */
@Injectable()
export class LedgerDueScheduler {
  private readonly logger = new Logger('LedgerDueScheduler');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_9AM, {
    name: 'ledger-due',
    timeZone: 'Asia/Seoul',
  })
  async handleDailyDueScan(): Promise<number> {
    return this.runDueScan();
  }

  /** 실제 스캔 로직(테스트/수동 트리거 재사용). 생성한 알림 수 반환. */
  async runDueScan(now: Date = new Date()): Promise<number> {
    const entries = await this.prisma.ledgerEntry.findMany({
      where: {
        dueDate: { not: null },
        status: { not: LedgerStatus.PAID },
      },
      include: { business: true },
    });

    let created = 0;
    const targets = new Set(TARGET_DDAYS);
    for (const e of entries) {
      if (!e.dueDate) continue;
      const dday = computeDday(e.dueDate, now);
      if (!targets.has(dday)) continue;

      // 완납이면 건너뜀 (status 필터로 대부분 걸러지나 재확인)
      const paid = sumPayments(e.payments);
      const amount = Number(e.amount);
      const outstanding = Math.max(0, amount - paid);
      if (outstanding <= 0) continue;

      if (await this.alreadyNotified(e.profileId, e.id, dday)) continue;

      const name = e.business?.name ?? e.counterpartyName ?? '상대';
      await this.notifications.create({
        profileId: e.profileId,
        type: NotificationType.PAYMENT_DUE,
        title: this.title(dday),
        body: `${name} 수금 예정 (미수 ${outstanding.toLocaleString('ko-KR')}원)`,
        data: { ledgerId: e.id, dday, outstanding },
      });
      created += 1;
    }
    this.logger.log(
      `수금 예정 알림 스캔 완료: 대상 ${entries.length}건, 신규 알림 ${created}건`,
    );
    return created;
  }

  private title(dday: number): string {
    return dday === 0 ? '오늘 수금 예정일입니다' : '내일 수금 예정일입니다';
  }

  private async alreadyNotified(
    profileId: string,
    ledgerId: string,
    dday: number,
  ): Promise<boolean> {
    const existing = await this.prisma.notification.findFirst({
      where: {
        profileId,
        type: NotificationType.PAYMENT_DUE,
        AND: [
          { data: { path: ['ledgerId'], equals: ledgerId } },
          { data: { path: ['dday'], equals: dday } },
        ],
      },
    });
    return !!existing;
  }
}
