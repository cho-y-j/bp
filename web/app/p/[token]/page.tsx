import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { apiGet, classifyLoadError } from '@/lib/api';
import StatusScreen from '@/components/StatusScreen';
import LanguageSwitcher from '@/components/LanguageSwitcher';
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
      <header style={{ marginBottom: 18 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온 · {t('kickerCard')}
        </p>
      </header>

      {/* 이름 + 서류 유효 배지 */}
      <section
        className="card"
        style={{ padding: '26px 22px', marginBottom: 16 }}
      >
        <h1
          style={{
            fontSize: 30,
            fontWeight: 800,
            margin: '0 0 12px',
            lineHeight: 1.2,
            color: 'var(--ink)',
          }}
        >
          {p.name}
        </h1>

        {p.docValidity.valid ? (
          <span
            className="badge done"
            style={{ fontSize: 15, padding: '6px 12px' }}
          >
            {t('cardValidDocs')} ✓
          </span>
        ) : null}

        {p.intro ? (
          <p
            style={{
              marginTop: 16,
              marginBottom: 0,
              fontSize: 17,
              color: 'var(--ink-2)',
              lineHeight: 1.55,
              whiteSpace: 'pre-wrap',
            }}
          >
            {p.intro}
          </p>
        ) : null}
      </section>

      {/* 업종 */}
      {p.industryTags.length > 0 ? (
        <Section title={t('cardIndustryTitle')}>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {p.industryTags.map((tag) => (
              <Chip key={tag}>{tag}</Chip>
            ))}
          </div>
        </Section>
      ) : null}

      {/* 서류 유효 상세(유형·개수만 — 파일/상세 비노출) */}
      {p.docValidity.valid && p.docValidity.types.length > 0 ? (
        <Section title={t('cardValidDocs')}>
          <p
            style={{
              margin: '0 0 10px',
              fontSize: 15,
              color: 'var(--ink-2)',
            }}
          >
            {t('cardValidDocsDesc')}
          </p>
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
              <Chip key={`${eq.type}-${i}`}>{eq.type}</Chip>
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
