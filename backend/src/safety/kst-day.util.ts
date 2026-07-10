/** 주어진 시각이 속한 KST 달력일의 [start, end) instant 범위. */
const DAY_MS = 24 * 60 * 60 * 1000;
const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

export function kstDayRange(now: Date): { start: Date; end: Date } {
  const shifted = now.getTime() + KST_OFFSET_MS;
  const dayStart = Math.floor(shifted / DAY_MS) * DAY_MS - KST_OFFSET_MS;
  return { start: new Date(dayStart), end: new Date(dayStart + DAY_MS) };
}
