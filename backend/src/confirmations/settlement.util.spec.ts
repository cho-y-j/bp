import { computeSettlement } from './settlement.util';

describe('computeSettlement', () => {
  const NO_DUE = null;

  it('입금 0 → UNPAID, 전액 미수', () => {
    const s = computeSettlement(260000, [], NO_DUE);
    expect(s).toEqual({
      paidAmount: 0,
      outstandingAmount: 260000,
      status: 'UNPAID',
    });
  });

  it('일부 입금 → PARTIAL, 미수 잔존', () => {
    const s = computeSettlement(260000, [{ amount: 100000 }], NO_DUE);
    expect(s).toEqual({
      paidAmount: 100000,
      outstandingAmount: 160000,
      status: 'PARTIAL',
    });
  });

  it('완납 → PAID, 미수 0', () => {
    const s = computeSettlement(
      260000,
      [{ amount: 100000 }, { amount: 160000 }],
      NO_DUE,
    );
    expect(s).toEqual({
      paidAmount: 260000,
      outstandingAmount: 0,
      status: 'PAID',
    });
  });

  it('초과 입금 → PAID, 미수 0 (음수 방지)', () => {
    const s = computeSettlement(100000, [{ amount: 150000 }], NO_DUE);
    expect(s.status).toBe('PAID');
    expect(s.outstandingAmount).toBe(0);
    expect(s.paidAmount).toBe(150000);
  });

  it('연체(OVERDUE)여도 입금 0 이면 UNPAID 로 축약(색은 미수 주황)', () => {
    const past = new Date('2020-01-01T00:00:00Z');
    const now = new Date('2026-07-18T00:00:00Z');
    const s = computeSettlement(200000, [], past, now);
    expect(s.status).toBe('UNPAID');
    expect(s.outstandingAmount).toBe(200000);
  });

  it('연체 + 일부 입금 → PARTIAL', () => {
    const past = new Date('2020-01-01T00:00:00Z');
    const now = new Date('2026-07-18T00:00:00Z');
    const s = computeSettlement(200000, [{ amount: 50000 }], past, now);
    expect(s.status).toBe('PARTIAL');
    expect(s.paidAmount).toBe(50000);
    expect(s.outstandingAmount).toBe(150000);
  });
});
