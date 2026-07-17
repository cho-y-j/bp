/**
 * PdfService 렌더링 입력 타입 (도메인 서비스 ↔ PDF 렌더러 계약).
 *  - 확인서/명세서 PDF 는 문자열·숫자만 넘겨받아 그린다(도메인 결합 최소화).
 */

export interface ConfirmationPdfLine {
  label: string; // 항목명 (기본/연장/야간 등)
  detail: string; // "단가 × 수량" 표기
  amount: number; // 금액(원)
}

export interface ConfirmationPdfData {
  title: string; // "작업확인서"
  date: string; // YYYY-MM-DD
  companyName: string; // 지시자/회사명
  contact?: string | null; // 상대 연락처(수기)
  workerName: string; // 작업자명
  site: string; // 현장/장소
  workContent: string; // 작업 내용
  timeRange: string; // "08:00 ~ 17:00"
  rateTypeLabel: string; // 단가 유형(일당/시급/건당)
  lines: ConfirmationPdfLine[]; // 금액 항목
  subtotal: number;
  vatRate: number;
  vat: number;
  total: number;
  notes?: string | null; // 특이사항
  equipment?: {
    // 장비 섹션(옵션)
    name?: string;
    vehicleNumber?: string;
    spec?: string;
    guide?: boolean; // 유도원 여부
  } | null;
  // 팀(반장) 확인서 명단 — 있으면 팀원별 표(이름/공수/단가/금액)를 렌더한다.
  teamEntries?: Array<{
    name: string;
    quantity: number; // 공수
    rate: number;
    amount: number;
  }> | null;
  signerName?: string | null;
  signedAt?: string | null; // 서명 시각 표시용
  signImagePng?: Buffer | null; // 서명 이미지(PNG) — 있으면 서명란에 삽입
  statusLabel: string; // 상태(작성됨/전송됨/서명됨)
}

export interface StatementCompanyGroup {
  companyName: string;
  days: number; // 일수
  subtotal: number; // 소계(청구액 합계)
  paid: number; // 입금 합계
  outstanding: number; // 미수 합계
}

export interface StatementPdfData {
  title: string; // "월간 명세서"
  month: string; // YYYY-MM
  workerName: string;
  groups: StatementCompanyGroup[];
  totalDays: number;
  totalAmount: number;
  totalPaid: number;
  totalOutstanding: number;
}

export interface LaborContractPdfData {
  title: string; // "표준근로계약서"
  statusLabel: string; // 작성됨/전송됨/서명됨
  businessName: string; // 사업장(사용자) 상호
  businessNumber?: string | null;
  businessAddress?: string | null;
  workerName: string; // 근로자 성명
  workerPhone?: string | null;
  startDate: string; // 근로개시일 YYYY-MM-DD
  endDate?: string | null; // 종료일(없으면 기간의 정함 없음)
  workplace: string; // 근무 장소
  jobDescription: string; // 업무 내용
  timeRange: string; // "08:00 ~ 17:00"
  breakTime?: string | null; // 휴게시간
  wageTypeLabel: string; // 일급/시급
  wageAmount: number; // 금액
  payday: string; // 임금 지급일
  payMethod: string; // 지급 방법
  weeklyHolidayAllowance: boolean; // 주휴수당 문구
  overtimeAllowance: boolean; // 연장·야간·휴일 가산수당 문구
  socialInsurance?: {
    employment?: boolean;
    health?: boolean;
    pension?: boolean;
    industrialAccident?: boolean;
  } | null;
  specialTerms?: string | null; // 특약사항
  employerSignerName?: string | null; // 사업장 대표자명
  employerSignedAt?: string | null;
  employerSignPng?: Buffer | null;
  workerSignerName?: string | null; // 근로자 서명자명
  workerSignedAt?: string | null;
  workerSignPng?: Buffer | null;
}

export interface SafetyReportTypeCount {
  typeLabel: string; // 유형(폭염알림/휴식안내/서류확인/컨디션체크)
  count: number;
}

export interface SafetyReportRow {
  date: string; // 발생 일자 (YYYY-MM-DD)
  typeLabel: string; // 유형
  targetName: string; // 대상(작업자)
  ackAt: string | null; // 확인 시각 (없으면 '-')
}

/** 월간 TBM(안전점검회의) 요약 행 (P2c). */
export interface SafetyReportTbmRow {
  date: string; // 실시 일자 (YYYY-MM-DD)
  site: string; // 현장명
  hazards: string; // 위험요인 요약(한국어)
  attendeeCount: number; // 참석 N
  ackCount: number; // 확인 M
}

/** 연간(기간별) 소득 리포트 PDF 입력 (P2d). */
export interface IncomeReportMonthly {
  month: string; // YYYY-MM
  billed: number;
  paid: number;
  outstanding: number;
  daysWorked: number;
  gongsu: number;
}

export interface IncomeReportCompany {
  companyName: string;
  count: number; // 건수
  total: number;
  paid: number;
  outstanding: number;
}

export interface IncomeReportPdfData {
  title: string; // "연간 소득 리포트"
  periodLabel: string; // "2026년" 또는 "2026-01 ~ 2026-03"
  workerName: string;
  monthly: IncomeReportMonthly[];
  companies: IncomeReportCompany[];
  totals: {
    totalBilled: number;
    totalPaid: number;
    totalOutstanding: number;
    totalDays: number;
    totalGongsu: number;
    teamPayout: number;
    netBilled: number;
  };
  taxNoteLines: string[]; // 종소세 안내 문구(한국어)
}

/** 현장별 인건비 집계 PDF (P5a) — 발주처 제출용. */
export interface SiteCostsPdfWorker {
  workerName: string; // 마스킹된 이름(팀이면 반장명 + 팀 표기)
  isTeam: boolean;
  teamMemberCount: number;
  days: number;
  gongsu: number;
  amount: number;
}

export interface SiteCostsPdfSite {
  site: string;
  entries: SiteCostsPdfWorker[];
  subtotalDays: number;
  subtotalGongsu: number;
  subtotalAmount: number;
}

export interface SiteCostsPdfData {
  title: string; // "현장별 인건비 집계"
  businessName: string; // 사업장 상호(헤더)
  periodLabel: string; // "2026-01 ~ 2026-03"
  sites: SiteCostsPdfSite[];
  totalDays: number;
  totalGongsu: number;
  totalAmount: number;
}

export interface SafetyReportPdfData {
  title: string; // "안전관리 이행 리포트"
  month: string; // YYYY-MM
  businessName: string;
  totalCount: number;
  byType: SafetyReportTypeCount[];
  rows: SafetyReportRow[];
  tbm?: SafetyReportTbmRow[]; // 월간 TBM 목록 (P2c)
}
