'use client';

import { useRef, useState } from 'react';
import Link from 'next/link';
import axios from 'axios';
import { API_URL, absoluteUrl } from '@/lib/api';
import SignaturePad, { type SignaturePadHandle } from '@/components/SignaturePad';
import type { ConfirmationView } from '@/components/PaperConfirmation';
import { CheckCircle, Pen, Download } from '@/components/Icons';
import { createT, type Lang } from '@/lib/i18n';

/** 외부(미가입) 서명 섹션 — 미서명이면 서명 폼, 서명 후 완료+가입 유도. */
export default function SignSection({
  token,
  initialSigned,
  view,
  lang = 'ko',
}: {
  token: string;
  initialSigned: boolean;
  view: ConfirmationView;
  lang?: Lang;
}) {
  const t = createT(lang);
  const padRef = useRef<SignaturePadHandle>(null);
  const [signerName, setSignerName] = useState('');
  const [padEmpty, setPadEmpty] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(initialSigned);
  const [signedInfo, setSignedInfo] = useState<{
    signerName?: string | null;
    signedAt?: string | null;
  }>({ signerName: view.signerName, signedAt: view.signedAt });

  const pdfHref = absoluteUrl(`/api/public/confirmations/${token}/pdf`);

  async function submit() {
    setError(null);
    if (signerName.trim().length < 1) {
      setError(t('signErrName'));
      return;
    }
    if (padRef.current?.isEmpty()) {
      setError(t('signErrSign'));
      return;
    }
    setSubmitting(true);
    try {
      const dataUrl = padRef.current!.toDataURL();
      const res = await axios.post(
        `${API_URL}/public/confirmations/${token}/sign`,
        { signerName: signerName.trim(), signImageBase64: dataUrl },
      );
      const data = (res.data?.data ?? res.data) as {
        signerName?: string;
        signedAt?: string;
      };
      setSignedInfo({
        signerName: data.signerName ?? signerName.trim(),
        signedAt: data.signedAt,
      });
      setDone(true);
    } catch (e) {
      const msg =
        axios.isAxiosError(e) && e.response?.data?.error?.message
          ? e.response.data.error.message
          : t('signErrSubmit');
      setError(msg);
    } finally {
      setSubmitting(false);
    }
  }

  if (done) {
    return (
      <>
        <div
          className="card"
          style={{
            marginTop: 22,
            padding: 22,
            borderColor: 'var(--deposited)',
            background: 'color-mix(in srgb, var(--deposited) 7%, var(--surface))',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              color: 'var(--deposited-badge)',
            }}
          >
            <CheckCircle width={30} height={30} />
            <div>
              <div style={{ fontSize: 20, fontWeight: 800 }}>
                {t('signDoneTitle')}
              </div>
              <div style={{ fontSize: 15, color: 'var(--ink-2)' }}>
                {signedInfo.signerName
                  ? t('signDoneBy', { name: signedInfo.signerName })
                  : t('signDoneReceived')}
                {signedInfo.signedAt ? (
                  <span className="num"> · {signedInfo.signedAt}</span>
                ) : null}
              </div>
            </div>
          </div>
          <a
            href={pdfHref}
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-ghost"
            style={{ width: '100%', marginTop: 16 }}
          >
            <Download width={20} height={20} />
            {t('signViewPdf')}
          </a>
        </div>

        <div className="join-banner">
          <p className="brand-kicker">
            <span className="brand-dot" />
            작업온
          </p>
          <h2
            style={{
              fontSize: 21,
              fontWeight: 800,
              margin: '10px 0 6px',
              lineHeight: 1.3,
            }}
          >
            {t('joinTitle')}
          </h2>
          <p style={{ fontSize: 15, color: 'var(--ink-2)', margin: '0 0 16px' }}>
            {t('joinDesc')}
          </p>
          <Link
            href="/login"
            className="btn btn-primary btn-lg"
            style={{ maxWidth: 320 }}
          >
            {t('joinCta')}
          </Link>
        </div>
      </>
    );
  }

  return (
    <div className="sign-zone card" style={{ marginTop: 22, padding: 20 }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          marginBottom: 14,
          color: 'var(--accent-text)',
        }}
      >
        <Pen width={22} height={22} />
        <span style={{ fontSize: 19, fontWeight: 800, color: 'var(--ink)' }}>
          {t('signHeading')}
        </span>
      </div>

      <div className="field">
        <label className="flabel" htmlFor="signerName">
          {t('signNameLabel')}
        </label>
        <input
          id="signerName"
          className="input"
          placeholder={t('signNamePlaceholder')}
          value={signerName}
          onChange={(e) => setSignerName(e.target.value)}
          maxLength={50}
          autoComplete="name"
        />
      </div>

      <label className="flabel">{t('signSignLabel')}</label>
      <SignaturePad
        ref={padRef}
        onChange={setPadEmpty}
        hint={t('signPadHint')}
        ariaLabel={t('signPadAria')}
      />
      <div
        style={{
          display: 'flex',
          justifyContent: 'flex-end',
          marginTop: 8,
        }}
      >
        <button
          type="button"
          className="btn btn-ghost"
          style={{ height: 44, minHeight: 44, padding: '0 16px' }}
          onClick={() => padRef.current?.clear()}
          disabled={padEmpty}
        >
          {t('signRedraw')}
        </button>
      </div>

      {error ? (
        <p
          role="alert"
          style={{ color: 'var(--receivable)', fontSize: 15, marginTop: 10 }}
        >
          {error}
        </p>
      ) : null}

      <button
        type="button"
        className="btn btn-primary btn-lg"
        style={{ marginTop: 16 }}
        onClick={submit}
        disabled={submitting}
      >
        {submitting ? <span className="spinner" /> : <CheckCircle />}
        {submitting ? t('signSubmitting') : t('signSubmit')}
      </button>
      <p
        style={{
          textAlign: 'center',
          fontSize: 14,
          color: 'var(--ink-3)',
          marginTop: 10,
        }}
      >
        {t('signFootnote')}
      </p>
      <p
        style={{
          textAlign: 'center',
          fontSize: 13,
          color: 'var(--ink-3)',
          marginTop: 6,
          lineHeight: 1.5,
        }}
      >
        {t('signLegal')}
      </p>
    </div>
  );
}
