'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { CheckCircle } from '@/components/Icons';

interface SelfBadge {
  businessId: string;
  businessName: string;
  status: 'EXCELLENT' | 'GOOD' | 'NONE' | 'INSUFFICIENT';
  avgDays: number | null;
  sampleSize: number;
  updatedAt: string | null;
}

/**
 * 사업장 본인용 지급 평판 배지 카드 (P3a) — /biz 홈(수신함) 상단.
 *  - 우수/양호는 배지 노출, 그 외는 부정 낙인 없이 개선 안내만.
 */
export default function BizPaymentBadge({
  businessId,
}: {
  businessId?: string;
}) {
  const [data, setData] = useState<SelfBadge | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const res = await api().get<SelfBadge>(
          `/biz/payment-badge${businessId ? `?businessId=${businessId}` : ''}`,
        );
        if (alive) setData(res.data);
      } catch {
        if (alive) setData(null);
      } finally {
        if (alive) setLoaded(true);
      }
    })();
    return () => {
      alive = false;
    };
  }, [businessId]);

  if (!loaded || !data) return null;

  const isBadge = data.status === 'EXCELLENT' || data.status === 'GOOD';
  const gradeLabel =
    data.status === 'EXCELLENT'
      ? '⚡ 우수 지급처'
      : data.status === 'GOOD'
        ? '양호 지급처'
        : null;

  // 개선 안내 문구 (부정 낙인 금지)
  const note =
    data.status === 'EXCELLENT'
      ? '작업자들에게 빠른 지급처로 표시됩니다.'
      : data.status === 'GOOD'
        ? '15일 내 지급 시 ⚡우수 지급처 배지를 받을 수 있어요.'
        : data.status === 'NONE'
          ? '15일 내 지급 시 우수 지급처 배지를 받을 수 있어요.'
          : `정산 3건 이상이 쌓이면 배지가 산출됩니다 (현재 ${data.sampleSize}건).`;

  return (
    <div
      className="card"
      style={{
        padding: '16px 18px',
        marginBottom: 16,
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        borderLeft: isBadge
          ? '4px solid var(--accent, #F4770C)'
          : '4px solid var(--border)',
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: 12,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: isBadge ? 'rgba(244,119,12,0.12)' : 'var(--paper-2, #f2efe9)',
          flexShrink: 0,
        }}
      >
        <CheckCircle
          width={22}
          height={22}
          color={isBadge ? 'var(--accent, #F4770C)' : 'var(--ink-2)'}
        />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <span style={{ fontSize: 17, fontWeight: 800 }}>
            {gradeLabel ?? '지급 평판'}
          </span>
          {data.avgDays != null && data.status !== 'INSUFFICIENT' ? (
            <span
              className="num"
              style={{ fontSize: 14, color: 'var(--ink-2)' }}
            >
              평균 {data.avgDays}일 · 표본 {data.sampleSize}건
            </span>
          ) : null}
        </div>
        <p style={{ margin: '4px 0 0', fontSize: 14, color: 'var(--ink-2)' }}>
          {note}
        </p>
      </div>
    </div>
  );
}
