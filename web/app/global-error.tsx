'use client';

/**
 * 루트 레이아웃 자체가 실패했을 때의 최종 안전망(html/body 를 직접 포함).
 * app/error.tsx 로 잡히지 않는 최상위 오류만 여기로 온다.
 */
export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="ko">
      <body
        style={{
          fontFamily: 'system-ui, -apple-system, sans-serif',
          display: 'flex',
          minHeight: '100vh',
          alignItems: 'center',
          justifyContent: 'center',
          margin: 0,
          padding: 24,
          background: '#F7F6F3',
          color: '#1A2233',
        }}
      >
        <div style={{ textAlign: 'center', maxWidth: 360 }}>
          <p style={{ fontSize: 18, fontWeight: 700, margin: '0 0 8px' }}>
            일시적인 오류입니다
          </p>
          <p style={{ fontSize: 15, color: '#555', margin: '0 0 16px' }}>
            잠시 후 다시 시도해 주세요.
          </p>
          <button
            onClick={reset}
            style={{
              padding: '12px 20px',
              fontSize: 16,
              fontWeight: 700,
              color: '#fff',
              background: '#F4770C',
              border: 0,
              borderRadius: 12,
              cursor: 'pointer',
            }}
          >
            다시 시도
          </button>
        </div>
      </body>
    </html>
  );
}
