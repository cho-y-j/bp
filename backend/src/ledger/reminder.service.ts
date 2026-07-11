import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  Business,
  Confirmation,
  LedgerEntry,
  NotificationType,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { computeDday } from '../common/dday.util';
import { toKstDateStr } from '../confirmations/time.util';
import { NotificationsService } from '../notifications/notifications.service';
import { computeOutstanding } from './ledger.util';
import {
  autoReminderStage,
  hasStageBeenSent,
  manualCooldown,
  normalizeReminders,
  ReminderRecord,
  ReminderStage,
} from './reminder.util';

type EntryForReminder = LedgerEntry & {
  confirmation: Confirmation | null;
  business: Business | null;
};

export interface ReminderSendResult {
  sent: boolean;
  channel: 'push' | 'alimtalk' | null;
  reason?: string;
}

/**
 * 수금 독촉 발송 서비스 (P3a).
 *  - 작업자를 대신해 상대(연결 사업장 소유자 / 수기 미가입 상대)에게 점잖은 대금 안내.
 *  - 연결 사업장 = 푸시 + 인앱 알림(사업장 소유자), 수기 상대 = 알림톡(전화 있을 때, 명세서/확인서 공개 링크 포함).
 *  - 발송 이력을 reminders 에 append, 같은 단계(D7/D30) 중복 발송 방지.
 */
