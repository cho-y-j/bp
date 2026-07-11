'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, authedBlob, ApiError } from '@/lib/api';
import { useBiz } from '../biz-context';
import { won, dateLabel } from '@/lib/format';
import { FileText, Download, CheckCircle } from '@/components/Icons';

interface ContractItem {
  id: string;
  status: string;
  statusLabel: string;
  title: string;
  workerName: string;
  workerLinked: boolean;
  workplace: string;
  startDate: string;
  endDate: string | null;
  wageTypeLabel: string;
  wageAmount: number;
  employerSigned: boolean;
  workerSigned: boolean;
  shareToken: string;
  revokedAt: string | null;
}

function statusBadge(it: ContractItem) {
  if (it.revokedAt) return { cls: 'warn', text: '무효화됨' };
  if (it.status === 'SIGNED') return { cls: 'done', text: '서명완료' };
  if (it.status === 'SENT') return { cls: 'soon', text: '서명대기' };
  return { cls: 'calm', text: '작성중' };
}

export default function ContractsPage() {
  const { business } = useBiz();
  const businessId = business?.id;
  const [items, setItems] = useState<ContractItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const res = await api().get<{ count: number; items: ContractItem[] }>(
        `/biz/contracts${businessId ? `?businessId=${businessId}` : ''}`,
      );
      setItems(res.data.items);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
      setItems([]);
    }
  }, [businessId]);

  useEffect(() => {
    void load();
  }, [load]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  }

  async function openPdf(id: string) {
    setError(null);
    try {
      const blob = await authedBlob(`/biz/contracts/${id}/pdf`);
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank');
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    } catch (e) {
      setError(
        e instanceof ApiError ? e.message : 'PDF 를 불러오지 못했습니다.',
      );
    }
  }

  async function copyLink(token: string) {
    const origin =
      typeof window !== 'undefined' ? window.location.origin : '';
    const link = `${origin}/lc/${token}`;
    try {
      await navigator.clipboard.writeText(link);
      flash('외부 서명 링크를 복사했습니다.');
    } catch {
      // clipboard 미지원 환경 폴백: prompt 로 노출
      if (typeof window !== 'undefined') window.prompt('링크 복사', link);
    }
  }

  return (
    <>
      <h1 className="page-title">표준근로계약서</h1>
      <p className="page-sub">
        발행한 근로계약서 목록입니다. PDF 를 열거나 외부 서명 링크를 복사할 수
        있습니다. 작성·서명은 작업온 앱에서 진행하세요.
      </p>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}
      {error ? (
        <p style={{ color: 'var(--receivable)' }}>{error}</p>
      ) : null}

      {items === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : items.length === 0 ? (
        <div className="card empty">
          <FileText width={30} height={30} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            발행한 계약서가 없습니다
          </p>
          <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>
            작업온 앱의 사업장 메뉴에서 표준근로계약서를 작성·발행하세요.
          </p>
        </div>
      ) : (
        <div className="card">
          {items.map((it) => {
            const b = statusBadge(it);
            return (
              <div
                key={it.id}
                className="row-item"
                style={{
                  borderBottom: '1px solid var(--border)',
                  alignItems: 'flex-start',
                  flexWrap: 'wrap',
                  gap: 10,
                }}
              >
                <span className="avatar" style={{ background: 'var(--surface-2)' }}>
                  {it.workerName.slice(0, 1)}
                </span>
                <span style={{ flex: 1, minWidth: 160 }}>
                  <span
                    style={{ display: 'block', fontSize: 17, fontWeight: 700 }}
                  >
                    {it.workerName}
                    {it.workerLinked ? null : (
                      <span
                        style={{
                          fontSize: 13,
                          color: 'var(--ink-3)',
                          fontWeight: 500,
                          marginLeft: 6,
                        }}
                      >
                        (수기)
                      </span>
                    )}
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
                    {it.workplace} · {dateLabel(it.startDate)}
                    {it.endDate ? ` ~ ${dateLabel(it.endDate)}` : ''}
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
                    {it.wageTypeLabel} {won(it.wageAmount)}원
                  </span>
                </span>
                <span
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'flex-end',
                    gap: 8,
                  }}
                >
                  <span className={`badge ${b.cls}`}>{b.text}</span>
                  <span style={{ display: 'flex', gap: 8 }}>
                    <button
                      className="btn btn-ghost"
                      style={{ height: 40, minHeight: 40, padding: '0 12px' }}
                      onClick={() => openPdf(it.id)}
                    >
                      <Download width={16} height={16} />
                      PDF
                    </button>
                    {it.status !== 'DRAFT' && !it.revokedAt ? (
                      <button
                        className="btn btn-ghost"
                        style={{ height: 40, minHeight: 40, padding: '0 12px' }}
                        onClick={() => copyLink(it.shareToken)}
                      >
                        링크 복사
                      </button>
                    ) : null}
                  </span>
                </span>
              </div>
            );
          })}
        </div>
      )}
    </>
  );
}
