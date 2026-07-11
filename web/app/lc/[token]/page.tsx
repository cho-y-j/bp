import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { apiGet, classifyLoadError } from '@/lib/api';
import PaperLaborContract, {
  type LaborContractView,
} from '@/components/PaperLaborContract';
import StatusScreen from '@/components/StatusScreen';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { createT } from '@/lib/i18n';
import { resolveServerLang } from '@/lib/i18n/server';
import LcSignSection from './LcSignSection';

export const dynamic = 'force-dynamic';

type Params = { token: string };
type SearchParams = { lang?: string };
type LoadResult =
  | { status: 'ok'; data: LaborContractView }
  | { status: 'notfound' }
  | { status: 'transient' };

async function load(token: string): Promise<LoadResult> {
  try {
    const data = await apiGet<LaborContractView>(`/public/contracts/${token}`);
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
    return { title: '표준근로계약서 · 작업온' };
  }
  const c = r.data;
  const title = `표준근로계약서 — ${c.businessName}`;
  const desc = `${c.workerName} · ${c.workplace}${
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

export default async function LaborContractPage({
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
          작업온 · {t('kickerContract')}
        </p>
      </header>

      <PaperLaborContract c={c} lang={lang} />

      <LcSignSection
        token={token}
        initialSigned={c.workerSigned}
        view={c}
        lang={lang}
      />
    </main>
  );
}
