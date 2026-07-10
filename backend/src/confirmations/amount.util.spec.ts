import { calcAmount } from './amount.util';

describe('calcAmount (확인서 금액 계산)', () => {
  it('DAILY 기본: 일당 × 일수', () => {
    const r = calcAmount({ rateType: 'DAILY', rate: 150000, quantity: 2 });
    expect(r.items).toHaveLength(1);
    expect(r.items[0]).toMatchObject({
      type: 'BASE',
      label: '기본(일당)',
      amount: 300000,
    });
    expect(r.subtotal).toBe(300000);
    expect(r.vat).toBe(0);
    expect(r.total).toBe(300000);
  });

  it('HOURLY 기본 + 연장/야간 추가항목 합산', () => {
    const r = calcAmount({
      rateType: 'HOURLY',
      rate: 20000,
      quantity: 8, // 160,000
      additionalItems: [
        { type: 'OVERTIME', rate: 30000, quantity: 2 }, // 60,000
        { type: 'NIGHT', rate: 25000, quantity: 1 }, // 25,000
      ],
    });
    expect(r.items).toHaveLength(3);
    expect(r.items.map((i) => i.amount)).toEqual([160000, 60000, 25000]);
    expect(r.items[1].label).toBe('연장');
    expect(r.items[2].label).toBe('야간');
    expect(r.subtotal).toBe(245000);
    expect(r.total).toBe(245000);
  });

  it('PER_CASE 건당 + 조출/철야/기타(라벨)', () => {
    const r = calcAmount({
      rateType: 'PER_CASE',
      rate: 50000,
      quantity: 3, // 150,000
      additionalItems: [
        { type: 'EARLY', rate: 10000, quantity: 1 },
        { type: 'ALLNIGHT', rate: 40000, quantity: 1 },
        { type: 'OTHER', label: '유류비', rate: 15000, quantity: 1 },
      ],
    });
    expect(r.items[0].label).toBe('기본(건당)');
    expect(r.items[1].label).toBe('조출');
    expect(r.items[2].label).toBe('철야');
    expect(r.items[3].label).toBe('유류비');
    expect(r.subtotal).toBe(215000);
  });

  it('부가세 10% 적용 → vat 반영, total = subtotal + vat', () => {
    const r = calcAmount({
      rateType: 'DAILY',
      rate: 100000,
      quantity: 1,
      vatRate: 0.1,
    });
    expect(r.subtotal).toBe(100000);
    expect(r.vatRate).toBe(0.1);
    expect(r.vat).toBe(10000);
    expect(r.total).toBe(110000);
  });

  it('음수/NaN 방어 → 0 으로 처리', () => {
    const r = calcAmount({
      rateType: 'DAILY',
      rate: -5000,
      quantity: NaN as unknown as number,
      additionalItems: [{ type: 'OVERTIME', rate: -1, quantity: -3 }],
    });
    expect(r.subtotal).toBe(0);
    expect(r.total).toBe(0);
  });

  it('반올림: 소수 단가 × 수량은 정수 원으로', () => {
    const r = calcAmount({
      rateType: 'HOURLY',
      rate: 12345.6,
      quantity: 1.5,
      vatRate: 0.1,
    });
    // 12345.6 * 1.5 = 18518.4 → 18518
    expect(r.items[0].amount).toBe(18518);
    expect(r.subtotal).toBe(18518);
    expect(r.vat).toBe(Math.round(18518 * 0.1)); // 1852
    expect(r.total).toBe(18518 + Math.round(18518 * 0.1));
  });
});
