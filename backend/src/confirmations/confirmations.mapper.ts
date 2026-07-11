import { Confirmation } from '@prisma/client';
import { toKstDateStr, toKstTimeStr, toKstDateTimeStr } from './time.util';

const RATE_TYPE_LABEL: Record<string, string> = {
  DAILY: '일당',
  HOURLY: '시급',
  PER_CASE: '건당',
  MONTHLY: '월급',
  UNIT: '물량단가',
  GONGSU: '공수',
};

const STATUS_LABEL: Record<string, string> = {
  DRAFT: '작성됨',
  SENT: '전송됨',
  SIGNED: '서명됨',
};

export interface ConfirmationDto {
  id: string;
  status: string;
  statusLabel: string;
  date: string; // KST YYYY-MM-DD
  siteName: string;
  businessId: string | null;
  companyName: string;
  contact: string | null;
  workDescription: string;
  startTime: string; // HH:mm
  endTime: string; // HH:mm
  rateType: string;
  rateTypeLabel: string;
  amountCalc: unknown;
  total: number;
  equipmentSection: unknown;
  notes: string | null;
  shareToken: string;
  signerName: string | null;
  signedAt: string | null;
  revokedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

function amountTotal(amountCalc: unknown): number {
  const t = (amountCalc as { total?: unknown } | null)?.total;
  return typeof t === 'number' ? t : 0;
}

/** Confirmation → API DTO. 내부 파일 경로(signImagePath)는 노출하지 않는다. */
export function toConfirmationDto(c: Confirmation): ConfirmationDto {
  return {
    id: c.id,
    status: c.status,
    statusLabel: STATUS_LABEL[c.status] ?? c.status,
    date: toKstDateStr(c.date),
    siteName: c.site,
    businessId: c.businessId,
    companyName: c.companyName,
    contact: c.manualContact,
    workDescription: c.workContent,
    startTime: toKstTimeStr(c.startTime),
    endTime: toKstTimeStr(c.endTime),
    rateType: c.rateType,
    rateTypeLabel: RATE_TYPE_LABEL[c.rateType] ?? c.rateType,
    amountCalc: c.amountCalc,
    total: amountTotal(c.amountCalc),
    equipmentSection: c.equipmentSection ?? null,
    notes: c.notes,
    shareToken: c.shareToken,
    signerName: c.signerName,
    signedAt: c.signedAt ? toKstDateTimeStr(c.signedAt) : null,
    revokedAt: c.revokedAt,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  };
}

export { RATE_TYPE_LABEL, STATUS_LABEL };
