import { HttpStatus, Injectable } from '@nestjs/common';
import {
  Confirmation,
  ConfirmationStatus,
  JobStatus,
  NotificationType,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { PdfService } from '../documents/pdf.service';
import type {
  SafetyReportPdfData,
  SafetyReportRow,
  SafetyReportTbmRow,
  SiteCostsPdfData,
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
  toKstTimeStr,
} from '../confirmations/time.util';
import { PaySettlementDto } from './dto/pay-settlement.dto';
import { BadgeService } from '../ledger/badge.service';
import { selfBadgeStatus } from '../ledger/badge.util';
import { aggregateSiteCosts, SiteCostInputRow } from './site-costs.util';
import {
  aggregateWageStatement,
  formatWageStatementText,
  wageStatementNotes,
  WagePaymentRow,
} from './wage-statement.util';

/** 확인서의 근로일수(연인원)·공수 기여분. 팀=공수합, GONGSU=수량, DAILY=일수, 그 외=1. */
export function workUnitsOf(c: Confirmation): {
  days: number;
  gongsu: number;
  isTeam: boolean;
  teamMemberCount: number;
} {
  const te = Array.isArray(c.teamEntries)
    ? (c.teamEntries as unknown as Array<{ quantity?: number }>)
    : [];
  if (te.length > 0) {
    const gongsu = te.reduce((s, x) => s + (x.quantity ?? 0), 0);
    return {
      days: gongsu,
      gongsu,
      isTeam: true,
      teamMemberCount: te.length,
    };
  }
  const calc = c.amountCalc as unknown as {
    items?: Array<{ type?: string; quantity?: number }>;
  } | null;
  const base = calc?.items?.find((i) => i.type === 'BASE');
  const qty = typeof base?.quantity === 'number' ? base.quantity : 0;
  if (c.rateType === 'GONGSU') {
    return { days: qty, gongsu: qty, isTeam: false, teamMemberCount: 0 };
  }
  if (c.rateType === 'DAILY') {
    return {
      days: qty > 0 ? qty : 1,
      gongsu: 0,
      isTeam: false,
      teamMemberCount: 0,
    };
  }
  // HOURLY / PER_CASE / MONTHLY / UNIT — 일용 일수 개념 약함, 1일로 간주.
  return { days: 1, gongsu: 0, isTeam: false, teamMemberCount: 0 };
}

function amountTotalOf(c: Confirmation): number {
  const calc = c.amountCalc as unknown as { total?: number } | null;
  return typeof calc?.total === 'number' ? calc.total : 0;
}

/** 오늘의 출역 — 작업자 1명의 상태 행. */
export interface AttendanceWorker {
  jobId: string;
  workerName: string;
  status: 'SCHEDULED' | 'ACCEPTED' | 'STARTED' | 'DONE' | 'CANCELLED';
  scheduledAt: string;
  startedAt: string | null;
  finishedAt: string | null;
  condition: string | null;
}

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
    private readonly badges: BadgeService,
  ) {}

  // --------------------------------------------------------------------------
  // 지급 평판 배지 — 사업장 본인용(데이터 부족/개선 안내 포함). P3a
  // --------------------------------------------------------------------------
  async paymentBadge(userId: string, businessId?: string) {
    const business = await this.resolveOwnedBusiness(userId, businessId);
    const status = selfBadgeStatus(business);
    return {
      businessId: business.id,
      businessName: business.name,
      status: status.status, // EXCELLENT | GOOD | NONE | INSUFFICIENT
      avgDays: status.avgDays,
      sampleSize: status.sampleSize,
      updatedAt: business.paymentBadgeUpdatedAt,
    };
  }

  /** 소유 사업장 1건 해석(businessId 지정 시 검증, 없으면 최초 소유). */
  private async resolveOwnedBusiness(userId: string, businessId?: string) {
    if (businessId) {
      const b = await this.prisma.business.findUnique({
        where: { id: businessId },
      });
      if (!b || b.ownerId !== userId) {
        throw new AppException(
          'BUSINESS_NOT_FOUND',
          '내 사업장을 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      return b;
    }
    const b = await this.prisma.business.findFirst({
      where: { ownerId: userId },
      orderBy: { createdAt: 'asc' },
    });
    if (!b) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        '보유한 사업장이 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return b;
  }

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

    // 지급 평판 배지 비동기 갱신(pay 시점) — 실패해도 pay 응답에 영향 없음. P3a
    const affectedBiz = [...new Set(businessIds)];
    void Promise.all(
      affectedBiz.map((bid) => this.badges.recomputeBusinessQuietly(bid)),
    );

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

  // ==========================================================================
  //  P5a-1. 현장별 인건비 집계 (SIGNED 확인서 → 현장별·작업자별, 팀 합계) + PDF
  // ==========================================================================
  async siteCosts(
    userId: string,
    from: string,
    to: string,
    businessId?: string,
  ) {
    const range = this.resolveSiteRange(from, to);
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    const { rows, businessName } = await this.siteCostRows(
      userId,
      businessIds,
      range,
    );
    const { sites, totals } = aggregateSiteCosts(rows);
    return {
      range: { from: range.from, to: range.to },
      businessName,
      sites,
      totals,
    };
  }

  async siteCostsPdf(
    userId: string,
    from: string,
    to: string,
    businessId?: string,
  ): Promise<Buffer> {
    const range = this.resolveSiteRange(from, to);
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    const { rows, businessName } = await this.siteCostRows(
      userId,
      businessIds,
      range,
    );
    const { sites, totals } = aggregateSiteCosts(rows);
    const data: SiteCostsPdfData = {
      title: '현장별 인건비 집계',
      businessName,
      periodLabel: `${range.from} ~ ${range.to}`,
      sites: sites.map((s) => ({
        site: s.site,
        entries: s.entries.map((e) => ({
          workerName: e.workerName,
          isTeam: e.isTeam,
          teamMemberCount: e.teamMemberCount,
          days: e.days,
          gongsu: e.gongsu,
          amount: e.amount,
        })),
        subtotalDays: s.subtotalDays,
        subtotalGongsu: s.subtotalGongsu,
        subtotalAmount: s.subtotalAmount,
      })),
      totalDays: totals.totalDays,
      totalGongsu: totals.totalGongsu,
      totalAmount: totals.totalAmount,
    };
    return this.pdf.renderSiteCostsPdf(data);
  }

  /** 현장별 인건비 집계용 확인서 → 정규화 행 + 사업장명. */
  private async siteCostRows(
    userId: string,
    businessIds: string[],
    range: { start: Date; end: Date },
  ): Promise<{ rows: SiteCostInputRow[]; businessName: string }> {
    const businessName = await this.scopedBusinessName(userId, businessIds);
    if (businessIds.length === 0) return { rows: [], businessName };
    const confirmations = await this.prisma.confirmation.findMany({
      where: {
        businessId: { in: businessIds },
        status: ConfirmationStatus.SIGNED,
        date: { gte: range.start, lt: range.end },
      },
      include: { profile: { select: { id: true, name: true } } },
      orderBy: { date: 'asc' },
    });
    const rows: SiteCostInputRow[] = confirmations.map((c) => {
      const wu = workUnitsOf(c);
      return {
        site: c.site,
        workerProfileId: c.profile.id,
        workerName: maskName(c.profile.name),
        workDate: toKstDateStr(c.date),
        amount: amountTotalOf(c),
        days: wu.days,
        gongsu: wu.gongsu,
        isTeam: wu.isTeam,
        teamMemberCount: wu.teamMemberCount,
      };
    });
    return { rows, businessName };
  }

  /** from&to(YYYY-MM) → [start,end) instant. 최대 12개월. */
  private resolveSiteRange(
    from: string,
    to: string,
  ): { from: string; to: string; start: Date; end: Date } {
    this.assertMonth(from);
    this.assertMonth(to);
    const [fy, fm] = from.split('-').map((n) => parseInt(n, 10));
    const [ty, tm] = to.split('-').map((n) => parseInt(n, 10));
    const startIdx = fy * 12 + (fm - 1);
    const endIdx = ty * 12 + (tm - 1);
    if (endIdx < startIdx) {
      throw new AppException(
        'INVALID_RANGE',
        'from 은 to 보다 이후일 수 없습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    if (endIdx - startIdx > 11) {
      throw new AppException(
        'RANGE_TOO_LONG',
        '조회 범위는 최대 12개월입니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const start = new Date(`${from}-01T00:00:00+09:00`);
    const { end } = kstMonthRange(to);
    return { from, to, start, end };
  }

  // ==========================================================================
  //  P5a-2. 일용근로소득 지급명세서 도우미 (지급 paidAt 기준) + 월 마감 표시
  // ==========================================================================
  async wageStatement(userId: string, month: string, businessId?: string) {
    this.assertMonth(month);
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    const businessName = await this.scopedBusinessName(userId, businessIds);
    const { start, end } = kstMonthRange(month);

    const rows: WagePaymentRow[] = [];
    if (businessIds.length > 0) {
      const entries = await this.prisma.ledgerEntry.findMany({
        where: {
          businessId: { in: businessIds },
          confirmation: { status: ConfirmationStatus.SIGNED },
        },
        include: {
          confirmation: true,
          profile: { select: { id: true, name: true } },
        },
      });
      for (const e of entries) {
        if (!e.confirmation) continue;
        const payments = Array.isArray(e.payments)
          ? (e.payments as unknown as PaymentRecord[])
          : [];
        // 이 확인서(지급 건)의 당월 지급 합계(부분입금 여러 건이면 합산).
        let paidInMonth = 0;
        for (const p of payments) {
          if (!p.paidAt) continue;
          const at = new Date(p.paidAt);
          if (at >= start && at < end) paidInMonth += Math.round(p.amount);
        }
        if (paidInMonth <= 0) continue;
        const wu = workUnitsOf(e.confirmation);
        rows.push({
          workerProfileId: e.profile.id,
          workerName: maskName(e.profile.name),
          amount: paidInMonth,
          days: wu.days,
          workDate: toKstDateStr(e.confirmation.date),
        });
      }
    }

    const { workers, totals } = aggregateWageStatement(rows);
    const marked = await this.isMonthMarked(userId, businessIds, month);
    return {
      month,
      businessName,
      marked,
      workers,
      totals,
      notes: wageStatementNotes(),
      hometaxNote:
        '주민등록번호는 본 앱에서 수집·저장하지 않습니다. 홈택스 지급명세서 제출 시 직접 입력하세요.',
      copyText: formatWageStatementText(month, businessName, workers),
    };
  }

  /** 월 마감 표시(홈택스 입력 완료). 멱등 — 이미 표시된 월이면 추가 없음. */
  async wageStatementMark(userId: string, month: string, businessId?: string) {
    this.assertMonth(month);
    const business = await this.resolveOwnedBusiness(userId, businessId);
    const already = business.wageMarkedMonths.includes(month);
    if (!already) {
      await this.prisma.business.update({
        where: { id: business.id },
        data: { wageMarkedMonths: { push: month } },
      });
    }
    return {
      businessId: business.id,
      month,
      marked: true,
      alreadyMarked: already,
    };
  }

  private async isMonthMarked(
    userId: string,
    businessIds: string[],
    month: string,
  ): Promise<boolean> {
    if (businessIds.length === 0) return false;
    const rows = await this.prisma.business.findMany({
      where: { id: { in: businessIds }, ownerId: userId },
      select: { wageMarkedMonths: true },
    });
    if (rows.length === 0) return false;
    // 스코프 내 모든 사업장이 해당 월을 마감했을 때만 marked.
    return rows.every((b) => b.wageMarkedMonths.includes(month));
  }

  // ==========================================================================
  //  P5a-3. 오늘의 출역 현황판 (오늘 KST jobs → 현장별 그룹 + 인원 요약)
  // ==========================================================================
  async todayAttendance(userId: string, businessId?: string) {
    const businessIds = await this.scopedBusinessIds(userId, businessId);
    const todayStr = toKstDateStr(new Date());
    const start = kstDate(todayStr);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);

    if (businessIds.length === 0) {
      return {
        date: todayStr,
        sites: [],
        summary: { total: 0, attended: 0, completed: 0, absent: 0 },
      };
    }

    const jobs = await this.prisma.job.findMany({
      where: {
        businessId: { in: businessIds },
        scheduledAt: { gte: start, lt: end },
      },
      include: {
        profile: { select: { id: true, name: true } },
        workLogs: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: [{ site: 'asc' }, { scheduledAt: 'asc' }],
    });

    const siteMap = new Map<string, AttendanceWorker[]>();
    let total = 0;
    let attended = 0;
    let completed = 0;

    for (const j of jobs) {
      const wl = j.workLogs[0];
      let status: AttendanceWorker['status'];
      if (j.status === JobStatus.CANCELLED) status = 'CANCELLED';
      else if (j.status === JobStatus.DONE) status = 'DONE';
      else if (j.status === JobStatus.IN_PROGRESS) status = 'STARTED';
      else if (j.acceptedAt) status = 'ACCEPTED';
      else status = 'SCHEDULED';

      if (status !== 'CANCELLED') {
        total += 1;
        if (status === 'STARTED' || status === 'DONE') attended += 1;
        if (status === 'DONE') completed += 1;
      }

      const cond =
        wl?.conditionCheck &&
        typeof (wl.conditionCheck as { result?: unknown }).result === 'string'
          ? ((wl.conditionCheck as { result: string }).result as string)
          : null;

      const arr = siteMap.get(j.site) ?? [];
      arr.push({
        jobId: j.id,
        workerName: maskName(j.profile.name),
        status,
        scheduledAt: toKstTimeStr(j.scheduledAt),
        startedAt: wl?.startedAt ? toKstTimeStr(wl.startedAt) : null,
        finishedAt: wl?.finishedAt ? toKstTimeStr(wl.finishedAt) : null,
        condition: cond,
      });
      siteMap.set(j.site, arr);
    }

    const sites = [...siteMap.entries()].map(([site, workers]) => {
      const active = workers.filter((w) => w.status !== 'CANCELLED');
      const siteCompleted = active.filter((w) => w.status === 'DONE').length;
      const siteAttended = active.filter(
        (w) => w.status === 'STARTED' || w.status === 'DONE',
      ).length;
      return {
        site,
        workers,
        summary: {
          total: active.length,
          attended: siteAttended,
          completed: siteCompleted,
          absent: active.length - siteAttended,
        },
      };
    });

    return {
      date: todayStr,
      sites,
      summary: { total, attended, completed, absent: total - attended },
    };
  }

  /** 스코프 사업장들의 상호를 합쳐 표시(헤더용). */
  private async scopedBusinessName(
    userId: string,
    businessIds: string[],
  ): Promise<string> {
    const owned = await this.prisma.business.findMany({
      where: {
        ownerId: userId,
        ...(businessIds.length ? { id: { in: businessIds } } : {}),
      },
      select: { name: true },
      orderBy: { createdAt: 'asc' },
    });
    return owned.map((b) => b.name).join(', ') || '내 사업장';
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
