'use client';

import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  LANGS,
  LANG_NATIVE,
  LANG_COOKIE,
  LANG_STORAGE,
  type Lang,
} from '@/lib/i18n';
import { Globe, Check, Chevron } from './Icons';

/** 선택 언어를 쿠키/localStorage 에 저장하고 <html lang> 을 동기화. */
function persistLang(lang: Lang) {
  try {
    document.cookie = `${LANG_COOKIE}=${lang}; path=/; max-age=31536000; samesite=lax`;
    window.localStorage.setItem(LANG_STORAGE, lang);
  } catch {
    /* 저장 실패는 무시(시크릿 모드 등) */
  }
  document.documentElement.lang = lang;
}

/**
 * 언어 선택 UI — 지구본 + 현재 언어(자국어 표기). 시안 디자인 토큰 스타일.
 * - current: SSR 이 결정한 현재 언어(?lang / 쿠키 / Accept-Language 순).
 * - 마운트 시 current 를 쿠키·localStorage 에 저장(알림톡 ?lang= 딥링크도 자동 기억).
 * - 선택 시 ?lang= 갱신 + SSR 재렌더(router.refresh)로 페이지 전체 문구 전환.
 */
export default function LanguageSwitcher({ current }: { current: Lang }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  // 마운트 시 현재 언어 저장 + html lang 동기화(?lang 딥링크 진입 포함).
  useEffect(() => {
    persistLang(current);
  }, [current]);

  // 바깥 클릭 시 닫기.
  useEffect(() => {
    if (!open) return;
    function onDown(e: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [open]);

  function choose(lang: Lang) {
    setOpen(false);
    if (lang === current) return;
    persistLang(lang);
    const url = new URL(window.location.href);
    url.searchParams.set('lang', lang);
    router.replace(url.pathname + url.search);
    router.refresh();
  }

  return (
    <div className="lang-switch" ref={rootRef}>
      <button
        type="button"
        className="lang-trigger"
        aria-haspopup="listbox"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <Globe width={18} height={18} />
        <span className="lang-current">{LANG_NATIVE[current]}</span>
        <Chevron
          width={16}
          height={16}
          style={{
            transform: open ? 'rotate(90deg)' : 'rotate(0deg)',
            transition: 'transform .15s',
          }}
        />
      </button>
      {open ? (
        <ul className="lang-menu" role="listbox">
          {LANGS.map((lang) => (
            <li key={lang}>
              <button
                type="button"
                role="option"
                aria-selected={lang === current}
                className={`lang-option${lang === current ? ' on' : ''}`}
                onClick={() => choose(lang)}
              >
                <span>{LANG_NATIVE[lang]}</span>
                {lang === current ? <Check width={16} height={16} /> : null}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
