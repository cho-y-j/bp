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
  FileText,
  Chevron,
  Home,
} from '@/components/Icons';
import {
  BizContext,
  type Business,
  type Me,
} from './biz-context';

const NAV = [
  { href: '/biz/inbox', label: '수신함', Icon: Inbox },
  { href: '/biz/settlements', label: '정산', Icon: Wallet },
  { href: '/biz/workers', label: '작업자·지시', Icon: Users },
  { href: '/biz/contracts', label: '계약서', Icon: FileText },
  { href: '/biz/safety', label: '안전 리포트', Icon: Shield },
];

/** 선택된 사업장 id 를 저장하는 localStorage 키. */
const SELECTED_BIZ_KEY = 'jakeobon_selected_biz';

export default function BizLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [me, setMe] = useState<Me | null>(null);
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
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
            businesses: Business[];
          }>('/businesses/mine');
          if (!alive) return;
          const list = Array.isArray(biz.data.businesses)
            ? biz.data.businesses
            : [];
          setBusinesses(list);
          // 저장된 선택값이 소유 목록에 있으면 유지, 없으면 첫 사업장.
          const saved =
            typeof window !== 'undefined'
              ? window.localStorage.getItem(SELECTED_BIZ_KEY)
              : null;
          const valid = saved && list.some((b) => b.id === saved) ? saved : null;
          setSelectedId(valid ?? (list.length ? list[0].id : null));
        } else {
          setBusinesses([]);
          setSelectedId(null);
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

  const business =
    businesses.find((b) => b.id === selectedId) ?? businesses[0] ?? null;

  function selectBusiness(id: string) {
    setSelectedId(id);
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(SELECTED_BIZ_KEY, id);
    }
  }

  function logout() {
    clearToken();
    if (typeof window !== 'undefined') {
      window.localStorage.removeItem(SELECTED_BIZ_KEY);
    }
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

  // 다중 소유일 때만 전환 드롭다운 노출(단일 사업장은 기존과 동일).
  const multi = businesses.length > 1;
  const switcher =
    business && multi ? (
      <BusinessSwitcher
        businesses={businesses}
        selectedId={business.id}
        onSelect={selectBusiness}
      />
    ) : null;

  return (
    <BizContext.Provider
      value={{
        me,
        business,
        businesses,
        selectBusiness,
        reload: () => setTick((t) => t + 1),
      }}
    >
      <div className="biz-shell">
        <aside className="biz-sidebar">
          <div style={{ padding: '4px 12px 18px' }}>
            <p className="brand-kicker">
              <span className="brand-dot" />
              작업온
            </p>
            {switcher ? (
              <div style={{ marginTop: 12 }}>{switcher}</div>
            ) : (
              <div
                style={{ marginTop: 10, fontSize: 15, color: 'var(--ink-2)' }}
              >
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
            )}
          </div>
          {nav}
          <div
            style={{
              marginTop: 'auto',
              borderTop: '1px solid var(--border)',
              paddingTop: 8,
            }}
          >
            <Link
              href="/w/home"
              className="biz-nav-item"
              style={{ color: 'var(--accent-text)', fontWeight: 700 }}
            >
              <Home width={20} height={20} />
              작업자 모드
            </Link>
            <button
              className="biz-nav-item"
              style={{ background: 'none', border: 0, width: '100%' }}
              onClick={logout}
            >
              <Logout width={20} height={20} />
              로그아웃
            </button>
          </div>
        </aside>

        <div className="biz-topbar">
          <div className="biz-topbar-head">
            {switcher ? (
              <span style={{ flex: 1, minWidth: 0, marginRight: 10 }}>
                {switcher}
              </span>
            ) : (
              <span className="biz-topbar-biz">
                <Building
                  width={16}
                  height={16}
                  style={{ verticalAlign: '-3px', marginRight: 6 }}
                />
                {business ? business.name : me?.name || '사업장 모드'}
              </span>
            )}
            <span style={{ display: 'flex', gap: 8, flex: '0 0 auto' }}>
              <Link
                href="/w/home"
                className="biz-topbar-logout"
                style={{ color: 'var(--accent-text)' }}
              >
                <Home width={16} height={16} />
                작업자
              </Link>
              <button
                type="button"
                className="biz-topbar-logout"
                onClick={logout}
              >
                <Logout width={18} height={18} />
                로그아웃
              </button>
            </span>
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

/**
 * 사업장 전환 드롭다운 — 소유 사업장이 2개 이상일 때만 노출.
 * 선택값은 layout 에서 localStorage 에 저장되고 컨텍스트로 전파된다.
 */
function BusinessSwitcher({
  businesses,
  selectedId,
  onSelect,
}: {
  businesses: Business[];
  selectedId: string;
  onSelect: (id: string) => void;
}) {
  return (
    <label
      className="biz-switcher"
      style={{ display: 'block', position: 'relative' }}
    >
      <span
        style={{
          position: 'absolute',
          width: 1,
          height: 1,
          overflow: 'hidden',
          clip: 'rect(0 0 0 0)',
        }}
      >
        사업장 선택
      </span>
      <Building
        width={16}
        height={16}
        aria-hidden
        style={{
          position: 'absolute',
          left: 12,
          top: '50%',
          transform: 'translateY(-50%)',
          color: 'var(--accent-text)',
          pointerEvents: 'none',
        }}
      />
      <select
        className="input"
        aria-label="사업장 선택"
        value={selectedId}
        onChange={(e) => onSelect(e.target.value)}
        style={{
          width: '100%',
          paddingLeft: 36,
          paddingRight: 28,
          fontWeight: 700,
          height: 44,
          minHeight: 44,
          cursor: 'pointer',
          appearance: 'none',
        }}
      >
        {businesses.map((b) => (
          <option key={b.id} value={b.id}>
            {b.name}
          </option>
        ))}
      </select>
      <Chevron
        width={16}
        height={16}
        aria-hidden
        style={{
          position: 'absolute',
          right: 10,
          top: '50%',
          transform: 'translateY(-50%) rotate(90deg)',
          color: 'var(--ink-3)',
          pointerEvents: 'none',
        }}
      />
    </label>
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
      <Link
        href="/w/home"
        className="btn btn-ghost"
        style={{ marginTop: 14, maxWidth: 240 }}
      >
        <Home width={18} height={18} />
        작업자 모드로 돌아가기
      </Link>
    </div>
  );
}
