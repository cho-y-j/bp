'use client';

import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { api, getToken, clearToken, ApiError } from '@/lib/api';
import {
  Inbox,
  Wallet,
  Users,
  Shield,
  Building,
  Logout,
  Plus,
} from '@/components/Icons';
import { BizContext, type BizContextValue, type Me } from './biz-context';

const NAV = [
  { href: '/biz/inbox', label: '수신함', Icon: Inbox },
  { href: '/biz/settlements', label: '정산', Icon: Wallet },
  { href: '/biz/workers', label: '작업자·지시', Icon: Users },
  { href: '/biz/safety', label: '안전 리포트', Icon: Shield },
];

export default function BizLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [me, setMe] = useState<Me | null>(null);
  const [business, setBusiness] = useState<BizContextValue['business']>(null);
  const [loading, setLoading] = useState(true);
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (!getToken()) {
      router.replace(
        `/login?next=${encodeURIComponent(pathname)}`,
      );
      return;
    }
    let alive = true;
    (async () => {
      setLoading(true);
      try {
        const meRes = await api().get<Me>('/me');
        if (!alive) return;
        setMe(meRes.data);
        if (meRes.data.hasBusiness) {
          const biz = await api().get<{
            count: number;
            businesses: { id: string; name: string; inviteCode?: string }[];
          }>('/businesses/mine');
          if (!alive) return;
          const list = biz.data.businesses;
          setBusiness(Array.isArray(list) && list.length ? list[0] : null);
        } else {
          setBusiness(null);
        }
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) return; // 인터셉터가 리다이렉트
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, [router, pathname, tick]);

  function logout() {
    clearToken();
    router.replace('/login');
  }

  const nav = (
    <>
      {NAV.map(({ href, label, Icon }) => {
        const active = pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            className={`biz-nav-item${active ? ' active' : ''}`}
          >
            <Icon width={20} height={20} />
            {label}
          </Link>
        );
      })}
    </>
  );

  return (
    <BizContext.Provider
      value={{ me, business, reload: () => setTick((t) => t + 1) }}
    >
      <div className="biz-shell">
        <aside className="biz-sidebar">
          <div style={{ padding: '4px 12px 18px' }}>
            <p className="brand-kicker">
              <span className="brand-dot" />
              작업온
            </p>
            <div style={{ marginTop: 10, fontSize: 15, color: 'var(--ink-2)' }}>
              {business ? (
                <>
                  <Building
                    width={16}
                    height={16}
                    style={{ verticalAlign: '-3px', marginRight: 6 }}
                  />
                  <b style={{ color: 'var(--ink)' }}>{business.name}</b>
                </>
              ) : (
                me?.name || '사업장 모드'
              )}
            </div>
          </div>
          {nav}
          <button
            className="biz-nav-item"
            style={{ marginTop: 'auto', background: 'none', border: 0 }}
            onClick={logout}
          >
            <Logout width={20} height={20} />
            로그아웃
          </button>
        </aside>

        <div className="biz-topbar">
          <div className="biz-topbar-head">
            <span className="biz-topbar-biz">
              <Building
                width={16}
                height={16}
                style={{ verticalAlign: '-3px', marginRight: 6 }}
              />
              {business ? business.name : me?.name || '사업장 모드'}
            </span>
            <button
              type="button"
              className="biz-topbar-logout"
              onClick={logout}
            >
              <Logout width={18} height={18} />
              로그아웃
            </button>
          </div>
          <div className="biz-topbar-nav">{nav}</div>
        </div>

        <main className="biz-main">
          {loading ? (
            <div className="empty">
              <span className="spinner" />
            </div>
          ) : me && !me.hasBusiness ? (
            <BusinessGate onCreated={() => setTick((t) => t + 1)} />
          ) : (
            children
          )}
        </main>
      </div>
    </BizContext.Provider>
  );
}

/** 사업장 미보유 시 생성 유도 화면 (웹은 사업장 중심). */
function BusinessGate({ onCreated }: { onCreated: () => void }) {
  const [name, setName] = useState('');
  const [bizNo, setBizNo] = useState('');
  const [addr, setAddr] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function create() {
    setError(null);
    if (name.trim().length < 1) {
      setError('상호를 입력하세요.');
      return;
    }
    setBusy(true);
    try {
      await api().post('/businesses', {
        name: name.trim(),
        businessNumber: bizNo.trim() || undefined,
        address: addr.trim() || undefined,
      });
      onCreated();
    } catch (e) {
      setError(
        e instanceof ApiError ? e.message : '사업장 생성에 실패했습니다.',
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ maxWidth: 480 }}>
      <span style={{ color: 'var(--accent-text)' }}>
        <Building width={30} height={30} />
      </span>
      <h1 className="page-title" style={{ marginTop: 10 }}>
        사업장을 먼저 만들어 주세요
      </h1>
      <p className="page-sub">
        작업온 웹은 사업장 중심입니다. 사업장을 만들면 확인서 수신·정산·안전관리를
        시작할 수 있습니다.
      </p>
      <div className="card" style={{ padding: 20 }}>
        <div className="field">
          <label className="flabel" htmlFor="bname">
            상호 *
          </label>
          <input
            id="bname"
            className="input"
            placeholder="예) 대성건설"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </div>
        <div className="field">
          <label className="flabel" htmlFor="bno">
            사업자등록번호
          </label>
          <input
            id="bno"
            className="input num"
            placeholder="000-00-00000"
            value={bizNo}
            onChange={(e) => setBizNo(e.target.value)}
          />
        </div>
        <div className="field">
          <label className="flabel" htmlFor="baddr">
            주소
          </label>
          <input
            id="baddr"
            className="input"
            placeholder="예) 서울 서초구 반포동"
            value={addr}
            onChange={(e) => setAddr(e.target.value)}
          />
        </div>
        {error ? (
          <p style={{ color: 'var(--receivable)', fontSize: 15 }}>{error}</p>
        ) : null}
        <button
          className="btn btn-primary btn-lg"
          onClick={create}
          disabled={busy}
        >
          {busy ? <span className="spinner" /> : <Plus />}
          사업장 만들기
        </button>
      </div>
    </div>
  );
}
