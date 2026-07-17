import {
  aggregateWageStatement,
  business33Withholding,
  dailyWageTaxPerDay,
  dailyWageWithholding,
  wageStatementNotes,
  WagePaymentRow,
} from './wage-statement.util';

describe('wage-statement.util — 원천징수 세액 산출', () => {
  describe('business33Withholding (사업소득 3.3%)', () => {
    it('600,000원 → 소득세 18,000 + 지방 1,800 = 19,800, 차인 580,200', () => {
      const w = business33Withholding(600000);
      expect(w.incomeTax).toBe(18000);
      expect(w.localTax).toBe(1800);
      expect(w.totalTax).toBe(19800);
      expect(w.netPay).toBe(580200);
    });
    it('0원 → 세액 0', () => {
      const w = business33Withholding(0);
      expect(w.totalTax).toBe(0);
      expect(w.netPay).toBe(0);
    });
    it('원단위 절사 — 33,333원 → 소득세 floor10(999.99)=990', () => {
      const w = business33Withholding(33333);
      expect(w.incomeTax).toBe(990); // floor10(33333*0.03=999.99)
      expect(w.localTax).toBe(90); // floor10(99)
    });
  });

  describe('dailyWageTaxPerDay (일용근로 1일 세액)', () => {
    it('일급 150,000 이하 → 과세표준 0 → 0원', () => {
      expect(dailyWageTaxPerDay(150000)).toBe(0);
      expect(dailyWageTaxPerDay(120000)).toBe(0);
    });
    it('일급 170,000 → (20,000×2.7%)=540 < 1,000 소액부징수 → 0원', () => {
      expect(dailyWageTaxPerDay(170000)).toBe(0);
    });
    it('일급 200,000 → (50,000×6%×45%)=1,350 ≥ 1,000 → 1,350원', () => {
      expect(dailyWageTaxPerDay(200000)).toBe(1350);
    });
    it('일급 1,000,000 → (850,000×2.7%)=22,950원', () => {
      expect(dailyWageTaxPerDay(1000000)).toBe(22950);
    });
    it('소액부징수 경계 — 세액 정확히 1,000이 되는 지점 이상만 징수', () => {
      // 과세표준 x*0.027 >= 1000 → x >= 37037. 일급 = 150000 + 37037 = 187037
      expect(dailyWageTaxPerDay(150000 + 37030)).toBe(0); // 37030*0.027=999.81 → floor10 990 <1000 → 0
      expect(dailyWageTaxPerDay(150000 + 37040)).toBe(1000); // 37040*0.027=1000.08 → floor10 1000
    });
  });

  describe('dailyWageWithholding (지급 건별 일수)', () => {
    it('일당 20만 × 3일(600,000) → 소득세 4,050 + 지방 400 = 4,450, 차인 595,550', () => {
      const w = dailyWageWithholding([{ amount: 600000, days: 3 }]);
      expect(w.incomeTax).toBe(4050); // 1,350 × 3
      expect(w.localTax).toBe(400); // floor10(405)
      expect(w.totalTax).toBe(4450);
      expect(w.netPay).toBe(595550);
    });
    it('공수 1.5일(270,000, 180,000/공수) → 일급 180,000 → 810<1,000 → 0원', () => {
      const w = dailyWageWithholding([{ amount: 270000, days: 1.5 }]);
      expect(w.incomeTax).toBe(0);
      expect(w.netPay).toBe(270000);
    });
    it('여러 지급 건 합산', () => {
      const w = dailyWageWithholding([
        { amount: 600000, days: 3 }, // 4,050
        { amount: 200000, days: 1 }, // 1,350
      ]);
      expect(w.incomeTax).toBe(5400);
    });
  });

  describe('aggregateWageStatement', () => {
    it('작업자별 그룹 + 소득 유형별 세액 + 총계', () => {
      const rows: WagePaymentRow[] = [
        {
          workerProfileId: 'w1',
          workerName: '김*수',
          amount: 600000,
          days: 3,
          workDate: '2026-07-03',
        },
        {
          workerProfileId: 'w1',
          workerName: '김*수',
          amount: 200000,
          days: 1,
          workDate: '2026-07-10',
        },
        {
          workerProfileId: 'w2',
          workerName: '이*호',
          amount: 150000,
          days: 1,
          workDate: '2026-07-05',
        },
      ];
      const { workers, totals } = aggregateWageStatement(rows);
      expect(workers).toHaveLength(2);
      const w1 = workers.find((w) => w.workerProfileId === 'w1')!;
      expect(w1.paidTotal).toBe(800000);
      expect(w1.paymentCount).toBe(2);
      expect(w1.workDays).toBe(4);
      expect(w1.business3_3.incomeTax).toBe(24000); // 800,000×3%
      expect(w1.dailyWage.incomeTax).toBe(5400); // 4,050 + 1,350
      const w2 = workers.find((w) => w.workerProfileId === 'w2')!;
      expect(w2.dailyWage.incomeTax).toBe(0); // 일급 150,000 → 0
      // 총계 정렬(지급총액 내림차순) + 합산
      expect(workers[0].workerProfileId).toBe('w1');
      expect(totals.workerCount).toBe(2);
      expect(totals.paidTotal).toBe(950000);
      expect(totals.paymentCount).toBe(3);
      expect(totals.business3_3.incomeTax).toBe(24000 + 4500);
    });
    it('빈 입력 → 총계 0', () => {
      const { workers, totals } = aggregateWageStatement([]);
      expect(workers).toHaveLength(0);
      expect(totals.paidTotal).toBe(0);
    });
  });

  it('안내 문구 — 세무 상담 아님·세무사 확인·주민번호 비수집 명시', () => {
    const joined = wageStatementNotes().join(' ');
    expect(joined).toContain('세무 상담이 아닙니다');
    expect(joined).toContain('세무 전문가');
    expect(joined).toContain('주민등록번호');
    expect(joined).toContain('2026');
  });
});
