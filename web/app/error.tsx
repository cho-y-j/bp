'use client';

import { useEffect, useState } from 'react';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import {
  LANG_COOKIE,
  LANG_STORAGE,
  DEFAULT_LANG,
  createT,
  resolveLang,
  type Lang,
} from '@/lib/i18n';

function readClientLang(): Lang {
  if (typeof window === 'undefined') return DEFAULT_LANG;
  const cookie = document.cookie
    .split('; ')
    .find((c) => c.startsWith(`${LANG_COOKIE}=`))
    ?.split('=')[1];
  let stored: string | null = null;
  try {
    stored = window.localStorage.getItem(LANG_STORAGE);
  } catch {
    stored = null;
  }
  return resolveLang({
    stored: cookie ?? stored,
    acceptLanguage: navigator.language,
  });
}

/**
 * 전역 에러 바운더리 — 예기치 못한 렌더/데이터 오류 시 친화 화면 + 재시도.
 * (공개 페이지는 데이터 로드 실패를 자체적으로 친화 화면으로 처리하지만,
 *  그 외 예외의 안전망으로 유지한다.) 언어는 클라이언트 저장값/브라우저 기준.
 */
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const [lang, setLang] = useState<Lang>(DEFAULT_LANG);
  useEffect(() => {
    console.error(error);
    setLang(readClientLang());
  }, [error]);
  const t = createT(lang);

  return (
    <main className="page">
      <div className="lang-bar">
        <LanguageSwitcher current={lang} />
      </div>
      <header style={{ marginBottom: 18 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온
        </p>
      </header>
      <div className="card empty">
        <p style={{ fontSize: 18, fontWeight: 700 }}>
          {t('statusTransientTitle')}
        </p>
        <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>
          {t('statusTransientMsg')}
        </p>
        <button
          className="btn btn-primary"
          style={{ marginTop: 16, maxWidth: 200 }}
          onClick={reset}
        >
          {t('statusRetry')}
        </button>
      </div>
    </main>
  );
}
