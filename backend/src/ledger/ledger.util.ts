/**
 * 장부 집계 유틸 (순수 함수 — 단위 테스트 대상).
 *  - 부분입금 합산 → 미수/상태 계산.
 *  - 상태 전이: PENDING → PARTIAL → PAID, 기한 지남+미완납이면 OVERDUE.
 *  - 수금예정일 D-day 는 공통 dday.util(KST 기준) 재사용.
 */
import { LedgerStatus } from '@prisma/client';
import { computeDday } from '../common/dday.util';

export interface PaymentRecord {
  amount: number;
  paidAt?: string; // ISO
  memo?: string;
}

/** payments JSONB[] 의 입금 합계(정수 원). 잘못된 값은 무시. */
export function sumPayments(payments: unknown): number {
  if (!Array.isArray(payments)) return 0;
  let total = 0;
  for (const p of payments) {
    const amt = (p as PaymentRecord)?.amount;
    if (typeof amt === 'number' && Number.isFinite(amt) && amt > 0) {
      total += Math.round(amt);
    }
  }
  return total;
}

/**
 * 입금 합계·금액·수금예정일로부터 장부 상태를 계산한다.
 *  - paid >= amount            → PAID
 *  - 0 < paid < amount         → PARTIAL (단, 기한 지남이면 OVERDUE)
 *  - paid == 0                 → PENDING (단, 기한 지남이면 OVERDUE)
 * 완납(PAID)은 기한과 무관하게 PAID 우선.
 */
export function deriveLedgerStatus(
  amount: number,
  paid: number,
  dueDate: Date | null,
  now: Date = new Date(),
): LedgerStatus {
  if (paid >= amount && amount > 0) return LedgerStatus.PAID;
  if (paid >= amount && amount === 0) return LedgerStatus.PAID;

  const overdue = dueDate ? computeDday(dueDate, now) < 0 : false;
  if (overdue) return LedgerStatus.OVERDUE;
  if (paid > 0) return LedgerStatus.PARTIAL;
  return LedgerStatus.PENDING;
}

export interface OutstandingResult {
  amount: number;
  paid: number;
  outstanding: number; // 미수 (amount - paid, 최소 0)
  status: LedgerStatus;
  dday: number | null; // 수금예정일 D-day (없으면 null)
}

/** 단일 장부 항목의 미수/상태/D-day 를 한 번에 계산. */
export function computeOutstanding(
  amount: number,
  payments: unknown,
  dueDate: Date | null,
  now: Date = new Date(),
): OutstandingResult {
  const paid = sumPayments(payments);
  const outstanding = Math.max(0, amount - paid);
  const status = deriveLedgerStatus(amount, paid, dueDate, now);
  const dday = dueDate ? computeDday(dueDate, now) : null;
  return { amount, paid, outstanding, status, dday };
}
