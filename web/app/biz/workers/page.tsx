'use client';

import { useCallback, useEffect, useState } from 'react';
import { api, ApiError } from '@/lib/api';
import { useBiz } from '../biz-context';
import { Search, Users, Plus, Check, CheckCircle } from '@/components/Icons';

interface WorkerHit {
  profileId: string;
  maskedName: string;
  industryTags: string[];
}
interface Connection {
  id: string;
  status: string;
  role: string;
  business: { id: string; name: string };
  worker: { id: string; name: string };
}

export default function WorkersPage() {
  const { business } = useBiz();
  const [connections, setConnections] = useState<Connection[] | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const loadConns = useCallback(async () => {
    try {
      const res = await api().get<{ items: Connection[] }>('/connections');
      setConnections(res.data.items);
    } catch {
      setConnections([]);
    }
  }, []);

  useEffect(() => {
    void loadConns();
  }, [loadConns]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  const workerConns =
    connections?.filter((c) => c.role === 'BUSINESS') ?? [];
  const acceptedWorkers = workerConns.filter((c) => c.status === 'ACCEPTED');

  return (
    <>
      <h1 className="page-title">작업자 · 지시</h1>
      <p className="page-sub">
        전화번호로 작업자를 찾아 연결하고, 작업을 지시하세요.
      </p>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}

      <SearchConnect
        businessId={business?.id}
        onConnected={() => {
          void loadConns();
          flash('연결 요청을 보냈습니다.');
        }}
      />

      <h2 style={{ fontSize: 19, fontWeight: 800, margin: '28px 0 12px' }}>
        연결된 작업자{' '}
        <span style={{ color: 'var(--ink-3)', fontWeight: 500, fontSize: 15 }}>
          {workerConns.length}명
        </span>
      </h2>
      {connections === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : workerConns.length === 0 ? (
        <div className="card empty">
          <Users width={28} height={28} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            아직 연결된 작업자가 없습니다
          </p>
        </div>
      ) : (
        <div className="card">
          {workerConns.map((c) => (
            <div key={c.id} className="row-item">
              <span className="avatar">{c.worker.name.slice(0, 1)}</span>
              <span style={{ flex: 1, fontSize: 17, fontWeight: 700 }}>
                {c.worker.name}
              </span>
              <span
                className={`badge ${c.status === 'ACCEPTED' ? 'done' : 'calm'}`}
              >
                {c.status === 'ACCEPTED' ? '연결됨' : '수락 대기'}
              </span>
            </div>
          ))}
        </div>
      )}

      <h2 style={{ fontSize: 19, fontWeight: 800, margin: '28px 0 12px' }}>
        작업 지시
      </h2>
      <JobForm
        businessId={business?.id}
        workers={acceptedWorkers.map((c) => ({
          id: c.worker.id,
          name: c.worker.name,
        }))}
        onCreated={() => flash('작업 지시를 등록했습니다.')}
      />
    </>
  );
}

function SearchConnect({
  businessId,
  onConnected,
}: {
  businessId?: string;
  onConnected: () => void;
}) {
  const [phone, setPhone] = useState('');
  const [hits, setHits] = useState<WorkerHit[] | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function search() {
    setError(null);
    setHits(null);
    const p = phone.replace(/\D/g, '');
    if (p.length < 8) {
      setError('전화번호를 정확히 입력하세요.');
      return;
    }
    setBusy(true);
    try {
      const res = await api().get<{ items: WorkerHit[] }>(
        `/workers/search?phone=${p}`,
      );
      setHits(res.data.items);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '검색 실패');
    } finally {
      setBusy(false);
    }
  }

  async function connect(workerProfileId: string) {
    if (!businessId) return;
    setError(null);
    try {
      await api().post('/connections', {
        businessId,
        workerProfileId,
        path: 'PHONE_SEARCH',
      });
      onConnected();
      setHits(null);
      setPhone('');
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '연결 요청 실패');
    }
  }

  return (
    <div className="card" style={{ padding: 18 }}>
      <label className="flabel">전화번호로 작업자 검색</label>
      <div style={{ display: 'flex', gap: 10 }}>
        <input
          className="input num"
          inputMode="numeric"
          placeholder="010-0000-0000"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && search()}
        />
        <button
          className="btn btn-primary"
          style={{ width: 108, flex: '0 0 auto' }}
          onClick={search}
          disabled={busy}
        >
          {busy ? <span className="spinner" /> : <Search width={18} height={18} />}
          검색
        </button>
      </div>
      {error ? (
        <p style={{ color: 'var(--receivable)', marginTop: 10 }}>{error}</p>
      ) : null}
      {hits !== null ? (
        hits.length === 0 ? (
          <p style={{ color: 'var(--ink-2)', marginTop: 12 }}>
            검색 결과가 없습니다. (전화번호 검색에 동의한 작업자만 노출됩니다.)
          </p>
        ) : (
          <div style={{ marginTop: 12 }}>
            {hits.map((h) => (
              <div
                key={h.profileId}
                className="row-item"
                style={{ padding: '12px 0' }}
              >
                <span className="avatar">{h.maskedName.slice(0, 1)}</span>
                <span style={{ flex: 1 }}>
                  <span style={{ fontSize: 17, fontWeight: 700 }}>
                    {h.maskedName}
                  </span>
                  {h.industryTags.length ? (
                    <span
                      style={{
                        display: 'block',
                        fontSize: 14,
                        color: 'var(--ink-2)',
                      }}
                    >
                      {h.industryTags.join(' · ')}
                    </span>
                  ) : null}
                </span>
                <button
                  className="btn btn-ghost"
                  style={{ width: 120, flex: '0 0 auto' }}
                  onClick={() => connect(h.profileId)}
                >
                  <Plus width={18} height={18} />
                  연결 요청
                </button>
              </div>
            ))}
          </div>
        )
      ) : null}
    </div>
  );
}

