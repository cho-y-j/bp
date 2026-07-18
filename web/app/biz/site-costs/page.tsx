'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, authedBlob, ApiError } from '@/lib/api';
import { useBiz } from '../biz-context';
import { won, currentMonth, monthLabel, shiftMonth } from '@/lib/format';
import { Coins, Download, Chevron, Users } from '@/components/Icons';

interface SiteEntry {
  workerProfileId: string;
  workerName: string;
  isTeam: boolean;
  teamMemberCount: number;
  days: number;
  gongsu: number;
  amount: number;
  entryCount: number;
}
interface SiteGroup {
  site: string;
  entries: SiteEntry[];
  subtotalAmount: number;
  subtotalDays: number;
  subtotalGongsu: number;
  workerCount: number;
}
interface SiteCosts {
  range: { from: string; to: string };
  businessName: string;
  sites: SiteGroup[];
  totals: {
    totalAmount: number;
    totalDays: number;
    totalGongsu: number;
    siteCount: number;
    entryCount: number;
  };
}

/** YYYY-MM 를 정수 개월값으로(비교·개월수 계산용). */
function monthIndex(m: string): number {
  const [y, mm] = m.split('-').map(Number);
  return y * 12 + (mm - 1);
}

/** 월 선택 컨트롤(±1개월 이동 + 라벨). */
function MonthPicker({
  label,
  month,
  onChange,
}: {
  label: string;
  month: string;
  onChange: (m: string) => void;
}) {
  return (
    <div style={{ minWidth: 0 }}>
      <div className="flabel" style={{ marginBottom: 6 }}>
        {label}
      </div>
      <div className="month-nav" style={{ margin: 0 }}>
        <button onClick={() => onChange(shiftMonth(month, -1))} aria-label={`${label} 이전 달`}>
          <Chevron width={16} height={16} style={{ transform: 'rotate(180deg)' }} />
        </button>
        <span className="label num">{monthLabel(month)}</span>
        <button onClick={() => onChange(shiftMonth(month, 1))} aria-label={`${label} 다음 달`}>
          <Chevron width={16} height={16} />
        </button>
      </div>
    </div>
  );
}

