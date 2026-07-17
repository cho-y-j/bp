'use client';

import { Suspense, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import axios from 'axios';
import { API_URL, setToken } from '@/lib/api';
import { Phone, Check } from '@/components/Icons';

function LoginInner() {
  const router = useRouter();
  const params = useSearchParams();
  // 명시적 next 가 있으면 그대로, 없으면 로그인 후 사업장 보유 여부로 분기.
  const next = params.get('next');

  const [phase, setPhase] = useState<'phone' | 'code'>('phone');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [devCode, setDevCode] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function errMsg(e: unknown, fallback: string): string {
    if (axios.isAxiosError(e) && e.response?.data?.error?.message) {
      return e.response.data.error.message;
    }
    return fallback;
  }

  async function requestCode() {
    setError(null);
    const p = phone.replace(/\D/g, '');
    if (p.length < 10) {
      setError('전화번호를 정확히 입력하세요.');
      return;
    }
    setBusy(true);
    try {
      const res = await axios.post(`${API_URL}/auth/phone/request`, { phone: p });
      const data = (res.data?.data ?? res.data) as { devCode?: string };
      setDevCode(data.devCode ?? null);
      setPhase('code');
    } catch (e) {
      setError(errMsg(e, '인증코드 발송에 실패했습니다.'));
    } finally {
      setBusy(false);
    }
  }

  async function verify() {
    setError(null);
    if (code.length !== 6) {
      setError('인증코드 6자리를 입력하세요.');
      return;
    }
    setBusy(true);
    try {
      const res = await axios.post(`${API_URL}/auth/phone/verify`, {
        phone: phone.replace(/\D/g, ''),
        code: code.replace(/\D/g, ''),
      });
      const data = (res.data?.data ?? res.data) as { accessToken: string };
      setToken(data.accessToken);
      if (next) {
        router.replace(next);
      } else {
        // 사업장 있으면 사업장 수신함, 없으면 작업자 홈으로.
        let dest = '/w/home';
        try {
          const meRes = await axios.get(`${API_URL}/me`, {
            headers: { Authorization: `Bearer ${data.accessToken}` },
          });
          const me = (meRes.data?.data ?? meRes.data) as {
            hasBusiness?: boolean;
          };
          dest = me.hasBusiness ? '/biz/inbox' : '/w/home';
        } catch {
          /* /me 실패 시 작업자 홈으로 폴백 */
        }
        router.replace(dest);
      }
    } catch (e) {
      setError(errMsg(e, '인증에 실패했습니다. 코드를 확인하세요.'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <main
      className="page"
      style={{
        maxWidth: 440,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        minHeight: '100vh',
      }}
    >
      <p className="brand-kicker">
        <span className="brand-dot" />
        작업온 · 사업장 웹
      </p>
      <h1 style={{ fontSize: 28, fontWeight: 800, margin: '14px 0 6px' }}>
        전화번호로 로그인
      </h1>
      <p style={{ color: 'var(--ink-2)', fontSize: 15, margin: '0 0 26px' }}>
        {phase === 'phone'
          ? '가입한 전화번호로 인증코드를 보내드립니다.'
          : `${phone} 로 보낸 인증코드를 입력하세요.`}
      </p>

      {phase === 'phone' ? (
        <>
          <div className="field">
            <label className="flabel" htmlFor="phone">
              전화번호
            </label>
            <input
              id="phone"
              className="input num"
              inputMode="numeric"
              placeholder="010-0000-0000"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && requestCode()}
              autoComplete="tel"
            />
          </div>
          <button
            className="btn btn-primary btn-lg"
            onClick={requestCode}
            disabled={busy}
          >
            {busy ? <span className="spinner" /> : <Phone />}
            인증코드 받기
          </button>
        </>
      ) : (
        <>
          {devCode ? (
            <div
              className="warn-banner"
              style={{ marginBottom: 16 }}
              role="status"
            >
              <span>
                개발용 인증코드: <b className="num">{devCode}</b>
              </span>
            </div>
          ) : null}
          <div className="field">
            <label className="flabel" htmlFor="code">
              인증코드
            </label>
            <input
              id="code"
              className="input num"
              inputMode="numeric"
              pattern="\d{6}"
              placeholder="6자리 숫자"
              value={code}
              onChange={(e) =>
                setCode(e.target.value.replace(/\D/g, '').slice(0, 6))
              }
              onKeyDown={(e) => e.key === 'Enter' && verify()}
              autoFocus
              maxLength={6}
            />
          </div>
          <button
            className="btn btn-primary btn-lg"
            onClick={verify}
            disabled={busy}
          >
            {busy ? <span className="spinner" /> : <Check />}
            로그인
          </button>
          <button
            className="btn btn-ghost"
            style={{ marginTop: 10 }}
            onClick={() => {
              setPhase('phone');
              setCode('');
              setError(null);
            }}
          >
            전화번호 다시 입력
          </button>
        </>
      )}

      {error ? (
        <p
          role="alert"
          style={{ color: 'var(--receivable)', fontSize: 15, marginTop: 14 }}
        >
          {error}
        </p>
      ) : null}
    </main>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={<main className="page" />}>
      <LoginInner />
    </Suspense>
  );
}
