import { money, formatDate } from '@/lib/format';
import { createT, type Lang } from '@/lib/i18n';
import { Check } from './Icons';

export interface SocialInsuranceView {
  employment?: boolean;
  health?: boolean;
  pension?: boolean;
  industrialAccident?: boolean;
}

export interface LaborContractView {
  status: string;
  signed: boolean;
  workerSigned: boolean;
  title: string;
  businessName: string;
  businessNumber?: string | null;
  businessAddress?: string | null;
  workerName: string;
  startDate: string;
  endDate?: string | null;
  workplace: string;
  jobDescription: string;
  workStartTime: string;
  workEndTime: string;
  breakTime?: string | null;
  wageType: string; // DAILY | HOURLY
  wageTypeLabel: string;
  wageAmount: number;
  payday: string;
  payMethod: string;
  weeklyHolidayAllowance: boolean;
  overtimeAllowance: boolean;
  socialInsurance?: SocialInsuranceView | null;
  specialTerms?: string | null;
  employerSignerName?: string | null;
  employerSignedAt?: string | null;
  // 손글씨 서명 획(PNG data URI). 서명 완료된 쪽만 서버가 제공. 없으면 체크 스탬프 폴백.
  employerSignImageDataUrl?: string | null;
  workerSignerName?: string | null;
  workerSignedAt?: string | null;
  workerSignImageDataUrl?: string | null;
  pdfUrl?: string;
}

/**
 * 종이 표준근로계약서 렌더 — 조항 라벨은 번역, 계약 데이터 값은 원문 유지.
 * 하단에 정본(한국어본) 안내 문구를 반드시 표기한다.
 */
