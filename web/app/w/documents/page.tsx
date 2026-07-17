'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { api, ApiError, absoluteUrl } from '@/lib/api';
import { dateLabel, ddayBadge } from '@/lib/format';
import {
  Folder,
  Upload,
  Send,
  Copy,
  Trash,
  X,
  CheckCircle,
  AlertTriangle,
} from '@/components/Icons';
import { copyText } from '@/lib/worker';
import { type DocumentItem } from '../types';

const DOCUMENT_TYPES = [
  '신분증',
  '사업자등록증',
  '통장사본',
  '자격증',
  '면허증',
  '경력증명서',
  '보험증권',
  '안전보건교육수료증',
  '건강진단서',
  '기타',
];

interface ShareItem {
  id: string;
  shareToken: string;
  expiresAt: string;
  revokedAt: string | null;
  active: boolean;
  viewCount: number;
  documents: { documentId: string; type: string; servesMasked: boolean }[];
}

export default function DocumentsPage() {
  const [tab, setTab] = useState<'docs' | 'shares'>('docs');
  const [docs, setDocs] = useState<DocumentItem[] | null>(null);
  const [shares, setShares] = useState<ShareItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [showUpload, setShowUpload] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [shareUrl, setShareUrl] = useState<string | null>(null);
  const [sharing, setSharing] = useState(false);

  const loadDocs = useCallback(async () => {
    try {
      const res = await api().get<{ items: DocumentItem[] }>('/documents');
      setDocs(res.data.items ?? []);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
      setDocs([]);
    }
  }, []);

  const loadShares = useCallback(async () => {
    try {
      const res = await api().get<{ items: ShareItem[] }>('/document-shares');
      setShares(res.data.items ?? []);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '불러오기 실패');
      setShares([]);
    }
  }, []);

  useEffect(() => {
    void loadDocs();
    void loadShares();
  }, [loadDocs, loadShares]);

  function flash(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  }

  function toggle(id: string) {
    setSelected((prev) => {
      const n = new Set(prev);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });
    setShareUrl(null);
  }

  async function createShare() {
    if (selected.size === 0) return;
    setSharing(true);
    setError(null);
    try {
      const res = await api().post<{ url: string }>('/document-shares', {
        documentIds: [...selected],
        expiresInDays: 7,
      });
      setShareUrl(res.data.url);
      const ok = await copyText(res.data.url);
      flash(ok ? '공유 링크를 복사했습니다.' : '공유 링크를 만들었습니다.');
      void loadShares();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '공유 생성 실패');
    } finally {
      setSharing(false);
    }
  }

  async function revokeShare(id: string) {
    try {
      await api().delete(`/document-shares/${id}`);
      flash('공유를 무효화했습니다.');
      void loadShares();
    } catch (e) {
      flash(e instanceof ApiError ? e.message : '무효화 실패');
    }
  }

  return (
    <>
      <h1 className="page-title">서류</h1>
      <p className="page-sub">
        서류를 보관하고 만료를 관리하며, 선택한 서류를 묶어 링크로 공유합니다.
      </p>

      {toast ? (
        <div className="sign-stamp" role="status" style={{ marginBottom: 16 }}>
          <CheckCircle width={20} height={20} />
          {toast}
        </div>
      ) : null}

      <div className="w-tabs">
        <button
          className={`w-tab${tab === 'docs' ? ' on' : ''}`}
          onClick={() => setTab('docs')}
        >
          내 서류
        </button>
        <button
          className={`w-tab${tab === 'shares' ? ' on' : ''}`}
          onClick={() => setTab('shares')}
        >
          공유 관리
        </button>
      </div>

      {error ? <p style={{ color: 'var(--receivable)' }}>{error}</p> : null}

      {tab === 'docs' ? (
        <>
          <div className="w-toolbar">
            <p style={{ margin: 0, color: 'var(--ink-2)', fontSize: 14 }}>
              공유할 서류를 선택하세요.
            </p>
            <button
              className="btn btn-primary"
              onClick={() => setShowUpload(true)}
              style={{ maxWidth: 160 }}
            >
              <Upload />
              업로드
            </button>
          </div>

          {/* 마스킹 백로그 안내 */}
          <div
            className="warn-banner"
            role="note"
            style={{ marginBottom: 16 }}
          >
            <AlertTriangle width={18} height={18} />
            <span>
              민감 정보 마스킹(가림) 편집은 <b>모바일 앱</b>에서 지원합니다. 웹은
              원본/앱에서 만든 마스킹본을 공유합니다.
            </span>
          </div>

          {docs === null ? (
            <div className="empty">
              <span className="spinner" />
            </div>
          ) : docs.length === 0 ? (
            <div className="card empty">
              <Folder width={30} height={30} />
              <p style={{ fontWeight: 700, marginTop: 8 }}>
                보관된 서류가 없습니다
              </p>
            </div>
          ) : (
            <>
              <div className="card">
                {docs.map((d) => {
                  const on = selected.has(d.id);
                  const badge = d.dday !== null ? ddayBadge(d.dday) : null;
                  return (
                    <div
                      key={d.id}
                      className={`checkrow${on ? ' on' : ''}`}
                      onClick={() => toggle(d.id)}
                    >
                      <span className="checkbox">
                        {on ? <CheckCircle width={16} height={16} /> : null}
                      </span>
                      <span className="avatar">
                        <Folder width={20} height={20} />
                      </span>
                      <span style={{ flex: 1, minWidth: 0 }}>
                        <span
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 6,
                            fontWeight: 700,
                          }}
                        >
                          {d.type}
                          {d.hasMask ? (
                            <span className="badge accent">마스킹본</span>
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
                          {d.expiryDate
                            ? `만료 ${dateLabel(d.expiryDate)}`
                            : '만료일 없음'}
                        </span>
                      </span>
                      {badge ? (
                        <span className={`badge ${badge.cls}`}>{badge.text}</span>
                      ) : null}
                    </div>
                  );
                })}
              </div>

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

              {selected.size > 0 ? (
                <div
                  style={{
                    position: 'sticky',
                    bottom: 0,
                    marginTop: 16,
                    background: 'var(--bg)',
                    paddingTop: 8,
                  }}
                >
                  <button
                    className="btn btn-primary btn-lg"
                    onClick={createShare}
                    disabled={sharing}
                  >
                    {sharing ? <span className="spinner" /> : <Send />}
                    선택한 {selected.size}건 묶음 공유 링크 만들기
                  </button>
                </div>
              ) : null}
            </>
          )}
        </>
      ) : (
        <SharesTab
          shares={shares}
          onRevoke={revokeShare}
          onCopy={async (token) => {
            const url = absoluteUrl(`/s/${token}`);
            const ok = await copyText(url);
            flash(ok ? '링크를 복사했습니다.' : url);
          }}
        />
      )}

      {showUpload ? (
        <UploadModal
          onClose={() => setShowUpload(false)}
          onUploaded={() => {
            setShowUpload(false);
            flash('서류를 업로드했습니다.');
            void loadDocs();
          }}
        />
      ) : null}
    </>
  );
}

