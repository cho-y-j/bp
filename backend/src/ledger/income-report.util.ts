/**
 * 연간(기간별) 소득 리포트 집계 유틸 (순수 함수 — 단위 테스트 대상).
 *
 * 입력: 한 사용자의 장부 항목을 정규화한 행 목록(월/작업일/금액/입금/미수/공수/
 *      상대/팀 지급분/파생여부). 실제 미수·공수·팀 계산은 서비스에서 수행하고,
 *      여기서는 순수 합산·그룹화·검증만 한다(파생 중복 합산 방지 검증 포함).
 *
 * 팀 파생 처리 원칙(현행 장부와 동일):
 *  - 팀원(파생 항목, derived=true): 각자 몫이 본인 소득으로 이미 개별 항목으로 존재 →
 *    그대로 소득 집계(teamPayout=0 이어야 함).
 *  - 반장(팀 확인서 합계 항목): 팀 전체 합계가 반장 매출로 집계됨. 팀원에게 지급되는
 *    몫(본인 몫 제외)을 teamPayout 으로 별도 표기 → 순소득 참고(netBilled)만 제공,
 *    합계 자체는 차감하지 않는다.
 */

export interface IncomeReportInputRow {
  month: string; // YYYY-MM (KST 기준 유효 월)
  workDate: string; // YYYY-MM-DD (KST 기준 유효 작업일)
  amount: number; // 청구액(원)
  paid: number; // 입금 합계(원)
  outstanding: number; // 미수(원)
  gongsu: number; // 공수 기여분
  businessId: string | null;
  companyName: string;
  teamPayout: number; // 반장 팀 확인서의 팀원 지급분(본인 몫 제외). 그 외 0.
  derived: boolean; // 팀 파생(팀원 몫) 여부
}

export interface IncomeMonthlyPoint {
  month: string; // YYYY-MM
  billed: number;
  paid: number;
  outstanding: number;
  daysWorked: number;
  gongsu: number;
}

export interface IncomeCompanyAgg {
  companyName: string;
  businessId: string | null;
  count: number; // 건수(장부 항목 수)
  total: number; // 총 청구액
  paid: number; // 입금
  outstanding: number; // 미수
}

export interface IncomeTotals {
  totalBilled: number;
  totalPaid: number;
  totalOutstanding: number;
  totalDays: number; // 기간 내 서로 다른 일한 날 수
  totalGongsu: number;
  entryCount: number;
  teamPayout: number; // 팀 지급분 합계(반장 순소득 참고용)
  netBilled: number; // 총 청구 - 팀 지급분
}

export interface IncomeReportResult {
  monthly: IncomeMonthlyPoint[];
  companies: IncomeCompanyAgg[];
  totals: IncomeTotals;
}

const round1 = (n: number): number => Math.round(n * 10) / 10; // 공수 0.1 단위 오차 정리

/**
 * 정규화 행 + 대상 월 목록으로 소득 리포트를 집계한다.
 *  - months: 리포트에 포함할 전체 월(YYYY-MM). 데이터 없는 월도 0으로 채워 추이 그래프를 만든다.
 *  - 내부 정합성 검증: 월별 합 = 상대별 합 = 총계. 파생 행은 teamPayout=0 이어야 한다.
 */
