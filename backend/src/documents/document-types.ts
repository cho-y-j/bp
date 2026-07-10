/**
 * 서류 유형 (한국어 서류명 enum).
 * 진위확인 실연동은 사업자등록증만 지원(국세청 API), 나머지는 수동확인 fallback.
 */
export const DOCUMENT_TYPES = [
  '신분증',
  '사업자등록증',
  '통장사본',
  '자격증',
  '면허증',
  '경력증명서',
  '보험증권',
  '장비등록증',
  '장비검사증',
  '보험가입증명서',
  '안전보건교육수료증',
  '건강진단서',
  '기타',
] as const;

export type DocumentType = (typeof DOCUMENT_TYPES)[number];

/** 국세청 진위확인 API 로 실연동 가능한 유형. */
export const VERIFIABLE_TYPE: DocumentType = '사업자등록증';

export function isDocumentType(value: unknown): value is DocumentType {
  return (
    typeof value === 'string' &&
    (DOCUMENT_TYPES as readonly string[]).includes(value)
  );
}
