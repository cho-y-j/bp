/**
 * 지급 평판 배지 유틸 (순수 함수 — 단위 테스트 대상). P3a.
 *
 * 원칙(부정 낙인 금지 — 좋은 것만 노출):
 *  - 평균 지급 소요일 = SIGNED(확인서 서명 완료) → 전액 PAID 까지 일수의 평균.
 *  - 최근 12개월 표본이 3건 이상일 때만 산출("데이터 부족" 미달).
 *  - 등급: ⚡우수(≤15일) / 양호(≤30일) / 표시 없음(>30일 또는 데이터 부족).
 */

export type PaymentBadgeGrade = 'EXCELLENT' | 'GOOD';

export const BADGE_MIN_SAMPLE = 3;
export const BADGE_EXCELLENT_MAX_DAYS = 15;
export const BADGE_GOOD_MAX_DAYS = 30;

/** 배지 캐시 컬럼(사업장) 형태. */
export interface BadgeCache {
  paymentAvgDays: number | null;
  paymentSampleSize: number;
}

/** 공개 노출용 배지 DTO(우수/양호만). 미달·>30일은 null. */
export interface PaymentBadge {
  grade: PaymentBadgeGrade;
  avgDays: number;
  sampleSize: number;
}

/** 평균 소요일로부터 등급을 판정. 표시 대상이 아니면 null. */
export function gradeForAvgDays(
  avgDays: number | null,
): PaymentBadgeGrade | null {
  if (avgDays == null || !Number.isFinite(avgDays) || avgDays < 0) return null;
  if (avgDays <= BADGE_EXCELLENT_MAX_DAYS) return 'EXCELLENT';
  if (avgDays <= BADGE_GOOD_MAX_DAYS) return 'GOOD';
  return null;
}

/**
 * 캐시 컬럼 → 공개 배지 DTO. 표본 3건 미만 또는 등급 미해당이면 null(노출 안 함).
 */
export function badgeFromCache(cache: BadgeCache): PaymentBadge | null {
  if (cache.paymentSampleSize < BADGE_MIN_SAMPLE) return null;
  const grade = gradeForAvgDays(cache.paymentAvgDays);
  if (!grade || cache.paymentAvgDays == null) return null;
  return {
    grade,
    avgDays: Math.round(cache.paymentAvgDays * 10) / 10,
    sampleSize: cache.paymentSampleSize,
  };
}

/**
 * 사업장 본인용 배지 상태(부정 낙인 없이, 개선 안내 목적).
 *  - status: 'EXCELLENT' | 'GOOD' | 'NONE'(표시 없음, >30일) | 'INSUFFICIENT'(데이터 부족)
 */
export interface SelfBadgeStatus {
  status: PaymentBadgeGrade | 'NONE' | 'INSUFFICIENT';
  avgDays: number | null;
  sampleSize: number;
}

export function selfBadgeStatus(cache: BadgeCache): SelfBadgeStatus {
  const avgDays =
    cache.paymentAvgDays == null
      ? null
      : Math.round(cache.paymentAvgDays * 10) / 10;
  if (cache.paymentSampleSize < BADGE_MIN_SAMPLE) {
    return {
      status: 'INSUFFICIENT',
      avgDays,
      sampleSize: cache.paymentSampleSize,
    };
  }
  const grade = gradeForAvgDays(cache.paymentAvgDays);
  return {
    status: grade ?? 'NONE',
    avgDays,
    sampleSize: cache.paymentSampleSize,
  };
}

/**
 * 지급 소요일 표본으로부터 평균을 계산(표본 3건 미만이면 null).
 *  - days: 각 확인서의 (SIGNED → 전액 PAID) 소요 일수 배열.
 */
export function computeAvgDays(days: number[]): {
  avgDays: number | null;
  sampleSize: number;
} {
  const valid = days.filter((d) => Number.isFinite(d) && d >= 0);
  if (valid.length < BADGE_MIN_SAMPLE) {
    return { avgDays: null, sampleSize: valid.length };
  }
  const sum = valid.reduce((s, d) => s + d, 0);
  return { avgDays: sum / valid.length, sampleSize: valid.length };
}

/** 두 시각 사이 경과 일수(내림, 최소 0). KST 달력일이 아닌 절대 경과시간 기준. */
export function daysBetween(fromIso: Date, toIso: Date): number {
  const ms = toIso.getTime() - fromIso.getTime();
  return Math.max(0, Math.floor(ms / (24 * 60 * 60 * 1000)));
}
