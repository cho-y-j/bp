import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfirmationStatus, NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { PdfService } from '../documents/pdf.service';
import type {
  SafetyReportPdfData,
  SafetyReportRow,
  SafetyReportTbmRow,
} from '../documents/pdf.types';
import { NotificationsService } from '../notifications/notifications.service';
import { SAFETY_TYPE_LABEL } from '../common/safety-labels';
import { tbmHazardsSummaryKo, TbmHazardItem } from '../common/tbm-presets';
import { maskName } from '../common/phone.util';
import {
  computeOutstanding,
  deriveLedgerStatus,
  sumPayments,
  PaymentRecord,
} from '../ledger/ledger.util';
import {
  kstDate,
  kstMonthRange,
  toKstDateStr,
  toKstDateTimeStr,
} from '../confirmations/time.util';
import { PaySettlementDto } from './dto/pay-settlement.dto';

export interface SettlementWorkerGroup {
  workerProfileId: string;
  workerName: string;
  entryCount: number;
  total: number;
  paid: number;
  outstanding: number;
  ledgerEntryIds: string[]; // 미수 항목만 (pay 대상)
}

@Injectable()
export class BizService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pdf: PdfService,
    private readonly notifications: NotificationsService,
  ) {}

  // --------------------------------------------------------------------------
  // 수신 확인서함 — 연동 작업자가 send 한 확인서(내 사업장 대상)
  // --------------------------------------------------------------------------
  async inbox(userId: string, businessId?: string) {
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    if (businessIds.length === 0) return { count: 0, items: [] };

    const rows = await this.prisma.confirmation.findMany({
      where: {
        businessId: { in: businessIds },
        status: { in: [ConfirmationStatus.SENT, ConfirmationStatus.SIGNED] },
      },
      include: {
        profile: { select: { name: true } },
        ledgerEntry: { select: { amount: true, payments: true } },
      },
      orderBy: { date: 'desc' },
    });
    return {
      count: rows.length,
      items: rows.map((c) => {
        const calc = c.amountCalc as { total?: number } | null;
        return {
          id: c.id,
          status: c.status,
          date: toKstDateStr(c.date),
          site: c.site,
          companyName: c.companyName,
          workerName: maskName(c.profile.name),
          workContent: c.workContent,
          total: calc?.total ?? 0,
          signerName: c.signerName,
          signedAt: c.signedAt ? toKstDateTimeStr(c.signedAt) : null,
        };
      }),
    };
  }

  // --------------------------------------------------------------------------
  // 작업자별 미지급 집계 (SIGNED 확인서 기준, ledger 미수와 대칭)
  // --------------------------------------------------------------------------
  async settlements(userId: string, month: string, businessId?: string) {
    this.assertMonth(month);
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    if (businessIds.length === 0)
      return { month, workers: [], totalOutstanding: 0 };
    const { start, end } = kstMonthRange(month);
    const now = new Date();

    const entries = await this.prisma.ledgerEntry.findMany({
      where: {
        businessId: { in: businessIds },
        confirmation: {
          status: ConfirmationStatus.SIGNED,
          date: { gte: start, lt: end },
        },
      },
      include: {
        profile: { select: { id: true, name: true } },
        confirmation: { select: { date: true, site: true } },
      },
    });

    const groups = new Map<string, SettlementWorkerGroup>();
    let totalOutstanding = 0;

    for (const e of entries) {
      const amount = Number(e.amount);
      const { paid, outstanding } = computeOutstanding(
        amount,
        e.payments,
        e.dueDate,
        now,
      );
      const key = e.profile.id;
      const g =
        groups.get(key) ??
        ({
          workerProfileId: key,
          workerName: maskName(e.profile.name),
          entryCount: 0,
          total: 0,
          paid: 0,
          outstanding: 0,
          ledgerEntryIds: [],
        } as SettlementWorkerGroup);
      g.entryCount += 1;
      g.total += amount;
      g.paid += paid;
      g.outstanding += outstanding;
      if (outstanding > 0) g.ledgerEntryIds.push(e.id);
      groups.set(key, g);
      totalOutstanding += outstanding;
    }

    return {
      month,
      totalOutstanding,
      workers: [...groups.values()].sort(
        (a, b) => b.outstanding - a.outstanding,
      ),
    };
  }

  // --------------------------------------------------------------------------
  // 지급 처리 — 각 ledger 에 입금 기록(작업자 장부와 동일 데이터) + 작업자 알림
  // --------------------------------------------------------------------------
  async pay(userId: string, dto: PaySettlementDto) {
    const businessIds = await this.ownedBusinessIds(userId);
    if (businessIds.length === 0) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        '보유한 사업장이 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const ids = [...new Set(dto.ledgerEntryIds)];

    const paidAtIso = dto.paidAt
      ? kstDate(dto.paidAt).toISOString()
      : new Date().toISOString();

    // read-modify-write 를 하나의 트랜잭션으로 묶어 원자적으로 처리(부분 실패 방지).
    const { results, notifyByWorker } = await this.prisma.$transaction(
      async (tx) => {
        const entries = await tx.ledgerEntry.findMany({
          where: { id: { in: ids }, businessId: { in: businessIds } },
        });
        if (entries.length !== ids.length) {
          throw new AppException(
            'LEDGER_NOT_FOUND',
            '내 사업장의 장부 항목이 아니거나 존재하지 않는 항목이 있습니다.',
            HttpStatus.NOT_FOUND,
          );
        }

        const results: Array<{ ledgerEntryId: string; paidAmount: number }> =
          [];
        const notifyByWorker = new Map<string, number>();

        for (const e of entries) {
          const amount = Number(e.amount);
          const existingPaid = sumPayments(e.payments);
          const outstanding = Math.max(0, amount - existingPaid);
          if (outstanding <= 0) {
            results.push({ ledgerEntryId: e.id, paidAmount: 0 });
            continue;
          }
          const payment: PaymentRecord & { byBusiness: boolean } = {
            amount: outstanding,
            paidAt: paidAtIso,
            memo: dto.memo,
            byBusiness: true,
          };
          const payments = Array.isArray(e.payments)
            ? (e.payments as unknown as PaymentRecord[])
            : [];
          const nextPayments = [...payments, payment];
          const status = deriveLedgerStatus(
            amount,
            sumPayments(nextPayments),
            e.dueDate,
          );
          await tx.ledgerEntry.update({
            where: { id: e.id },
            data: {
              payments: nextPayments as unknown as Prisma.InputJsonValue[],
              status,
            },
          });
          results.push({ ledgerEntryId: e.id, paidAmount: outstanding });
          notifyByWorker.set(
            e.profileId,
            (notifyByWorker.get(e.profileId) ?? 0) + outstanding,
          );
        }
        return { results, notifyByWorker };
      },
    );

    // 작업자별 입금 알림 (장부 PAID 반영을 작업자도 즉시 인지)
    for (const [profileId, amount] of notifyByWorker.entries()) {
      await this.notifications.create({
        profileId,
        type: NotificationType.PAYMENT_DUE,
        title: '입금이 완료되었습니다',
        body: `${amount.toLocaleString('ko-KR')}원이 입금 처리되었습니다. 장부에서 확인하세요.`,
        data: { paidAmount: amount, paidAt: paidAtIso },
      });
    }

    const totalPaid = results.reduce((s, r) => s + r.paidAmount, 0);
    return {
      paidCount: results.filter((r) => r.paidAmount > 0).length,
      totalPaid,
      results,
    };
  }

  // --------------------------------------------------------------------------
  // 안전관리 이행 리포트 PDF
  // --------------------------------------------------------------------------
  async safetyReport(
    userId: string,
    month: string,
    businessId?: string,
  ): Promise<Buffer> {
    this.assertMonth(month);
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    const { start, end } = kstMonthRange(month);

    const owned = await this.prisma.business.findMany({
      where: {
        ownerId: userId,
        ...(businessIds.length ? { id: { in: businessIds } } : {}),
      },
      select: { name: true },
      orderBy: { createdAt: 'asc' },
    });
    const businessName = owned.map((b) => b.name).join(', ') || '내 사업장';

    const logs =
      businessIds.length === 0
        ? []
        : await this.prisma.safetyLog.findMany({
            where: {
              businessId: { in: businessIds },
              createdAt: { gte: start, lt: end },
            },
            include: { target: { select: { name: true } } },
            orderBy: { createdAt: 'asc' },
          });

    const byTypeMap = new Map<string, number>();
    const rows: SafetyReportRow[] = [];
    for (const l of logs) {
      const label = SAFETY_TYPE_LABEL[l.type];
      byTypeMap.set(label, (byTypeMap.get(label) ?? 0) + 1);
      rows.push({
        date: toKstDateStr(l.createdAt),
        typeLabel: label,
        targetName: maskName(l.target.name),
        ackAt: l.ackAt ? toKstDateTimeStr(l.ackAt) : null,
      });
    }

    // TBM(안전점검회의) 월간 목록 — tbm_records 에서 직접 집계.
    const tbmRecords =
      businessIds.length === 0
        ? []
        : await this.prisma.tbmRecord.findMany({
            where: {
              businessId: { in: businessIds },
              occurredAt: { gte: start, lt: end },
            },
            include: { _count: { select: { attendees: true } } },
            orderBy: { occurredAt: 'asc' },
          });
    const tbmAckCounts = new Map<string, number>();
    if (tbmRecords.length > 0) {
      const acks = await this.prisma.tbmAttendee.groupBy({
        by: ['recordId'],
        where: {
          recordId: { in: tbmRecords.map((t) => t.id) },
          ackAt: { not: null },
        },
        _count: { _all: true },
      });
      for (const a of acks) tbmAckCounts.set(a.recordId, a._count._all);
    }
    const tbm: SafetyReportTbmRow[] = tbmRecords.map((t) => ({
      date: toKstDateStr(t.occurredAt),
      site: t.site,
      hazards: tbmHazardsSummaryKo(
        Array.isArray(t.hazards) ? (t.hazards as TbmHazardItem[]) : [],
      ),
      attendeeCount: t._count.attendees,
      ackCount: tbmAckCounts.get(t.id) ?? 0,
    }));

    const data: SafetyReportPdfData = {
      title: '안전관리 이행 리포트',
      month,
      businessName,
      totalCount: logs.length,
      byType: [...byTypeMap.entries()].map(([typeLabel, count]) => ({
        typeLabel,
        count,
      })),
      rows,
      tbm,
    };
    return this.pdf.renderSafetyReportPdf(data);
  }

  // --------------------------------------------------------------------------
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  private async ownedBusinessIds(userId: string): Promise<string[]> {
    const rows = await this.prisma.business.findMany({
      where: { ownerId: userId },
      select: { id: true },
    });
    return rows.map((r) => r.id);
  }

  /**
   * 조회 대상 사업장 id 집합을 해석한다(다중 사업장 스코프).
   *  - businessId 미지정: 소유 전체(기존 동작 그대로 — additive).
   *  - businessId 지정 & 소유: 해당 1건으로 스코프.
   *  - businessId 지정 & 미소유: 빈 배열(타 사업장 데이터 유출 차단).
   */
  private async scopedBusinessIds(
    userId: string,
    businessId?: string,
  ): Promise<string[]> {
    const owned = await this.ownedBusinessIds(userId);
    if (!businessId) return owned;
    return owned.includes(businessId) ? [businessId] : [];
  }

  private assertMonth(month: string): void {
    if (!month || !/^\d{4}-\d{2}$/.test(month)) {
      throw new AppException(
        'INVALID_MONTH',
        'month 는 YYYY-MM 형식이어야 합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}
