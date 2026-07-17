'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { api, ApiError } from '@/lib/api';
import { useBiz } from '../biz-context';
import { won, dateLabel } from '@/lib/format';
import PaperConfirmation, {
  type ConfirmationView,
} from '@/components/PaperConfirmation';
import SignaturePad, {
  type SignaturePadHandle,
} from '@/components/SignaturePad';
import { FileText, Pen, CheckCircle, Clock, Chevron } from '@/components/Icons';
import BizPaymentBadge from '@/components/BizPaymentBadge';
import { AttendanceStats, type TodayAttendance } from '../attendance/shared';

/** 사업장 홈 상단 — 오늘 출역 요약 카드(상세는 /biz/attendance). */
function TodayAttendanceCard({ businessId }: { businessId?: string }) {
  const [data, setData] = useState<TodayAttendance | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const res = await api().get<TodayAttendance>(
          `/biz/today-attendance${businessId ? `?businessId=${businessId}` : ''}`,
        );
        if (alive) setData(res.data);
      } catch {
        if (alive) setFailed(true);
      }
    })();
    return () => {
      alive = false;
    };
  }, [businessId]);

  if (failed) return null;

  return (
    <Link
      href="/biz/attendance"
      className="card"
      style={{
        display: 'block',
        padding: 18,
        marginBottom: 18,
        textDecoration: 'none',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 14,
        }}
      >
        <span
          style={{
            fontSize: 16,
            fontWeight: 800,
            display: 'inline-flex',
            alignItems: 'center',
            gap: 6,
          }}
        >
          <Clock width={18} height={18} />
          오늘의 출역
        </span>
        <span
          style={{
            fontSize: 14,
            color: 'var(--accent-text)',
            fontWeight: 700,
            display: 'inline-flex',
            alignItems: 'center',
          }}
        >
          상세 보기
          <Chevron width={16} height={16} />
        </span>
      </div>
      {data ? (
        <AttendanceStats summary={data.summary} />
      ) : (
        <div className="empty" style={{ padding: '8px 0' }}>
          <span className="spinner" />
        </div>
      )}
    </Link>
  );
}

interface InboxItem {
  id: string;
  status: string;
  date: string;
  site: string;
  companyName: string | null;
  workerName: string;
  workContent: string;
  total: number;
  signerName: string | null;
  signedAt: string | null;
}

function statusBadge(status: string) {
  if (status === 'SIGNED') return { cls: 'done', text: '서명완료' };
  return { cls: 'soon', text: '서명대기' };
}

/** 인박스 아이템 → 종이 확인서 렌더용 뷰(요약 기반). */
function toView(it: InboxItem): ConfirmationView {
  return {
    status: it.status,
    signed: it.status === 'SIGNED',
    date: it.date,
    companyName: it.companyName,
    workerName: it.workerName,
    site: it.site,
    workContent: it.workContent,
    startTime: '-',
    endTime: '-',
    rateTypeLabel: '',
    amountCalc: {
      items: [
        {
          type: 'BASE',
          label: '작업 금액',
          rate: it.total,
          quantity: 1,
          amount: it.total,
        },
      ],
      subtotal: it.total,
      vatRate: 0,
      vat: 0,
      total: it.total,
    },
    total: it.total,
    signerName: it.signerName,
    signedAt: it.signedAt,
  };
}

