import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import './globals.css';
import { resolveServerLang } from '@/lib/i18n/server';

export const metadata: Metadata = {
  title: '작업온',
  description:
    '일한 것을 30초에 기록하면, 확인서·장부·정산·안전증빙이 자동으로 따라오는 앱',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#F4770C',
};

export default async function RootLayout({ children }: { children: ReactNode }) {
  // 저장값(쿠키)·Accept-Language 로 <html lang> 을 결정. ?lang= 딥링크는
  // 클라이언트(LanguageSwitcher 마운트)에서 document.documentElement.lang 로 보정한다.
  const lang = await resolveServerLang();
  return (
    <html lang={lang}>
      <head>
        {/* Pretendard (한글·라틴·키릴·베트남어) — 실패 시 시스템 폰트로 폴백.
            네팔어(데바나가리)는 globals.css 폰트 스택의 시스템 폰트로 폴백. */}
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable.min.css"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
