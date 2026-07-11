import { calcAmount, validateGongsuQuantity } from './amount.util';

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

  describe('GONGSU(공수) 단가유형', () => {
    it('1.5공수 × 180,000 = 270,000, 기본항목 unit=공수', () => {
      const r = calcAmount({ rateType: 'GONGSU', rate: 180000, quantity: 1.5 });
      expect(r.items).toHaveLength(1);
      expect(r.items[0]).toMatchObject({
        type: 'BASE',
        label: '기본(공수)',
        unit: '공수',
        rate: 180000,
        quantity: 1.5,
        amount: 270000,
      });
      expect(r.subtotal).toBe(270000);
      expect(r.total).toBe(270000);
    });

    it('0.5공수 × 200,000 = 100,000', () => {
      const r = calcAmount({ rateType: 'GONGSU', rate: 200000, quantity: 0.5 });
      expect(r.items[0].amount).toBe(100000);
      expect(r.subtotal).toBe(100000);
    });

    it('공수 소수 금액 반올림: 0.7공수 × 150,000 = 105,000', () => {
      const r = calcAmount({ rateType: 'GONGSU', rate: 150000, quantity: 0.7 });
      // 150000 * 0.7 = 105000 (정확), 부동소수 오차는 money() 반올림으로 흡수
      expect(r.items[0].amount).toBe(105000);
    });
  });

  describe('validateGongsuQuantity', () => {
    it('0.5/1/1.5 등 0.1 단위는 정규화 반환', () => {
      expect(validateGongsuQuantity(0.5)).toBe(0.5);
      expect(validateGongsuQuantity(1)).toBe(1);
      expect(validateGongsuQuantity(1.5)).toBe(1.5);
      expect(validateGongsuQuantity(0.1)).toBe(0.1);
      expect(validateGongsuQuantity(2.3)).toBe(2.3);
    });

    it('0 이하·0.1 미만 단위·NaN 은 null', () => {
      expect(validateGongsuQuantity(0)).toBeNull();
      expect(validateGongsuQuantity(-1)).toBeNull();
      expect(validateGongsuQuantity(0.05)).toBeNull(); // 0.1 단위 아님
      expect(validateGongsuQuantity(1.25)).toBeNull(); // 0.1 단위 아님
      expect(validateGongsuQuantity(NaN)).toBeNull();
    });
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
