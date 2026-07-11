import { money, formatDate } from '@/lib/format';
import { createT, type Lang, type MessageKey } from '@/lib/i18n';
import { Check } from './Icons';

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

        <div className="calc">
          {c.amountCalc.items.map((it, i) => (
            <div className="line" key={i}>
              <span>
                {itemLabel(it)}
                {it.quantity ? (
                  <span className="num" style={{ color: 'var(--ink-3)' }}>
                    {'  '}
                    {money(it.rate, lang)} × {it.quantity}
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
            </div>
            <div className="sign-stamp">
              <Check width={20} height={20} />
              <span>
                {t('paperSignedBy', { name: c.signerName ?? '' })}
                {c.signedAt ? (
                  <span
                    className="num"
                    style={{
                      color: 'var(--ink-3)',
                      fontWeight: 500,
                      marginLeft: 6,
                    }}
                  >
                    {c.signedAt}
                  </span>
                ) : null}
              </span>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
