import Link from 'next/link';
import { Building, FileText, Wallet, Shield } from '@/components/Icons';

/** 루트 랜딩 — S1 검수 지적(‘/’ 가 API /health 로 리다이렉트) 해소. */
export default function Home() {
  return (
    <main className="page" style={{ maxWidth: 620 }}>
      <p className="brand-kicker" style={{ marginTop: 24 }}>
        <span className="brand-dot" />
        작업온 · WORKON
      </p>
      <h1
        style={{
          fontSize: 34,
          fontWeight: 800,
          letterSpacing: '-0.02em',
          margin: '14px 0 12px',
          lineHeight: 1.25,
        }}
      >
        일한 것을 30초에 기록하면
        <br />
        <span style={{ color: 'var(--accent-text)' }}>
          확인서·장부·정산·안전
        </span>
        이 따라옵니다
      </h1>
      <p style={{ fontSize: 17, color: 'var(--ink-2)', margin: '0 0 28px' }}>
        현장 작업자와 사업장을 잇는 작업확인서·서류·정산 관리. 카톡으로 받은
        확인서는 가입 없이 열어 서명하고, 사업장은 웹에서 수신·정산·안전관리를
        한번에.
      </p>

      <Link
        href="/login"
        className="btn btn-primary btn-lg"
        style={{ maxWidth: 320 }}
      >
        사업장 웹 로그인
      </Link>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 14,
          marginTop: 36,
        }}
      >
        {[
          {
            Icon: Building,
            t: '작업 지시·연동',
            d: '전화번호로 작업자 연결, 작업 지시',
          },
          {
            Icon: FileText,
            t: '작업확인서',
            d: '수신·앱내 서명, 종이 확인서 그대로',
          },
          { Icon: Wallet, t: '정산', d: '작업자별 미지급 집계, 선택 지급' },
          { Icon: Shield, t: '안전 리포트', d: '폭염 알림·이행 리포트 PDF' },
        ].map(({ Icon, t, d }) => (
          <div className="card" key={t} style={{ padding: 18 }}>
            <span style={{ color: 'var(--accent-text)' }}>
              <Icon width={24} height={24} />
            </span>
            <div style={{ fontWeight: 700, fontSize: 17, margin: '10px 0 4px' }}>
              {t}
            </div>
            <div style={{ fontSize: 14, color: 'var(--ink-2)' }}>{d}</div>
          </div>
        ))}
      </div>

      <p style={{ marginTop: 32, fontSize: 14, color: 'var(--ink-3)' }}>
        작업자용 모바일 앱은 곧 출시됩니다. 확인서 링크를 받으셨다면 링크를
        그대로 열어 서명하세요.
      </p>
    </main>
  );
}
