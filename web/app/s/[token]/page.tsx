import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { apiGet, classifyLoadError, absoluteUrl } from '@/lib/api';
import { formatDate } from '@/lib/format';
import { FileText, Download } from '@/components/Icons';
import StatusScreen from '@/components/StatusScreen';
import LanguageSwitcher from '@/components/LanguageSwitcher';
import { createT } from '@/lib/i18n';
import { resolveServerLang } from '@/lib/i18n/server';

export const dynamic = 'force-dynamic';

type Params = { token: string };
type SearchParams = { lang?: string };

interface ShareDoc {
  documentId: string;
  type: string;
  issuedDate: string | null;
  expiryDate: string | null;
  dday: number | null;
  status: string;
  masked: boolean;
  fileUrl: string;
}
interface ShareView {
  shareToken: string;
  expiresAt: string;
  documents: ShareDoc[];
}

type LoadResult =
  | { status: 'ok'; data: ShareView }
  | { status: 'notfound' }
  | { status: 'transient' };

async function load(token: string): Promise<LoadResult> {
  try {
    const data = await apiGet<ShareView>(`/public/shares/${token}`);
    return { status: 'ok', data };
  } catch (e) {
    return { status: classifyLoadError(e) };
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<Params>;
}): Promise<Metadata> {
  const { token } = await params;
  const r = await load(token);
  const title = '서류 묶음 · 작업온';
  return {
    title,
    description:
      r.status === 'ok'
        ? `서류 ${r.data.documents.length}건 공유`
        : '서류 공유 링크',
    openGraph: { title, siteName: '작업온', type: 'website' },
  };
}

export default async function SharePage({
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

  // 무효/만료 링크 → HTTP 404, 일시 장애 → 친화 화면(200).
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
  const s = r.data;

  return (
    <main className="page">
      <div className="lang-bar">
        <LanguageSwitcher current={lang} />
      </div>
      <header style={{ marginBottom: 8 }}>
        <p className="brand-kicker">
          <span className="brand-dot" />
          작업온 · {t('kickerShare')}
        </p>
        <h1 style={{ fontSize: 26, fontWeight: 800, margin: '12px 0 4px' }}>
          {t('shareCount', { n: s.documents.length })}
        </h1>
        <p style={{ color: 'var(--ink-2)', fontSize: 15, margin: 0 }}>
          {t('shareValidUntil', { date: formatDate(s.expiresAt, lang) })}
        </p>
      </header>

      <div style={{ display: 'grid', gap: 14, marginTop: 18 }}>
        {s.documents.map((d) => {
          // 만료 배지(앱 규칙 통일): 지남→"만료됨" 빨강, 90일 이내만 D-N, 원거리는 생략.
          const dd = d.dday;
          const badge =
            dd === null || dd === undefined
              ? null
              : dd < 0
                ? { text: t('docExpired'), cls: 'warn' }
                : dd <= 90
                  ? { text: `D-${dd}`, cls: dd <= 30 ? 'soon' : 'calm' }
                  : null;
          const url = absoluteUrl(d.fileUrl);
          // 다운로드는 ?download=1 → 백엔드가 Content-Disposition: attachment 로 응답.
          const downloadUrl = `${url}${url.includes('?') ? '&' : '?'}download=1`;
          return (
            <div className="card" key={d.documentId} style={{ padding: 16 }}>
              <div
                style={{ display: 'flex', alignItems: 'center', gap: 12 }}
              >
                <span
                  className="avatar"
                  style={{
                    background: 'var(--surface-2)',
                    color: 'var(--ink-2)',
                  }}
                >
                  <FileText width={22} height={22} />
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 17, fontWeight: 700 }}>{d.type}</div>
                  <div
                    style={{
                      fontSize: 14,
                      color: 'var(--ink-2)',
                      marginTop: 2,
                    }}
                  >
                    {d.expiryDate ? (
                      <span className="num">
                        {t('shareExpiry', {
                          date: formatDate(d.expiryDate, lang),
                        })}
                      </span>
                    ) : (
                      t('shareNoExpiry')
                    )}
                    {d.masked ? ` · ${t('shareMasked')}` : ''}
                  </div>
                </div>
                {badge ? (
                  <span className={`badge ${badge.cls} num`}>{badge.text}</span>
                ) : null}
              </div>
              <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
                <a
                  href={url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn btn-ghost"
                  style={{ flex: 1 }}
                >
                  <FileText width={18} height={18} />
                  {t('shareView')}
                </a>
                <a
                  href={downloadUrl}
                  download
                  className="btn btn-primary"
                  style={{ flex: 1 }}
                >
                  <Download width={18} height={18} />
                  {t('shareDownload')}
                </a>
              </div>
            </div>
          );
        })}
      </div>
    </main>
  );
}