@Injectable()
export class ReminderService {
  private readonly logger = new Logger('ReminderService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {}

  // --------------------------------------------------------------------------
  // 자동 독촉 크론 스캔 — autoRemind=true·미수·D+7/D+30 도달 항목 발송.
  // --------------------------------------------------------------------------
  async runReminderScan(now: Date = new Date()): Promise<number> {
    const entries = await this.prisma.ledgerEntry.findMany({
      where: {
        autoRemind: true,
        derived: false, // 파생 항목 제외
        dueDate: { not: null },
        status: { not: 'PAID' },
      },
      include: { confirmation: true, business: true },
    });

    let sent = 0;
    for (const e of entries) {
      if (!e.dueDate) continue;
      const dday = computeDday(e.dueDate, now);
      const stage = autoReminderStage(dday);
      if (!stage) continue;
      // 같은 단계 이미 발송했으면 건너뜀(중복 방지).
      if (hasStageBeenSent(e.reminders, stage)) continue;
      // 완납이면 건너뜀(status 필터 보강).
      const { outstanding } = computeOutstanding(
        Number(e.amount),
        e.payments,
        e.dueDate,
        now,
      );
      if (outstanding <= 0) continue;
      const result = await this.dispatch(e, stage, outstanding, now);
      if (result.sent) sent += 1;
    }
    this.logger.log(
      `수금 독촉 스캔 완료: 대상 ${entries.length}건, 발송 ${sent}건`,
    );
    return sent;
  }

  // --------------------------------------------------------------------------
  // 수동 즉시 독촉 — 쿨다운 3일(409). 소유자 검증 + 미수/파생 검증.
  // --------------------------------------------------------------------------
  async manualRemind(
    userId: string,
    ledgerId: string,
    now: Date = new Date(),
  ): Promise<ReminderSendResult & { lastAt: Date | null }> {
    const entry = await this.prisma.ledgerEntry.findUnique({
      where: { id: ledgerId },
      include: { confirmation: true, business: true },
    });
    if (!entry || entry.profileId !== userId) {
      throw new AppException(
        'LEDGER_NOT_FOUND',
        '장부 항목을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (entry.derived) {
      throw new AppException(
        'LEDGER_DERIVED_READONLY',
        '팀 작업 파생 항목은 독촉을 보낼 수 없습니다.',
        HttpStatus.CONFLICT,
      );
    }
    const { outstanding } = computeOutstanding(
      Number(entry.amount),
      entry.payments,
      entry.dueDate,
      now,
    );
    if (outstanding <= 0) {
      throw new AppException(
        'LEDGER_ALREADY_PAID',
        '이미 전액 입금된 항목입니다.',
        HttpStatus.CONFLICT,
      );
    }
    // 쿨다운 검사(수동/자동 통합 최근 발송 기준 3일).
    const cd = manualCooldown(entry.reminders, now);
    if (cd.blocked) {
      const hours = Math.ceil(cd.retryAfterMs / (60 * 60 * 1000));
      throw new AppException(
        'REMIND_COOLDOWN',
        `최근에 안내를 보냈습니다. ${hours}시간 후 다시 보낼 수 있습니다.`,
        HttpStatus.CONFLICT,
      );
    }
    const result = await this.dispatch(entry, 'MANUAL', outstanding, now);
    if (!result.sent) {
      // 보낼 대상(연결 사업장/수기 전화)이 없으면 안내.
      throw new AppException(
        'REMIND_NO_TARGET',
        '안내를 보낼 대상 정보(연결 사업장 또는 상대 연락처)가 없습니다.',
        HttpStatus.CONFLICT,
      );
    }
    return { ...result, lastAt: now };
  }

  // --------------------------------------------------------------------------
  // 공통 발송 로직 — 채널 결정 + 발송 + 이력 append.
  // --------------------------------------------------------------------------
  private async dispatch(
    entry: EntryForReminder,
    stage: ReminderStage,
    outstanding: number,
    now: Date,
  ): Promise<ReminderSendResult> {
    const worker = await this.prisma.profile.findUnique({
      where: { id: entry.profileId },
      select: {
        name: true,
        payoutBank: true,
        payoutAccount: true,
        payoutHolder: true,
      },
    });
    const workerName = worker?.name ?? '작업자';
    const monthLabel = this.monthLabel(entry);
    const amountStr = outstanding.toLocaleString('ko-KR');
    const account = this.accountString(worker);
    const link = this.publicLink(entry.confirmation);

    let channel: 'push' | 'alimtalk' | null = null;

    if (entry.businessId && entry.business) {
      // 연결 사업장 → 사업장 소유자에게 푸시 + 인앱 알림.
      const ownerId = entry.business.ownerId;
      const body =
        `${workerName}님이 ${monthLabel} 작업 대금 안내를 드립니다. ` +
        `금액 ${amountStr}원${account ? ` (${account})` : ''}`;
      await this.notifications.create({
        profileId: ownerId,
        type: NotificationType.PAYMENT_DUE,
        title: '작업 대금 안내가 도착했습니다',
        body,
        data: {
          kind: 'reminder',
          ledgerId: entry.id,
          stage,
          outstanding,
          link,
        },
      });
      channel = 'push';
    } else {
      // 수기 미가입 상대 → 알림톡(전화 있을 때, 공개 링크 포함).
      const phone = entry.confirmation?.manualContact ?? null;
      if (phone && phone.trim()) {
        await this.notifications.sendExternalAlimtalk(
          phone,
          'PAYMENT_REMINDER',
          {
            workerName,
            month: monthLabel,
            amount: amountStr,
            account: account ? `\n계좌: ${account}` : '',
            url: link ?? '',
          },
        );
        channel = 'alimtalk';
      }
    }

    if (!channel) {
      return { sent: false, channel: null, reason: 'NO_TARGET' };
    }

    // 발송 이력 append (같은 단계 중복 방지는 호출부에서 검사).
    const record: ReminderRecord = {
      at: now.toISOString(),
      channel,
      stage,
    };
    const next = [...normalizeReminders(entry.reminders), record];
    await this.prisma.ledgerEntry.update({
      where: { id: entry.id },
      data: { reminders: next as unknown as Prisma.InputJsonValue[] },
    });
    return { sent: true, channel };
  }

  private monthLabel(entry: EntryForReminder): string {
    const d = entry.confirmation?.date ?? entry.createdAt;
    const month = parseInt(toKstDateStr(d).slice(5, 7), 10);
    return `${month}월`;
  }

  private accountString(
    worker: {
      payoutBank: string | null;
      payoutAccount: string | null;
      payoutHolder: string | null;
    } | null,
  ): string {
    if (!worker) return '';
    const parts = [
      worker.payoutBank,
      worker.payoutAccount,
      worker.payoutHolder,
    ].filter((s): s is string => !!s && s.trim().length > 0);
    return parts.join(' ');
  }

  private publicLink(confirmation: Confirmation | null): string | null {
    if (!confirmation?.shareToken) return null;
    const base = (
      this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:3001'
    ).replace(/\/$/, '');
    return `${base}/c/${confirmation.shareToken}`;
  }
}
