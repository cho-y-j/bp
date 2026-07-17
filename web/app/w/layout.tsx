'use client';

import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { api, getToken, clearToken, ApiError } from '@/lib/api';
import {
  Home,
  FileText,
  Wallet,
  Folder,
  Coins,
  Logout,
  Building,
} from '@/components/Icons';
import { WorkerContext } from './w-context';
import type { Me } from '../biz/biz-context';

const NAV = [
  { href: '/w/home', label: '홈', Icon: Home },
  { href: '/w/confirmations', label: '확인서', Icon: FileText },
  { href: '/w/ledger', label: '장부', Icon: Wallet },
  { href: '/w/documents', label: '서류', Icon: Folder },
  { href: '/w/income', label: '소득', Icon: Coins },
];

export default function WorkerLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [me, setMe] = useState<Me | null>(null);
  const [loading, setLoading] = useState(true);
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (!getToken()) {
      router.replace(`/login?next=${encodeURIComponent(pathname)}`);
      return;
    }
    let alive = true;
    (async () => {
      setLoading(true);
      try {
        const meRes = await api().get<Me>('/me');
        if (alive) setMe(meRes.data);
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

  // 사업장↔작업자 모드 전환: 사업장 보유 시 "사업장 모드", 미보유 시 "사업장 만들기".
  const modeSwitch = (
    <Link
      href={me?.hasBusiness ? '/biz/inbox' : '/biz'}
      className="biz-nav-item"
      style={{ color: 'var(--accent-text)', fontWeight: 700 }}
    >
      <Building width={20} height={20} />
      {me?.hasBusiness ? '사업장 모드' : '사업장 만들기'}
    </Link>
  );

  return (
    <WorkerContext.Provider value={{ me, reload: () => setTick((t) => t + 1) }}>
      <div className="biz-shell">
        <aside className="biz-sidebar">
          <div style={{ padding: '4px 12px 18px' }}>
            <p className="brand-kicker">
              <span className="brand-dot" />
              작업온
            </p>
            <div style={{ marginTop: 10, fontSize: 15, color: 'var(--ink-2)' }}>
              <b style={{ color: 'var(--ink)' }}>{me?.name || '작업자'}</b> 님
              <span style={{ marginLeft: 6, color: 'var(--ink-3)' }}>
                · 작업자 모드
              </span>
            </div>
          </div>
          {nav}
          <div
            style={{
              marginTop: 'auto',
              borderTop: '1px solid var(--border)',
              paddingTop: 8,
            }}
          >
            {modeSwitch}
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
            <span className="biz-topbar-biz">
              <Home
                width={16}
                height={16}
                style={{ verticalAlign: '-3px', marginRight: 6 }}
              />
              {me?.name || '작업자'} · 작업자 모드
            </span>
            <span style={{ display: 'flex', gap: 8, flex: '0 0 auto' }}>
              <Link
                href={me?.hasBusiness ? '/biz/inbox' : '/biz'}
                className="biz-topbar-logout"
                style={{ color: 'var(--accent-text)' }}
              >
                <Building width={16} height={16} />
                {me?.hasBusiness ? '사업장' : '사업장 만들기'}
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
          ) : (
            children
          )}
        </main>
      </div>
    </WorkerContext.Provider>
  );
}
