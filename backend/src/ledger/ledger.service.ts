import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  Business,
  Confirmation,
  ConfirmationStatus,
  LedgerEntry,
  LedgerStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { computeDday } from '../common/dday.util';
import { PdfService } from '../documents/pdf.service';
import type {
  StatementCompanyGroup,
  StatementPdfData,
} from '../documents/pdf.types';
import {
  kstDate,
  kstMonthRange,
  toKstDateStr,
} from '../confirmations/time.util';
import {
  computeOutstanding,
  deriveLedgerStatus,
  sumPayments,
  PaymentRecord,
} from './ledger.util';
import { toLedgerDto, STATUS_LABEL } from './ledger.mapper';
import { AddPaymentDto } from './dto/add-payment.dto';
import { UpdateLedgerDto } from './dto/update-ledger.dto';
import {
  buildTaxInvoiceGroups,
  formatTaxInvoiceText,
  type TaxInvoiceSourceRow,
  type TaxInvoiceSupplier,
} from './tax-invoice.util';
import {
  aggregateIncomeReport,
  incomeTaxNoticeKo,
  type IncomeReportInputRow,
} from './income-report.util';

type EntryWithRefs = LedgerEntry & {
  confirmation: Confirmation | null;
  sourceConfirmation: Confirmation | null;
  business: Business | null;
};

/** 소득 리포트 조회 파라미터(year 또는 from&to). */
export interface IncomeReportQuery {
  year?: string | number;
  from?: string; // YYYY-MM
  to?: string; // YYYY-MM
}

interface ResolvedRange {
  from: string; // YYYY-MM
  to: string; // YYYY-MM
  year?: number;
  months: string[]; // from..to (양끝 포함)
  start: Date; // instant (KST 월 시작)
  end: Date; // instant (to 다음 달 시작, 미포함)
}

/** "YYYY-MM" from..to(양끝 포함) 월 목록. 역순/과도한 범위는 예외. */
function enumerateMonths(from: string, to: string): string[] {
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
  if (endIdx - startIdx > 23) {
    throw new AppException(
      'RANGE_TOO_LONG',
      '조회 범위는 최대 24개월입니다.',
      HttpStatus.BAD_REQUEST,
    );
  }
  const months: string[] = [];
  for (let i = startIdx; i <= endIdx; i++) {
    const y = Math.floor(i / 12);
    const m = (i % 12) + 1;
    months.push(`${y}-${String(m).padStart(2, '0')}`);
  }
  return months;
}

