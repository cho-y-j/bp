'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, authedBlob, ApiError } from '@/lib/api';
import { currentMonth, monthLabel, dateLabel } from '@/lib/format';
import MonthNav from '@/components/MonthNav';
import { Shield, Download, AlertTriangle } from '@/components/Icons';

interface Notif {
  id: string;
  type: string;
  title: string;
  body: string;
  createdAt: string;
}

// 안전 관련 알림 유형 (수신함/정산 등 비안전 알림 제외)
const SAFETY_TYPES = new Set([
  'HEAT_ALERT',
  'REST_GUIDE',
  'SAFETY',
  'DOCUMENT_VALIDITY',
  'CONDITION_CHECK',
]);

export default function SafetyPage() {
  const [month, setMonth] = useState(currentMonth());
  const [logs, setLogs] = useState<Notif[] | null>(null);
  const [downloading, setDownloading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const res = await api().get<{ items: Notif[] }>('/notifications');
      setLogs(res.data.items.filter((n) => SAFETY_TYPES.has(n.type)));
    } catch {
      setLogs([]);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function downloadReport() {
    setError(null);
    setDownloading(true);
    try {
      // 인증 blob 방식: Authorization 헤더로 PDF 스트림을 받아 브라우저에서 열기.
      const blob = await authedBlob(`/biz/safety-report?month=${month}`);
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank');
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    } catch (e) {
      setError(
        e instanceof ApiError
          ? e.message
          : '리포트를 불러오지 못했습니다.',
      );
    } finally {
      setDownloading(false);
    }
  }

  return (
    <>
      <h1 className="page-title">안전 리포트</h1>
      <p className="page-sub">
        폭염 알림·서류 유효성·컨디션 체크 등 안전관리 이행 기록입니다. 월별
        리포트를 PDF 로 내려받을 수 있습니다.
      </p>

      <div className="card" style={{ padding: 20, marginBottom: 24 }}>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: 14,
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ color: 'var(--accent-text)' }}>
              <Shield width={28} height={28} />
            </span>
            <div>
              <div style={{ fontSize: 17, fontWeight: 700 }}>
                안전관리 이행 리포트
              </div>
              <div style={{ fontSize: 14, color: 'var(--ink-2)' }}>
                {monthLabel(month)} 기준
              </div>
            </div>
          </div>
          <MonthNav month={month} onChange={setMonth} />
        </div>
        {error ? (
          <p style={{ color: 'var(--receivable)', marginTop: 12 }}>{error}</p>
        ) : null}
        <button
          className="btn btn-primary btn-lg"
          style={{ marginTop: 16 }}
          onClick={downloadReport}
          disabled={downloading}
        >
          {downloading ? <span className="spinner" /> : <Download />}
          {monthLabel(month)} 리포트 PDF 열기
        </button>
      </div>

      <h2 style={{ fontSize: 19, fontWeight: 800, margin: '0 0 12px' }}>
        최근 안전 알림
      </h2>
      {logs === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : logs.length === 0 ? (
        <div className="card empty">
          <Shield width={28} height={28} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            최근 안전 알림이 없습니다
          </p>
        </div>
      ) : (
        <div className="card">
          {logs.map((n) => (
            <div key={n.id} className="row-item">
              <span
                className="avatar"
                style={{
                  background: 'var(--warn-bg)',
                  color: 'var(--warn-ink)',
                }}
              >
                <AlertTriangle width={22} height={22} />
              </span>
              <span style={{ flex: 1, minWidth: 0 }}>
                <span style={{ display: 'block', fontSize: 16, fontWeight: 700 }}>
                  {n.title}
                </span>
                <span
                  style={{
                    display: 'block',
                    fontSize: 14,
                    color: 'var(--ink-2)',
                    marginTop: 2,
                  }}
                >
                  {n.body}
                </span>
              </span>
              <span
                className="num"
                style={{
                  fontSize: 14,
                  color: 'var(--ink-3)',
                  flex: '0 0 auto',
                }}
              >
                {dateLabel(n.createdAt)}
              </span>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
