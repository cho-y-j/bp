/**
 * 일용근로소득 지급명세서 도우미 — 원천징수 세액 산출 순수 함수 (단위 테스트 대상).
 *
 *  ⚠️ 아래 세율·공제 기준은 2026년 시행 기준으로 작성한 참고값이다. 세법은 매년 개정될 수
 *     있으므로 실제 신고 전 홈택스 및 세무 전문가 확인이 필요하다. 본 산출은 세무 상담이 아니다.
 *
 * 두 가지 소득 유형을 동시에 제공한다(사용자가 소득 유형을 선택해 홈택스에 입력):
 *
 *  ① 사업소득 3.3% 원천징수 (business3_3) — 인적용역 사업소득
 *     - 소득세 = 지급액 × 3%,  지방소득세 = 소득세 × 10% (= 지급액 × 0.3%)
 *     - 원천징수 합계 3.3%,  차인지급액 = 지급액 − 원천징수 합계
 *
 *  ② 일용근로소득 (dailyWage) — 일(日) 단위 계산
 *     - 근로소득공제: 1일 150,000원 (일급에서 공제)
 *     - 산출세액   : 과세표준(=일급−150,000, 음수면 0) × 6%
 *     - 근로소득세액공제 55% 감면 → 결정세액 = 산출세액 × 45%
 *       즉 과세표준 × 6% × 45% = 과세표준 × 2.7% (실효 2.7%)
 *     - 소액부징수: 1일 소득세가 1,000원 미만이면 0 (징수하지 않음)
 *     - 지방소득세 = 소득세 × 10%
 *     - 여러 날(공수/일수)은 1일 세액을 일수만큼 합산.
 */

// --- 상수 (2026 기준 — 개정 시 이 값만 수정) ---
export const DAILY_WAGE_DEDUCTION = 150_000; // 일용근로 1일 근로소득공제
export const DAILY_WAGE_TAX_RATE = 0.06; // 산출세액 세율 6%
export const DAILY_WAGE_CREDIT_RATE = 0.45; // 근로소득세액공제 후 잔여(=1−0.55). 55% 감면
export const DAILY_WAGE_MIN_TAX = 1_000; // 소액부징수 기준(1일 소득세 1,000원 미만이면 0)
export const BUSINESS_INCOME_TAX_RATE = 0.03; // 사업소득 소득세 3%
export const LOCAL_TAX_RATE = 0.1; // 지방소득세 = 소득세의 10%

/** 원천징수 원단위 절사(10원 미만 버림). */
function floor10(n: number): number {
  return Math.floor(n / 10) * 10;
}

export interface WithholdingResult {
  incomeTax: number; // 소득세
  localTax: number; // 지방소득세(소득세의 10%)
  totalTax: number; // 원천징수 합계
  netPay: number; // 차인지급액(지급액 − 원천징수 합계)
}

/** 사업소득 3.3% 원천징수. 지급액 기준. */
export function business33Withholding(paidAmount: number): WithholdingResult {
  const base = Math.max(0, Math.round(paidAmount));
  const incomeTax = floor10(base * BUSINESS_INCOME_TAX_RATE);
  const localTax = floor10(incomeTax * LOCAL_TAX_RATE);
  const totalTax = incomeTax + localTax;
  return { incomeTax, localTax, totalTax, netPay: base - totalTax };
}

/** 일용근로 1일 소득세(소액부징수·감면 반영, 원단위 절사). */
export function dailyWageTaxPerDay(dailyWage: number): number {
  const taxable = Math.max(0, dailyWage - DAILY_WAGE_DEDUCTION);
  const raw = floor10(taxable * DAILY_WAGE_TAX_RATE * DAILY_WAGE_CREDIT_RATE);
  return raw < DAILY_WAGE_MIN_TAX ? 0 : raw;
}

/** 지급 1건(payment)의 일용근로 원천징수. 일수(days)로 일급을 산정해 일 단위 합산. */
export interface DailyWagePaymentInput {
  amount: number; // 지급액
  days: number; // 근로일수(공수 포함, 최소 1)
}

export function dailyWageWithholding(
  payments: DailyWagePaymentInput[],
): WithholdingResult {
  let paidTotal = 0;
  let incomeTax = 0;
  for (const p of payments) {
    const amount = Math.max(0, Math.round(p.amount));
    paidTotal += amount;
    const days = p.days > 0 ? p.days : 1;
    const dailyWage = amount / days; // 지급액을 일수로 나눠 1일 임금 산정
    // 1일 세액(소액부징수 반영) × 일수. (공수 소수도 일수 비례 합산)
    incomeTax += dailyWageTaxPerDay(dailyWage) * days;
  }
  incomeTax = floor10(incomeTax);
  const localTax = floor10(incomeTax * LOCAL_TAX_RATE);
  const totalTax = incomeTax + localTax;
  return { incomeTax, localTax, totalTax, netPay: paidTotal - totalTax };
}

// --- 작업자별 집계 ---
export interface WagePaymentRow {
  workerProfileId: string;
  workerName: string; // 마스킹된 이름
  amount: number; // 이 지급 건의 금액
  days: number; // 이 지급 건의 근로일수(확인서 기준, 공수 포함)
  workDate: string | null; // 확인서 작업일(YYYY-MM-DD) — 일수 집계용
}

