import { LedgerStatus } from '@prisma/client';
import {
  computeOutstanding,
  deriveLedgerStatus,
  sumPayments,
} from './ledger.util';

const DAY_MS = 24 * 60 * 60 * 1000;

describe('sumPayments', () => {
  it('유효한 입금만 합산, 잘못된 값 무시', () => {
    expect(
      sumPayments([
        { amount: 10000 },
        { amount: 5000 },
        { amount: -3 }, // 무시
        { amount: 'x' } as unknown,
        { foo: 1 } as unknown,
      ]),
    ).toBe(15000);
  });
  it('배열 아님 → 0', () => {
    expect(sumPayments(null)).toBe(0);
    expect(sumPayments(undefined)).toBe(0);
  });
});

describe('deriveLedgerStatus (상태 전이)', () => {
  const future = new Date(Date.now() + 5 * DAY_MS);
  const past = new Date(Date.now() - 5 * DAY_MS);

  it('입금 0 + 기한 전 → PENDING', () => {
    expect(deriveLedgerStatus(100000, 0, future)).toBe(LedgerStatus.PENDING);
  });
  it('부분입금 + 기한 전 → PARTIAL', () => {
    expect(deriveLedgerStatus(100000, 40000, future)).toBe(
      LedgerStatus.PARTIAL,
    );
  });
  it('완납 → PAID (기한 지나도 PAID 우선)', () => {
    expect(deriveLedgerStatus(100000, 100000, past)).toBe(LedgerStatus.PAID);
    expect(deriveLedgerStatus(100000, 120000, future)).toBe(LedgerStatus.PAID);
  });
  it('미완납 + 기한 지남 → OVERDUE (부분입금이어도)', () => {
    expect(deriveLedgerStatus(100000, 0, past)).toBe(LedgerStatus.OVERDUE);
    expect(deriveLedgerStatus(100000, 50000, past)).toBe(LedgerStatus.OVERDUE);
  });
  it('수금예정일 없음 + 미수 → PENDING', () => {
    expect(deriveLedgerStatus(100000, 0, null)).toBe(LedgerStatus.PENDING);
  });
});

describe('computeOutstanding (미수/D-day 통합)', () => {
  it('부분입금 시 미수 = 금액 - 입금, 상태 PARTIAL', () => {
    const r = computeOutstanding(
      100000,
      [{ amount: 30000 }, { amount: 20000 }],
      new Date(Date.now() + 3 * DAY_MS),
    );
    expect(r.paid).toBe(50000);
    expect(r.outstanding).toBe(50000);
    expect(r.status).toBe(LedgerStatus.PARTIAL);
    expect(r.dday).toBe(3);
  });

  it('과입금이어도 미수는 0 (음수 방지), 상태 PAID', () => {
    const r = computeOutstanding(100000, [{ amount: 150000 }], null);
    expect(r.outstanding).toBe(0);
    expect(r.status).toBe(LedgerStatus.PAID);
    expect(r.dday).toBeNull();
  });
});
