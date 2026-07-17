'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { won, currentMonth, monthLabel } from '@/lib/format';
import MonthNav from '@/components/MonthNav';
import {
  Coins,
  Download,
  Copy,
  Check,
  ChevronLeft,
  Chevron,
  CheckCircle,
  AlertTriangle,
} from '@/components/Icons';
import { openAuthedPdf, copyText } from '@/lib/worker';

interface IncomeMonthly {
  month: string;
  billed: number;
  paid: number;
  outstanding: number;
  daysWorked: number;
  gongsu: number;
}
interface IncomeCompany {
  companyName: string;
  businessId: string | null;
  count: number;
  total: number;
  paid: number;
  outstanding: number;
}
interface IncomeTotals {
  totalBilled: number;
  totalPaid: number;
  totalOutstanding: number;
  totalDays: number;
  totalGongsu: number;
  entryCount: number;
  teamPayout: number;
  netBilled: number;
}
interface IncomeReport {
  range: { from: string; to: string; year: number | null };
  monthly: IncomeMonthly[];
  companies: IncomeCompany[];
  totals: IncomeTotals;
  taxNote: { period: string; lines: string[] };
}

interface TaxGroup {
  buyerName: string;
  buyerBizNumber: string | null;
  supplyTotal: number;
  taxTotal: number;
  grandTotal: number;
  items: { date: string; content: string; supplyAmount: number }[];
  ledgerIds: string[];
}
interface TaxData {
  month: string;
  supplier: {
    name: string | null;
    bizNumber: string | null;
    bizName: string | null;
    bizAddress: string | null;
  };
  supplierReady: boolean;
  groupCount: number;
  groups: TaxGroup[];
  text: string;
}

export default function IncomePage() {
  const [tab, setTab] = useState<'report' | 'tax'>('report');
  const [toast, setToast] = useState<string | null>(null);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  return (
    <>
      <h1 className="page-title">소득</h1>
      <p className="page-sub">
        연간 소득 리포트와 세금계산서 작성 자료를 준비합니다.
      </p>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}

      <div className="w-tabs">
        <button
          className={`w-tab${tab === 'report' ? ' on' : ''}`}
          onClick={() => setTab('report')}
        >
          소득 리포트
        </button>
        <button
          className={`w-tab${tab === 'tax' ? ' on' : ''}`}
          onClick={() => setTab('tax')}
        >
          세금계산서 준비
        </button>
      </div>

      {tab === 'report' ? <ReportTab /> : <TaxTab flash={flash} />}
    </>
  );
}

