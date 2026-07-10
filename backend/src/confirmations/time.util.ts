/**
 * KST(UTC+9) 기준 날짜/시각 조합·포맷 유틸 (순수 함수).
 *  - 확인서의 date/startTime/endTime 은 KST 벽시계 기준으로 저장/표시한다.
 *  - 서버 타임존과 무관하게 일관되도록 오프셋을 고정한다.
 */

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** "YYYY-MM-DD" (KST 자정) → Date(instant). */
export function kstDate(dateStr: string): Date {
  return new Date(`${dateStr}T00:00:00+09:00`);
}

/** "YYYY-MM-DD" + "HH:mm" → Date(instant, KST 벽시계). */
export function kstDateTime(dateStr: string, timeStr: string): Date {
  return new Date(`${dateStr}T${timeStr}:00+09:00`);
}

/** Date → KST "YYYY-MM-DD". */
export function toKstDateStr(date: Date): string {
  const shifted = new Date(date.getTime() + KST_OFFSET_MS);
  return shifted.toISOString().slice(0, 10);
}

/** Date → KST "HH:mm". */
export function toKstTimeStr(date: Date): string {
  const shifted = new Date(date.getTime() + KST_OFFSET_MS);
  return shifted.toISOString().slice(11, 16);
}

/** Date → KST "YYYY-MM-DD HH:mm" (서명일시 등 표시용). */
export function toKstDateTimeStr(date: Date): string {
  return `${toKstDateStr(date)} ${toKstTimeStr(date)}`;
}

/** "YYYY-MM" → [monthStart, nextMonthStart) instant 범위 (KST 자정 경계). */
export function kstMonthRange(month: string): { start: Date; end: Date } {
  const [y, m] = month.split('-').map((n) => parseInt(n, 10));
  const start = new Date(`${month}-01T00:00:00+09:00`);
  const nextMonth = m === 12 ? 1 : m + 1;
  const nextYear = m === 12 ? y + 1 : y;
  const end = new Date(
    `${nextYear}-${String(nextMonth).padStart(2, '0')}-01T00:00:00+09:00`,
  );
  return { start, end };
}
