import { money, formatDate } from '@/lib/format';
import { createT, type Lang, type MessageKey } from '@/lib/i18n';
import { Check } from './Icons';

/** 인영(도장)에 새길 텍스트. 이름이 짧으면 그대로, 길면 성(첫 2자)만. */
function sealText(name?: string | null): string {
  const n = (name ?? '').trim();
  if (!n) return '확인';
  if (n.length <= 3) return n;
  return n.slice(0, 2);
}

/** 금액 항목 type → 번역 키. OTHER/미지의 유형은 서버 label 을 그대로 쓴다. */
const AMOUNT_TYPE_KEY: Record<string, MessageKey> = {
  BASE: 'amtBase',
  OVERTIME: 'amtOvertime',
  EARLY: 'amtEarly',
  NIGHT: 'amtNight',
  ALLNIGHT: 'amtAllnight',
};

export interface AmountItem {
  type: string;
  label: string;
  rate: number;
  quantity: number;
  amount: number;
  unit?: string;
}
export interface AmountCalc {
  items: AmountItem[];
  subtotal: number;
  vatRate: number;
  vat: number;
  total: number;
}
export interface EquipmentSection {
  name?: string;
  vehicleNumber?: string;
  spec?: string;
  guide?: boolean;
}
export interface TeamEntry {
  memberId?: string;
  name: string;
  profileId?: string | null;
  quantity: number; // 공수
  rate: number;
  amount: number;
}
export interface ConfirmationView {
  status: string;
  signed: boolean;
  date: string;
  companyName?: string | null;
  contact?: string | null;
  workerName?: string | null;
  site: string;
  workContent: string;
  startTime: string;
  endTime: string;
  rateTypeLabel: string;
  amountCalc: AmountCalc;
  total: number;
  equipmentSection?: EquipmentSection | null;
  // 팀(반장) 확인서 명단 (P2a) — 있으면 팀원 표 렌더.
  teamEntries?: TeamEntry[] | null;
  isTeam?: boolean;
  notes?: string | null;
  signerName?: string | null;
  signedAt?: string | null;
}

/**
 * 종이 확인서 렌더 (시그니처 컴포넌트).
 * 절취선·스탬프·필드 표·큰 금액. 외부 열람과 사업장 수신함에서 공용.
 */
