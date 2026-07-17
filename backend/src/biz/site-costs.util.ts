/**
 * 현장별 인건비 집계 — 순수 함수 (단위 테스트 대상).
 *
 * 사업장 대상 SIGNED 확인서를 현장명(siteName)별로 집계한다.
 *  - 일반 확인서: 작업자(profileId)별로 묶어 일수·공수·금액 합산(이름 마스킹은 서비스에서).
 *  - 팀 확인서(teamEntries 有): 팀 단위 1행으로 표기(반장 이름 + 팀원 인원수), 팀 합계 금액.
 *  - 현장 소계(작업자 합 + 팀 합) + 전체 총계.
 *
 * 팀 파생 중복 방지 원칙(P2d 계승): 사업장 입장에서 확인서는 "반장 팀 확인서 1장"만
 *   존재하며(팀원 파생 항목은 반장 개인 장부에만 생김), 여기서는 사업장 대상 confirmations
 *   만 집계하므로 이중 합산이 발생하지 않는다. 그럼에도 소계=행 합, 총계=현장 소계 합을
 *   검증해 회귀를 막는다.
 */

export interface SiteCostInputRow {
  site: string; // 현장명
  workerProfileId: string; // 작성 작업자(반장 포함)
  workerName: string; // 마스킹된 이름
  workDate: string; // YYYY-MM-DD (KST 작업일)
  amount: number; // 확인서 청구 합계(원)
  days: number; // 근로일수(연인원 man-days: 일당=일수, 공수/팀=공수, 그 외=1)
  gongsu: number; // 공수 기여분(없으면 0)
  isTeam: boolean; // 팀 확인서 여부
  teamMemberCount: number; // 팀 인원수(팀 확인서만, 아니면 0)
}

export interface SiteCostWorkerEntry {
  workerProfileId: string;
  workerName: string;
  isTeam: boolean;
  teamMemberCount: number; // 팀이면 인원수, 아니면 0
  days: number; // 연인원(man-days) 합
  gongsu: number; // 공수 합
  amount: number; // 금액 합
  entryCount: number; // 확인서 건수
}

export interface SiteCostGroup {
  site: string;
  entries: SiteCostWorkerEntry[]; // 작업자/팀 행
  subtotalAmount: number;
  subtotalDays: number; // 현장 연인원(man-days) 합
  subtotalGongsu: number;
  workerCount: number; // 참여 작업자(팀 반장 포함) 수
}

export interface SiteCostTotals {
  totalAmount: number;
  totalDays: number; // 전체 연인원(man-days) 합
  totalGongsu: number;
  siteCount: number;
  entryCount: number; // 전체 확인서 건수
}

export interface SiteCostsResult {
  sites: SiteCostGroup[];
  totals: SiteCostTotals;
}

const round1 = (n: number): number => Math.round(n * 10) / 10;

export function aggregateSiteCosts(rows: SiteCostInputRow[]): SiteCostsResult {
  // 현장 → (작업자키 → 집계). 팀 확인서는 작업자 내에서도 팀 행을 분리하기 위해 키에 team 표시.
  const siteMap = new Map<
    string,
    { site: string; workers: Map<string, SiteCostWorkerEntry> }
  >();

  for (const r of rows) {
    const srec =
      siteMap.get(r.site) ??
      (() => {
        const created = {
          site: r.site,
          workers: new Map<string, SiteCostWorkerEntry>(),
        };
        siteMap.set(r.site, created);
        return created;
      })();

    // 일반은 작업자별로 합치고, 팀 확인서는 (회차별 인원 구성이 다를 수 있어) 반장 기준으로 합친다.
    const key = r.isTeam
      ? `team:${r.workerProfileId}`
      : `worker:${r.workerProfileId}`;
    const wrec =
      srec.workers.get(key) ??
      ({
        workerProfileId: r.workerProfileId,
        workerName: r.workerName,
        isTeam: r.isTeam,
        teamMemberCount: 0,
        days: 0,
        gongsu: 0,
        amount: 0,
        entryCount: 0,
      } as SiteCostWorkerEntry);
    wrec.amount += r.amount;
    wrec.gongsu += r.gongsu;
    wrec.days += r.days;
    wrec.entryCount += 1;
    if (r.isTeam) {
      // 팀 인원수는 회차 최대값(가장 큰 명단) 표기.
      wrec.teamMemberCount = Math.max(wrec.teamMemberCount, r.teamMemberCount);
    }
    srec.workers.set(key, wrec);
  }

  let totalAmount = 0;
  let totalGongsu = 0;
  let totalDays = 0;
  let entryCount = 0;
  for (const r of rows) {
    totalAmount += r.amount;
    totalGongsu += r.gongsu;
    totalDays += r.days;
    entryCount += 1;
  }

  const sites: SiteCostGroup[] = [...siteMap.values()]
    .map((s) => {
      const entries: SiteCostWorkerEntry[] = [...s.workers.values()]
        .map((w) => ({
          workerProfileId: w.workerProfileId,
          workerName: w.workerName,
          isTeam: w.isTeam,
          teamMemberCount: w.teamMemberCount,
          days: round1(w.days),
          gongsu: round1(w.gongsu),
          amount: w.amount,
          entryCount: w.entryCount,
        }))
        .sort((a, b) => b.amount - a.amount);
      return {
        site: s.site,
        entries,
        subtotalAmount: entries.reduce((sum, e) => sum + e.amount, 0),
        subtotalDays: round1(entries.reduce((sum, e) => sum + e.days, 0)),
        subtotalGongsu: round1(entries.reduce((sum, e) => sum + e.gongsu, 0)),
        workerCount: entries.length,
      };
    })
    .sort((a, b) => b.subtotalAmount - a.subtotalAmount);

  const totals: SiteCostTotals = {
    totalAmount,
    totalDays: round1(totalDays),
    totalGongsu: round1(totalGongsu),
    siteCount: sites.length,
    entryCount,
  };

  // --- 정합성 검증(회귀 방지): 현장 소계 합 = 총계, 행 합 = 소계 ---
  const sumSites = sites.reduce((s, g) => s + g.subtotalAmount, 0);
  if (sumSites !== totalAmount) {
    throw new Error(
      `SITE_COSTS_INVARIANT: 현장 소계 합(${sumSites}) ≠ 총계(${totalAmount}).`,
    );
  }

  return { sites, totals };
}