function ReportTab() {
  const [year, setYear] = useState(new Date().getFullYear());
  const [data, setData] = useState<IncomeReport | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pdfBusy, setPdfBusy] = useState(false);

  const load = useCallback(async (y: number) => {
    setError(null);
    setData(null);
    try {
      const res = await api().get<IncomeReport>(
        `/ledger/income-report?year=${y}`,
      );
      setData(res.data);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
    }
  }, []);

  useEffect(() => {
    void load(year);
  }, [year, load]);

  async function pdf() {
    setPdfBusy(true);
    try {
      await openAuthedPdf(`/ledger/income-report/pdf?year=${year}`);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'PDF 열기 실패');
    } finally {
      setPdfBusy(false);
    }
  }

  return (
    <>
      <div className="w-toolbar">
        <div className="month-nav">
          <button onClick={() => setYear((y) => y - 1)} aria-label="이전 해">
            <ChevronLeft />
          </button>
          <span className="label num">{year}년</span>
          <button
            onClick={() => setYear((y) => y + 1)}
            aria-label="다음 해"
            disabled={year >= new Date().getFullYear()}
          >
            <Chevron />
          </button>
        </div>
        <button
          className="btn btn-ghost"
          onClick={pdf}
          disabled={pdfBusy || !data}
          style={{ maxWidth: 200 }}
        >
          {pdfBusy ? <span className="spinner" /> : <Download />}
          리포트 PDF
        </button>
      </div>

      {error ? <p style={{ color: 'var(--receivable)' }}>{error}</p> : null}

      {!data ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : (
        <>
          <div className="w-stat-grid">
            <Stat label="총 청구" value={`${won(data.totals.totalBilled)}원`} />
            <Stat label="입금" value={`${won(data.totals.totalPaid)}원`} />
            <Stat
              label="미수"
              value={`${won(data.totals.totalOutstanding)}원`}
              rcv
            />
            <Stat
              label="일한 날 / 공수"
              value={`${data.totals.totalDays}일 · ${data.totals.totalGongsu}공수`}
            />
          </div>

          {data.totals.teamPayout > 0 ? (
            <p style={{ color: 'var(--ink-2)', fontSize: 14, marginTop: 12 }}>
              팀 지급분 {won(data.totals.teamPayout)}원 · 순소득 참고{' '}
              <b>{won(data.totals.netBilled)}원</b>
            </p>
          ) : null}

          {/* 월별 */}
          <h2 style={{ fontSize: 18, fontWeight: 800, margin: '28px 0 12px' }}>
            월별 추이
          </h2>
          <div className="card w-table-scroll" style={{ padding: 12 }}>
            <table className="w-mini-table">
              <thead>
                <tr>
                  <th>월</th>
                  <th>청구</th>
                  <th>입금</th>
                  <th>미수</th>
                  <th>일수</th>
                  <th>공수</th>
                </tr>
              </thead>
              <tbody>
                {data.monthly.map((m) => (
                  <tr key={m.month}>
                    <td className="num">{m.month}</td>
                    <td className="num">{won(m.billed)}</td>
                    <td className="num">{won(m.paid)}</td>
                    <td className="num">{won(m.outstanding)}</td>
                    <td className="num">{m.daysWorked}</td>
                    <td className="num">{m.gongsu}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* 상대별 */}
          <h2 style={{ fontSize: 18, fontWeight: 800, margin: '28px 0 12px' }}>
            상대별
          </h2>
          {data.companies.length === 0 ? (
            <div className="card empty">
              <Coins width={28} height={28} />
              <p style={{ fontWeight: 700, marginTop: 8 }}>
                {year}년 소득 내역이 없습니다
              </p>
            </div>
          ) : (
            <div className="card w-table-scroll" style={{ padding: 12 }}>
              <table className="w-mini-table">
                <thead>
                  <tr>
                    <th>상대</th>
                    <th>건수</th>
                    <th>총액</th>
                    <th>입금</th>
                    <th>미수</th>
                  </tr>
                </thead>
                <tbody>
                  {data.companies.map((c, i) => (
                    <tr key={c.businessId ?? `m${i}`}>
                      <td>{c.companyName}</td>
                      <td className="num">{c.count}</td>
                      <td className="num">{won(c.total)}</td>
                      <td className="num">{won(c.paid)}</td>
                      <td className="num">{won(c.outstanding)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* 종소세 안내 */}
          {data.taxNote?.lines?.length ? (
            <div
              className="card"
              style={{
                padding: 16,
                marginTop: 20,
                background: 'var(--surface-2)',
              }}
            >
              <div style={{ fontWeight: 700, marginBottom: 6 }}>
                {data.taxNote.period} 참고
              </div>
              {data.taxNote.lines.map((l, i) => (
                <p
                  key={i}
                  style={{
                    margin: '2px 0',
                    fontSize: 14,
                    color: 'var(--ink-2)',
                  }}
                >
                  {l}
                </p>
              ))}
            </div>
          ) : null}
        </>
      )}
    </>
  );
}

function TaxTab({ flash }: { flash: (m: string) => void }) {
  const [month, setMonth] = useState(currentMonth());
  const [data, setData] = useState<TaxData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async (m: string) => {
    setError(null);
    setData(null);
    try {
      const res = await api().get<TaxData>(
        `/ledger/tax-invoice-data?month=${m}`,
      );
      setData(res.data);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
    }
  }, []);

  useEffect(() => {
    void load(month);
  }, [month, load]);

  async function copyAll() {
    if (!data) return;
    const ok = await copyText(data.text);
    flash(ok ? '작성 자료를 복사했습니다.' : '복사 실패');
  }

  async function mark(group: TaxGroup) {
    setBusy(true);
    try {
      await api().post('/ledger/tax-invoice-data/mark', {
        ledgerIds: group.ledgerIds,
      });
      flash(`${group.buyerName} 발행 완료로 표시했습니다.`);
      await load(month);
    } catch (e) {
      flash(e instanceof ApiError ? e.message : '표시 실패');
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <div className="w-toolbar">
        <MonthNav month={month} onChange={setMonth} />
        {data ? (
          <button
            className="btn btn-ghost"
            onClick={copyAll}
            disabled={data.groups.length === 0}
            style={{ maxWidth: 200 }}
          >
            <Copy />
            작성 자료 복사
          </button>
        ) : null}
      </div>

      {error ? <p style={{ color: 'var(--receivable)' }}>{error}</p> : null}

      {!data ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : (
        <>
          {!data.supplierReady ? (
            <div className="warn-banner" role="note" style={{ marginBottom: 16 }}>
              <AlertTriangle width={18} height={18} />
              <span>
                공급자 사업자번호가 없습니다. 세금계산서 발행 전 앱에서 사업자
                정보를 등록하세요.
              </span>
            </div>
          ) : (
            <p style={{ color: 'var(--ink-2)', fontSize: 14 }}>
              공급자: {data.supplier.bizName ?? data.supplier.name} ·{' '}
              <span className="num">{data.supplier.bizNumber}</span>
            </p>
          )}

          {data.groups.length === 0 ? (
            <div className="card empty">
              <Coins width={28} height={28} />
              <p style={{ fontWeight: 700, marginTop: 8 }}>
                {monthLabel(month)} 발행 대상이 없습니다
              </p>
              <p style={{ color: 'var(--ink-2)', fontSize: 14 }}>
                서명 완료된(미발행) 확인서만 집계됩니다.
              </p>
            </div>
          ) : (
            data.groups.map((g, i) => (
              <div
                key={i}
                className="card"
                style={{ padding: 16, marginBottom: 14 }}
              >
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'baseline',
                    marginBottom: 8,
                  }}
                >
                  <div style={{ fontWeight: 800, fontSize: 17 }}>
                    {g.buyerName}
                    {g.buyerBizNumber ? (
                      <span
                        className="num"
                        style={{
                          fontSize: 13,
                          color: 'var(--ink-3)',
                          marginLeft: 6,
                        }}
                      >
                        {g.buyerBizNumber}
                      </span>
                    ) : null}
                  </div>
                  <div className="num" style={{ fontWeight: 800 }}>
                    {won(g.grandTotal)}원
                  </div>
                </div>
                <div className="w-table-scroll">
                  <table className="w-mini-table">
                    <thead>
                      <tr>
                        <th>일자</th>
                        <th>내용</th>
                        <th>공급가액</th>
                      </tr>
                    </thead>
                    <tbody>
                      {g.items.map((it, j) => (
                        <tr key={j}>
                          <td className="num">{it.date}</td>
                          <td>{it.content}</td>
                          <td className="num">{won(it.supplyAmount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    marginTop: 10,
                    fontSize: 14,
                    color: 'var(--ink-2)',
                  }}
                >
                  <span className="num">
                    공급가 {won(g.supplyTotal)} · 세액 {won(g.taxTotal)}
                  </span>
                  <button
                    className="btn btn-ghost"
                    style={{ height: 40, minHeight: 40, padding: '0 14px' }}
                    onClick={() => mark(g)}
                    disabled={busy}
                  >
                    <Check width={16} height={16} />
                    발행 완료 표시
                  </button>
                </div>
              </div>
            ))
          )}
        </>
      )}
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
          fontSize: 18,
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