export default function SiteCostsPage() {
  const { business } = useBiz();
  const businessId = business?.id;
  const [from, setFrom] = useState(currentMonth());
  const [to, setTo] = useState(currentMonth());
  const [data, setData] = useState<SiteCosts | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [downloading, setDownloading] = useState(false);
  const [open, setOpen] = useState<Set<string>>(new Set());

  const rangeValid = monthIndex(from) <= monthIndex(to);
  const monthSpan = monthIndex(to) - monthIndex(from) + 1;
  const tooLong = monthSpan > 12;

  const load = useCallback(async () => {
    if (monthIndex(from) > monthIndex(to)) {
      setError('시작 월이 종료 월보다 늦습니다.');
      setData(null);
      return;
    }
    if (monthIndex(to) - monthIndex(from) + 1 > 12) {
      setError('기간은 최대 12개월까지 조회할 수 있습니다.');
      setData(null);
      return;
    }
    setError(null);
    setData(null);
    try {
      const res = await api().get<SiteCosts>(
        `/biz/site-costs?from=${from}&to=${to}${
          businessId ? `&businessId=${businessId}` : ''
        }`,
      );
      setData(res.data);
      // 기본으로 모든 현장 펼침.
      setOpen(new Set(res.data.sites.map((s) => s.site)));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
    }
  }, [from, to, businessId]);

  useEffect(() => {
    void load();
  }, [load]);

  function toggle(site: string) {
    setOpen((prev) => {
      const n = new Set(prev);
      if (n.has(site)) n.delete(site);
      else n.add(site);
      return n;
    });
  }

  async function downloadPdf() {
    if (!rangeValid || tooLong) return;
    setError(null);
    setDownloading(true);
    try {
      const blob = await authedBlob(
        `/biz/site-costs/pdf?from=${from}&to=${to}${
          businessId ? `&businessId=${businessId}` : ''
        }`,
      );
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank');
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'PDF 를 불러오지 못했습니다.');
    } finally {
      setDownloading(false);
    }
  }

  return (
    <>
      <h1 className="page-title">현장별 인건비 집계</h1>
      <p className="page-sub">
        서명 완료된 확인서 기준, 기간 내 현장별 인건비입니다. 발주처 제출용 PDF 로
        내려받을 수 있습니다. (작업자 이름은 개인정보 보호를 위해 마스킹됩니다.)
      </p>

      <div className="card" style={{ padding: 18, marginBottom: 18 }}>
        <div
          style={{
            display: 'flex',
            gap: 16,
            flexWrap: 'wrap',
            alignItems: 'flex-end',
          }}
        >
          <MonthPicker label="시작 월" month={from} onChange={setFrom} />
          <span
            style={{ color: 'var(--ink-3)', paddingBottom: 10, fontWeight: 700 }}
            aria-hidden
          >
            ~
          </span>
          <MonthPicker label="종료 월" month={to} onChange={setTo} />
          <button
            className="btn btn-primary"
            style={{ marginLeft: 'auto', width: 'auto', padding: '0 20px', height: 48 }}
            onClick={downloadPdf}
            disabled={downloading || !rangeValid || tooLong}
          >
            {downloading ? <span className="spinner" /> : <Download width={18} height={18} />}
            PDF 다운로드
          </button>
        </div>
      </div>

      {error ? <p style={{ color: 'var(--receivable)' }}>{error}</p> : null}

      {data === null && !error ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : data ? (
        <>
          <div
            className="card"
            style={{
              padding: '16px 18px',
              marginBottom: 18,
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: 10,
            }}
          >
            <div>
              <div style={{ fontSize: 14, color: 'var(--ink-2)', fontWeight: 600 }}>
                전체 총계 · 현장 {data.totals.siteCount}개 · 확인서{' '}
                {data.totals.entryCount}건 · 연인원 {data.totals.totalDays}
              </div>
              <div style={{ fontSize: 13, color: 'var(--ink-3)' }}>
                {data.businessName}
              </div>
            </div>
            <div
              className="num money rcv"
              style={{ fontSize: 28, fontWeight: 800 }}
            >
              {won(data.totals.totalAmount)}원
            </div>
          </div>

          {data.sites.length === 0 ? (
            <div className="card empty">
              <Coins width={30} height={30} />
              <p style={{ fontWeight: 700, marginTop: 8 }}>
                해당 기간 인건비 내역이 없습니다
              </p>
            </div>
          ) : (
            data.sites.map((s) => {
              const expanded = open.has(s.site);
              return (
                <div key={s.site} className="card" style={{ marginBottom: 14 }}>
                  <button
                    onClick={() => toggle(s.site)}
                    style={{
                      width: '100%',
                      background: 'none',
                      border: 0,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '16px 18px',
                      cursor: 'pointer',
                      textAlign: 'left',
                      gap: 10,
                    }}
                    aria-expanded={expanded}
                  >
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
                      <Chevron
                        width={18}
                        height={18}
                        style={{
                          transform: expanded ? 'rotate(90deg)' : 'none',
                          transition: 'transform .15s',
                          color: 'var(--ink-3)',
                          flex: '0 0 auto',
                        }}
                      />
                      <span style={{ fontSize: 17, fontWeight: 800 }}>{s.site}</span>
                      <span
                        className="num"
                        style={{ fontSize: 13, color: 'var(--ink-3)', fontWeight: 600 }}
                      >
                        {s.workerCount}명 · 연인원 {s.subtotalDays}
                      </span>
                    </span>
                    <span
                      className="num"
                      style={{ fontSize: 18, fontWeight: 800, flex: '0 0 auto' }}
                    >
                      {won(s.subtotalAmount)}원
                    </span>
                  </button>
                  {expanded ? (
                    <>
                    <div className="tbl-desktop" style={{ overflowX: 'auto', borderTop: '1px solid var(--border)' }}>
                      <table className="data-table">
                        <thead>
                          <tr>
                            <th style={{ textAlign: 'left' }}>작업자</th>
                            <th>연인원</th>
                            <th>공수</th>
                            <th style={{ textAlign: 'right' }}>금액</th>
                          </tr>
                        </thead>
                        <tbody>
                          {s.entries.map((e) => (
                            <tr key={e.workerProfileId + e.amount}>
                              <td style={{ textAlign: 'left' }}>
                                <span style={{ fontWeight: 700 }}>{e.workerName}</span>
                                {e.isTeam ? (
                                  <span
                                    className="badge accent"
                                    style={{ marginLeft: 8, verticalAlign: 'middle' }}
                                  >
                                    <Users width={12} height={12} />팀 {e.teamMemberCount}명
                                  </span>
                                ) : null}
                                {e.entryCount > 1 ? (
                                  <span
                                    className="num"
                                    style={{ color: 'var(--ink-3)', fontSize: 13, marginLeft: 8 }}
                                  >
                                    확인서 {e.entryCount}건
                                  </span>
                                ) : null}
                              </td>
                              <td className="num" style={{ textAlign: 'center' }}>
                                {e.days}
                              </td>
                              <td className="num" style={{ textAlign: 'center' }}>
                                {e.gongsu || '-'}
                              </td>
                              <td className="num" style={{ textAlign: 'right', fontWeight: 700 }}>
                                {won(e.amount)}원
                              </td>
                            </tr>
                          ))}
                          <tr style={{ background: 'var(--surface-2)' }}>
                            <td style={{ textAlign: 'left', fontWeight: 800 }}>소계</td>
                            <td className="num" style={{ textAlign: 'center', fontWeight: 700 }}>
                              {s.subtotalDays}
                            </td>
                            <td className="num" style={{ textAlign: 'center', fontWeight: 700 }}>
                              {s.subtotalGongsu || '-'}
                            </td>
                            <td className="num" style={{ textAlign: 'right', fontWeight: 800 }}>
                              {won(s.subtotalAmount)}원
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                    {/* 모바일: 작업자별 카드 — 금액을 크게 우측에 노출 */}
                    <div className="row-cards" style={{ borderTop: '1px solid var(--border)' }}>
                      {s.entries.map((e) => (
                        <div className="rowcard" key={e.workerProfileId + e.amount}>
                          <div className="rowcard-main">
                            <div className="rowcard-name">
                              {e.workerName}
                              {e.isTeam ? (
                                <span
                                  className="badge accent"
                                  style={{ marginLeft: 8, verticalAlign: 'middle' }}
                                >
                                  <Users width={12} height={12} />팀 {e.teamMemberCount}명
                                </span>
                              ) : null}
                            </div>
                            <div className="rowcard-sub num">
                              연인원 {e.days} · 공수 {e.gongsu || '-'}
                              {e.entryCount > 1 ? ` · 확인서 ${e.entryCount}건` : ''}
                            </div>
                          </div>
                          <div className="rowcard-amt">
                            <div className="amt-val num">{won(e.amount)}원</div>
                          </div>
                        </div>
                      ))}
                      <div className="rowcard rowcard-total">
                        <div className="rowcard-main">
                          <div className="rowcard-name">소계</div>
                          <div className="rowcard-sub num">
                            연인원 {s.subtotalDays} · 공수 {s.subtotalGongsu || '-'}
                          </div>
                        </div>
                        <div className="rowcard-amt">
                          <div className="amt-val num">{won(s.subtotalAmount)}원</div>
                        </div>
                      </div>
                    </div>
                    </>
                  ) : null}
                </div>
              );
            })
          )}
        </>
      ) : null}
    </>
  );
}
