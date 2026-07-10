/** 금액을 천단위 콤마 문자열로. */
export function won(n: number | null | undefined): string {
  return (n ?? 0).toLocaleString('ko-KR');
}

/** ISO 또는 YYYY-MM-DD → "2026.07.11 (토)" */
const WEEK = ['일', '월', '화', '수', '목', '금', '토'];
export function dateLabel(input: string | Date | null | undefined): string {
  if (!input) return '-';
  const d = typeof input === 'string' ? new Date(input) : input;
  if (Number.isNaN(d.getTime())) return String(input);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}.${m}.${day} (${WEEK[d.getDay()]})`;
}

/** YYYY-MM 현재 달 (KST 기준 근사) */
export function currentMonth(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

/** YYYY-MM → 다른 달로 이동 */
export function shiftMonth(month: string, delta: number): string {
  const [y, m] = month.split('-').map(Number);
  const d = new Date(y, m - 1 + delta, 1);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

/** YYYY-MM → "2026년 7월" */
export function monthLabel(month: string): string {
  const [y, m] = month.split('-').map(Number);
  return `${y}년 ${m}월`;
}

/** D-day 숫자 → 배지 텍스트/클래스 */
export function ddayBadge(dday: number | null): { text: string; cls: string } {
  if (dday === null || dday === undefined) return { text: '', cls: 'calm' };
  if (dday < 0) return { text: `D+${-dday}`, cls: 'warn' };
  if (dday === 0) return { text: 'D-day', cls: 'warn' };
  if (dday <= 30) return { text: `D-${dday}`, cls: 'soon' };
  return { text: `D-${dday}`, cls: 'calm' };
}