@Injectable()
export class LedgerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pdf: PdfService,
    private readonly config: ConfigService,
  ) {}

  // --------------------------------------------------------------------------
  // 월 합계 (일한 날 수 / 총 청구액 / 미수 합계 / 입금 합계)
  // --------------------------------------------------------------------------
  async summary(userId: string, month: string) {
    this.assertMonth(month);
    const now = new Date();
    const entries = await this.entriesForMonth(userId, month);

    const workDates = new Set<string>();
    let totalBilled = 0;
    let totalOutstanding = 0;
    let totalPaid = 0;
    let totalGongsu = 0; // 공수 확인서의 공수 합계(별도 집계)
    for (const e of entries) {
      const amount = Number(e.amount);
      const { paid, outstanding } = computeOutstanding(
        amount,
        e.payments,
        e.dueDate,
        now,
      );
      totalBilled += amount;
      totalOutstanding += outstanding;
      totalPaid += paid;
      workDates.add(toKstDateStr(this.effectiveDate(e)));
      totalGongsu += this.gongsuOf(e);
    }
    return {
      month,
      daysWorked: workDates.size,
      totalBilled,
      totalOutstanding,
      totalPaid,
      totalGongsu: Math.round(totalGongsu * 10) / 10, // 부동소수 오차 정리(0.1 단위)
      entryCount: entries.length,
    };
  }

  // --------------------------------------------------------------------------
  // 상대별 집계 (연동 사업장 or 수기명)
  // --------------------------------------------------------------------------
  async byCompany(userId: string, month: string) {
    this.assertMonth(month);
    const now = new Date();
    const entries = await this.entriesForMonth(userId, month);

    interface Group {
      key: string;
      companyName: string;
      businessId: string | null;
      days: Set<string>;
      total: number;
      paid: number;
      outstanding: number;
      nearestDue: Date | null; // 미수 항목 중 가장 이른 수금예정일
      anyOverdue: boolean;
    }
    const groups = new Map<string, Group>();

    for (const e of entries) {
      const businessId = e.businessId;
      const name = e.business?.name ?? e.counterpartyName ?? '(미지정)';
      const key = businessId ? `biz:${businessId}` : `manual:${name}`;
      const g =
        groups.get(key) ??
        ({
          key,
          companyName: name,
          businessId,
          days: new Set<string>(),
          total: 0,
          paid: 0,
          outstanding: 0,
          nearestDue: null,
          anyOverdue: false,
        } as Group);

      const amount = Number(e.amount);
      const { paid, outstanding, status } = computeOutstanding(
        amount,
        e.payments,
        e.dueDate,
        now,
      );
      g.days.add(toKstDateStr(this.effectiveDate(e)));
      g.total += amount;
      g.paid += paid;
      g.outstanding += outstanding;
      if (outstanding > 0 && e.dueDate) {
        if (!g.nearestDue || e.dueDate.getTime() < g.nearestDue.getTime()) {
          g.nearestDue = e.dueDate;
        }
      }
      if (status === LedgerStatus.OVERDUE) g.anyOverdue = true;
      groups.set(key, g);
    }

    const items = [...groups.values()]
      .map((g) => {
        const status = this.groupStatus(g.outstanding, g.paid, g.anyOverdue);
        return {
          companyName: g.companyName,
          businessId: g.businessId,
          days: g.days.size,
          total: g.total,
          paid: g.paid,
          outstanding: g.outstanding,
          dueDate: g.nearestDue,
          dday: g.nearestDue ? computeDday(g.nearestDue, now) : null,
          status,
          statusLabel: STATUS_LABEL[status],
        };
      })
      .sort((a, b) => b.outstanding - a.outstanding);

    return { month, companies: items };
  }

  // --------------------------------------------------------------------------
  // 월별 개별 장부 항목 목록 (앱 장부 상세 — 항목 id로 부분입금 기록에 사용).
  // 상대명(연동 사업장명 or 수기명)·현장·작업일을 함께 내려 클라이언트 그룹화를 돕는다.
  // --------------------------------------------------------------------------
  async entries(userId: string, month: string, businessId?: string) {
    this.assertMonth(month);
    const now = new Date();
    const rows = await this.entriesForMonth(userId, month);
    const items = rows
      .filter((e) => !businessId || e.businessId === businessId)
      .map((e) => {
        const ref = e.confirmation ?? e.sourceConfirmation;
        const dto = toLedgerDto(e, now);
        return {
          ...dto,
          companyName: e.business?.name ?? e.counterpartyName ?? '(미지정)',
          siteName: ref?.site ?? null,
          date: ref ? toKstDateStr(ref.date) : null,
        };
      });
    return { month, count: items.length, items };
  }

  // --------------------------------------------------------------------------
  // 부분입금 기록
  // --------------------------------------------------------------------------
  async addPayment(userId: string, id: string, dto: AddPaymentDto) {
    const entry = await this.ownedOrThrow(userId, id);
    const payment: PaymentRecord = {
      amount: Math.round(dto.amount),
      paidAt: dto.paidAt
        ? kstDate(dto.paidAt).toISOString()
        : new Date().toISOString(),
      memo: dto.memo,
    };
    const payments = Array.isArray(entry.payments)
      ? (entry.payments as unknown as PaymentRecord[])
      : [];
    const nextPayments = [...payments, payment];
    const amount = Number(entry.amount);
    const paid = sumPayments(nextPayments);
    const status = deriveLedgerStatus(amount, paid, entry.dueDate);

    const updated = await this.prisma.ledgerEntry.update({
      where: { id },
      data: {
        payments: nextPayments as unknown as Prisma.InputJsonValue[],
        status,
      },
    });
    return toLedgerDto(updated);
  }

  // --------------------------------------------------------------------------
  // 수금예정일 수정 (+ 상태 재계산)
  // --------------------------------------------------------------------------
  async updateLedger(userId: string, id: string, dto: UpdateLedgerDto) {
    const entry = await this.ownedOrThrow(userId, id);
    // 팀 파생 항목(팀원 몫)은 읽기전용 — 수금예정일 수정 불가(입금 기록만 가능).
    if (entry.derived) {
      throw new AppException(
        'LEDGER_DERIVED_READONLY',
        '팀 작업 파생 항목은 수정할 수 없습니다 (입금 기록만 가능).',
        HttpStatus.CONFLICT,
      );
    }
    const dueDate =
      dto.dueDate === undefined
        ? entry.dueDate
        : dto.dueDate === null
          ? null
          : kstDate(dto.dueDate);

    const amount = Number(entry.amount);
    const paid = sumPayments(entry.payments);
    const status = deriveLedgerStatus(amount, paid, dueDate);

    const updated = await this.prisma.ledgerEntry.update({
      where: { id },
      data: { dueDate, status },
    });
    return toLedgerDto(updated);
  }

  // --------------------------------------------------------------------------
  // 월간 명세서 PDF
  // --------------------------------------------------------------------------
  async statement(userId: string, month: string): Promise<Buffer> {
    this.assertMonth(month);
    const now = new Date();
    const entries = await this.entriesForMonth(userId, month);
    const worker = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { name: true },
    });

    const groups = new Map<
      string,
      StatementCompanyGroup & { _days: Set<string> }
    >();
    for (const e of entries) {
      const name = e.business?.name ?? e.counterpartyName ?? '(미지정)';
      const key = e.businessId ? `biz:${e.businessId}` : `manual:${name}`;
      const g =
        groups.get(key) ??
        ({
          companyName: name,
          days: 0,
          subtotal: 0,
          paid: 0,
          outstanding: 0,
          _days: new Set<string>(),
        } as StatementCompanyGroup & { _days: Set<string> });
      const amount = Number(e.amount);
      const { paid, outstanding } = computeOutstanding(
        amount,
        e.payments,
        e.dueDate,
        now,
      );
      g.subtotal += amount;
      g.paid += paid;
      g.outstanding += outstanding;
      g._days.add(toKstDateStr(this.effectiveDate(e)));
      groups.set(key, g);
    }

    const groupList: StatementCompanyGroup[] = [...groups.values()].map(
      (g) => ({
        companyName: g.companyName,
        days: g._days.size,
        subtotal: g.subtotal,
        paid: g.paid,
        outstanding: g.outstanding,
      }),
    );
    const data: StatementPdfData = {
      title: '월간 명세서',
      month,
      workerName: worker?.name ?? '작업자',
      groups: groupList,
      totalDays: groupList.reduce((s, g) => s + g.days, 0),
      totalAmount: groupList.reduce((s, g) => s + g.subtotal, 0),
      totalPaid: groupList.reduce((s, g) => s + g.paid, 0),
      totalOutstanding: groupList.reduce((s, g) => s + g.outstanding, 0),
    };
    return this.pdf.renderStatementPdf(data);
  }

  // --------------------------------------------------------------------------
  // 세금계산서 1단계 — 홈택스 입력용 데이터 정리 (상대별)
  //  - SIGNED 확인서 + 미발행(taxInvoicedAt=null) 항목만 집계.
  //  - 공급가액=확인서 amountCalc.subtotal, 세액=10%. JSON + 복사용 텍스트 반환.
  // --------------------------------------------------------------------------
  async taxInvoiceData(userId: string, month: string, businessId?: string) {
    this.assertMonth(month);
    const rows = await this.entriesForMonth(userId, month);
    const supplierProfile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { name: true, bizNumber: true, bizName: true, bizAddress: true },
    });
    const supplier: TaxInvoiceSupplier = {
      name: supplierProfile?.name ?? null,
      bizNumber: supplierProfile?.bizNumber ?? null,
      bizName: supplierProfile?.bizName ?? null,
      bizAddress: supplierProfile?.bizAddress ?? null,
    };

    const sourceRows: TaxInvoiceSourceRow[] = rows
      .filter((e) => {
        const c = e.confirmation;
        if (!c || c.status !== ConfirmationStatus.SIGNED) return false;
        if (e.taxInvoicedAt) return false; // 이미 발행 표시된 항목 제외
        if (businessId && e.businessId !== businessId) return false;
        return true;
      })
      .map((e) => {
        const c = e.confirmation as Confirmation;
        const calc = c.amountCalc as unknown as { subtotal?: number } | null;
        return {
          ledgerId: e.id,
          businessId: e.businessId,
          buyerName: e.business?.name ?? e.counterpartyName ?? '(미지정)',
          buyerBizNumber: e.business?.businessNumber ?? null,
          date: toKstDateStr(c.date),
          content: c.workContent,
          supplyAmount: typeof calc?.subtotal === 'number' ? calc.subtotal : 0,
        };
      });

    const writeDate = toKstDateStr(new Date());
    const groups = buildTaxInvoiceGroups(sourceRows, writeDate);
    const supplierReady = !!supplier.bizNumber;
    return {
      month,
      businessId: businessId ?? null,
      writeDate,
      supplier,
      supplierReady, // false 면 PATCH /me 로 bizNumber 등록 안내
      groupCount: groups.length,
      groups,
      text: formatTaxInvoiceText(supplier, groups),
    };
  }

  // --------------------------------------------------------------------------
  // 세금계산서 발행(홈택스 입력) 완료 표시 — 이후 집계에서 제외
  // --------------------------------------------------------------------------
  async markTaxInvoiced(userId: string, ledgerIds: string[]) {
    const uniqueIds = [...new Set(ledgerIds)];
    // 소유 검증: 내 장부 항목만 표시 가능.
    const owned = await this.prisma.ledgerEntry.findMany({
      where: { id: { in: uniqueIds }, profileId: userId },
      select: { id: true, taxInvoicedAt: true },
    });
    if (owned.length !== uniqueIds.length) {
      throw new AppException(
        'LEDGER_NOT_FOUND',
        '일부 장부 항목을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const now = new Date();
    // 아직 표시 안 된 항목만 표시(재표시 방지, 최초 시각 보존).
    const toMark = owned.filter((e) => !e.taxInvoicedAt).map((e) => e.id);
    if (toMark.length > 0) {
      await this.prisma.ledgerEntry.updateMany({
        where: { id: { in: toMark }, profileId: userId, taxInvoicedAt: null },
        data: { taxInvoicedAt: now },
      });
    }
    return {
      marked: toMark.length,
      alreadyMarked: uniqueIds.length - toMark.length,
      taxInvoicedAt: now,
    };
  }

  // --------------------------------------------------------------------------
  // 연간(기간별) 소득 리포트 — 월별 추이 / 상대별 / 총계 / 팀 지급분 / 종소세 안내
  //  - year 또는 from&to(YYYY-MM, 분기 등) 지원.
  //  - 팀 파생: 팀원 파생 항목은 본인 소득으로 집계, 반장은 팀 확인서 전체가 매출이며
  //    팀원 지급분(teamPayout)을 별도 표기해 순소득(netBilled) 참고 제공(차감 아님).
  // --------------------------------------------------------------------------
  async incomeReport(userId: string, opts: IncomeReportQuery) {
    const range = this.resolveRange(opts);
    const rows = await this.normalizeIncomeRows(userId, range);
    const { monthly, companies, totals } = aggregateIncomeReport(
      rows,
      range.months,
    );
    return {
      range: { from: range.from, to: range.to, year: range.year ?? null },
      monthly,
      companies,
      totals,
      taxNote: incomeTaxNoticeKo(this.rangeLabel(range)),
    };
  }

  async incomeReportPdf(
    userId: string,
    opts: IncomeReportQuery,
  ): Promise<Buffer> {
    const range = this.resolveRange(opts);
    const rows = await this.normalizeIncomeRows(userId, range);
    const { monthly, companies, totals } = aggregateIncomeReport(
      rows,
      range.months,
    );
    const worker = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { name: true },
    });
    const note = incomeTaxNoticeKo(this.rangeLabel(range));
    return this.pdf.renderIncomeReportPdf({
      title: '연간 소득 리포트',
      periodLabel: this.rangeLabel(range),
      workerName: worker?.name ?? '작업자',
      monthly,
      companies,
      totals,
      taxNoteLines: note.lines,
    });
  }

  /** year 또는 from/to 로부터 리포트 대상 월 범위·목록·instant 경계를 계산한다. */
  private resolveRange(opts: IncomeReportQuery): ResolvedRange {
    let from: string;
    let to: string;
    let year: number | undefined;
    if (opts.year != null && opts.year !== '') {
      if (!/^\d{4}$/.test(String(opts.year))) {
        throw new AppException(
          'INVALID_YEAR',
          'year 는 YYYY 형식이어야 합니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      year = parseInt(String(opts.year), 10);
      from = `${year}-01`;
      to = `${year}-12`;
    } else if (opts.from && opts.to) {
      this.assertMonth(opts.from);
      this.assertMonth(opts.to);
      from = opts.from;
      to = opts.to;
    } else {
      throw new AppException(
        'INVALID_RANGE',
        'year 또는 from&to(YYYY-MM)를 지정해야 합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const months = enumerateMonths(from, to); // from>to 또는 24개월 초과 시 예외
    const start = new Date(`${from}-01T00:00:00+09:00`);
    const { end } = kstMonthRange(to);
    return { from, to, year, months, start, end };
  }

  private rangeLabel(range: ResolvedRange): string {
    if (range.year != null) return `${range.year}년`;
    return `${range.from} ~ ${range.to}`;
  }

  /** 기간 내 장부 항목을 소득 집계용 정규화 행으로 변환. */
  private async normalizeIncomeRows(
    userId: string,
    range: ResolvedRange,
  ): Promise<IncomeReportInputRow[]> {
    const now = new Date();
    const entries = await this.entriesForRange(userId, range.start, range.end);
    return entries.map((e) => {
      const amount = Number(e.amount);
      const { paid, outstanding } = computeOutstanding(
        amount,
        e.payments,
        e.dueDate,
        now,
      );
      const workDate = toKstDateStr(this.effectiveDate(e));
      return {
        month: workDate.slice(0, 7),
        workDate,
        amount,
        paid,
        outstanding,
        gongsu: this.gongsuOf(e),
        businessId: e.businessId,
        companyName: e.business?.name ?? e.counterpartyName ?? '(미지정)',
        teamPayout: this.teamPayoutOf(e, userId),
        derived: e.derived,
      };
    });
  }

  /** [start, end) instant 범위의 장부 항목(월간 조회와 동일 기준, 범위만 확장). */
  private async entriesForRange(
    userId: string,
    start: Date,
    end: Date,
  ): Promise<EntryWithRefs[]> {
    return this.prisma.ledgerEntry.findMany({
      where: {
        profileId: userId,
        OR: [
          { confirmation: { date: { gte: start, lt: end } } },
          { sourceConfirmation: { date: { gte: start, lt: end } } },
          {
            confirmationId: null,
            sourceConfirmationId: null,
            createdAt: { gte: start, lt: end },
          },
        ],
      },
      include: { confirmation: true, sourceConfirmation: true, business: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  // --------------------------------------------------------------------------
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  /** 장부 항목의 기준 날짜: 연결 확인서(또는 팀 파생 원 확인서)의 작업일 우선, 없으면 생성일. */
  private effectiveDate(e: EntryWithRefs): Date {
    return e.confirmation?.date ?? e.sourceConfirmation?.date ?? e.createdAt;
  }

  /**
   * 장부 항목의 공수 합계 기여분.
   *  - 반장 팀 확인서(teamEntries): 팀원 공수 합계.
   *  - 팀 파생 항목(팀원 몫, sourceConfirmation): 자기 몫의 공수.
   *  - 일반 GONGSU 확인서: 기본항목 공수 수량.
   */
  private gongsuOf(e: EntryWithRefs): number {
    // 팀 파생 항목: 원 확인서 teamEntries 에서 이 사람 몫 공수 합.
    if (e.derived && e.sourceConfirmation) {
      const te = this.teamEntriesOf(e.sourceConfirmation);
      return te
        .filter((x) => x.profileId === e.profileId)
        .reduce((s, x) => s + (x.quantity ?? 0), 0);
    }
    const confirmation = e.confirmation;
    if (!confirmation) return 0;
    // 반장 팀 확인서: 팀원 공수 합계.
    const teamEntries = this.teamEntriesOf(confirmation);
    if (teamEntries.length > 0) {
      return teamEntries.reduce((s, x) => s + (x.quantity ?? 0), 0);
    }
    if (confirmation.rateType !== 'GONGSU') return 0;
    const calc = confirmation.amountCalc as unknown as {
      items?: Array<{ type: string; quantity?: number }>;
    } | null;
    const base = calc?.items?.find((i) => i.type === 'BASE');
    return typeof base?.quantity === 'number' ? base.quantity : 0;
  }

  private teamEntriesOf(
    confirmation: Confirmation,
  ): Array<{ profileId?: string | null; quantity?: number; amount?: number }> {
    const te = confirmation.teamEntries as unknown;
    return Array.isArray(te)
      ? (te as Array<{
          profileId?: string | null;
          quantity?: number;
          amount?: number;
        }>)
      : [];
  }

  /**
   * 반장 팀 확인서에서 팀원(본인 제외)에게 지급되는 몫 합계(팀 지급분).
   *  - 팀 확인서(teamEntries 有, 비-파생)만 대상. 파생 항목/일반 항목은 0.
   *  - 반장 본인 몫(profileId === userId)은 제외 → 순소득(netBilled) 참고 계산에 사용.
   */
  private teamPayoutOf(e: EntryWithRefs, userId: string): number {
    if (e.derived || !e.confirmation) return 0;
    const te = this.teamEntriesOf(e.confirmation);
    if (te.length === 0) return 0;
    return te
      .filter((x) => x.profileId !== userId)
      .reduce((s, x) => s + (typeof x.amount === 'number' ? x.amount : 0), 0);
  }

  private groupStatus(
    outstanding: number,
    paid: number,
    anyOverdue: boolean,
  ): LedgerStatus {
    if (outstanding <= 0) return LedgerStatus.PAID;
    if (anyOverdue) return LedgerStatus.OVERDUE;
    if (paid > 0) return LedgerStatus.PARTIAL;
    return LedgerStatus.PENDING;
  }

  /** 해당 월(KST)의 장부 항목: 확인서 작업일 우선, 없으면 생성일 기준. */
  private async entriesForMonth(
    userId: string,
    month: string,
  ): Promise<EntryWithRefs[]> {
    const { start, end } = kstMonthRange(month);
    return this.prisma.ledgerEntry.findMany({
      where: {
        profileId: userId,
        OR: [
          { confirmation: { date: { gte: start, lt: end } } },
          // 팀 파생 항목: 원 확인서(반장 팀 확인서)의 작업일 기준으로 월 집계.
          { sourceConfirmation: { date: { gte: start, lt: end } } },
          {
            confirmationId: null,
            sourceConfirmationId: null,
            createdAt: { gte: start, lt: end },
          },
        ],
      },
      include: { confirmation: true, sourceConfirmation: true, business: true },
      orderBy: { createdAt: 'asc' },
    });
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

  private async ownedOrThrow(userId: string, id: string): Promise<LedgerEntry> {
    const entry = await this.prisma.ledgerEntry.findUnique({ where: { id } });
    if (!entry || entry.profileId !== userId) {
      throw new AppException(
        'LEDGER_NOT_FOUND',
        '장부 항목을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return entry;
  }
}
