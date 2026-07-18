import Link from 'next/link';
import { Pen, Wallet, Shield } from '@/components/Icons';

/**
 * 루트 랜딩 — 한 문장 + 큰 CTA 1개(감사 ★7).
 * 모바일: 단일 칼럼(깔끔 유지). 데스크톱(≥1024px): 좌 카피+CTA / 우 앱 화면 목업 2장.
 * 히어로 아래 신뢰 3블록으로 데스크톱 공백 해소.
 */
export default function Home() {
  return (
    <main className="landing">
      <div className="landing-inner">
        <div className="landing-grid">
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
          </div>

          <div className="landing-visual">
            <div className="phone phone-back">
              <img
                src="/landing-app-confirmation.png"
                alt="작업온 앱에서 손글씨로 서명한 작업확인서 화면"
                width={1206}
                height={2622}
              />
            </div>
            <div className="phone phone-front">
              <img
                src="/landing-app-home.png"
                alt="작업온 앱 홈 화면 — 오늘 일정과 이번 달 받을 돈 요약"
                width={1206}
                height={2622}
              />
            </div>
          </div>
        </div>

        <ul className="landing-trust">
          <li>
            <span className="landing-trust-ic">
              <Pen width={20} height={20} />
            </span>
            상대가 가입 안 해도 링크로 서명
          </li>
          <li>
            <span className="landing-trust-ic">
              <Wallet width={20} height={20} />
            </span>
            확인서 쓰면 장부·정산 자동
          </li>
          <li>
            <span className="landing-trust-ic">
              <Shield width={20} height={20} />
            </span>
            안전관리 증빙 PDF
          </li>
        </ul>
      </div>
    </main>
  );
}
