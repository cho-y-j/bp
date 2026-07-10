import { won, dateLabel } from '@/lib/format';
import { Check } from './Icons';

export interface AmountItem {
  type: string;
  label: string;
  rate: number;
  quantity: number;
  amount: number;
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
export default function PaperConfirmation({ c }: { c: ConfirmationView }) {
  const eq = c.equipmentSection;
  return (
    <div className="paper">
      <div className="perf">
        <span className="stamp">작 업 확 인 서</span>
        <span className="tear" />
      </div>
      <div className="paper-body">
        <div className="conf-table">
          <div className="k">작업일</div>
          <div className="v num">{dateLabel(c.date)}</div>
          <div className="k">시간</div>
          <div className="v num">
            {c.startTime} ~ {c.endTime}
          </div>
          <div className="k">현장</div>
          <div className="v">{c.site}</div>
          <div className="k">작업자</div>
          <div className="v">{c.workerName ?? '-'}</div>
          <div className="k">지시자</div>
          <div className="v">
            {c.companyName ?? '-'}
            {c.contact ? (
              <span className="num" style={{ color: 'var(--ink-3)' }}>
                {' · '}
                {c.contact}
              </span>
            ) : null}
          </div>
          <div className="k">작업내용</div>
          <div className="v">{c.workContent}</div>
          {eq && (eq.name || eq.vehicleNumber) ? (
            <>
              <div className="k">장비</div>
              <div className="v num">
                {[eq.name, eq.vehicleNumber, eq.spec]
                  .filter(Boolean)
                  .join(' · ')}
                {eq.guide ? ' · 유도원' : ''}
              </div>
            </>
          ) : null}
        </div>

        <div className="calc">
          {c.amountCalc.items.map((it, i) => (
            <div className="line" key={i}>
              <span>
                {it.label}
                {it.quantity ? (
                  <span className="num" style={{ color: 'var(--ink-3)' }}>
                    {'  '}
                    {won(it.rate)} × {it.quantity}
                  </span>
                ) : null}
              </span>
              <span className="num">{won(it.amount)} 원</span>
            </div>
          ))}
          {c.amountCalc.vat > 0 ? (
            <div className="line">
              <span>부가세 ({Math.round(c.amountCalc.vatRate * 100)}%)</span>
              <span className="num">{won(c.amountCalc.vat)} 원</span>
            </div>
          ) : null}
          <div className="total">
            <span className="k">받을 금액</span>
            <span className="v num">
              {won(c.total)}
              <small> 원</small>
            </span>
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
            메모 · {c.notes}
          </p>
        ) : null}

        {c.signed ? (
          <div className="sign-zone">
            <div className="sign-head">
              <span className="k">지시자 서명</span>
            </div>
            <div className="sign-stamp">
              <Check width={20} height={20} />
              <span>
                <b>{c.signerName}</b> 님 서명 완료
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