export interface WageWorkerAgg {
  workerProfileId: string;
  workerName: string;
  paidTotal: number; // 지급총액(월)
  paymentCount: number; // 지급 건수
  workDays: number; // 근로일수 합계(확인서 일수/공수)
  business3_3: WithholdingResult; // 사업소득 3.3% 산출
  dailyWage: WithholdingResult; // 일용근로소득 산출
}

export interface WageStatementTotals {
  workerCount: number;
  paidTotal: number;
  paymentCount: number;
  business3_3: WithholdingResult;
  dailyWage: WithholdingResult;
}

const round1 = (n: number): number => Math.round(n * 10) / 10;

function sumWithholding(list: WithholdingResult[]): WithholdingResult {
  const incomeTax = list.reduce((s, w) => s + w.incomeTax, 0);
  const localTax = list.reduce((s, w) => s + w.localTax, 0);
  const totalTax = incomeTax + localTax;
  const netPay = list.reduce((s, w) => s + w.netPay, 0);
  return { incomeTax, localTax, totalTax, netPay };
}

/** 지급 행(payment 단위) → 작업자별 집계 + 소득 유형별 세액 산출. */
export function aggregateWageStatement(rows: WagePaymentRow[]): {
  workers: WageWorkerAgg[];
  totals: WageStatementTotals;
} {
  const groups = new Map<
    string,
    {
      workerProfileId: string;
      workerName: string;
      payments: DailyWagePaymentInput[];
      paidTotal: number;
      paymentCount: number;
      workDays: number;
    }
  >();

  for (const r of rows) {
    const g = groups.get(r.workerProfileId) ?? {
      workerProfileId: r.workerProfileId,
      workerName: r.workerName,
      payments: [] as DailyWagePaymentInput[],
      paidTotal: 0,
      paymentCount: 0,
      workDays: 0,
    };
    const days = r.days > 0 ? r.days : 1;
    g.payments.push({ amount: r.amount, days });
    g.paidTotal += Math.round(r.amount);
    g.paymentCount += 1;
    g.workDays += days;
    groups.set(r.workerProfileId, g);
  }

  const workers: WageWorkerAgg[] = [...groups.values()]
    .map((g) => ({
      workerProfileId: g.workerProfileId,
      workerName: g.workerName,
      paidTotal: g.paidTotal,
      paymentCount: g.paymentCount,
      workDays: round1(g.workDays),
      business3_3: business33Withholding(g.paidTotal),
      dailyWage: dailyWageWithholding(g.payments),
    }))
    .sort((a, b) => b.paidTotal - a.paidTotal);

  const totals: WageStatementTotals = {
    workerCount: workers.length,
    paidTotal: workers.reduce((s, w) => s + w.paidTotal, 0),
    paymentCount: workers.reduce((s, w) => s + w.paymentCount, 0),
    business3_3: sumWithholding(workers.map((w) => w.business3_3)),
    dailyWage: sumWithholding(workers.map((w) => w.dailyWage)),
  };

  return { workers, totals };
}

/** 세율·공제 기준 안내(응답 노트). "세무 상담 아님·세무사 확인 권장" 필수 문구 포함. */
export function wageStatementNotes(): string[] {
  return [
    '사업소득(3.3%): 소득세 3% + 지방소득세 0.3%. 인적용역 사업소득 원천징수 기준.',
    '일용근로소득: 1일 150,000원 근로소득공제 후 6% 산출세액에서 55% 세액공제(실효 2.7%), 1일 세액 1,000원 미만은 소액부징수로 0원.',
    '위 세율·공제는 2026년 기준 참고값입니다. 세법은 매년 개정될 수 있으니 신고 전 홈택스·세무 전문가 확인을 권장합니다.',
    '본 산출은 일반 정보이며 세무 상담이 아닙니다.',
    '주민등록번호는 수집·저장하지 않습니다. 홈택스 지급명세서 제출 시 주민번호는 직접 입력하세요.',
  ];
}

/** 홈택스 입력용 복사 텍스트(작업자별 지급총액·일수·소득 유형별 세액). */
export function formatWageStatementText(
  month: string,
  businessName: string,
  workers: WageWorkerAgg[],
): string {
  const lines: string[] = [];
  lines.push(`[일용근로소득 지급명세서 도우미] ${businessName} · ${month}`);
  lines.push('※ 주민번호는 홈택스에서 직접 입력하세요(본 앱 비수집).');
  lines.push('');
  for (const w of workers) {
    lines.push(
      `- ${w.workerName} | 지급총액 ${w.paidTotal.toLocaleString('ko-KR')}원 | ${w.paymentCount}건 / ${w.workDays}일`,
    );
    lines.push(
      `  · 사업소득 3.3%: 소득세 ${w.business3_3.incomeTax.toLocaleString('ko-KR')} + 지방 ${w.business3_3.localTax.toLocaleString('ko-KR')} = ${w.business3_3.totalTax.toLocaleString('ko-KR')}원, 차인지급 ${w.business3_3.netPay.toLocaleString('ko-KR')}원`,
    );
    lines.push(
      `  · 일용근로: 소득세 ${w.dailyWage.incomeTax.toLocaleString('ko-KR')} + 지방 ${w.dailyWage.localTax.toLocaleString('ko-KR')} = ${w.dailyWage.totalTax.toLocaleString('ko-KR')}원, 차인지급 ${w.dailyWage.netPay.toLocaleString('ko-KR')}원`,
    );
  }
  return lines.join('\n');
}
