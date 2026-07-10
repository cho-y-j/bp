/**
 * 미가입 상대 승격 매칭 로직 (순수 함수 — 단위 테스트 대상).
 *  - 확인서/장부의 수기 상대(manualContact) 전화번호를 정규화해
 *    사업장(사업주 프로필 전화 등) 전화 집합과 매칭한다.
 */
import { normalizePhone } from '../common/phone.util';

export interface ManualCandidate {
  id: string;
  manualContact: string | null;
}

/**
 * 후보(수기 상대) 중 주어진 전화 집합과 일치하는 항목의 id 를 고른다.
 *  - 양측 모두 숫자만 남겨 비교(하이픈/공백 무시).
 *  - 빈 전화는 매칭하지 않는다.
 */
export function selectPromotable(
  candidates: ManualCandidate[],
  businessPhones: string[],
): string[] {
  const phoneSet = new Set(
    businessPhones.map(normalizePhone).filter((p) => p.length >= 8),
  );
  if (phoneSet.size === 0) return [];
  const matched: string[] = [];
  for (const c of candidates) {
    const p = normalizePhone(c.manualContact);
    if (p.length >= 8 && phoneSet.has(p)) matched.push(c.id);
  }
  return matched;
}
