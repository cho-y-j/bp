import { LANG_LOCALE, type Lang } from './i18n';

/** 금액을 천단위 콤마 문자열로. */
export function won(n: number | null | undefined): string {
  return (n ?? 0).toLocaleString('ko-KR');
}

/**
 * 언어별 천단위 그룹핑만 적용한 숫자 문자열(통화기호 없음).
 * ru 는 공백, ne 는 인도식(라크) 그룹핑 등 각 로케일 규칙을 따른다.
 */
export function grouped(n: number | null | undefined, lang: Lang): string {
  return new Intl.NumberFormat(LANG_LOCALE[lang]).format(n ?? 0);
}

/**
 * 통화 표기(원화 고정). 한국어는 "1,234원", 그 외 언어는 "₩1,234"(언어별 천단위).
 * 통화 자체는 항상 원화(KRW) — 환산하지 않는다.
 */
export function money(n: number | null | undefined, lang: Lang): string {
  const g = grouped(n, lang);
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

/** D-day 숫자 → 배지 텍스트/클래스 */
export function ddayBadge(dday: number | null): { text: string; cls: string } {
  if (dday === null || dday === undefined) return { text: '', cls: 'calm' };
  if (dday < 0) return { text: `D+${-dday}`, cls: 'warn' };
  if (dday === 0) return { text: 'D-day', cls: 'warn' };
  if (dday <= 30) return { text: `D-${dday}`, cls: 'soon' };
  return { text: `D-${dday}`, cls: 'calm' };
}