export default function InboxPage() {
  const { business } = useBiz();
  const businessId = business?.id;
  const [items, setItems] = useState<InboxItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<InboxItem | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const res = await api().get<{ count: number; items: InboxItem[] }>(
        `/biz/inbox${businessId ? `?businessId=${businessId}` : ''}`,
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

  return (
    <>
      <h1 className="page-title">수신함</h1>
      <p className="page-sub">
        작업자가 보낸 작업확인서입니다. 확인 후 앱에서 바로 서명하세요.
      </p>

      <TodayAttendanceCard businessId={businessId} />

      <BizPaymentBadge businessId={businessId} />

      {error ? (
        <p style={{ color: 'var(--receivable)' }}>{error}</p>
      ) : items === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : items.length === 0 ? (
        <div className="card empty">
          <FileText width={30} height={30} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>받은 확인서가 없습니다</p>
          <p style={{ color: 'var(--ink-2)', fontSize: 15 }}>
            연결된 작업자가 확인서를 보내면 여기에 표시됩니다.
          </p>
        </div>
      ) : (
        <div className="card">
          {items.map((it) => {
            const b = statusBadge(it.status);
            return (
              <button
                key={it.id}
                className="row-item"
                style={{
                  width: '100%',
                  background: 'none',
                  border: 0,
                  borderBottom: '1px solid var(--border)',
                  textAlign: 'left',
                  cursor: 'pointer',
                }}
                onClick={() => setSelected(it)}
              >
                <span className="avatar">{it.workerName.slice(0, 1)}</span>
                <span style={{ flex: 1, minWidth: 0 }}>
                  <span
                    style={{ display: 'block', fontSize: 17, fontWeight: 700 }}
                  >
                    {it.site}
                  </span>
                  <span
                    style={{
                      display: 'block',
                      fontSize: 14,
                      color: 'var(--ink-2)',
                      marginTop: 2,
                    }}
                    className="num"
                  >
                    {it.workerName} · {dateLabel(it.date)}
                  </span>
                </span>
                <span style={{ textAlign: 'right' }}>
                  <span
                    className="num"
                    style={{ display: 'block', fontWeight: 800, fontSize: 17 }}
                  >
                    {won(it.total)}원
                  </span>
                  <span className={`badge ${b.cls}`} style={{ marginTop: 6 }}>
                    {b.text}
                  </span>
                </span>
              </button>
            );
          })}
        </div>
      )}

      {selected ? (
        <DetailModal
          item={selected}
          onClose={() => setSelected(null)}
          onSigned={() => {
            setSelected(null);
            void load();
          }}
        />
      ) : null}
    </>
  );
}

function DetailModal({
  item,
  onClose,
  onSigned,
}: {
  item: InboxItem;
  onClose: () => void;
  onSigned: () => void;
}) {
  const padRef = useRef<SignaturePadHandle>(null);
  const [signerName, setSignerName] = useState('');
  const [padEmpty, setPadEmpty] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // 모달 오픈 시 상세(시간·금액 내역 전체) 조회 — 목록은 요약만 담고 있음.
  const [detail, setDetail] = useState<ConfirmationView | null>(null);
  const [detailLoading, setDetailLoading] = useState(true);
  const signable = item.status === 'SENT';

  useEffect(() => {
    let alive = true;
    setDetailLoading(true);
    (async () => {
      try {
        const res = await api().get<ConfirmationView>(
          `/biz/confirmations/${item.id}`,
        );
        if (alive) setDetail(res.data);
      } catch {
        // 상세 조회 실패 시 요약 뷰로 폴백(아래 view 계산에서 처리).
        if (alive) setDetail(null);
      } finally {
        if (alive) setDetailLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, [item.id]);

  // 상세가 오면 전체 내역, 아직 로딩/실패면 요약(toView)로 렌더.
  const view = detail ?? toView(item);

  async function sign() {
    setError(null);
    if (signerName.trim().length < 1) {
      setError('서명자 이름을 입력하세요.');
      return;
    }
    if (padRef.current?.isEmpty()) {
      setError('서명을 입력하세요.');
      return;
    }
    setBusy(true);
    try {
      await api().post(`/biz/confirmations/${item.id}/sign`, {
        signerName: signerName.trim(),
        signImageBase64: padRef.current!.toDataURL(),
      });
      onSigned();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '서명에 실패했습니다.');
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
              수신 확인서
            </h2>
            <button
              className="btn btn-ghost"
              style={{ height: 44, minHeight: 44, padding: '0 14px' }}
              onClick={onClose}
            >
              닫기
            </button>
          </div>
        </div>
        <div style={{ padding: '8px 20px 22px' }}>
          {detailLoading ? (
            <div className="empty" style={{ padding: '10px 0' }}>
              <span className="spinner" />
            </div>
          ) : null}
          <PaperConfirmation c={view} />

          {signable ? (
            <div className="sign-zone">
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  margin: '18px 0 12px',
                  color: 'var(--accent-text)',
                }}
              >
                <Pen width={20} height={20} />
                <span
                  style={{ fontSize: 17, fontWeight: 800, color: 'var(--ink)' }}
                >
                  앱에서 바로 서명
                </span>
              </div>
              <div className="field">
                <label className="flabel" htmlFor="bizSigner">
                  서명자 이름
                </label>
                <input
                  id="bizSigner"
                  className="input"
                  placeholder="예) 이현수"
                  value={signerName}
                  onChange={(e) => setSignerName(e.target.value)}
                  maxLength={50}
                />
              </div>
              <SignaturePad ref={padRef} onChange={setPadEmpty} />
              <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 8 }}>
                <button
                  className="btn btn-ghost"
                  style={{ height: 44, minHeight: 44, padding: '0 16px' }}
                  onClick={() => padRef.current?.clear()}
                  disabled={padEmpty}
                >
                  다시 그리기
                </button>
              </div>
              {error ? (
                <p style={{ color: 'var(--receivable)', marginTop: 10 }}>
                  {error}
                </p>
              ) : null}
              <button
                className="btn btn-primary btn-lg"
                style={{ marginTop: 14 }}
                onClick={sign}
                disabled={busy}
              >
                {busy ? <span className="spinner" /> : <CheckCircle />}
                서명하고 확정
              </button>
            </div>
          ) : (
            <div className="sign-stamp" style={{ marginTop: 16 }}>
              <CheckCircle width={20} height={20} />
              <span>
                이미 서명 완료된 확인서입니다
                {item.signerName ? (
                  <>
                    {' · '}
                    <b>{item.signerName}</b>
                  </>
                ) : null}
              </span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
