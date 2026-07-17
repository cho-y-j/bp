'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, ApiError } from '@/lib/api';
import { won, currentMonth, monthLabel, dateLabel, ddayBadge } from '@/lib/format';
import {
  FileText,
  Folder,
  Bell,
  Wallet,
  Plus,
  Chevron,
} from '@/components/Icons';
import {
  type LedgerSummary,
  type ConfirmationListItem,
  type DocumentItem,
  type NotificationItem,
  confStatusBadge,
} from '../types';

export default function WorkerHome() {
  const month = currentMonth();
  const [summary, setSummary] = useState<LedgerSummary | null>(null);
  const [confs, setConfs] = useState<ConfirmationListItem[] | null>(null);
  const [expiring, setExpiring] = useState<DocumentItem[] | null>(null);
  const [notis, setNotis] = useState<NotificationItem[] | null>(null);

  useEffect(() => {
    let alive = true;
    (async () => {
      const results = await Promise.allSettled([
        api().get<LedgerSummary>(`/ledger/summary?month=${month}`),
        api().get<{ items: ConfirmationListItem[] }>(
          `/confirmations?month=${month}`,
        ),
        api().get<{ items: DocumentItem[] }>('/documents/expiring?days=30'),
        api().get<{ items: NotificationItem[] }>('/notifications?unread=true'),
      ]);
      if (!alive) return;
      if (results[0].status === 'fulfilled') setSummary(results[0].value.data);
      else setSummary(null);
      if (results[1].status === 'fulfilled') {
        const items = results[1].value.data.items ?? [];
        // 최근 확인서 5건(날짜 내림차순).
        setConfs(
          [...items]
            .sort((a, b) => b.date.localeCompare(a.date))
            .slice(0, 5),
        );
      } else setConfs([]);
      if (results[2].status === 'fulfilled')
        setExpiring(results[2].value.data.items ?? []);
      else setExpiring([]);
      if (results[3].status === 'fulfilled')
        setNotis(results[3].value.data.items ?? []);
      else setNotis([]);
    })();
    return () => {
      alive = false;
    };
  }, [month]);

  return (
    <>
      <h1 className="page-title">홈</h1>
      <p className="page-sub">
        {monthLabel(month)} 요약과 확인이 필요한 항목입니다.
      </p>

      {/* 이번 달 요약 */}
      <div className="w-stat-grid">
        <StatCard
          label="일한 날"
          value={summary ? `${summary.daysWorked}일` : '—'}
        />
        <StatCard
          label="공수"
          value={summary ? `${summary.totalGongsu}공수` : '—'}
        />
        <StatCard
          label="미수"
          value={summary ? `${won(summary.totalOutstanding)}원` : '—'}
          rcv
        />
        <StatCard
          label="입금"
          value={summary ? `${won(summary.totalPaid)}원` : '—'}
        />
      </div>

      {/* 최근 확인서 */}
      <SectionHead
        title="최근 확인서"
        href="/w/confirmations"
        action="전체 보기"
      />
      {confs === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : confs.length === 0 ? (
        <div className="card empty">
          <FileText width={28} height={28} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            이번 달 확인서가 없습니다
          </p>
          <Link
            href="/w/confirmations"
            className="btn btn-primary"
            style={{ marginTop: 12, maxWidth: 220 }}
          >
            <Plus width={18} height={18} />
            확인서 작성
          </Link>
        </div>
      ) : (
        <div className="card">
          {confs.map((c) => {
            const b = confStatusBadge(c.status);
            return (
              <Link
                key={c.id}
                href="/w/confirmations"
                className="row-item"
                style={{ textDecoration: 'none', color: 'inherit' }}
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
                    {c.companyName} · {dateLabel(c.date)}
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
              </Link>
            );
          })}
        </div>
      )}

      {/* 만료 임박 서류 */}
      <SectionHead
        title="만료 임박 서류"
        href="/w/documents"
        action="서류 관리"
      />
      {expiring === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : expiring.length === 0 ? (
        <div className="card empty">
          <Folder width={28} height={28} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>
            30일 내 만료 예정 서류가 없습니다
          </p>
        </div>
      ) : (
        <div className="card">
          {expiring.map((d) => {
            const badge = ddayBadge(d.dday);
            return (
              <div key={d.id} className="row-item">
                <span className="avatar">
                  <Folder width={20} height={20} />
                </span>
                <span style={{ flex: 1, minWidth: 0 }}>
                  <span style={{ display: 'block', fontWeight: 700 }}>
                    {d.type}
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
                    만료 {d.expiryDate ? dateLabel(d.expiryDate) : '-'}
                  </span>
                </span>
                <span className={`badge ${badge.cls}`}>{badge.text}</span>
              </div>
            );
          })}
        </div>
      )}

      {/* 대기 알림 */}
      <SectionHead title="대기 알림" />
      {notis === null ? (
        <div className="empty">
          <span className="spinner" />
        </div>
      ) : notis.length === 0 ? (
        <div className="card empty">
          <Bell width={28} height={28} />
          <p style={{ fontWeight: 700, marginTop: 8 }}>새 알림이 없습니다</p>
        </div>
      ) : (
        <div className="card">
          {notis.slice(0, 6).map((n) => (
            <div key={n.id} className="row-item">
              <span className="avatar">
                <Bell width={20} height={20} />
              </span>
              <span style={{ flex: 1, minWidth: 0 }}>
                <span style={{ display: 'block', fontWeight: 700 }}>
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
            </div>
          ))}
        </div>
      )}
    </>
  );
}

function StatCard({
  label,
  value,
  rcv,
}: {
  label: string;
  value: string;
  rcv?: boolean;
}) {
  return (
    <div className="card" style={{ padding: 16 }}>
      <div style={{ fontSize: 13, color: 'var(--ink-2)', fontWeight: 600 }}>
        {label}
      </div>
      <div
        className={`num${rcv ? ' money rcv' : ''}`}
        style={{
          fontSize: 22,
          fontWeight: 800,
          marginTop: 4,
          color: rcv ? 'var(--receivable)' : 'var(--ink)',
        }}
      >
        {value}
      </div>
    </div>
  );
}

function SectionHead({
  title,
  href,
  action,
}: {
  title: string;
  href?: string;
  action?: string;
}) {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        margin: '28px 0 12px',
      }}
    >
      <h2 style={{ fontSize: 18, fontWeight: 800, margin: 0 }}>{title}</h2>
      {href && action ? (
        <Link
          href={href}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: 2,
            fontSize: 14,
            fontWeight: 700,
            color: 'var(--accent-text)',
            textDecoration: 'none',
          }}
        >
          {action}
          <Chevron width={16} height={16} />
        </Link>
      ) : null}
    </div>
  );
}