function SharesTab({
  shares,
  onRevoke,
  onCopy,
}: {
  shares: ShareItem[] | null;
  onRevoke: (id: string) => void;
  onCopy: (token: string) => void;
}) {
  if (shares === null)
    return (
      <div className="empty">
        <span className="spinner" />
      </div>
    );
  if (shares.length === 0)
    return (
      <div className="card empty">
        <Send width={30} height={30} />
        <p style={{ fontWeight: 700, marginTop: 8 }}>공유한 링크가 없습니다</p>
      </div>
    );
  return (
    <div className="card">
      {shares.map((s) => (
        <div
          key={s.id}
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
              서류 {s.documents.length}건
              <span className={`badge ${s.active ? 'done' : 'calm'}`}>
                {s.active ? '유효' : '만료·무효'}
              </span>
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
              {s.documents.map((d) => d.type).join(', ')}
            </span>
            <span
              className="num"
              style={{ display: 'block', fontSize: 13, color: 'var(--ink-3)' }}
            >
              열람 {s.viewCount}회 · 만료 {dateLabel(s.expiresAt)}
            </span>
          </span>
          <div className="w-btn-row">
            <button
              className="btn btn-ghost"
              style={{ height: 40, minHeight: 40, padding: '0 12px' }}
              onClick={() => onCopy(s.shareToken)}
              disabled={!s.active}
            >
              <Copy width={16} height={16} />
              링크
            </button>
            {s.active ? (
              <button
                className="btn btn-ghost"
                style={{
                  height: 40,
                  minHeight: 40,
                  padding: '0 12px',
                  color: 'var(--receivable)',
                }}
                onClick={() => onRevoke(s.id)}
              >
                <Trash width={16} height={16} />
                무효화
              </button>
            ) : null}
          </div>
        </div>
      ))}
    </div>
  );
}

function UploadModal({
  onClose,
  onUploaded,
}: {
  onClose: () => void;
  onUploaded: () => void;
}) {
  const fileRef = useRef<HTMLInputElement>(null);
  const [type, setType] = useState(DOCUMENT_TYPES[0]);
  const [issueDate, setIssueDate] = useState('');
  const [expiryDate, setExpiryDate] = useState('');
  const [fileName, setFileName] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    setError(null);
    const file = fileRef.current?.files?.[0];
    if (!file) return setError('업로드할 파일을 선택하세요.');
    const fd = new FormData();
    fd.append('file', file);
    fd.append('type', type);
    fd.append('ownerType', 'PROFILE');
    if (issueDate) fd.append('issueDate', issueDate);
    if (expiryDate) fd.append('expiryDate', expiryDate);
    setBusy(true);
    try {
      await api().post('/documents', fd);
      onUploaded();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : '업로드 실패');
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
              서류 업로드
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
          <div className="field">
            <label className="flabel" htmlFor="up-type">
              서류 유형
            </label>
            <select
              id="up-type"
              className="input"
              value={type}
              onChange={(e) => setType(e.target.value)}
            >
              {DOCUMENT_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <span className="flabel">파일 (이미지 또는 PDF)</span>
            <button
              type="button"
              className="btn btn-ghost btn-lg"
              onClick={() => fileRef.current?.click()}
              style={{ justifyContent: 'flex-start' }}
            >
              <Upload />
              {fileName ?? '파일 선택'}
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/*,application/pdf"
              style={{ display: 'none' }}
              onChange={(e) =>
                setFileName(e.target.files?.[0]?.name ?? null)
              }
            />
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <div className="field" style={{ flex: 1 }}>
              <label className="flabel" htmlFor="up-issue">
                발급일 (선택)
              </label>
              <input
                id="up-issue"
                type="date"
                className="input num"
                value={issueDate}
                onChange={(e) => setIssueDate(e.target.value)}
              />
            </div>
            <div className="field" style={{ flex: 1 }}>
              <label className="flabel" htmlFor="up-expiry">
                만료일 (선택)
              </label>
              <input
                id="up-expiry"
                type="date"
                className="input num"
                value={expiryDate}
                onChange={(e) => setExpiryDate(e.target.value)}
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
            {busy ? <span className="spinner" /> : <Upload />}
            업로드
          </button>
        </div>
      </div>
    </div>
  );
}
