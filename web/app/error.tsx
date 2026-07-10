'use client';

import { useEffect } from 'react';

/**
 * 전역 에러 바운더리 — 예기치 못한 렌더/데이터 오류 시 친화 화면 + 재시도.
 * (공개 페이지는 데이터 로드 실패를 자체적으로 친화 화면으로 처리하지만,
 *  그 외 예외의 안전망으로 유지한다.)
 */
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="page">
      <header style={{ marginBottom: 18 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온
        </p>
      </header>
      <div className="card empty">
        <p style={{ fontSize: 18, fontWeight: 700 }}>일시적인 오류입니다</p>
        <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>
          잠시 후 다시 시도해 주세요.
        </p>
        <button
          className="btn btn-primary"
          style={{ marginTop: 16, maxWidth: 200 }}
          onClick={reset}
        >
          다시 시도
        </button>
      </div>
    </main>
  );
}
