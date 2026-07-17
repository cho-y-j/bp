'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { won, currentMonth, dateLabel } from '@/lib/format';
import MonthNav from '@/components/MonthNav';
import PaperConfirmation, {
  type ConfirmationView,
} from '@/components/PaperConfirmation';
import {
  FileText,
  Plus,
  Send,
  Download,
  Copy,
  X,
  AlertTriangle,
  CheckCircle,
  Truck,
} from '@/components/Icons';
import { openAuthedPdf, copyText } from '@/lib/worker';
import { useWorker } from '../w-context';
import {
  type ConfirmationListItem,
  type ConnectionItem,
  confStatusBadge,
} from '../types';

const RATE_TYPES: { value: string; label: string; unit: string }[] = [
  { value: 'DAILY', label: '일당', unit: '일' },
  { value: 'GONGSU', label: '공수', unit: '공수' },
  { value: 'HOURLY', label: '시급', unit: '시간' },
  { value: 'PER_CASE', label: '건당', unit: '건' },
];

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(
    d.getDate(),
  ).padStart(2, '0')}`;
}

export default function ConfirmationsPage() {
  const [month, setMonth] = useState(currentMonth());
  const [items, setItems] = useState<ConfirmationListItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const load = useCallback(async (m: string) => {
    setError(null);
    setItems(null);
    try {
      const res = await api().get<{ items: ConfirmationListItem[] }>(
        `/confirmations?month=${m}`,
      );
      setItems(res.data.items ?? []);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
      setItems([]);
    }
  }, []);

  useEffect(() => {
    void load(month);
  }, [month, load]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  return (
    <>
      <h1 className="page-title">확인서</h1>
      <p className="page-sub">
        작업확인서를 작성해 상대에게 보내고, 서명 상태를 관리합니다.
      </p>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}

      <div className="w-toolbar">
        <MonthNav month={month} onChange={setMonth} />
        <button
          className="btn btn-primary"
          onClick={() => setShowForm(true)}
          style={{ maxWidth: 200 }}
        >
          <Plus />
          확인서 작성
        </button>
      </div>

      {error ? (
        <p style={{ color: 'var(--receivable)' }}>{error}</p>
      ) : items === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : items.length === 0 ? (
        <div className="card empty">
          <FileText width={30} height={30} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            이번 달 확인서가 없습니다
          </p>
        </div>
      ) : (
        <div className="card">
          {items.map((c) => {
            const b = confStatusBadge(c.status);
            return (
              <button
                key={c.id}
                className="row-item"
                style={{
                  width: '100%',
                  background: 'none',
                  border: 0,
                  borderBottom: '1px solid var(--border)',
                  textAlign: 'left',
                  cursor: 'pointer',
                }}
                onClick={() => setSelectedId(c.id)}
              >
                <span className="avatar">
                  {(c.companyName || c.siteName).slice(0, 1)}
                </span>
                <span style={{ flex: 1, minWidth: 0 }}>
                  <span style={{ display: 'block', fontWeight: 700 }}>
                    {c.siteName}
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
                    {c.companyName} · {dateLabel(c.date)} · {c.rateTypeLabel}
                  </span>
                </span>
                <span style={{ textAlign: 'right' }}>
                  <span
                    className="num"
                    style={{ display: 'block', fontWeight: 800 }}
                  >
                    {won(c.total)}원
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

      {showForm ? (
        <CreateForm
          onClose={() => setShowForm(false)}
          onCreated={() => {
            setShowForm(false);
            flash('확인서를 작성했습니다.');
            void load(month);
          }}
        />
      ) : null}

      {selectedId ? (
        <DetailModal
          id={selectedId}
          onClose={() => setSelectedId(null)}
          onChanged={(msg) => {
            if (msg) flash(msg);
            void load(month);
          }}
        />
      ) : null}
    </>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// 작성 폼
// ──────────────────────────────────────────────────────────────────────────
function CreateForm({
  onClose,
  onCreated,
}: {
  onClose: () => void;
  onCreated: () => void;
}) {
  const [date, setDate] = useState(todayStr());
  const [siteName, setSiteName] = useState('');
  const [mode, setMode] = useState<'linked' | 'manual'>('manual');
  const [businessId, setBusinessId] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [contact, setContact] = useState('');
  const [workDescription, setWorkDescription] = useState('');
  const [startTime, setStartTime] = useState('08:00');
  const [endTime, setEndTime] = useState('17:00');
  const [rateType, setRateType] = useState('DAILY');
  const [rate, setRate] = useState('');
  const [quantity, setQuantity] = useState('1');
  const [useEquip, setUseEquip] = useState(false);
  const [eqName, setEqName] = useState('');
  const [eqVehicle, setEqVehicle] = useState('');
  const [eqSpec, setEqSpec] = useState('');
  const [eqGuide, setEqGuide] = useState(false);
  const [connections, setConnections] = useState<ConnectionItem[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const rt = RATE_TYPES.find((r) => r.value === rateType)!;
  const isGongsu = rateType === 'GONGSU';

  useEffect(() => {
    (async () => {
      try {
        const res = await api().get<{ items: ConnectionItem[] }>(
          '/connections',
        );
        const accepted = (res.data.items ?? []).filter(
          (c) => c.role === 'WORKER' && c.status === 'ACCEPTED',
        );
        setConnections(accepted);
        if (accepted.length > 0) {
          setMode('linked');
          setBusinessId(accepted[0].business.id);
        }
      } catch {
        /* 연결 없음 → 수기 입력 유지 */
      }
    })();
  }, []);

  const preview = useMemo(() => {
    const r = parseFloat(rate) || 0;
    const q = parseFloat(quantity) || 0;
    return Math.round(r * q);
  }, [rate, quantity]);

  async function submit() {
    setError(null);
    if (siteName.trim().length < 1) return setError('현장/장소를 입력하세요.');
    if (workDescription.trim().length < 1)
      return setError('작업 내용을 입력하세요.');
    if (mode === 'linked' && !businessId)
      return setError('연결 사업장을 선택하세요.');
    if (mode === 'manual' && companyName.trim().length < 1)
      return setError('상대(회사명)를 입력하세요.');
    const r = parseFloat(rate);
    const q = parseFloat(quantity);
    if (!Number.isFinite(r) || r <= 0) return setError('단가를 입력하세요.');
    if (!Number.isFinite(q) || q <= 0) return setError('수량을 입력하세요.');
    if (isGongsu && Math.abs(q * 10 - Math.round(q * 10)) > 1e-9)
      return setError('공수는 0.1 단위여야 합니다 (예: 0.5, 1, 1.5).');

    const body: Record<string, unknown> = {
      date,
      siteName: siteName.trim(),
      workDescription: workDescription.trim(),
      startTime,
      endTime,
      rateType,
      rate: r,
      quantity: q,
    };
    if (mode === 'linked') body.businessId = businessId;
    else {
      body.companyName = companyName.trim();
      if (contact.trim()) body.contact = contact.trim();
    }
    if (useEquip && (eqName.trim() || eqVehicle.trim())) {
      body.equipmentSection = {
        name: eqName.trim() || undefined,
        vehicleNumber: eqVehicle.trim() || undefined,
        spec: eqSpec.trim() || undefined,
        guide: eqGuide,
      };
    }
    setBusy(true);
    try {
      await api().post('/confirmations', body);
      onCreated();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '작성에 실패했습니다.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <ModalHead title="확인서 작성" onClose={onClose} />
        <div style={{ padding: '8px 20px 22px' }}>
          <div className="field">
            <label className="flabel" htmlFor="cf-date">
              작업 날짜
            </label>
            <input
              id="cf-date"
              type="date"
              className="input num"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>
          <div className="field">
            <label className="flabel" htmlFor="cf-site">
              현장 / 장소
            </label>
            <input
              id="cf-site"
              className="input"
              placeholder="예) 반포 자이 신축현장"
              value={siteName}
              onChange={(e) => setSiteName(e.target.value)}
              maxLength={100}
            />
          </div>

          {/* 상대 */}
          <div className="field">
            <span className="flabel">상대 (발주처)</span>
            <div className="w-btn-row" style={{ marginBottom: 8 }}>
              <button
                type="button"
                className={`w-tab${mode === 'linked' ? ' on' : ''}`}
                style={{ flex: 1 }}
                onClick={() => setMode('linked')}
                disabled={connections.length === 0}
              >
                연결 사업장
              </button>
              <button
                type="button"
                className={`w-tab${mode === 'manual' ? ' on' : ''}`}
                style={{ flex: 1 }}
                onClick={() => setMode('manual')}
              >
                직접 입력
              </button>
            </div>
            {mode === 'linked' ? (
              connections.length === 0 ? (
                <p style={{ color: 'var(--ink-2)', fontSize: 14 }}>
                  연결된 사업장이 없습니다. 직접 입력을 사용하세요.
                </p>
              ) : (
                <select
                  className="input"
                  value={businessId}
                  onChange={(e) => setBusinessId(e.target.value)}
                >
                  {connections.map((c) => (
                    <option key={c.business.id} value={c.business.id}>
                      {c.business.name}
                    </option>
                  ))}
                </select>
              )
            ) : (
              <>
                <input
                  className="input"
                  placeholder="회사명 (예) 대성건설"
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  maxLength={100}
                  style={{ marginBottom: 8 }}
                />
                <input
                  className="input num"
                  placeholder="연락처 (선택) 010-0000-0000"
                  value={contact}
                  onChange={(e) => setContact(e.target.value)}
                  maxLength={50}
                />
              </>
            )}
          </div>

          <div className="field">
            <label className="flabel" htmlFor="cf-work">
              작업 내용
            </label>
            <textarea
              id="cf-work"
              className="input"
              rows={2}
              placeholder="예) 형틀 목공, 3층 벽체"
              value={workDescription}
              onChange={(e) => setWorkDescription(e.target.value)}
              maxLength={1000}
              style={{ resize: 'vertical' }}
            />
          </div>

          <div style={{ display: 'flex', gap: 10 }}>
            <div className="field" style={{ flex: 1 }}>
              <label className="flabel" htmlFor="cf-start">
                시작
              </label>
              <input
                id="cf-start"
                type="time"
                className="input num"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
              />
            </div>
            <div className="field" style={{ flex: 1 }}>
              <label className="flabel" htmlFor="cf-end">
                종료
              </label>
              <input
                id="cf-end"
                type="time"
                className="input num"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
              />
            </div>
          </div>

          {/* 단가 */}
          <div className="field">
            <span className="flabel">단가 유형</span>
            <div className="w-btn-row">
              {RATE_TYPES.map((r) => (
                <button
                  key={r.value}
                  type="button"
                  className={`w-tab${rateType === r.value ? ' on' : ''}`}
                  style={{ flex: 1 }}
                  onClick={() => {
                    setRateType(r.value);
                    if (r.value === 'GONGSU' && !quantity) setQuantity('1');
                  }}
                >
                  {r.label}
                </button>
              ))}
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <div className="field" style={{ flex: 1.3 }}>
              <label className="flabel" htmlFor="cf-rate">
                단가 (원)
              </label>
              <input
                id="cf-rate"
                className="input num"
                inputMode="numeric"
                placeholder="예) 180000"
                value={rate}
                onChange={(e) =>
                  setRate(e.target.value.replace(/[^\d]/g, ''))
                }
              />
            </div>
            <div className="field" style={{ flex: 1 }}>
              <label className="flabel" htmlFor="cf-qty">
                수량 ({rt.unit})
              </label>
              <input
                id="cf-qty"
                type="number"
                className="input num"
                inputMode="decimal"
                step={isGongsu ? 0.5 : 1}
                min={isGongsu ? 0.5 : 1}
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
              />
            </div>
          </div>
          <div
            className="card"
            style={{
              padding: '12px 16px',
              margin: '4px 0 14px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              background: 'var(--surface-2)',
            }}
          >
            <span style={{ color: 'var(--ink-2)', fontWeight: 600 }}>
              예상 금액
            </span>
            <span
              className="num"
              style={{ fontSize: 20, fontWeight: 800 }}
            >
              {won(preview)}원
            </span>
          </div>

          {/* 장비 섹션 */}
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => setUseEquip((v) => !v)}
            style={{ marginBottom: useEquip ? 12 : 0 }}
          >
            <Truck width={18} height={18} />
            {useEquip ? '장비 섹션 접기' : '장비 섹션 추가'}
          </button>
          {useEquip ? (
            <div
              className="card"
              style={{ padding: 16, marginBottom: 14 }}
            >
              <div style={{ display: 'flex', gap: 10 }}>
                <div className="field" style={{ flex: 1 }}>
                  <label className="flabel" htmlFor="cf-eqname">
                    장비명
                  </label>
                  <input
                    id="cf-eqname"
                    className="input"
                    placeholder="예) 25톤 크레인"
                    value={eqName}
                    onChange={(e) => setEqName(e.target.value)}
                    maxLength={50}
                  />
                </div>
                <div className="field" style={{ flex: 1 }}>
                  <label className="flabel" htmlFor="cf-eqveh">
                    차량번호
                  </label>
                  <input
                    id="cf-eqveh"
                    className="input num"
                    placeholder="예) 12가3456"
                    value={eqVehicle}
                    onChange={(e) => setEqVehicle(e.target.value)}
                    maxLength={30}
                  />
                </div>
              </div>
              <div className="field" style={{ marginBottom: 8 }}>
                <label className="flabel" htmlFor="cf-eqspec">
                  규격 (선택)
                </label>
                <input
                  id="cf-eqspec"
                  className="input"
                  placeholder="예) 붐 40m"
                  value={eqSpec}
                  onChange={(e) => setEqSpec(e.target.value)}
                  maxLength={30}
                />
              </div>
              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  fontSize: 15,
                  cursor: 'pointer',
                }}
              >
                <input
                  type="checkbox"
                  checked={eqGuide}
                  onChange={(e) => setEqGuide(e.target.checked)}
                  style={{ width: 18, height: 18 }}
                />
                유도원 포함
              </label>
            </div>
          ) : null}

          {error ? (
            <p style={{ color: 'var(--receivable)', marginTop: 6 }}>{error}</p>
          ) : null}
          <button
            className="btn btn-primary btn-lg"
            style={{ marginTop: 8 }}
            onClick={submit}
            disabled={busy}
          >
            {busy ? <span className="spinner" /> : <FileText />}
            확인서 만들기
          </button>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// 상세 모달 (PaperConfirmation 재사용 + 전송/PDF/무효화)
// ──────────────────────────────────────────────────────────────────────────
function DetailModal({
  id,
  onClose,
  onChanged,
}: {
  id: string;
  onClose: () => void;
  onChanged: (msg?: string) => void;
}) {
  const { me } = useWorker();
  const [c, setC] = useState<ConfirmationListItem | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [shareUrl, setShareUrl] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      const res = await api().get<ConfirmationListItem>(`/confirmations/${id}`);
      setC(res.data);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
    }
  }, [id]);

  useEffect(() => {
    void load();
  }, [load]);

  const view: ConfirmationView | null = useMemo(() => {
    if (!c) return null;
    const calc = c.amountCalc as ConfirmationView['amountCalc'];
    return {
      status: c.status,
      signed: c.status === 'SIGNED',
      date: c.date,
      companyName: c.companyName,
      contact: c.contact,
      workerName: me?.name ?? '작업자',
      site: c.siteName,
      workContent: c.workDescription,
      startTime: c.startTime,
      endTime: c.endTime,
      rateTypeLabel: c.rateTypeLabel,
      amountCalc: calc,
      total: c.total,
      equipmentSection:
        c.equipmentSection as ConfirmationView['equipmentSection'],
      teamEntries: c.teamEntries as ConfirmationView['teamEntries'],
      isTeam: !!c.teamId,
      notes: c.notes,
      signerName: c.signerName,
      signedAt: c.signedAt,
    };
  }, [c, me]);

  async function send() {
    setBusy('send');
    setError(null);
    try {
      const res = await api().post<{ url: string; alimtalkSent?: boolean }>(
        `/confirmations/${id}/send`,
      );
      setShareUrl(res.data.url);
      const ok = await copyText(res.data.url);
      onChanged(ok ? '전송 완료 · 링크를 복사했습니다.' : '전송 완료');
      await load();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '전송 실패');
    } finally {
      setBusy(null);
    }
  }

  async function pdf() {
    setBusy('pdf');
    setError(null);
    try {
      await openAuthedPdf(`/confirmations/${id}/pdf`);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'PDF 열기 실패');
    } finally {
      setBusy(null);
    }
  }

  async function revoke() {
    setBusy('revoke');
    setError(null);
    try {
      await api().post(`/confirmations/${id}/revoke`);
      onChanged('링크를 무효화했습니다.');
      setShareUrl(null);
      await load();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '무효화 실패');
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <ModalHead title="확인서 상세" onClose={onClose} />
        <div style={{ padding: '8px 20px 22px' }}>
          {error ? (
            <p style={{ color: 'var(--receivable)' }}>{error}</p>
          ) : null}
          {!view ? (
            <div className="empty">
              <span className="spinner" />
            </div>
          ) : (
            <>
              <PaperConfirmation c={view} />

              {shareUrl ? (
                <div
                  className="warn-banner"
                  style={{ marginTop: 14 }}
                  role="status"
                >
                  <span
                    className="num"
                    style={{ wordBreak: 'break-all', fontSize: 13 }}
                  >
                    {shareUrl}
                  </span>
                </div>
              ) : null}

              <div className="w-btn-row" style={{ marginTop: 16 }}>
                {c && c.status !== 'SIGNED' ? (
                  <button
                    className="btn btn-primary"
                    onClick={send}
                    disabled={busy !== null}
                    style={{ flex: 1, minWidth: 150 }}
                  >
                    {busy === 'send' ? (
                      <span className="spinner" />
                    ) : (
                      <Send width={18} height={18} />
                    )}
                    {c.status === 'DRAFT' ? '전송 · 링크 복사' : '링크 다시 복사'}
                  </button>
                ) : null}
                <button
                  className="btn btn-ghost"
                  onClick={pdf}
                  disabled={busy !== null}
                  style={{ flex: 1, minWidth: 120 }}
                >
                  {busy === 'pdf' ? (
                    <span className="spinner" />
                  ) : (
                    <Download width={18} height={18} />
                  )}
                  PDF
                </button>
                {shareUrl ? (
                  <button
                    className="btn btn-ghost"
                    onClick={() => copyText(shareUrl)}
                    style={{ flex: '0 0 auto' }}
                  >
                    <Copy width={18} height={18} />
                    복사
                  </button>
                ) : null}
              </div>

              {c && c.status === 'SENT' ? (
                <button
                  className="btn btn-ghost"
                  onClick={revoke}
                  disabled={busy !== null}
                  style={{
                    marginTop: 8,
                    width: '100%',
                    color: 'var(--receivable)',
                  }}
                >
                  {busy === 'revoke' ? (
                    <span className="spinner" />
                  ) : (
                    <AlertTriangle width={18} height={18} />
                  )}
                  공유 링크 무효화
                </button>
              ) : null}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function ModalHead({
  title,
  onClose,
}: {
  title: string;
  onClose: () => void;
}) {
  return (
    <div style={{ padding: '18px 20px 4px' }}>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <h2 style={{ fontSize: 20, fontWeight: 800, margin: 0 }}>{title}</h2>
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
  );
}