export function aggregateIncomeReport(
  rows: IncomeReportInputRow[],
  months: string[],
): IncomeReportResult {
  // --- 파생 중복 합산 방지 검증 ---
  for (const r of rows) {
    if (r.derived && r.teamPayout !== 0) {
      throw new Error(
        `INCOME_REPORT_INVARIANT: 파생 항목(팀원 몫)에 팀 지급분이 존재할 수 없습니다 (month=${r.month}).`,
      );
    }
  }

  // --- 월별 ---
  const monthMap = new Map<
    string,
    {
      billed: number;
      paid: number;
      outstanding: number;
      gongsu: number;
      days: Set<string>;
    }
  >();
  for (const m of months) {
    monthMap.set(m, {
      billed: 0,
      paid: 0,
      outstanding: 0,
      gongsu: 0,
      days: new Set<string>(),
    });
  }

  // --- 상대별 ---
  const companyMap = new Map<
    string,
    IncomeCompanyAgg & { _days: Set<string> }
  >();

  let totalBilled = 0;
  let totalPaid = 0;
  let totalOutstanding = 0;
  let totalGongsu = 0;
  let teamPayout = 0;
  const totalDays = new Set<string>();

  for (const r of rows) {
    // 월별 (범위 밖 월이 들어오면 즉시 생성해 누락 방지)
    const mrec =
      monthMap.get(r.month) ??
      (() => {
        const created = {
          billed: 0,
          paid: 0,
          outstanding: 0,
          gongsu: 0,
          days: new Set<string>(),
        };
        monthMap.set(r.month, created);
        return created;
      })();
    mrec.billed += r.amount;
    mrec.paid += r.paid;
    mrec.outstanding += r.outstanding;
    mrec.gongsu += r.gongsu;
    mrec.days.add(r.workDate);

    // 상대별
    const key = r.businessId ? `biz:${r.businessId}` : `manual:${r.companyName}`;
    const crec =
      companyMap.get(key) ??
      ({
        companyName: r.companyName,
        businessId: r.businessId,
        count: 0,
        total: 0,
        paid: 0,
        outstanding: 0,
        _days: new Set<string>(),
      } as IncomeCompanyAgg & { _days: Set<string> });
    crec.count += 1;
    crec.total += r.amount;
    crec.paid += r.paid;
    crec.outstanding += r.outstanding;
    crec._days.add(r.workDate);
    companyMap.set(key, crec);

    // 총계
    totalBilled += r.amount;
    totalPaid += r.paid;
    totalOutstanding += r.outstanding;
    totalGongsu += r.gongsu;
    teamPayout += r.teamPayout;
    totalDays.add(r.workDate);
  }

  // months 순서를 보존한 월별 배열(정렬)
  const monthly: IncomeMonthlyPoint[] = [...monthMap.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([month, v]) => ({
      month,
      billed: v.billed,
      paid: v.paid,
      outstanding: v.outstanding,
      daysWorked: v.days.size,
      gongsu: round1(v.gongsu),
    }));

  const companies: IncomeCompanyAgg[] = [...companyMap.values()]
    .map((c) => ({
      companyName: c.companyName,
      businessId: c.businessId,
      count: c.count,
      total: c.total,
      paid: c.paid,
      outstanding: c.outstanding,
    }))
    .sort((a, b) => b.total - a.total);

  const totals: IncomeTotals = {
    totalBilled,
    totalPaid,
    totalOutstanding,
    totalDays: totalDays.size,
    totalGongsu: round1(totalGongsu),
    entryCount: rows.length,
    teamPayout,
    netBilled: totalBilled - teamPayout,
  };

  // --- 내부 정합성 검증(파생/이중 합산 회귀 방지) ---
  const sumMonthly = monthly.reduce((s, m) => s + m.billed, 0);
  const sumCompany = companies.reduce((s, c) => s + c.total, 0);
  if (sumMonthly !== totalBilled || sumCompany !== totalBilled) {
    throw new Error(
      `INCOME_REPORT_INVARIANT: 청구액 합 불일치 (월별 ${sumMonthly} / 상대별 ${sumCompany} / 총계 ${totalBilled}).`,
    );
  }

  return { monthly, companies, totals };
}

/**
 * 종소세(종합소득세) 일반 안내 문구(정본 한국어). 세무 상담이 아닌 일반 안내 수준.
 *  - 신고 기간(5월), 인적용역 사업소득 3.3% 원천징수 참고, 경비/장부 보관 안내.
 */
export function incomeTaxNoticeKo(periodLabel: string): {
  period: string;
  lines: string[];
} {
  return {
    period: periodLabel,
    lines: [
      '종합소득세는 매년 5월 1일~5월 31일에 전년도 소득을 신고·납부합니다.',
      '건설 인적용역 등 사업소득은 대금 지급 시 3.3%(소득세 3% + 지방소득세 0.3%)가 원천징수되는 경우가 많습니다.',
      '원천징수된 세액은 5월 종합소득세 신고 시 정산(환급 또는 추가납부)됩니다.',
      '실제 지출한 경비(유류비·장비·자재 등)와 확인서·명세서를 보관하면 신고 시 소득 산정에 도움이 됩니다.',
      '본 안내는 일반 정보이며 세무 상담이 아닙니다. 정확한 신고는 세무 전문가 또는 홈택스를 확인하세요.',
    ],
  };
}
