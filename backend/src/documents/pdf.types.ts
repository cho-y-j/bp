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

export interface SafetyReportPdfData {
  title: string; // "안전관리 이행 리포트"
  month: string; // YYYY-MM
  businessName: string;
  totalCount: number;
  byType: SafetyReportTypeCount[];
  rows: SafetyReportRow[];
}
