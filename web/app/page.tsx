import Link from 'next/link';
import { Building, FileText, Wallet, Shield } from '@/components/Icons';

/** 루트 랜딩 — 한 문장 + 큰 CTA 1개로 단순화(감사 ★7). */
export default function Home() {
  return (
    <main className="landing">
      <div className="landing-hero">
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온 · WORKON
        </p>
        <h1 className="landing-title">
          일한 것을 30초에 기록하면
          <br />
          <span style={{ color: 'var(--accent-text)' }}>
            확인서·정산·안전
          </span>
          이 따라옵니다
        </h1>
        <p className="landing-sub">
          카톡으로 받은 확인서는 가입 없이 열어 서명하고, 사업장은 웹에서
          수신·정산·안전관리를 한 번에.
        </p>

        <Link href="/login" className="btn btn-primary btn-lg landing-cta">
          사업장 웹 로그인
        </Link>

        <p className="landing-note">
          확인서 링크를 받으셨다면 링크를 그대로 열어 서명하세요. 작업자용
          모바일 앱은 곧 출시됩니다.
        </p>

        <div className="landing-features">
          {[
            { Icon: Building, t: '작업 지시·연동' },
            { Icon: FileText, t: '작업확인서' },
            { Icon: Wallet, t: '정산 장부' },
            { Icon: Shield, t: '안전 리포트' },
          ].map(({ Icon, t }) => (
            <span className="landing-feature" key={t}>
              <Icon width={18} height={18} />
              {t}
            </span>
          ))}
        </div>
      </div>
    </main>
  );
}
