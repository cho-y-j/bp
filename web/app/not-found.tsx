import StatusScreen from '@/components/StatusScreen';
import { createT } from '@/lib/i18n';
import { resolveServerLang } from '@/lib/i18n/server';

export const dynamic = 'force-dynamic';

/** 404 — 무효/만료 링크, 존재하지 않는 경로. HTTP 404 로 응답된다. */
export default async function NotFound() {
  const lang = await resolveServerLang();
  const t = createT(lang);
  return (
    <StatusScreen
      lang={lang}
      title={t('statusNotFoundTitle')}
      message={t('statusNotFoundMsg')}
    />
  );
}
