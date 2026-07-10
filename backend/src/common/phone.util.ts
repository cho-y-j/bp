/**
 * 전화번호/이름 공통 유틸 (순수 함수).
 *  - normalizePhone: 숫자만 남긴다(Profile.phone 저장 규약과 동일).
 *  - maskName: 이름 일부 마스킹(홍길동 → 홍*동, 김철 → 김*, 김 → *).
 */

/** 전화번호에서 숫자만 남긴다. (auth.service 저장 규약과 일치) */
export function normalizePhone(phone: string | null | undefined): string {
  if (!phone) return '';
  return phone.replace(/[^0-9]/g, '');
}

/** 이름 마스킹: 가운데 글자를 * 로 가린다. */
export function maskName(name: string | null | undefined): string {
  const n = (name ?? '').trim();
  if (n.length === 0) return '';
  if (n.length === 1) return '*';
  if (n.length === 2) return `${n[0]}*`;
  return `${n[0]}${'*'.repeat(n.length - 2)}${n[n.length - 1]}`;
}
