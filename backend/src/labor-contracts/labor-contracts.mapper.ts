import { LaborContract } from '@prisma/client';
import { toKstDateStr, toKstDateTimeStr } from '../confirmations/time.util';

const STATUS_LABEL: Record<string, string> = {
  DRAFT: '작성됨',
  SENT: '전송됨',
  SIGNED: '서명됨',
};

const WAGE_TYPE_LABEL: Record<string, string> = {
  DAILY: '일급',
  HOURLY: '시급',
};

export interface SocialInsurance {
  employment?: boolean;
  health?: boolean;
  pension?: boolean;
  industrialAccident?: boolean;
}

export interface LaborContractDto {
  id: string;
  status: string;
  statusLabel: string;
  businessId: string;
  businessName?: string | null;
  title: string;
  workerProfileId: string | null;
  workerLinked: boolean;
  workerName: string;
  workerPhone: string | null;
  startDate: string;
  endDate: string | null;
  workplace: string;
  jobDescription: string;
  workStartTime: string;
  workEndTime: string;
  breakTime: string | null;
  wageType: string;
  wageTypeLabel: string;
  wageAmount: number;
  payday: string;
  payMethod: string;
  weeklyHolidayAllowance: boolean;
  overtimeAllowance: boolean;
  socialInsurance: SocialInsurance | null;
  specialTerms: string | null;
  employerSigned: boolean;
  employerSignerName: string | null;
  employerSignedAt: string | null;
  workerSigned: boolean;
  workerSignerName: string | null;
  workerSignedAt: string | null;
  shareToken: string;
  revokedAt: Date | null;
  viewCount: number;
  createdAt: Date;
  updatedAt: Date;
}

/** LaborContract → API DTO. 내부 파일 경로(signImagePath)는 노출하지 않는다. */
export function toLaborContractDto(
  c: LaborContract & { business?: { name: string } | null },
): LaborContractDto {
  return {
    id: c.id,
    status: c.status,
    statusLabel: STATUS_LABEL[c.status] ?? c.status,
    businessId: c.businessId,
    businessName: c.business?.name ?? null,
    title: c.title,
    workerProfileId: c.workerProfileId,
    workerLinked: c.workerProfileId !== null,
    workerName: c.workerName,
    workerPhone: c.workerPhone,
    startDate: toKstDateStr(c.startDate),
    endDate: c.endDate ? toKstDateStr(c.endDate) : null,
    workplace: c.workplace,
    jobDescription: c.jobDescription,
    workStartTime: c.workStartTime,
    workEndTime: c.workEndTime,
    breakTime: c.breakTime,
    wageType: c.wageType,
    wageTypeLabel: WAGE_TYPE_LABEL[c.wageType] ?? c.wageType,
    wageAmount: Number(c.wageAmount),
    payday: c.payday,
    payMethod: c.payMethod,
    weeklyHolidayAllowance: c.weeklyHolidayAllowance,
    overtimeAllowance: c.overtimeAllowance,
    socialInsurance: (c.socialInsurance as SocialInsurance | null) ?? null,
    specialTerms: c.specialTerms,
    employerSigned: c.employerSignedAt !== null,
    employerSignerName: c.employerSignerName,
    employerSignedAt: c.employerSignedAt
      ? toKstDateTimeStr(c.employerSignedAt)
      : null,
    workerSigned: c.workerSignedAt !== null,
    workerSignerName: c.workerSignerName,
    workerSignedAt: c.workerSignedAt
      ? toKstDateTimeStr(c.workerSignedAt)
      : null,
    shareToken: c.shareToken,
    revokedAt: c.revokedAt,
    viewCount: c.viewCount,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  };
}

export { STATUS_LABEL as LC_STATUS_LABEL, WAGE_TYPE_LABEL };
