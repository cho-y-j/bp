import {
  aggregateIncomeReport,
  incomeTaxNoticeKo,
  type IncomeReportInputRow,
} from './income-report.util';

/** 테스트 행 헬퍼 — 기본값 위에 필요한 필드만 덮어쓴다. */
function row(p: Partial<IncomeReportInputRow>): IncomeReportInputRow {
  return {
    month: '2026-03',
    workDate: '2026-03-10',
    amount: 0,
    paid: 0,
    outstanding: 0,
    gongsu: 0,
    businessId: null,
    companyName: '(미지정)',
    teamPayout: 0,
    derived: false,
    ...p,
  };
}

const MONTHS_2026 = Array.from(
  { length: 12 },
  (_, i) => `2026-${String(i + 1).padStart(2, '0')}`,
);

describe('aggregateIncomeReport', () => {
  it('빈 입력 — 월 목록은 0으로 채워지고 총계 0', () => {
    const r = aggregateIncomeReport([], MONTHS_2026);
    expect(r.monthly).toHaveLength(12);
    expect(r.monthly.every((m) => m.billed === 0 && m.daysWorked === 0)).toBe(
      true,
    );
    expect(r.companies).toHaveLength(0);
    expect(r.totals.totalBilled).toBe(0);
    expect(r.totals.entryCount).toBe(0);
    expect(r.totals.netBilled).toBe(0);
  });

  it('일반 소득 — 월별/상대별/총계 합산', () => {
    const rows = [
      row({
        month: '2026-03',
        workDate: '2026-03-05',
        amount: 180000,
        paid: 180000,
        outstanding: 0,
        gongsu: 1,
        businessId: 'b1',
        companyName: '삼성물산',
      }),
      row({
        month: '2026-03',
        workDate: '2026-03-06',
        amount: 200000,
        paid: 0,
        outstanding: 200000,
        gongsu: 1,
        businessId: 'b1',
        companyName: '삼성물산',
      }),
      row({
        month: '2026-04',
        workDate: '2026-04-01',
        amount: 150000,
        paid: 150000,
        outstanding: 0,
        gongsu: 1,
        businessId: null,
        companyName: '현대건설(수기)',
      }),
    ];
    const r = aggregateIncomeReport(rows, MONTHS_2026);

    // 월별
    const mar = r.monthly.find((m) => m.month === '2026-03')!;
    expect(mar.billed).toBe(380000);
    expect(mar.paid).toBe(180000);
    expect(mar.outstanding).toBe(200000);
    expect(mar.daysWorked).toBe(2);
    expect(mar.gongsu).toBe(2);
    const apr = r.monthly.find((m) => m.month === '2026-04')!;
    expect(apr.billed).toBe(150000);
    expect(apr.daysWorked).toBe(1);

    // 상대별(총액 내림차순)
    expect(r.companies).toHaveLength(2);
    expect(r.companies[0].companyName).toBe('삼성물산');
    expect(r.companies[0].count).toBe(2);
    expect(r.companies[0].total).toBe(380000);
    expect(r.companies[1].companyName).toBe('현대건설(수기)');

    // 총계
    expect(r.totals.totalBilled).toBe(530000);
    expect(r.totals.totalPaid).toBe(330000);
    expect(r.totals.totalOutstanding).toBe(200000);
    expect(r.totals.totalDays).toBe(3);
    expect(r.totals.totalGongsu).toBe(3);
    expect(r.totals.entryCount).toBe(3);
    expect(r.totals.teamPayout).toBe(0);
    expect(r.totals.netBilled).toBe(530000);
  });

  it('공수 소수 합산 — 부동소수 오차 0.1 단위 정리', () => {
    const rows = [
      row({ amount: 100, gongsu: 0.1, workDate: '2026-03-01' }),
      row({ amount: 100, gongsu: 0.2, workDate: '2026-03-02' }),
    ];
    const r = aggregateIncomeReport(rows, MONTHS_2026);
    expect(r.totals.totalGongsu).toBe(0.3); // 0.30000000000000004 아님
  });

  it('팀 반장 — 팀 확인서 전체가 매출, 팀 지급분 별도·순소득 참고', () => {
    // 반장 장부: 팀 확인서 합계 1건(420,000), 팀원 지급분 270,000(홍길동) + 150,000(수기)
    const rows = [
      row({
        month: '2026-07',
        workDate: '2026-07-08',
        amount: 420000,
        paid: 0,
        outstanding: 420000,
        gongsu: 2.5,
        businessId: 'bz',
        companyName: '삼성물산',
        teamPayout: 420000, // 반장 본인 몫 없음 → 전액 팀원 지급
        derived: false,
      }),
    ];
    const r = aggregateIncomeReport(rows, ['2026-07']);
    expect(r.totals.totalBilled).toBe(420000);
    expect(r.totals.teamPayout).toBe(420000);
    expect(r.totals.netBilled).toBe(0);
    expect(r.totals.totalGongsu).toBe(2.5);
  });

  it('팀원 — 파생 항목은 본인 소득으로 집계(teamPayout 0)', () => {
    const rows = [
      row({
        month: '2026-07',
        workDate: '2026-07-08',
        amount: 270000,
        paid: 270000,
        outstanding: 0,
        gongsu: 1.5,
        companyName: '박반장',
        teamPayout: 0,
        derived: true,
      }),
    ];
    const r = aggregateIncomeReport(rows, ['2026-07']);
    expect(r.totals.totalBilled).toBe(270000);
    expect(r.totals.teamPayout).toBe(0);
    expect(r.totals.netBilled).toBe(270000);
    expect(r.companies[0].companyName).toBe('박반장');
  });

  it('파생 중복 합산 방지 — 파생 항목에 팀 지급분이 있으면 예외', () => {
    const rows = [row({ amount: 100, teamPayout: 50, derived: true })];
    expect(() => aggregateIncomeReport(rows, MONTHS_2026)).toThrow(
      /INVARIANT/,
    );
  });
});

describe('incomeTaxNoticeKo', () => {
  it('기간 라벨 + 안내 문구(5월 신고·3.3% 원천징수·세무상담 아님)', () => {
    const n = incomeTaxNoticeKo('2026년');
    expect(n.period).toBe('2026년');
    expect(n.lines.length).toBeGreaterThanOrEqual(4);
    expect(n.lines.join(' ')).toContain('5월');
    expect(n.lines.join(' ')).toContain('3.3%');
    expect(n.lines.join(' ')).toContain('세무 상담');
  });
});
