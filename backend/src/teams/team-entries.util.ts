import { HttpStatus } from '@nestjs/common';
import { AppException } from '../common/errors';
import { validateGongsuQuantity } from '../confirmations/amount.util';

/**
 * 팀(반장) 확인서 금액 계산 — 순수 함수(단위 테스트 대상).
 *
 * 설계:
 *  - 팀원별 공수(quantity, 0.1 단위) × 단가(rate) = 각자 몫(amount, 정수 원).
 *  - 팀 합계(total) = 팀원 몫 합계.
 *  - 공수 수량은 확인서 GONGSU 검증(validateGongsuQuantity)을 재사용한다.
 *  - 클라이언트가 보낸 금액은 신뢰하지 않는다(항상 서버 재계산).
 */

/** 요청 입력 — 팀원(memberId) 별 공수·단가. */
export interface TeamEntryInput {
  memberId: string;
  rate?: number; // 미지정 시 팀원 defaultRate 로 대체
  quantity: number; // 공수(0.1 단위)
}

/** 팀원 명단 스냅샷(계산에 필요한 최소 정보). */
export interface TeamMemberRef {
  id: string;
  name: string;
  profileId: string | null;
  defaultRate: number | null;
}

/** 저장·표시용 팀원 몫. */
export interface TeamEntryComputed {
  memberId: string;
  name: string;
  profileId: string | null;
  rate: number;
  quantity: number; // 공수
  amount: number; // rate × quantity (정수 원)
}

export interface TeamAmountResult {
  entries: TeamEntryComputed[];
  total: number; // 팀 합계
  totalGongsu: number; // 공수 합계 (0.1 단위 정리)
}

/** 음수/NaN 방지 후 반올림한 정수 금액. */
function money(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.round(n);
}

/**
 * 팀원별 입력 + 팀원 명단(membersById) → 검증·계산된 팀 몫과 합계.
 *  - membersById 에 없는 memberId → 400 TEAM_MEMBER_NOT_IN_TEAM
 *  - 공수 수량 위반 → 400 INVALID_GONGSU_QUANTITY (확인서와 동일 규칙)
 *  - rate 미지정/음수 → 팀원 defaultRate 로 대체(없으면 0)
 */
export function computeTeamEntries(
  inputs: TeamEntryInput[],
  membersById: Map<string, TeamMemberRef>,
): TeamAmountResult {
  if (!Array.isArray(inputs) || inputs.length === 0) {
    throw new AppException(
      'TEAM_ENTRIES_REQUIRED',
      '팀 확인서는 팀원별 항목(teamEntries)이 최소 1건 필요합니다.',
      HttpStatus.BAD_REQUEST,
    );
  }
  const seen = new Set<string>();
  const entries: TeamEntryComputed[] = [];
  let total = 0;
  let totalGongsu = 0;
  for (const input of inputs) {
    const member = membersById.get(input.memberId);
    if (!member) {
      throw new AppException(
        'TEAM_MEMBER_NOT_IN_TEAM',
        '선택한 팀원이 이 팀에 속해 있지 않습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    if (seen.has(input.memberId)) {
      throw new AppException(
        'TEAM_MEMBER_DUPLICATED',
        '같은 팀원이 중복 입력되었습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    seen.add(input.memberId);

    const quantity = validateGongsuQuantity(input.quantity);
    if (quantity === null) {
      throw new AppException(
        'INVALID_GONGSU_QUANTITY',
        '공수 수량은 0보다 크고 0.1 단위여야 합니다 (예: 0.5, 1, 1.5).',
        HttpStatus.BAD_REQUEST,
      );
    }
    const rawRate =
      typeof input.rate === 'number' && input.rate >= 0
        ? input.rate
        : (member.defaultRate ?? 0);
    const rate = money(Math.max(0, rawRate));
    const amount = money(rate * quantity);
    entries.push({
      memberId: member.id,
      name: member.name,
      profileId: member.profileId,
      rate,
      quantity,
      amount,
    });
    total += amount;
    totalGongsu += quantity;
  }
  return {
    entries,
    total: money(total),
    totalGongsu: Math.round(totalGongsu * 10) / 10,
  };
}
