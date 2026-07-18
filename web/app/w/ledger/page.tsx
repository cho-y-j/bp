'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { won, currentMonth, dateLabel, collectBadge } from '@/lib/format';
import MonthNav from '@/components/MonthNav';
import {
  Wallet,
  Download,
  Check,
  Bell,
  Refresh,
  X,
  CheckCircle,
} from '@/components/Icons';
import { openAuthedPdf } from '@/lib/worker';
import {
  type LedgerSummary,
  type LedgerEntryItem,
  type ByCompanyItem,
  ledgerStatusBadge,
} from '../types';

export default function LedgerPage() {
  const [month, setMonth] = useState(currentMonth());
  const [summary, setSummary] = useState<LedgerSummary | null>(null);
  const [companies, setCompanies] = useState<ByCompanyItem[] | null>(null);
  const [entries, setEntries] = useState<LedgerEntryItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [payTarget, setPayTarget] = useState<LedgerEntryItem | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [pdfBusy, setPdfBusy] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async (m: string) => {
    setError(null);
    setSummary(null);
    setCompanies(null);
    setEntries(null);
    try {
      const [s, byco, ent] = await Promise.all([
        api().get<LedgerSummary>(`/ledger/summary?month=${m}`),
        api().get<{ companies: ByCompanyItem[] }>(`/ledger/by-company?month=${m}`),
        api().get<{ items: LedgerEntryItem[] }>(`/ledger/entries?month=${m}`),
      ]);
      setSummary(s.data);
      setCompanies(byco.data.companies ?? []);
      setEntries(ent.data.items ?? []);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
      setCompanies([]);
      setEntries([]);
    }
  }, []);

  useEffect(() => {
    void load(month);
  }, [month, load]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  async function statement() {
    setPdfBusy(true);
    try {
      await openAuthedPdf(`/ledger/statement?month=${month}`);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '명세서 열기 실패');
    } finally {
      setPdfBusy(false);
    }
  }

  async function toggleAutoRemind(e: LedgerEntryItem) {
    setBusyId(e.id);
    try {
      await api().patch(`/ledger/${e.id}`, { autoRemind: !e.autoRemind });
      flash(!e.autoRemind ? '자동 독촉을 켰습니다.' : '자동 독촉을 껐습니다.');
      await load(month);
    } catch (err) {
      flash(err instanceof ApiError ? err.message : '변경 실패');
    } finally {
      setBusyId(null);
    }
  }

  async function remind(e: LedgerEntryItem) {
    setBusyId(e.id);
    try {
      await api().post(`/ledger/${e.id}/remind`);
      flash('수금 안내를 발송했습니다.');
      await load(month);
    } catch (err) {
      flash(err instanceof ApiError ? err.message : '독촉 실패');
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <h1 className="page-title">장부</h1>
      <p className="page-sub">회사별 미수와 입금 현황을 관리합니다.</p>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}

      <div className="w-toolbar">
        <MonthNav month={month} onChange={setMonth} />
        <button
          className="btn btn-ghost"
          onClick={statement}
          disabled={pdfBusy}
          style={{ maxWidth: 220 }}
        >
          {pdfBusy ? <span className="spinner" /> : <Download />}
          월간 명세서 PDF
        </button>
      </div>

      {error ? <p style={{ color: 'var(--receivable)' }}>{error}</p> : null}

      {/* 요약 */}
      <div className="w-stat-grid">
        <Stat label="일한 날" value={summary ? `${summary.daysWorked}일` : '—'} />
        <Stat
          label="총 청구"
          value={summary ? `${won(summary.totalBilled)}원` : '—'}
        />
        <Stat
          label="미수"
          value={summary ? `${won(summary.totalOutstanding)}원` : '—'}
          rcv
        />
        <Stat
          label="입금"
          value={summary ? `${won(summary.totalPaid)}원` : '—'}
        />
      </div>

      {/* 회사별 미수 */}
      <h2 style={{ fontSize: 18, fontWeight: 800, margin: '28px 0 12px' }}>
        회사별 미수
      </h2>
      {companies === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : companies.length === 0 ? (
        <div className="card empty">
          <Wallet width={28} height={28} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            이번 달 장부 내역이 없습니다
          </p>
        </div>
      ) : (
        <div className="card">
          {companies.map((g, i) => {
            const badge = collectBadge(g.dday);
            return (
              <div key={g.businessId ?? `m${i}`} className="row-item">
                <span className="avatar">{g.companyName.slice(0, 1)}</span>
                <span style={{ flex: 1, minWidth: 0 }}>
                  <span style={{ display: 'block', fontWeight: 700 }}>
                    {g.companyName}
                  </span>
                  <span
                    className="num"
                    style={{
                      display: 'block',
                      fontSize: 14,
                      color: 'var(--ink-2)',
                      marginTop: 2,
                    }}
                  >
                    {g.days}일 · 입금 {won(g.paid)}원
                    {g.dueDate ? ` · 예정 ${dateLabel(g.dueDate)}` : ''}
                  </span>
                </span>
                <span style={{ textAlign: 'right' }}>
                  {g.outstanding > 0 ? (
                    <span
                      className="num money rcv"
                      style={{ display: 'block', fontWeight: 800 }}
                    >
                      {won(g.outstanding)}원
                    </span>
                  ) : (
                    <span className="badge done">완납</span>
                  )}
                  {badge && g.outstanding > 0 ? (
                    <span
                      className={`badge ${badge.cls}`}
                      style={{ marginTop: 6 }}
                    >
                      {badge.text}
                    </span>
                  ) : null}
                </span>
              </div>
            );
          })}
        </div>
      )}

      {/* 개별 항목 */}
      <h2 style={{ fontSize: 18, fontWeight: 800, margin: '28px 0 12px' }}>
        개별 항목
      </h2>
      {entries === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : entries.length === 0 ? (
        <div className="card empty">
          <p style={{ fontWeight: 700 }}>항목이 없습니다</p>
        </div>
      ) : (
        <div className="card">
          {entries.map((e) => {
            const cls = ledgerStatusBadge(e.status);
            const paid = e.outstanding <= 0;
            return (
              <div
                key={e.id}
                className="row-item"
                style={{ flexWrap: 'wrap', alignItems: 'flex-start' }}
              >
                <span style={{ flex: 1, minWidth: 160 }}>
                  <span
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 6,
                      fontWeight: 700,
                    }}
                  >
                    {e.companyName}
                    {e.derived ? (
                      <span className="badge calm">팀 파생</span>
                    ) : null}
                  </span>
                  <span
                    className="num"
                    style={{
                      display: 'block',
                      fontSize: 14,
                      color: 'var(--ink-2)',
                      marginTop: 2,
                    }}
                  >
                    {e.siteName ?? '기타'}
                    {e.date ? ` · ${dateLabel(e.date)}` : ''}
                  </span>
                </span>
                <span style={{ textAlign: 'right', minWidth: 110 }}>
                  <span
                    className="num"
                    style={{ display: 'block', fontWeight: 800 }}
                  >
                    {won(e.amount)}원
                  </span>
                  <span className={`badge ${cls}`} style={{ marginTop: 4 }}>
                    {e.statusLabel}
                    {e.outstanding > 0 && e.paid > 0
                      ? ` · 잔액 ${won(e.outstanding)}`
                      : ''}
                  </span>
                </span>
                {/* 액션 행 */}
                <div
                  className="w-btn-row"
                  style={{ flexBasis: '100%', marginTop: 10 }}
                >
                  {!paid ? (
                    <button
                      className="btn btn-ghost"
                      style={{ height: 40, minHeight: 40, padding: '0 12px' }}
                      onClick={() => setPayTarget(e)}
                    >
                      <Check width={16} height={16} />
                      입금 기록
                    </button>
                  ) : null}
                  {!e.derived ? (
                    <button
                      className="btn btn-ghost"
                      style={{
                        height: 40,
                        minHeight: 40,
                        padding: '0 12px',
                        color: e.autoRemind
                          ? 'var(--accent-text)'
                          : 'var(--ink-2)',
                      }}
                      onClick={() => toggleAutoRemind(e)}
                      disabled={busyId === e.id}
                    >
                      <Bell width={16} height={16} />
                      자동 독촉 {e.autoRemind ? 'ON' : 'OFF'}
                    </button>
                  ) : null}
                  {!paid ? (
                    <button
                      className="btn btn-ghost"
                      style={{ height: 40, minHeight: 40, padding: '0 12px' }}
                      onClick={() => remind(e)}
                      disabled={busyId === e.id}
                    >
                      <Refresh width={16} height={16} />
                      독촉
                    </button>
                  ) : null}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {payTarget ? (
        <PaymentModal
          entry={payTarget}
          onClose={() => setPayTarget(null)}
          onPaid={() => {
            setPayTarget(null);
            flash('입금을 기록했습니다.');
            void load(month);
          }}
        />
      ) : null}
    </>
  );
}

function Stat({
  label,
  value,
  rcv,
}: {
  label: string;
  value: string;
  rcv?: boolean;
}) {
  return (
    <div className="card" style={{ padding: 16 }}>
      <div style={{ fontSize: 13, color: 'var(--ink-2)', fontWeight: 600 }}>
        {label}
      </div>
      <div
        className="num"
        style={{
          fontSize: 20,
          fontWeight: 800,
          marginTop: 4,
          color: rcv ? 'var(--receivable)' : 'var(--ink)',
        }}
      >
        {value}
      </div>
    </div>
  );
}

function PaymentModal({
  entry,
  onClose,
  onPaid,
}: {
  entry: LedgerEntryItem;
  onClose: () => void;
  onPaid: () => void;
}) {
  const [amount, setAmount] = useState(String(entry.outstanding));
  const [paidAt, setPaidAt] = useState('');
  const [memo, setMemo] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    setError(null);
    const a = parseInt(amount.replace(/[^\d]/g, ''), 10);
    if (!Number.isFinite(a) || a < 1) return setError('입금액을 입력하세요.');
    setBusy(true);
    try {
      const body: Record<string, unknown> = { amount: a };
      if (paidAt) body.paidAt = paidAt;
      if (memo.trim()) body.memo = memo.trim();
      await api().post(`/ledger/${entry.id}/payments`, body);
      onPaid();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '입금 기록 실패');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div style={{ padding: '18px 20px 4px' }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <h2 style={{ fontSize: 20, fontWeight: 800, margin: 0 }}>
              입금 기록
            </h2>
            <button
              type="button"
              className="btn btn-ghost"
              style={{ height: 44, minHeight: 44, padding: '0 12px' }}
              onClick={onClose}
              aria-label="닫기"
            >
              <X width={18} height={18} />
            </button>
          </div>
        </div>
        <div style={{ padding: '8px 20px 22px' }}>
          <p style={{ color: 'var(--ink-2)', fontSize: 14, marginTop: 0 }}>
            {entry.companyName} · 잔액 {won(entry.outstanding)}원
          </p>
          <div className="field">
            <label className="flabel" htmlFor="pay-amt">
              입금액 (원)
            </label>
            <input
              id="pay-amt"
              className="input num"
              inputMode="numeric"
              value={amount}
              onChange={(e) => setAmount(e.target.value.replace(/[^\d]/g, ''))}
            />
          </div>
          <div className="field">
            <label className="flabel" htmlFor="pay-date">
              입금일 (선택)
            </label>
            <input
              id="pay-date"
              type="date"
              className="input num"
              value={paidAt}
              onChange={(e) => setPaidAt(e.target.value)}
            />
          </div>
          <div className="field">
            <label className="flabel" htmlFor="pay-memo">
              메모 (선택)
            </label>
            <input
              id="pay-memo"
              className="input"
              value={memo}
              onChange={(e) => setMemo(e.target.value)}
              maxLength={100}
            />
          </div>
          {error ? (
            <p style={{ color: 'var(--receivable)' }}>{error}</p>
          ) : null}
          <button
            className="btn btn-primary btn-lg"
            onClick={submit}
            disabled={busy}
          >
            {busy ? <span className="spinner" /> : <Check />}
            입금 기록
          </button>
        </div>
      </div>
    </div>
  );
}