export default function PaperConfirmation({
  c,
  lang = 'ko',
}: {
  c: ConfirmationView;
  lang?: Lang;
}) {
  const eq = c.equipmentSection;
  const t = createT(lang);
  // 한국어는 서버 라벨(예: "기본(일당)")을 그대로 유지, 그 외 언어는 type 기준 번역.
  const itemLabel = (it: AmountItem): string => {
    if (lang === 'ko') return it.label;
    const key = AMOUNT_TYPE_KEY[it.type];
    return key ? t(key) : it.label;
  };
  // 수량 뒤 단위 표기. 한국어는 서버 라벨(예: "기본(공수)")이 이미 단위를 담으므로 미표기(회귀 방지).
  // 비한국어는 번역 단위 + 한국어 '공수' 병기(서명자가 한국 원본 서류와 대조 가능하도록).
  const unitSuffix = (it: AmountItem): string => {
    if (lang === 'ko' || !it.unit) return '';
    if (it.unit === '공수') return ` ${t('unitGongsu')} (${it.unit})`;
    return ` ${it.unit}`; // 미지의 단위는 서버 표기 그대로 병기
  };
  return (
    <div className="paper">
      <div className="perf">
        <span className="stamp">{t('paperStamp')}</span>
        <span className="tear" />
      </div>
      <div className="paper-body">
        <div className="conf-table">
          <div className="k">{t('paperDate')}</div>
          <div className="v num">{formatDate(c.date, lang)}</div>
          <div className="k">{t('paperTime')}</div>
          <div className="v num">
            {c.startTime} ~ {c.endTime}
          </div>
          <div className="k">{t('paperSite')}</div>
          <div className="v">{c.site}</div>
          <div className="k">{t('paperWorker')}</div>
          <div className="v">{c.workerName ?? '-'}</div>
          <div className="k">{t('paperOrderer')}</div>
          <div className="v">
            {c.companyName ?? '-'}
            {c.contact ? (
              <span className="num" style={{ color: 'var(--ink-3)' }}>
                {' · '}
                {c.contact}
              </span>
            ) : null}
          </div>
          <div className="k">{t('paperWork')}</div>
          <div className="v">{c.workContent}</div>
          {eq && (eq.name || eq.vehicleNumber) ? (
            <>
              <div className="k">{t('paperEquipment')}</div>
              <div className="v num">
                {[eq.name, eq.vehicleNumber, eq.spec]
                  .filter(Boolean)
                  .join(' · ')}
                {eq.guide ? ` · ${t('paperGuide')}` : ''}
              </div>
            </>
          ) : null}
        </div>

        {c.teamEntries && c.teamEntries.length > 0 ? (
          <div className="calc" style={{ marginTop: 12 }}>
            <div className="sign-head" style={{ marginBottom: 6 }}>
              <span className="k">{t('paperTeam')}</span>
            </div>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '1.4fr 0.8fr 1fr 1.2fr',
                gap: '2px 8px',
                fontSize: 13,
                color: 'var(--ink-3)',
                paddingBottom: 6,
                borderBottom: '1px solid var(--border)',
              }}
            >
              <span>{t('paperTeamName')}</span>
              <span style={{ textAlign: 'right' }}>{t('paperTeamGongsu')}</span>
              <span style={{ textAlign: 'right' }}>{t('paperTeamRate')}</span>
              <span style={{ textAlign: 'right' }}>{t('paperTeamAmount')}</span>
            </div>
            {c.teamEntries.map((m, i) => (
              <div
                key={m.memberId ?? i}
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1.4fr 0.8fr 1fr 1.2fr',
                  gap: '2px 8px',
                  fontSize: 15,
                  padding: '7px 0',
                  borderBottom: '1px solid var(--border)',
                  alignItems: 'baseline',
                }}
              >
                <span>{m.name}</span>
                <span className="num" style={{ textAlign: 'right' }}>
                  {m.quantity}
                  {lang === 'ko' ? t('unitGongsu') : ` ${t('paperTeamGongsu')}`}
                </span>
                <span className="num" style={{ textAlign: 'right', color: 'var(--ink-3)' }}>
                  {money(m.rate, lang)}
                </span>
                <span className="num" style={{ textAlign: 'right' }}>
                  {money(m.amount, lang)}
                </span>
              </div>
            ))}
            <div className="total" style={{ marginTop: 4 }}>
              <span className="k">{t('paperTeamTotal')}</span>
              <span className="v num">{money(c.total, lang)}</span>
            </div>
          </div>
        ) : null}

        {/* 팀 확인서는 위 팀 명단 표에서 합계를 이미 표기하므로 하단 금액 표는 생략. */}
        <div
          className="calc"
          style={
            c.teamEntries && c.teamEntries.length > 0
              ? { display: 'none' }
              : undefined
          }
        >
          {c.amountCalc.items.map((it, i) => (
            <div className="line" key={i}>
              <span>
                {itemLabel(it)}
                {it.quantity ? (
                  <span className="num" style={{ color: 'var(--ink-3)' }}>
                    {'  '}
                    {money(it.rate, lang)} × {it.quantity}
                    {unitSuffix(it)}
                  </span>
                ) : null}
              </span>
              <span className="num">{money(it.amount, lang)}</span>
            </div>
          ))}
          {c.amountCalc.vat > 0 ? (
            <div className="line">
              <span>
                {t('paperVat', { rate: Math.round(c.amountCalc.vatRate * 100) })}
              </span>
              <span className="num">{money(c.amountCalc.vat, lang)}</span>
            </div>
          ) : null}
          <div className="total">
            <span className="k">{t('paperTotal')}</span>
            <span className="v num">{money(c.total, lang)}</span>
          </div>
        </div>

        {c.notes ? (
          <p
            style={{
              margin: '14px 2px 0',
              fontSize: 15,
              color: 'var(--ink-2)',
            }}
          >
            {t('paperMemo')} · {c.notes}
          </p>
        ) : null}

        {c.signed ? (
          <div className="sign-zone">
            <div className="sign-head">
              <span className="k">{t('paperSignHead')}</span>
              {c.signedAt ? (
                <span className="num" style={{ fontSize: 13, color: 'var(--ink-3)', fontWeight: 600 }}>
                  {c.signedAt}
                </span>
              ) : null}
            </div>
            <div className="sign-plate">
              <div className="sign-plate-info">
                <span className="sign-plate-name">{c.signerName ?? '-'}</span>
                <span className="sign-plate-status">
                  <Check width={16} height={16} />
                  {t('paperSignConfirmed')}
                </span>
              </div>
              {/* 서명자 인영(도장) — 서명 이미지 대체 시각요소. 서버가 서명
                  이미지를 공개 API로 제공하면 여기에 실제 획을 렌더한다. */}
              <span className="seal" aria-hidden>
                <span className="seal-name">{sealText(c.signerName)}</span>
              </span>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
