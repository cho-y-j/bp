'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { useBiz } from '../biz-context';
import { won, currentMonth, monthLabel } from '@/lib/format';
import MonthNav from '@/components/MonthNav';
import { Copy, CheckCircle, Check, AlertTriangle } from '@/components/Icons';

interface Withholding {
  incomeTax: number;
  localTax: number;
  totalTax: number;
  netPay: number;
}
interface WageWorker {
  workerProfileId: string;
  workerName: string;
  paidTotal: number;
  paymentCount: number;
  workDays: number;
  business3_3: Withholding;
  dailyWage: Withholding;
}
interface WageStatement {
  month: string;
  businessName: string;
  marked: boolean;
  workers: WageWorker[];
  totals: {
    workerCount: number;
    paidTotal: number;
    paymentCount: number;
    business3_3: Withholding;
    dailyWage: Withholding;
  };
  notes: string[];
  hometaxNote: string;
  copyText: string;
}

type IncomeType = 'business3_3' | 'dailyWage';

export default function WageStatementPage() {
  const { business } = useBiz();
  const businessId = business?.id;
  const [month, setMonth] = useState(currentMonth());
  const [data, setData] = useState<WageStatement | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [incomeType, setIncomeType] = useState<IncomeType>('business3_3');
  const [toast, setToast] = useState<string | null>(null);
  const [marking, setMarking] = useState(false);

  const load = useCallback(async () => {
    setError(null);
    setData(null);
    try {
      const res = await api().get<WageStatement>(
        `/biz/wage-statement?month=${month}${
          businessId ? `&businessId=${businessId}` : ''
        }`,
      );
      setData(res.data);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
    }
  }, [month, businessId]);

  useEffect(() => {
    void load();
  }, [load]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  async function copyText() {
    if (!data) return;
    try {
      await navigator.clipboard.writeText(data.copyText);
      flash('홈택스 입력용 텍스트를 복사했습니다.');
    } catch {
      if (typeof window !== 'undefined') window.prompt('복사', data.copyText);
    }
  }

  async function markMonth() {
    setMarking(true);
    setError(null);
    try {
      const res = await api().post<{ alreadyMarked: boolean }>(
        '/biz/wage-statement/mark',
        { month, ...(businessId ? { businessId } : {}) },
      );
      flash(
        res.data.alreadyMarked
          ? '이미 마감된 월입니다.'
          : `${monthLabel(month)} 지급명세서를 마감 처리했습니다.`,
      );
      await load();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '마감 처리 실패');
    } finally {
      setMarking(false);
    }
  }

  const sel = (w: WageWorker): Withholding =>
    incomeType === 'business3_3' ? w.business3_3 : w.dailyWage;
  const selTotal = data
    ? incomeType === 'business3_3'
      ? data.totals.business3_3
      : data.totals.dailyWage
    : null;

  return (
    <>
      <h1 className="page-title">일용근로소득 지급명세서 도우미</h1>
      <p className="page-sub">
        지급(입금) 완료 기준 작업자별 지급총액과 원천징수 세액입니다. 소득 유형을
        선택해 홈택스에 직접 입력하세요.
      </p>

      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: 16,
        }}
      >
        <MonthNav month={month} onChange={setMonth} />
        {data?.marked ? (
          <span className="badge done" style={{ fontSize: 15, padding: '8px 14px' }}>
            <CheckCircle width={16} height={16} />
            {monthLabel(month)} 마감됨
          </span>
        ) : null}
      </div>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}
      {error ? <p style={{ color: 'var(--receivable)' }}>{error}</p> : null}

      {data === null && !error ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : data ? (
        <>
          {/* 소득 유형 토글 */}
          <div
            role="tablist"
            aria-label="소득 유형"
            style={{
              display: 'inline-flex',
              background: 'var(--surface-2)',
              border: '1px solid var(--border)',
              borderRadius: 12,
              padding: 4,
              marginBottom: 16,
            }}
          >
            {(
              [
                { key: 'business3_3', label: '사업소득 3.3%' },
                { key: 'dailyWage', label: '일용근로소득' },
              ] as { key: IncomeType; label: string }[]
            ).map((t) => {
              const on = incomeType === t.key;
              return (
                <button
                  key={t.key}
                  role="tab"
                  aria-selected={on}
                  onClick={() => setIncomeType(t.key)}
                  style={{
                    border: 0,
                    borderRadius: 9,
                    padding: '10px 18px',
                    fontSize: 15,
                    fontWeight: 700,
                    cursor: 'pointer',
                    background: on ? 'var(--primary)' : 'transparent',
                    color: on ? 'var(--primary-ink)' : 'var(--ink-2)',
                  }}
                >
                  {t.label}
                </button>
              );
            })}
          </div>

          {data.workers.length === 0 ? (
            <div className="card empty">
              <Copy width={30} height={30} />
              <p style={{ fontWeight: 700, marginTop: 8 }}>
                {monthLabel(month)} 지급 내역이 없습니다
              </p>
              <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>
                정산에서 지급 처리한 작업자가 여기에 집계됩니다.
              </p>
            </div>
          ) : (
            <>
              <div className="card tbl-desktop" style={{ overflowX: 'auto', marginBottom: 16 }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left' }}>작업자</th>
                      <th>일수</th>
                      <th style={{ textAlign: 'right' }}>지급총액</th>
                      <th style={{ textAlign: 'right' }}>소득세</th>
                      <th style={{ textAlign: 'right' }}>지방세</th>
                      <th style={{ textAlign: 'right' }}>차인지급액</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.workers.map((w) => {
                      const t = sel(w);
                      return (
                        <tr key={w.workerProfileId}>
                          <td style={{ textAlign: 'left' }}>
                            <span style={{ fontWeight: 700 }}>{w.workerName}</span>
                            {w.paymentCount > 1 ? (
                              <span
                                className="num"
                                style={{ color: 'var(--ink-3)', fontSize: 13, marginLeft: 8 }}
                              >
                                {w.paymentCount}건
                              </span>
                            ) : null}
                          </td>
                          <td className="num" style={{ textAlign: 'center' }}>
                            {w.workDays}
                          </td>
                          <td className="num" style={{ textAlign: 'right', fontWeight: 700 }}>
                            {won(w.paidTotal)}
                          </td>
                          <td className="num" style={{ textAlign: 'right' }}>
                            {won(t.incomeTax)}
                          </td>
                          <td className="num" style={{ textAlign: 'right' }}>
                            {won(t.localTax)}
                          </td>
                          <td
                            className="num money dep"
                            style={{ textAlign: 'right', fontWeight: 800 }}
                          >
                            {won(t.netPay)}
                          </td>
                        </tr>
                      );
                    })}
                    {selTotal ? (
                      <tr style={{ background: 'var(--surface-2)' }}>
                        <td style={{ textAlign: 'left', fontWeight: 800 }}>합계</td>
                        <td />
                        <td className="num" style={{ textAlign: 'right', fontWeight: 800 }}>
                          {won(data.totals.paidTotal)}
                        </td>
                        <td className="num" style={{ textAlign: 'right', fontWeight: 700 }}>
                          {won(selTotal.incomeTax)}
                        </td>
                        <td className="num" style={{ textAlign: 'right', fontWeight: 700 }}>
                          {won(selTotal.localTax)}
                        </td>
                        <td
                          className="num money dep"
                          style={{ textAlign: 'right', fontWeight: 800 }}
                        >
                          {won(selTotal.netPay)}
                        </td>
                      </tr>
                    ) : null}
                  </tbody>
                </table>
              </div>

              {/* 모바일: 행당 카드형 요약 — 차인지급액을 크게 우측에 노출 */}
              <div className="card row-cards" style={{ marginBottom: 16 }}>
                {data.workers.map((w) => {
                  const t = sel(w);
                  return (
                    <div className="rowcard" key={w.workerProfileId}>
                      <div className="rowcard-main">
                        <div className="rowcard-name">
                          {w.workerName}
                          {w.paymentCount > 1 ? (
                            <span
                              className="num"
                              style={{ color: 'var(--ink-3)', fontSize: 13, fontWeight: 600, marginLeft: 8 }}
                            >
                              {w.paymentCount}건
                            </span>
                          ) : null}
                        </div>
                        <div className="rowcard-sub num">
                          지급총액 {won(w.paidTotal)} · 일수 {w.workDays} · 소득세 {won(t.incomeTax)} · 지방세 {won(t.localTax)}
                        </div>
                      </div>
                      <div className="rowcard-amt">
                        <div className="amt-label">차인지급액</div>
                        <div className="amt-val num money dep">{won(t.netPay)}</div>
                      </div>
                    </div>
                  );
                })}
                {selTotal ? (
                  <div className="rowcard rowcard-total">
                    <div className="rowcard-main">
                      <div className="rowcard-name">합계</div>
                      <div className="rowcard-sub num">
                        지급총액 {won(data.totals.paidTotal)} · 소득세 {won(selTotal.incomeTax)} · 지방세 {won(selTotal.localTax)}
                      </div>
                    </div>
                    <div className="rowcard-amt">
                      <div className="amt-label">차인지급액 합계</div>
                      <div className="amt-val num money dep">{won(selTotal.netPay)}</div>
                    </div>
                  </div>
                ) : null}
              </div>

              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 20 }}>
                <button
                  className="btn btn-ghost"
                  style={{ width: 'auto', padding: '0 18px', height: 48 }}
                  onClick={copyText}
                >
                  <Copy width={18} height={18} />
                  홈택스 입력용 복사
                </button>
                <button
                  className="btn btn-primary"
                  style={{ width: 'auto', padding: '0 18px', height: 48 }}
                  onClick={markMonth}
                  disabled={marking || data.marked}
                >
                  {marking ? (
                    <span className="spinner" />
                  ) : data.marked ? (
                    <CheckCircle width={18} height={18} />
                  ) : (
                    <Check width={18} height={18} />
                  )}
                  {data.marked ? '마감 완료' : `${monthLabel(month)} 마감`}
                </button>
              </div>
            </>
          )}

          {/* 안내 노트(필수) */}
          <div
            className="warn-banner"
            style={{ alignItems: 'flex-start', marginBottom: 12 }}
          >
            <AlertTriangle width={20} height={20} style={{ flex: '0 0 auto', marginTop: 2 }} />
            <span style={{ fontWeight: 600 }}>{data.hometaxNote}</span>
          </div>
          <div
            className="card"
            style={{ padding: '14px 18px', background: 'var(--surface-2)' }}
          >
            <div style={{ fontSize: 14, fontWeight: 800, marginBottom: 8, color: 'var(--ink-2)' }}>
              세액 산출 안내
            </div>
            <ul style={{ margin: 0, paddingLeft: 18, fontSize: 14, color: 'var(--ink-2)', lineHeight: 1.6 }}>
              {data.notes.map((n, i) => (
                <li key={i}>{n}</li>
              ))}
            </ul>
          </div>
        </>
      ) : null}
    </>
  );
}
