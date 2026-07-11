import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { apiGet, classifyLoadError } from '@/lib/api';
import PaperConfirmation, {
  type ConfirmationView,
} from '@/components/PaperConfirmation';
import StatusScreen from '@/components/StatusScreen';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { won } from '@/lib/format';
import { createT } from '@/lib/i18n';
import { resolveServerLang } from '@/lib/i18n/server';
import SignSection from './SignSection';

export const dynamic = 'force-dynamic';

type Params = { token: string };
type SearchParams = { lang?: string };
type LoadResult =
  | { status: 'ok'; data: ConfirmationView }
  | { status: 'notfound' }
  | { status: 'transient' };

async function load(token: string): Promise<LoadResult> {
  try {
    const data = await apiGet<ConfirmationView>(
      `/public/confirmations/${token}`,
    );
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
    return { title: '작업확인서 · 작업온' };
  }
  const c = r.data;
  const title = `작업확인서 — ${c.site}`;
  const desc = `${c.workerName ?? '작업자'} · ${c.date} · ${won(c.total)}원${
    c.signed ? ' · 서명완료' : ' · 서명 요청'
  }`;
  return {
    title,
    description: desc,
    openGraph: {
      title,
      description: desc,
      type: 'website',
      siteName: '작업온',
    },
  };
}

export default async function ConfirmationPage({
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

  // 무효/만료 토큰 → HTTP 404 (notFound), 일시 장애(백엔드 다운 등) → 친화 화면(200).
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
  const c = r.data;

  return (
    <main className="page">
      <div className="lang-bar">
        <LanguageSwitcher current={lang} />
      </div>
      <header style={{ marginBottom: 18 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온 · {t('kickerConfirmation')}
        </p>
      </header>

      <PaperConfirmation c={c} lang={lang} />

      <SignSection token={token} initialSigned={c.signed} view={c} lang={lang} />
    </main>
  );
}
