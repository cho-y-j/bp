/**
 * QR 명함(공개 프로필) 순수 유틸 — 단위 테스트 대상. P3b.
 *
 * 서류 유효 배지 규약(민감정보 비노출, 좋은 신호만):
 *  - "서류 유효 ✓" 노출 조건:
 *      ① 만료일이 등록된 서류가 1개 이상 존재하고,
 *      ② 그 중 만료일이 지난(EXPIRED) 서류가 하나도 없을 것.
 *  - 서류의 상세·파일·발급일 등은 절대 노출하지 않는다. 개수·유형명 정도만.
 *  - ARCHIVED(보관/폐기) 서류는 판정에서 제외한다.
 */
import { computeDday } from '../common/dday.util';

/** 판정 입력: 서류의 만료일과 상태·유형만 필요(파일 경로 등은 불필요). */
export interface DocForValidity {
  type: string;
  expiryDate: Date | null;
  status: string; // DocumentStatus (ACTIVE | ARCHIVED ...)
}

/** 공개 노출용 서류 유효 요약. 파일·상세는 포함하지 않는다. */
export interface DocValiditySummary {
  valid: boolean; // 서류 유효 배지 노출 여부
  withExpiryCount: number; // 만료일이 등록된(유효기간 있는) 서류 수
  totalCount: number; // 보유 서류 수(ARCHIVED 제외)
  types: string[]; // 서류 유형명(중복 제거, 정렬) — 개수/유형만 노출
}

/**
 * 보유 서류 목록으로부터 공개 프로필용 서류 유효 요약을 계산한다.
 * ARCHIVED 서류는 무시한다.
 */
export function computeDocValidity(
  docs: DocForValidity[],
  now: Date = new Date(),
): DocValiditySummary {
  const active = docs.filter((d) => d.status !== 'ARCHIVED');

  const withExpiry = active.filter((d) => d.expiryDate != null);
  // 만료일이 등록된 서류 중 만료일이 지난 것이 하나라도 있으면 무효.
  const anyExpired = withExpiry.some(
    (d) => computeDday(d.expiryDate as Date, now) < 0,
  );

  const valid = withExpiry.length >= 1 && !anyExpired;

  const types = Array.from(new Set(active.map((d) => d.type))).sort();

  return {
    valid,
    withExpiryCount: withExpiry.length,
    totalCount: active.length,
    types,
  };
}
