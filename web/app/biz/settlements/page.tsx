'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { won, currentMonth } from '@/lib/format';
import MonthNav from '@/components/MonthNav';
import { Wallet, Check, CheckCircle } from '@/components/Icons';

interface WorkerGroup {
  workerProfileId: string;
  workerName: string;
  entryCount: number;
  total: number;
  paid: number;
  outstanding: number;
  ledgerEntryIds: string[];
}
interface Settlements {
  month: string;
  totalOutstanding: number;
  workers: WorkerGroup[];
}

export default function SettlementsPage() {
  const [month, setMonth] = useState(currentMonth());
  const [data, setData] = useState<Settlements | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [paying, setPaying] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const load = useCallback(async (m: string) => {
    setError(null);
    setData(null);
    setSelected(new Set());
    try {
      const res = await api().get<Settlements>(`/biz/settlements?month=${m}`);
      setData(res.data);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
    }
  }, []);

  useEffect(() => {
    void load(month);
  }, [month, load]);

  function toggle(id: string) {
    setSelected((prev) => {
      const n = new Set(prev);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });
  }

  const payableWorkers =
    data?.workers.filter((w) => w.outstanding > 0) ?? [];
  const selectedIds = payableWorkers
    .filter((w) => selected.has(w.workerProfileId))
    .flatMap((w) => w.ledgerEntryIds);
  const selectedAmount = payableWorkers
    .filter((w) => selected.has(w.workerProfileId))
    .reduce((s, w) => s + w.outstanding, 0);

  async function pay() {
    if (selectedIds.length === 0) return;
    setPaying(true);
    setError(null);
    try {
      await api().post('/biz/settlements/pay', {
        ledgerEntryIds: selectedIds,
      });
      setToast(`${won(selectedAmount)}원 지급 처리 완료`);
      await load(month);
      setTimeout(() => setToast(null), 3500);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '지급 처리 실패');
    } finally {
      setPaying(false);
    }
  }

  return (
    <>
      <h1 className="page-title">정산</h1>
      <p className="page-sub">
        서명 완료된 확인서 기준, 작업자별 미지급 금액입니다. 선택해 지급 처리하면
        작업자 장부에도 즉시 반영됩니다.
      </p>

      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: 18,
        }}
      >
        <MonthNav month={month} onChange={setMonth} />
        {data ? (
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 14, color: 'var(--ink-2)', fontWeight: 600 }}>
              이번 달 미지급 합계
            </div>
            <div
              className="num money rcv"
              style={{ fontSize: 26, fontWeight: 800 }}
            >
              {won(data.totalOutstanding)}원
            </div>
          </div>
        ) : null}
      </div>

      {toast ? (
        <div
          className="sign-stamp"
          role="status"
          style={{ marginBottom: 16 }}
        >
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}
      {error ? (
        <p style={{ color: 'var(--receivable)' }}>{error}</p>
      ) : null}

      {data === null && !error ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : data && data.workers.length === 0 ? (
        <div className="card empty">
          <Wallet width={30} height={30} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            이번 달 정산 내역이 없습니다
          </p>
        </div>
      ) : data ? (
        <>
          <div className="card">
            {data.workers.map((w) => {
              const payable = w.outstanding > 0;
              const on = selected.has(w.workerProfileId);
              return (
                <div
                  key={w.workerProfileId}
                  className={`checkrow${on ? ' on' : ''}`}
                  onClick={() => payable && toggle(w.workerProfileId)}
                  style={{ cursor: payable ? 'pointer' : 'default' }}
                >
                  <span className="checkbox">
                    {payable ? <Check width={18} height={18} /> : null}
                  </span>
                  <span className="avatar">{w.workerName.slice(0, 1)}</span>
                  <span style={{ flex: 1, minWidth: 0 }}>
                    <span
                      style={{ display: 'block', fontSize: 17, fontWeight: 700 }}
                    >
                      {w.workerName}
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
                      확인서 {w.entryCount}건 · 지급 {won(w.paid)}원
                    </span>
                  </span>
                  <span style={{ textAlign: 'right' }}>
                    {payable ? (
                      <span
                        className="num money rcv"
                        style={{ fontWeight: 800, fontSize: 17 }}
                      >
                        {won(w.outstanding)}원
                      </span>
                    ) : (
                      <span className="badge done">완납</span>
                    )}
                  </span>
                </div>
              );
            })}
          </div>

          {payableWorkers.length > 0 ? (
            <div
              style={{
                position: 'sticky',
                bottom: 0,
                marginTop: 18,
                background: 'var(--bg)',
                paddingTop: 8,
              }}
            >
              <button
                className="btn btn-primary btn-lg"
                onClick={pay}
                disabled={selectedIds.length === 0 || paying}
              >
                {paying ? <span className="spinner" /> : <Wallet />}
                {selectedIds.length === 0
                  ? '지급할 작업자를 선택하세요'
                  : `선택한 ${selected.size}명 · ${won(selectedAmount)}원 지급 처리`}
              </button>
            </div>
          ) : null}
        </>
      ) : null}
    </>
  );
}
