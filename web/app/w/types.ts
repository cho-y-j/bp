// 작업자 웹 공용 API 응답 타입 (백엔드 DTO 계약 기준 — web/ 전용 미러).

export interface LedgerSummary {
  month: string;
  daysWorked: number;
  totalBilled: number;
  totalOutstanding: number;
  totalPaid: number;
  totalGongsu: number;
  entryCount: number;
}

export interface ConfirmationListItem {
  id: string;
  status: string; // DRAFT | SENT | SIGNED
  statusLabel: string;
  date: string; // YYYY-MM-DD
  siteName: string;
  businessId: string | null;
  companyName: string;
  contact: string | null;
  workDescription: string;
  startTime: string;
  endTime: string;
  rateType: string;
  rateTypeLabel: string;
  amountCalc: unknown;
  total: number;
  equipmentSection: unknown;
  teamId: string | null;
  teamEntries: unknown;
  notes: string | null;
  shareToken: string;
  signerName: string | null;
  signedAt: string | null;
  revokedAt: string | null;
}

export interface DocumentItem {
  id: string;
  type: string;
  ownerType: string;
  status: string;
  derivedStatus: string;
  dday: number | null;
  issuedDate: string | null;
  expiryDate: string | null;
  hasMask: boolean;
  originalFileName: string | null;
}

export interface PaymentRecord {
  amount: number;
  paidAt: string;
  memo?: string;
}
export interface ReminderRecord {
  at: string;
  channel: string;
  stage: string;
}
export interface LedgerEntryItem {
  id: string;
  confirmationId: string | null;
  sourceConfirmationId: string | null;
  derived: boolean;
  businessId: string | null;
  counterpartyName: string | null;
  companyName: string;
  siteName: string | null;
  date: string | null;
  amount: number;
  paid: number;
  outstanding: number;
  status: string;
  statusLabel: string;
  dueDate: string | null;
  dday: number | null;
  payments: PaymentRecord[];
  autoRemind: boolean;
  reminders: ReminderRecord[];
}

export interface ByCompanyItem {
  companyName: string;
  businessId: string | null;
  days: number;
  total: number;
  paid: number;
  outstanding: number;
  dueDate: string | null;
  dday: number | null;
  status: string;
  statusLabel: string;
}

export interface NotificationItem {
  id: string;
  type: string;
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
}

export interface ConnectionItem {
  id: string;
  status: string; // ACCEPTED | REQUESTED | ...
  role: string; // WORKER | BUSINESS
  business: { id: string; name: string };
  worker: { id: string; name: string };
}

/** 확인서 상태 → 배지 클래스/문구. */
export function confStatusBadge(status: string): { cls: string; text: string } {
  if (status === 'SIGNED') return { cls: 'done', text: '서명완료' };
  if (status === 'SENT') return { cls: 'soon', text: '전송됨' };
  return { cls: 'calm', text: '작성중' };
}

/** 장부 상태 → 배지 클래스. */
export function ledgerStatusBadge(status: string): string {
  if (status === 'PAID') return 'done';
  if (status === 'OVERDUE') return 'warn';
  if (status === 'PARTIAL') return 'accent';
  return 'soon';
}
