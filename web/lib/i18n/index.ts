/**
 * 경량 사전(dictionary) 방식 i18n — 무거운 라이브러리 없이 SSR·클라이언트 공용.
 * 외부 공개 페이지(/c, /s, 상태화면, 가입배너)의 UI 문자열만 번역한다.
 */
import ko, { type MessageKey } from './ko';
import zh from './zh';
import ru from './ru';
import vi from './vi';
import ne from './ne';
import en from './en';

export type { MessageKey };

export type Lang = 'ko' | 'zh' | 'ru' | 'vi' | 'ne' | 'en';

/** 지원 언어 순서(스위처 노출 순서) — 한국어 기본 + 리서치 기반 5종. */
export const LANGS: Lang[] = ['ko', 'zh', 'ru', 'vi', 'ne', 'en'];

/** 각 언어의 자국어 표기(스위처에 그대로 노출). */
export const LANG_NATIVE: Record<Lang, string> = {
  ko: '한국어',
  zh: '简体中文',
  ru: 'Русский',
  vi: 'Tiếng Việt',
  ne: 'नेपाली',
  en: 'English',
};

/** Intl 로케일 매핑(날짜·숫자 포맷). */
export const LANG_LOCALE: Record<Lang, string> = {
  ko: 'ko-KR',
  zh: 'zh-CN',
  ru: 'ru-RU',
  vi: 'vi-VN',
  ne: 'ne-NP',
  en: 'en-US',
};

export const DEFAULT_LANG: Lang = 'ko';
export const LANG_COOKIE = 'jakeobon_lang';
export const LANG_STORAGE = 'jakeobon_lang';

const DICTS: Record<Lang, Record<MessageKey, string>> = { ko, zh, ru, vi, ne, en };

/** 임의 문자열을 지원 Lang 으로 정규화(대소문자·지역태그 허용). null 이면 미지원. */
export function normalizeLang(v: string | null | undefined): Lang | null {
  if (!v) return null;
  const base = v.toLowerCase().split('-')[0];
  return (LANGS as string[]).includes(base) ? (base as Lang) : null;
}

/** Accept-Language 헤더에서 지원 언어 중 q-우선순위가 가장 높은 것 선택. */
export function pickFromAcceptLanguage(header: string | null | undefined): Lang | null {
  if (!header) return null;
  const parsed = header
    .split(',')
    .map((part) => {
      const [tag, ...params] = part.trim().split(';');
      const q = params
        .map((p) => p.trim())
        .find((p) => p.startsWith('q='));
      const quality = q ? parseFloat(q.slice(2)) : 1;
      return { lang: normalizeLang(tag), q: Number.isNaN(quality) ? 1 : quality };
    })
    .filter((x): x is { lang: Lang; q: number } => x.lang !== null)
    .sort((a, b) => b.q - a.q);
  return parsed.length ? parsed[0].lang : null;
}

/**
 * 초기 언어 결정: ①명시값(?lang=) → ②저장값(cookie) → ③Accept-Language → 기본(ko).
 * 서버·클라이언트 어디서나 사용 가능한 순수 함수(입력만 넘기면 됨).
 */
export function resolveLang(sources: {
  explicit?: string | null;
  stored?: string | null;
  acceptLanguage?: string | null;
}): Lang {
  return (
    normalizeLang(sources.explicit) ??
    normalizeLang(sources.stored) ??
    pickFromAcceptLanguage(sources.acceptLanguage) ??
    DEFAULT_LANG
  );
}

/** t(): 사전 조회 + {param} 치환. 미번역 키는 한국어로 폴백. */
export function t(
  lang: Lang,
  key: MessageKey,
  params?: Record<string, string | number>,
): string {
  const dict = DICTS[lang] ?? ko;
  let s = dict[key] ?? ko[key] ?? key;
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      s = s.split(`{${k}}`).join(String(v));
    }
  }
  return s;
}

export type TFn = (key: MessageKey, params?: Record<string, string | number>) => string;

/** 특정 언어에 바인딩된 t 헬퍼 생성(컴포넌트에 t 하나만 넘길 때). */
export function createT(lang: Lang): TFn {
  return (key, params) => t(lang, key, params);
}
