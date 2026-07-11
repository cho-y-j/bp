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

type EntryWithRefs = LedgerEntry & {
  confirmation: Confirmation | null;
  business: Business | null;
};

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
      totalGongsu += this.gongsuOf(e.confirmation);
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
        const dto = toLedgerDto(e, now);
        return {
          ...dto,
          companyName: e.business?.name ?? e.counterpartyName ?? '(미지정)',
          siteName: e.confirmation?.site ?? null,
          date: e.confirmation ? toKstDateStr(e.confirmation.date) : null,
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
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  /** 장부 항목의 기준 날짜: 연결 확인서의 작업일 우선, 없으면 생성일. */
  private effectiveDate(e: EntryWithRefs): Date {
    return e.confirmation?.date ?? e.createdAt;
  }

  /** 연결 확인서가 공수(GONGSU) 유형이면 기본항목 공수 수량, 아니면 0. */
  private gongsuOf(confirmation: Confirmation | null): number {
    if (!confirmation || confirmation.rateType !== 'GONGSU') return 0;
    const calc = confirmation.amountCalc as unknown as {
      items?: Array<{ type: string; quantity?: number }>;
    } | null;
    const base = calc?.items?.find((i) => i.type === 'BASE');
    return typeof base?.quantity === 'number' ? base.quantity : 0;
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
          {
            confirmationId: null,
            createdAt: { gte: start, lt: end },
          },
        ],
      },
      include: { confirmation: true, business: true },
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
