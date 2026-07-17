'use client';

import { authedBlob } from './api';

/**
 * 인증이 필요한 PDF(확인서/명세서/소득리포트)를 blob 으로 받아 새 탭에 연다.
 * 팝업 차단 대비: 실패 시 다운로드 링크로 폴백.
 */
export async function openAuthedPdf(path: string): Promise<void> {
  const blob = await authedBlob(path);
  const url = URL.createObjectURL(blob);
  const win = window.open(url, '_blank');
  if (!win) {
    const a = document.createElement('a');
    a.href = url;
    a.download = path.split('/').pop() || 'document.pdf';
    a.click();
  }
  // 메모리 회수(새 탭이 로드될 시간을 준 뒤).
  setTimeout(() => URL.revokeObjectURL(url), 60_000);
}

/** 텍스트를 클립보드로 복사. Clipboard API 미지원 시 임시 textarea 폴백. */
export async function copyText(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {
    /* 폴백 시도 */
  }
  try {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    const ok = document.execCommand('copy');
    document.body.removeChild(ta);
    return ok;
  } catch {
    return false;
  }
}
