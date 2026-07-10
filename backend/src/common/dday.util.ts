/**
 * 만료 D-day 계산 유틸 (순수 함수 — 단위 테스트 대상).
 *
 * 규약:
 *  - D-day = (만료일의 달력 날짜) − (오늘의 달력 날짜), 일(day) 단위 정수.
 *  - 오늘 만료면 0, 남았으면 양수(D-30 = 30일 남음), 지났으면 음수.
 *  - 달력 경계는 한국 시간(KST, UTC+9) 자정을 기준으로 한다
 *    → 서버 타임존과 무관하게 사용자(한국) 기준 "며칠 남음"이 일관된다.
 */

const DAY_MS = 24 * 60 * 60 * 1000;
const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** 주어진 시각이 속한 KST 달력일의 자정(UTC epoch ms)을 반환. */
function startOfKstDay(date: Date): number {
  const shifted = date.getTime() + KST_OFFSET_MS;
  const dayStart = Math.floor(shifted / DAY_MS) * DAY_MS;
  return dayStart - KST_OFFSET_MS;
}

/** 만료일까지 남은 일수(D-day). now 기본값은 현재 시각. */
export function computeDday(expiry: Date, now: Date = new Date()): number {
  return Math.round((startOfKstDay(expiry) - startOfKstDay(now)) / DAY_MS);
}

export type ExpiryState = 'ACTIVE' | 'EXPIRING' | 'EXPIRED';

/**
 * D-day 로부터 만료 상태를 파생한다.
 *  - dday < 0        → EXPIRED
 *  - 0 ≤ dday ≤ 30   → EXPIRING (임박)
 *  - dday > 30       → ACTIVE
 */
export function expiryStateFromDday(dday: number | null): ExpiryState {
  if (dday === null) return 'ACTIVE'; // 만료일 없음 = 상시 유효
  if (dday < 0) return 'EXPIRED';
  if (dday <= 30) return 'EXPIRING';
  return 'ACTIVE';
}