export default function PaperLaborContract({
  c,
  lang = 'ko',
}: {
  c: LaborContractView;
  lang?: Lang;
}) {
  const t = createT(lang);
  const si = c.socialInsurance ?? {};
  const yn = (b?: boolean) => (b ? t('lcApplied') : t('lcNotApplied'));
  const wageLabel = c.wageType === 'HOURLY' ? t('lcWageHourly') : t('lcWageDaily');

  return (
    <div className="paper">
      <div className="perf">
        <span className="stamp">{t('lcStamp')}</span>
        <span className="tear" />
      </div>
      <div className="paper-body">
        {/* 계약 당사자 */}
        <div className="sign-head" style={{ marginBottom: 8 }}>
          <span className="k">{t('lcParties')}</span>
        </div>
        <div className="conf-table">
          <div className="k">{t('lcEmployer')}</div>
          <div className="v">
            {c.businessName}
            {c.businessNumber ? (
              <span className="num" style={{ color: 'var(--ink-3)' }}>
                {' · '}
                {t('lcBizNumber')} {c.businessNumber}
              </span>
            ) : null}
          </div>
          <div className="k">{t('lcWorker')}</div>
          <div className="v">{c.workerName}</div>
        </div>

        {/* 계약 내용 */}
        <div className="conf-table" style={{ marginTop: 4 }}>
          <div className="k">{t('lcPeriod')}</div>
          <div className="v num">
            {formatDate(c.startDate, lang)}
            {c.endDate ? ` ~ ${formatDate(c.endDate, lang)}` : ` · ${t('lcPeriodOpen')}`}
          </div>
          <div className="k">{t('lcWorkplace')}</div>
          <div className="v">{c.workplace}</div>
          <div className="k">{t('lcJob')}</div>
          <div className="v">{c.jobDescription}</div>
          <div className="k">{t('lcWorkTime')}</div>
          <div className="v num">
            {c.workStartTime} ~ {c.workEndTime}
            {c.breakTime ? (
              <span style={{ color: 'var(--ink-3)' }}>
                {' · '}
                {t('lcBreak')} {c.breakTime}
              </span>
            ) : null}
          </div>
          <div className="k">{t('lcWage')}</div>
          <div className="v">
            <span className="num">{money(c.wageAmount, lang)}</span>
            <span style={{ color: 'var(--ink-3)' }}> · {wageLabel}</span>
          </div>
          <div className="k">{t('lcPayday')}</div>
          <div className="v">{c.payday}</div>
          <div className="k">{t('lcPayMethod')}</div>
          <div className="v">{c.payMethod}</div>
        </div>

        {/* 수당 */}
        <div className="calc" style={{ marginTop: 12 }}>
          <div className="sign-head" style={{ marginBottom: 6 }}>
            <span className="k">{t('lcAllowance')}</span>
          </div>
          <p style={{ margin: '2px 2px', fontSize: 14, color: 'var(--ink-2)' }}>
            {c.weeklyHolidayAllowance
              ? t('lcWeeklyHoliday')
              : t('lcWeeklyHolidayNone')}
          </p>
          <p style={{ margin: '4px 2px', fontSize: 14, color: 'var(--ink-2)' }}>
            {c.overtimeAllowance ? t('lcOvertime') : t('lcOvertimeNone')}
          </p>
        </div>

        {/* 사회보험 */}
        <div className="calc" style={{ marginTop: 12 }}>
          <div className="sign-head" style={{ marginBottom: 6 }}>
            <span className="k">{t('lcInsurance')}</span>
          </div>
          <div className="line">
            <span>{t('lcInsEmployment')}</span>
            <span className="num">{yn(si.employment)}</span>
          </div>
          <div className="line">
            <span>{t('lcInsHealth')}</span>
            <span className="num">{yn(si.health)}</span>
          </div>
          <div className="line">
            <span>{t('lcInsPension')}</span>
            <span className="num">{yn(si.pension)}</span>
          </div>
          <div className="line">
            <span>{t('lcInsAccident')}</span>
            <span className="num">{yn(si.industrialAccident)}</span>
          </div>
        </div>

        {/* 특약사항 */}
        {c.specialTerms ? (
          <p
            style={{
              margin: '14px 2px 0',
              fontSize: 15,
              color: 'var(--ink-2)',
            }}
          >
            {t('lcSpecial')} · {c.specialTerms}
          </p>
        ) : null}

        {/* 정본(한국어본) 안내 */}
        <p
          style={{
            margin: '16px 2px 0',
            fontSize: 13,
            color: 'var(--ink-3)',
            lineHeight: 1.6,
            paddingTop: 10,
            borderTop: '1px dashed var(--border)',
          }}
        >
          ※ {t('lcMasterNote')}
        </p>

        {/* 서명 상태 */}
        {c.employerSignedAt ? (
          <div className="sign-zone" style={{ marginTop: 14 }}>
            <div className="sign-head">
              <span className="k">{t('lcEmployer')}</span>
            </div>
            <div className="sign-stamp">
              <Check width={20} height={20} />
              <span>
                {c.employerSignerName
                  ? t('paperSignedBy', { name: c.employerSignerName })
                  : t('lcEmployerSigned')}
                {c.employerSignedAt ? (
                  <span
                    className="num"
                    style={{ color: 'var(--ink-3)', fontWeight: 500, marginLeft: 6 }}
                  >
                    {c.employerSignedAt}
                  </span>
                ) : null}
              </span>
              {c.employerSignImageDataUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  className="sign-stroke sign-stroke-inline"
                  src={c.employerSignImageDataUrl}
                  alt={c.employerSignerName ?? t('lcEmployerSigned')}
                />
              ) : null}
            </div>
          </div>
        ) : null}

        {c.workerSigned ? (
          <div className="sign-zone" style={{ marginTop: 10 }}>
            <div className="sign-head">
              <span className="k">{t('lcWorker')}</span>
            </div>
            <div className="sign-stamp">
              <Check width={20} height={20} />
              <span>
                {t('paperSignedBy', { name: c.workerSignerName ?? '' })}
                {c.workerSignedAt ? (
                  <span
                    className="num"
                    style={{ color: 'var(--ink-3)', fontWeight: 500, marginLeft: 6 }}
                  >
                    {c.workerSignedAt}
                  </span>
                ) : null}
              </span>
              {c.workerSignImageDataUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  className="sign-stroke sign-stroke-inline"
                  src={c.workerSignImageDataUrl}
                  alt={c.workerSignerName ?? ''}
                />
              ) : null}
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
