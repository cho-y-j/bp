import { aggregateSiteCosts, SiteCostInputRow } from './site-costs.util';

function row(p: Partial<SiteCostInputRow>): SiteCostInputRow {
  return {
    site: '역삼 현장',
    workerProfileId: 'w1',
    workerName: '김*수',
    workDate: '2026-03-05',
    amount: 200000,
    days: 1,
    gongsu: 0,
    isTeam: false,
    teamMemberCount: 0,
    ...p,
  };
}

describe('site-costs.util — 현장별 인건비 집계', () => {
  it('빈 입력 → 총계 0', () => {
    const { sites, totals } = aggregateSiteCosts([]);
    expect(sites).toHaveLength(0);
    expect(totals.totalAmount).toBe(0);
    expect(totals.siteCount).toBe(0);
  });

  it('한 현장 작업자별 합산 — 같은 작업자 여러 확인서 합침', () => {
    const { sites, totals } = aggregateSiteCosts([
      row({ workDate: '2026-03-05', amount: 200000, days: 1 }),
      row({ workDate: '2026-03-06', amount: 200000, days: 1 }),
    ]);
    expect(sites).toHaveLength(1);
    expect(sites[0].entries).toHaveLength(1);
    expect(sites[0].entries[0].days).toBe(2); // man-days 합
    expect(sites[0].entries[0].amount).toBe(400000);
    expect(sites[0].entries[0].entryCount).toBe(2);
    expect(sites[0].subtotalAmount).toBe(400000);
    expect(totals.totalAmount).toBe(400000);
    expect(totals.totalDays).toBe(2);
  });

  it('공수(GONGSU) — days=gongsu 합, 공수 표기', () => {
    const { sites } = aggregateSiteCosts([
      row({ amount: 270000, days: 1.5, gongsu: 1.5 }),
    ]);
    expect(sites[0].entries[0].gongsu).toBe(1.5);
    expect(sites[0].entries[0].days).toBe(1.5);
    expect(sites[0].subtotalGongsu).toBe(1.5);
  });

  it('팀 확인서 — 팀 행으로 표기(인원수), 반장 기준 합침', () => {
    const { sites, totals } = aggregateSiteCosts([
      row({
        workerProfileId: 'boss',
        workerName: '박*장',
        amount: 420000,
        days: 2.5,
        gongsu: 2.5,
        isTeam: true,
        teamMemberCount: 2,
      }),
    ]);
    const e = sites[0].entries[0];
    expect(e.isTeam).toBe(true);
    expect(e.teamMemberCount).toBe(2);
    expect(e.amount).toBe(420000);
    expect(e.gongsu).toBe(2.5);
    expect(totals.totalGongsu).toBe(2.5);
  });

  it('여러 현장 — 소계·총계, 금액 내림차순 정렬', () => {
    const { sites, totals } = aggregateSiteCosts([
      row({ site: '역삼 현장', amount: 200000 }),
      row({ site: '판교 현장', workerProfileId: 'w2', amount: 500000 }),
      row({ site: '판교 현장', workerProfileId: 'w3', amount: 100000 }),
    ]);
    expect(sites).toHaveLength(2);
    // 판교(600,000) > 역삼(200,000)
    expect(sites[0].site).toBe('판교 현장');
    expect(sites[0].subtotalAmount).toBe(600000);
    expect(sites[0].workerCount).toBe(2);
    // 현장 내 금액 내림차순
    expect(sites[0].entries[0].amount).toBe(500000);
    expect(totals.totalAmount).toBe(800000);
    expect(totals.siteCount).toBe(2);
    expect(totals.entryCount).toBe(3);
  });

  it('일반+팀 혼합 현장 — 소계=행 합, 총계 정합', () => {
    const { sites, totals } = aggregateSiteCosts([
      row({
        site: '반포 현장',
        workerProfileId: 'w1',
        amount: 200000,
        days: 1,
      }),
      row({
        site: '반포 현장',
        workerProfileId: 'boss',
        amount: 420000,
        days: 2.5,
        gongsu: 2.5,
        isTeam: true,
        teamMemberCount: 2,
      }),
    ]);
    expect(sites[0].entries).toHaveLength(2);
    expect(sites[0].subtotalAmount).toBe(620000);
    expect(sites[0].subtotalDays).toBe(3.5);
    expect(totals.totalAmount).toBe(620000);
  });
});
