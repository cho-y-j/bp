import type { ReactNode } from 'react';
import LanguageSwitcher from './LanguageSwitcher';
import { type Lang } from '@/lib/i18n';

/**
 * 공개 페이지용 상태 화면 (일시 장애·찾을 수 없음 등).
 * title/message 는 호출부에서 언어에 맞게 번역해 넘긴다.
 * lang 을 주면 상단에 언어 선택 UI 를 노출한다(html lang 동기화 포함).
 */
export default function StatusScreen({
  title,
  message,
  action,
  lang,
}: {
  title: string;
  message: string;
  action?: ReactNode;
  lang?: Lang;
}) {
  return (
    <main className="page">
      {lang ? (
        <div className="lang-bar">
          <LanguageSwitcher current={lang} />
        </div>
      ) : null}
      <header style={{ marginBottom: 18 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온
        </p>
      </header>
      <div className="card empty">
        <p style={{ fontSize: 18, fontWeight: 700 }}>{title}</p>
        <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>{message}</p>
        {action ? <div style={{ marginTop: 16 }}>{action}</div> : null}
      </div>
    </main>
  );
}
