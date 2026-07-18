import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { apiGet, classifyLoadError } from '@/lib/api';
import StatusScreen from '@/components/StatusScreen';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { Shield, CheckCircle, Truck } from '@/components/Icons';
import { formatDate } from '@/lib/format';
import { createT } from '@/lib/i18n';
import { resolveServerLang } from '@/lib/i18n/server';

export const dynamic = 'force-dynamic';

type Params = { token: string };
type SearchParams = { lang?: string };

/** GET /public/profiles/:token 응답(민감정보 없음). */
export interface PublicProfile {
  name: string;
  industryTags: string[];
  intro: string | null;
  docValidity: {
    valid: boolean;
    count: number;
    withExpiryCount: number;
    types: string[];
  };
  equipments: { type: string }[];
  joinedAt: string;
  connect: {
    message: string;
    appDeepLink: string;
    storeLinks: { ios: string; android: string };
  };
}

type LoadResult =
  | { status: 'ok'; data: PublicProfile }
  | { status: 'notfound' }
  | { status: 'transient' };

async function load(token: string): Promise<LoadResult> {
  try {
    const data = await apiGet<PublicProfile>(`/public/profiles/${token}`);
    return { status: 'ok', data };
  } catch (e) {
    return { status: classifyLoadError(e) };
  }
}

/** 카카오톡/링크 미리보기용 OG 메타. */
export async function generateMetadata({
  params,
}: {
  params: Promise<Params>;
}): Promise<Metadata> {
  const { token } = await params;
  const r = await load(token);
  if (r.status !== 'ok') {
    return { title: '작업온 명함' };
  }
  const p = r.data;
  const title = `${p.name} · 작업온 명함`;
  const parts = [
    ...p.industryTags,
    p.docValidity.valid ? '서류 유효 ✓' : null,
  ].filter(Boolean);
  const desc = parts.length > 0 ? parts.join(' · ') : '작업온 작업자 공개 프로필';
  return {
    title,
    description: desc,
    openGraph: {
      title,
      description: desc,
      type: 'profile',
      siteName: '작업온',
    },
  };
}

export default async function PublicProfilePage({
  params,
  searchParams,
}: {
  params: Promise<Params>;
  searchParams: Promise<SearchParams>;
}) {
  const { token } = await params;
  const { lang: langParam } = await searchParams;
  const lang = await resolveServerLang(langParam);
  const t = createT(lang);
  const r = await load(token);

  // 무효 토큰 · 명함 OFF → HTTP 404. 일시 장애 → 친화 화면.
  if (r.status === 'notfound') notFound();
  if (r.status === 'transient') {
    return (
      <StatusScreen
        lang={lang}
        title={t('statusTransientTitle')}
        message={t('statusTransientMsg')}
      />
    );
  }
  const p = r.data;

  return (
    <main className="page">
      <div className="lang-bar">
        <LanguageSwitcher current={lang} />
      </div>
      <header style={{ marginBottom: 16 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온 · {t('kickerCard')}
        </p>
      </header>

      {/* 종이 명함 — 이름·업종·소개 + 서류 유효 인증 스트립 */}
      <section className="namecard">
        <div className="namecard-top">
          <span className="namecard-brand">
            <span className="brand-dot" />
            {t('brand')}
          </span>
          <span className="namecard-kind">{t('kickerCard')}</span>
        </div>
        <div className="namecard-body">
          <h1 className="namecard-name">{p.name}</h1>
          {p.industryTags.length > 0 ? (
            <p className="namecard-role">{p.industryTags.join(' · ')}</p>
          ) : null}
          {p.intro ? <p className="namecard-intro">{p.intro}</p> : null}
        </div>
        {p.docValidity.valid ? (
          <div className="namecard-verify">
            <Shield width={22} height={22} />
            <span className="namecard-verify-txt">
              <b>{t('cardValidDocs')}</b>
              <span>{t('cardValidDocsDesc')}</span>
            </span>
            <CheckCircle width={22} height={22} />
          </div>
        ) : null}
      </section>

      {/* 서류 유효 유형(종류·개수만 — 파일/상세 비노출) */}
      {p.docValidity.valid && p.docValidity.types.length > 0 ? (
        <Section title={t('cardValidDocs')}>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {p.docValidity.types.map((type) => (
              <Chip key={type} tone="done">
                {type}
              </Chip>
            ))}
          </div>
        </Section>
      ) : null}

      {/* 보유 장비(종류만) */}
      {p.equipments.length > 0 ? (
        <Section title={t('cardEquipmentTitle')}>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {p.equipments.map((eq, i) => (
              <Chip key={`${eq.type}-${i}`}>
                <Truck
                  width={15}
                  height={15}
                  style={{ marginRight: 5, verticalAlign: '-2px' }}
                />
                {eq.type}
              </Chip>
            ))}
          </div>
        </Section>
      ) : null}

      {/* 가입일 */}
      <p
        style={{
          margin: '18px 2px 22px',
          fontSize: 14,
          color: 'var(--ink-3)',
        }}
      >
        {t('cardJoined')} · {formatDate(p.joinedAt, lang)}
      </p>

      {/* 연결 유도 CTA */}
      <section
        className="card"
        style={{
          padding: '22px',
          background: 'var(--surface-2)',
          border: '1px solid var(--border-strong)',
        }}
      >
        <p
          style={{
            fontSize: 19,
            fontWeight: 800,
            margin: '0 0 8px',
            color: 'var(--ink)',
          }}
        >
          {t('cardConnectTitle')}
        </p>
        <p
          style={{
            margin: '0 0 18px',
            fontSize: 15,
            color: 'var(--ink-2)',
            lineHeight: 1.55,
          }}
        >
          {t('cardConnectDesc')}
        </p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <a
            className="btn btn-primary"
            href={p.connect.storeLinks.ios}
            target="_blank"
            rel="noopener noreferrer"
          >
            {t('cardStoreIos')}
          </a>
          <a
            className="btn btn-ghost"
            href={p.connect.storeLinks.android}
            target="_blank"
            rel="noopener noreferrer"
          >
            {t('cardStoreAndroid')}
          </a>
        </div>
      </section>
    </main>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section style={{ marginBottom: 16 }}>
      <p
        style={{
          fontSize: 14,
          fontWeight: 800,
          color: 'var(--ink-2)',
          margin: '0 2px 8px',
        }}
      >
        {title}
      </p>
      {children}
    </section>
  );
}

function Chip({
  children,
  tone,
}: {
  children: React.ReactNode;
  tone?: 'done';
}) {
  return (
    <span
      className={tone === 'done' ? 'badge done' : 'badge accent'}
      style={{ fontSize: 15, padding: '7px 13px' }}
    >
      {children}
    </span>
  );
}
