import { LedgerEntry, LedgerStatus } from '@prisma/client';
import { computeOutstanding, PaymentRecord } from './ledger.util';

const STATUS_LABEL: Record<LedgerStatus, string> = {
  PENDING: '미수',
  PARTIAL: '부분입금',
  PAID: '전액입금',
  OVERDUE: '기한지남',
};

export interface LedgerDto {
  id: string;
  confirmationId: string | null;
  sourceConfirmationId: string | null; // 팀 파생 항목의 원 확인서(반장 팀 확인서)
  derived: boolean; // 팀 파생(팀원 몫) — 읽기전용(입금 기록만 가능)
  businessId: string | null;
  counterpartyName: string | null;
  amount: number;
  paid: number;
  outstanding: number;
  status: LedgerStatus;
  statusLabel: string;
  dueDate: Date | null;
  dday: number | null;
  payments: PaymentRecord[];
  createdAt: Date;
  updatedAt: Date;
}

/** LedgerEntry → API DTO (미수/상태/D-day 파생). */
export function toLedgerDto(e: LedgerEntry, now: Date = new Date()): LedgerDto {
  const amount = Number(e.amount);
  const { paid, outstanding, status, dday } = computeOutstanding(
    amount,
    e.payments,
    e.dueDate,
    now,
  );
  return {
    id: e.id,
    confirmationId: e.confirmationId,
    sourceConfirmationId: e.sourceConfirmationId,
    derived: e.derived,
    businessId: e.businessId,
    counterpartyName: e.counterpartyName,
    amount,
    paid,
    outstanding,
    status,
    statusLabel: STATUS_LABEL[status],
    dueDate: e.dueDate,
    dday,
    payments: Array.isArray(e.payments)
      ? (e.payments as unknown as PaymentRecord[])
      : [],
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  };
}

export { STATUS_LABEL };
