'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { useBiz } from '../biz-context';
import { Clock, Refresh, MapPin, CheckCircle } from '@/components/Icons';
import {
  AttendanceStats,
  STATUS_META,
  CONDITION_LABEL,
  type TodayAttendance,
} from './shared';

export default function AttendancePage() {
  const { business } = useBiz();
  const businessId = business?.id;
  const [data, setData] = useState<TodayAttendance | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updatedAt, setUpdatedAt] = useState<string | null>(null);
  const firstLoad = useRef(true);

  const load = useCallback(async () => {
    try {
      const res = await api().get<TodayAttendance>(
        `/biz/today-attendance${businessId ? `?businessId=${businessId}` : ''}`,
      );
      setData(res.data);
      setError(null);
      setUpdatedAt(
        new Date().toLocaleTimeString('ko-KR', {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
        }),
      );
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
      if (firstLoad.current) setData({ date: '', sites: [], summary: { total: 0, attended: 0, completed: 0, absent: 0 } });
    } finally {
      firstLoad.current = false;
    }
  }, [businessId]);

  // 30초 자동 갱신.
  useEffect(() => {
    firstLoad.current = true;
    setData(null);
    void load();
    const t = setInterval(() => void load(), 30000);
    return () => clearInterval(t);
  }, [load]);

  return (
    <>
      <h1 className="page-title">오늘의 출역 현황</h1>
      <p className="page-sub">
        오늘 예정된 작업의 현장별 출역 상태입니다. 30초마다 자동 갱신됩니다.
      </p>

      {error ? (
        <p style={{ color: 'var(--receivable)' }}>{error}</p>
      ) : null}

      {data === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : (
        <>
          <div className="card" style={{ padding: 18, marginBottom: 18 }}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 14,
                gap: 10,
                flexWrap: 'wrap',
              }}
            >
              <span
                style={{
                  fontSize: 15,
                  fontWeight: 700,
                  color: 'var(--ink-2)',
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                }}
              >
                <Clock width={18} height={18} />
                {data.date || '오늘'}
              </span>
              <button
                className="btn btn-ghost"
                style={{ height: 40, minHeight: 40, padding: '0 12px', fontSize: 15 }}
                onClick={() => void load()}
              >
                <Refresh width={16} height={16} />
                {updatedAt ? `${updatedAt} 갱신` : '새로고침'}
              </button>
            </div>
            <AttendanceStats summary={data.summary} />
          </div>

          {data.sites.length === 0 ? (
            <div className="card empty">
              <Clock width={30} height={30} />
              <p style={{ fontWeight: 700, marginTop: 8 }}>
                오늘 예정된 출역이 없습니다
              </p>
              <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>
                앱에서 오늘 일정을 배정하면 여기에 실시간으로 표시됩니다.
              </p>
            </div>
          ) : (
            data.sites.map((s) => (
              <div key={s.site} className="card" style={{ marginBottom: 16 }}>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '14px 16px',
                    borderBottom: '1px solid var(--border)',
                    gap: 10,
                  }}
                >
                  <span
                    style={{
                      fontSize: 17,
                      fontWeight: 800,
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 6,
                      minWidth: 0,
                    }}
                  >
                    <MapPin width={18} height={18} />
                    {s.site}
                  </span>
                  <span
                    className="num"
                    style={{ fontSize: 14, color: 'var(--ink-2)', fontWeight: 600, flex: '0 0 auto' }}
                  >
                    출근 {s.summary.attended}/{s.summary.total}
                    {s.summary.completed > 0 ? ` · 완료 ${s.summary.completed}` : ''}
                  </span>
                </div>
                <div style={{ overflowX: 'auto' }}>
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th style={{ textAlign: 'left' }}>작업자</th>
                        <th>상태</th>
                        <th>시작</th>
                        <th>컨디션</th>
                      </tr>
                    </thead>
                    <tbody>
                      {s.workers.map((w) => {
                        const meta = STATUS_META[w.status];
                        return (
                          <tr key={w.jobId}>
                            <td style={{ textAlign: 'left' }}>
                              <span style={{ fontWeight: 700 }}>{w.workerName}</span>
                              <span
                                className="num"
                                style={{ color: 'var(--ink-3)', fontSize: 13, marginLeft: 8 }}
                              >
                                {w.scheduledAt}
                              </span>
                            </td>
                            <td style={{ textAlign: 'center' }}>
                              <span className={`badge ${meta.cls}`}>{meta.text}</span>
                            </td>
                            <td className="num" style={{ textAlign: 'center' }}>
                              {w.startedAt ?? '-'}
                              {w.finishedAt ? (
                                <span style={{ color: 'var(--ink-3)' }}>
                                  {' '}~ {w.finishedAt}
                                </span>
                              ) : null}
                            </td>
                            <td style={{ textAlign: 'center' }}>
                              {w.condition ? (
                                <span
                                  className={`badge ${w.condition === 'OK' ? 'done' : 'warn'}`}
                                >
                                  {w.condition === 'OK' ? (
                                    <CheckCircle width={13} height={13} />
                                  ) : null}
                                  {CONDITION_LABEL[w.condition] ?? w.condition}
                                </span>
                              ) : (
                                <span style={{ color: 'var(--ink-3)' }}>-</span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            ))
          )}
        </>
      )}
    </>
  );
}
