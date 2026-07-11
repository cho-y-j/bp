import {
  buildTaxInvoiceGroups,
  computeTax,
  formatTaxInvoiceText,
  TaxInvoiceSourceRow,
} from './tax-invoice.util';

describe('tax-invoice.util (세금계산서 1단계 집계)', () => {
  describe('computeTax', () => {
    it('공급가액의 10% 반올림', () => {
      expect(computeTax(1000000)).toBe(100000);
      expect(computeTax(270000)).toBe(27000);
      expect(computeTax(15)).toBe(2); // 1.5 → 2 반올림
      expect(computeTax(0)).toBe(0);
      expect(computeTax(-5)).toBe(0);
    });
  });

  describe('buildTaxInvoiceGroups', () => {
    const rows: TaxInvoiceSourceRow[] = [
      {
        ledgerId: 'l1',
        businessId: 'b1',
        buyerName: '대한건설',
        buyerBizNumber: '123-45-67890',
        date: '2026-07-05',
        content: '터파기',
        supplyAmount: 300000,
      },
      {
        ledgerId: 'l2',
        businessId: 'b1',
        buyerName: '대한건설',
        buyerBizNumber: '123-45-67890',
        date: '2026-07-03',
        content: '정리',
        supplyAmount: 150000,
      },
      {
        ledgerId: 'l3',
        businessId: null,
        buyerName: '개인현장',
        buyerBizNumber: null,
        date: '2026-07-10',
        content: '상차',
        supplyAmount: 200000,
      },
    ];

    it('상대별 그룹핑 + 공급가/세액/합계 집계 + 품목 날짜순', () => {
      const groups = buildTaxInvoiceGroups(rows, '2026-07-11');
      expect(groups).toHaveLength(2);

      // 공급가 큰 상대(대한건설 450,000) 먼저
      const daehan = groups[0];
      expect(daehan.buyerName).toBe('대한건설');
      expect(daehan.supplyTotal).toBe(450000);
      expect(daehan.taxTotal).toBe(45000);
      expect(daehan.grandTotal).toBe(495000);
      expect(daehan.buyerRegistered).toBe(true);
      expect(daehan.ledgerIds).toEqual(['l1', 'l2']);
      // 품목은 날짜 오름차순 (07-03 먼저)
      expect(daehan.items.map((i) => i.date)).toEqual([
        '2026-07-03',
        '2026-07-05',
      ]);

      const personal = groups[1];
      expect(personal.buyerName).toBe('개인현장');
      expect(personal.buyerBizNumber).toBeNull();
      expect(personal.buyerRegistered).toBe(false);
      expect(personal.supplyTotal).toBe(200000);
      expect(personal.taxTotal).toBe(20000);
    });

    it('빈 입력 → 빈 그룹', () => {
      expect(buildTaxInvoiceGroups([], '2026-07-11')).toHaveLength(0);
    });
  });

  describe('formatTaxInvoiceText', () => {
    it('공급자·상대·공급가/세액·품목이 텍스트에 포함', () => {
      const groups = buildTaxInvoiceGroups(
        [
          {
            ledgerId: 'l1',
            businessId: 'b1',
            buyerName: '대한건설',
            buyerBizNumber: '123-45-67890',
            date: '2026-07-05',
            content: '터파기',
            supplyAmount: 300000,
          },
        ],
        '2026-07-11',
      );
      const text = formatTaxInvoiceText(
        {
          name: '김기사',
          bizNumber: '111-22-33333',
          bizName: '김기사중기',
          bizAddress: '서울시 강남구',
        },
        groups,
      );
      expect(text).toContain('공급자');
      expect(text).toContain('111-22-33333');
      expect(text).toContain('대한건설');
      expect(text).toContain('123-45-67890');
      expect(text).toContain('공급가액: 300,000원');
      expect(text).toContain('세액(10%): 30,000원');
      expect(text).toContain('합계금액: 330,000원');
      expect(text).toContain('2026-07-05  터파기  300,000원');
    });

    it('발행 대상 없으면 안내 문구', () => {
      const text = formatTaxInvoiceText(
        { name: null, bizNumber: null, bizName: null, bizAddress: null },
        [],
      );
      expect(text).toContain('발행 대상');
    });
  });
});
