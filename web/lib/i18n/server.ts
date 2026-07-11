import { cookies, headers } from 'next/headers';
import { LANG_COOKIE, resolveLang, type Lang } from './index';

/**
 * SSR(서버 컴포넌트)용 초기 언어 결정.
 * 우선순위: ①?lang=(explicit 인자) → ②쿠키 저장값 → ③Accept-Language → 기본(ko).
 * (Next 15: cookies()/headers() 는 async)
 */
export async function resolveServerLang(explicit?: string | null): Promise<Lang> {
  const [cookieStore, headerStore] = await Promise.all([cookies(), headers()]);
  return resolveLang({
    explicit,
    stored: cookieStore.get(LANG_COOKIE)?.value ?? null,
    acceptLanguage: headerStore.get('accept-language'),
  });
}
