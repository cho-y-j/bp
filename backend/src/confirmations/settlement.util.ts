import { computeOutstanding } from '../ledger/ledger.util';

export type SettlementStatus = 'UNPAID' | 'PARTIAL' | 'PAID';

export interface Settlement {
  paidAmount: number; // 입금 합계(원)
  outstandingAmount: number; // 미수(원, amount - paid, 최소 0)
  status: SettlementStatus;
}

/**
 * 확인서의 정산 상태 — 연결된 1:1 ledger entry(amount/payments) 기준(순수 함수).
 *
 *  - 캘린더 색 구분(입금 초록 / 미수 주황)을 위해 장부 4-상태(PENDING/PARTIAL/PAID/OVERDUE)를
 *    3-상태로 축약한다:
 *      PAID    : 미수 0(완납).
 *      PARTIAL : 일부 입금(0 < 입금 < 청구).
 *      UNPAID  : 입금 0(연체 OVERDUE 포함 — 색은 미수 주황으로 동일 취급).
 *  - 팀(반장) 확인서: 연결 entry 는 팀 합계 1건이므로 그대로 사용한다. 팀원 파생 항목
 *    (derived=true)은 각 팀원 본인 장부의 별도 entry 이고 확인서 소유자의 목록에는
 *    존재하지 않으므로, 여기서 이중 계상되지 않는다(income-report 배제 규칙과 동일 원리).
 *
 * ledger entry 가 없는 확인서(방어적 케이스)는 호출부에서 null 로 처리한다. 현행 스키마상
 * 확인서 생성 시(DRAFT) 항상 1:1 entry 가 함께 생성되므로 실제로는 항상 존재한다.
 */
export function computeSettlement(
  amount: number,
  payments: unknown,
  dueDate: Date | null,
  now: Date = new Date(),
): Settlement {
  const { paid, outstanding } = computeOutstanding(
    amount,
    payments,
    dueDate,
    now,
  );
  let status: SettlementStatus;
  if (outstanding <= 0 && amount > 0) status = 'PAID';
  else if (paid > 0) status = 'PARTIAL';
  else status = 'UNPAID';
  return { paidAmount: paid, outstandingAmount: outstanding, status };
}
