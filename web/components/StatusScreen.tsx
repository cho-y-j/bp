import type { ReactNode } from 'react';

/**
 * 공개 페이지용 상태 화면 (일시 장애·찾을 수 없음 등).
 * 서버/클라이언트 어디서나 렌더 가능한 순수 표시 컴포넌트.
 */
export default function StatusScreen({
  title,
  message,
  action,
}: {
  title: string;
  message: string;
  action?: ReactNode;
}) {
  return (
    <main className="page">
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