const RATE_TYPES = [
  { v: 'DAILY', l: '일당' },
  { v: 'HOURLY', l: '시급' },
  { v: 'PER_CASE', l: '건당' },
];

function JobForm({
  businessId,
  workers,
  onCreated,
}: {
  businessId?: string;
  workers: { id: string; name: string }[];
  onCreated: () => void;
}) {
  const [workerId, setWorkerId] = useState('');
  const [site, setSite] = useState('');
  const [datetime, setDatetime] = useState('');
  const [rateType, setRateType] = useState('DAILY');
  const [rate, setRate] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    setError(null);
    if (!workerId) return setError('작업자를 선택하세요.');
    if (!site.trim()) return setError('현장명을 입력하세요.');
    if (!datetime) return setError('작업 일시를 선택하세요.');
    const r = Number(rate.replace(/\D/g, ''));
    if (!r) return setError('단가를 입력하세요.');
    setBusy(true);
    try {
      await api().post('/jobs', {
        businessId,
        workerProfileId: workerId,
        site: site.trim(),
        scheduledAt: new Date(datetime).toISOString(),
        rateType,
        rate: r,
      });
      onCreated();
      setSite('');
      setDatetime('');
      setRate('');
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '지시 등록 실패');
    } finally {
      setBusy(false);
    }
  }

  if (workers.length === 0) {
    return (
      <div className="card empty">
        <p style={{ color: 'var(--ink-2)' }}>
          작업을 지시하려면 먼저 작업자와 연결(수락 완료)되어야 합니다.
        </p>
      </div>
    );
  }

  return (
    <div className="card" style={{ padding: 18 }}>
      <div className="field">
        <label className="flabel">작업자</label>
        <select
          className="input"
          value={workerId}
          onChange={(e) => setWorkerId(e.target.value)}
        >
          <option value="">작업자 선택</option>
          {workers.map((w) => (
            <option key={w.id} value={w.id}>
              {w.name}
            </option>
          ))}
        </select>
      </div>
      <div className="field">
        <label className="flabel">현장</label>
        <input
          className="input"
          placeholder="예) 래미안 원펜타스 3공구"
          value={site}
          onChange={(e) => setSite(e.target.value)}
        />
      </div>
      <div className="field">
        <label className="flabel">작업 일시</label>
        <input
          className="input"
          type="datetime-local"
          value={datetime}
          onChange={(e) => setDatetime(e.target.value)}
        />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
        <div className="field">
          <label className="flabel">단가 유형</label>
          <select
            className="input"
            value={rateType}
            onChange={(e) => setRateType(e.target.value)}
          >
            {RATE_TYPES.map((t) => (
              <option key={t.v} value={t.v}>
                {t.l}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label className="flabel">단가 (원)</label>
          <input
            className="input num"
            inputMode="numeric"
            placeholder="550000"
            value={rate}
            onChange={(e) => setRate(e.target.value)}
          />
        </div>
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
        작업 지시 보내기
      </button>
    </div>
  );
}
