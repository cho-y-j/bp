import { LANG_LOCALE, type Lang } from './i18n';

/** 금액을 천단위 콤마 문자열로. */
export function won(n: number | null | undefined): string {
  return (n ?? 0).toLocaleString('ko-KR');
}

/**
 * 통화 표기(원화 고정) — 전 언어 공통 서식.
 * 금액의 천단위 구분은 **항상 한국식 콤마**(1,050,000)로 고정한다.
 * 로케일별 구분자(ru 공백·ne 라크·일부 로케일 점(.))는 한국 금액을
 * 오독(예: "₩1.050.000" → 1.05로 오해)시키므로 폐기한다.
 * 한국어는 "1,050,000원", 그 외 언어는 "₩1,050,000".
 * (won() 과 동일한 콤마 서식 — formatMoney 일원화)
 */
export function money(n: number | null | undefined, lang: Lang): string {
  const g = won(n); // 항상 ko-KR 콤마
  return lang === 'ko' ? `${g}원` : `₩${g}`;
}

/** 언어별 locale 날짜 포맷(요일 포함). 예: ko "2026. 7. 11. 토" */
export function formatDate(
  input: string | Date | null | undefined,
  lang: Lang,
): string {
  if (!input) return '-';
  const d = typeof input === 'string' ? new Date(input) : input;
  if (Number.isNaN(d.getTime())) return String(input);
  return new Intl.DateTimeFormat(LANG_LOCALE[lang], {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    weekday: 'short',
  }).format(d);
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

export interface DdayBadge {
  text: string;
  cls: string;
}

/**
 * 서류 만료 배지 (앱 규칙과 통일 — app_ko.arb docExpired/walletExpiring).
 * · 만료 지남 → "만료됨" 빨강(warn)  (D+N 부호 표기 폐기 — 40~60대 오독 방지)
 * · 30일 이내 → "D-N" 임박(soon)
 * · 31~90일  → "D-N" 차분(calm)
 * · 90일 초과 → 배지 없음(null). 날짜만 표기(원거리 D-day 노이즈 제거).
 */
export function expiryBadge(dday: number | null | undefined): DdayBadge | null {
  if (dday === null || dday === undefined) return null;
  if (dday < 0) return { text: '만료됨', cls: 'warn' };
  if (dday === 0) return { text: '오늘 만료', cls: 'warn' };
  if (dday <= 30) return { text: `D-${dday}`, cls: 'soon' };
  if (dday <= 90) return { text: `D-${dday}`, cls: 'calm' };
  return null;
}

/**
 * 수금 D-day 배지 (앱 규칙과 통일 — ddayText: collectDday/statusOverdue).
 * · 기한 지남 → "기한 지남" 빨강(warn)  (D+N 부호 폐기)
 * · 오늘/임박(≤30) → "수금 D-N" 임박(soon)
 * · 그 외 → "수금 D-N" 차분(calm)
 */
export function collectBadge(dday: number | null | undefined): DdayBadge | null {
  if (dday === null || dday === undefined) return null;
  if (dday < 0) return { text: '기한 지남', cls: 'warn' };
  if (dday === 0) return { text: '수금 D-day', cls: 'soon' };
  if (dday <= 30) return { text: `수금 D-${dday}`, cls: 'soon' };
  return { text: `수금 D-${dday}`, cls: 'calm' };
}
