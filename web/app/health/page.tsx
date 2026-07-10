export const dynamic = 'force-static';

export default function HealthPage() {
  return (
    <main
      style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '0.5rem',
        padding: '2rem',
        textAlign: 'center',
      }}
    >
      <h1 style={{ fontSize: '1.75rem', margin: 0 }}>작업온 웹 준비됨</h1>
      <p style={{ color: '#666', margin: 0 }}>Jakeobon Web · Stage 1 skeleton</p>
    </main>
  );
}
