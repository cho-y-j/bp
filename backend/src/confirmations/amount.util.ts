/**
 * 작업확인서 금액 계산 (순수 함수 — 단위 테스트 대상).
 *
 * 설계:
 *  - 기본 항목: rateType(DAILY/HOURLY/PER_CASE) × rate(단가) × quantity(일수/시간/건수).
 *  - 추가 항목: SKEP 단가 5종(기본/연장/조출/야간/철야) 차용 — 연장·야간 등은
 *    별도 단가 × 수량으로 항목별 계산해 합산한다(OTHER 로 임의 항목도 허용).
 *  - 부가세: 선택(vatRate, 기본 0). 청구서에 부가세를 붙일 때만 사용.
 *  - 금액은 모두 정수 원(KRW) 반올림. Decimal 정밀도 이슈를 피하려 정수로 다룬다.
 */

export type AdditionalItemType =
  | 'OVERTIME' // 연장
  | 'EARLY' // 조출
  | 'NIGHT' // 야간
  | 'ALLNIGHT' // 철야
  | 'OTHER'; // 기타(임의 라벨)

/** 기본 단가 유형 (API 계약: DAILY | HOURLY | PER_CASE(건당)). */
export type BaseRateType = 'DAILY' | 'HOURLY' | 'PER_CASE';

export interface AdditionalItemInput {
  type: AdditionalItemType;
  label?: string; // OTHER 등 표시용 라벨
  rate: number; // 항목 단가
  quantity: number; // 수량(시간/횟수 등)
}

export interface AmountCalcInput {
  rateType: BaseRateType;
  rate: number; // 기본 단가
  quantity: number; // 기본 수량(일수/시간/건수)
  additionalItems?: AdditionalItemInput[];
  vatRate?: number; // 부가세율 (예: 0.1). 미지정/0 이면 부가세 없음.
}

export interface AmountLineItem {
  type: 'BASE' | AdditionalItemType;
  label: string; // 사람이 읽는 항목명 (PDF/화면 표시용)
  rate: number;
  quantity: number;
  amount: number; // rate × quantity (정수 원)
}

export interface AmountCalcResult {
  items: AmountLineItem[];
  subtotal: number; // 항목 합계(공급가)
  vatRate: number; // 적용 부가세율 (0 이면 없음)
  vat: number; // 부가세액
  total: number; // 최종 청구액 (subtotal + vat)
}

const BASE_LABEL: Record<BaseRateType, string> = {
  DAILY: '기본(일당)',
  HOURLY: '기본(시급)',
  PER_CASE: '기본(건당)',
};

const ITEM_LABEL: Record<AdditionalItemType, string> = {
  OVERTIME: '연장',
  EARLY: '조출',
  NIGHT: '야간',
  ALLNIGHT: '철야',
  OTHER: '기타',
};

/** 음수/NaN 방지 후 반올림한 정수 금액. */
function money(n: number): number {
  if (!Number.isFinite(n)) return 0;
  return Math.round(n);
}

/**
 * 확인서 금액 계산. 서버에서만 계산해 amountCalc(JSONB)로 저장한다.
 * 클라이언트가 보낸 금액은 신뢰하지 않는다(항상 재계산).
 */
export function calcAmount(input: AmountCalcInput): AmountCalcResult {
  const items: AmountLineItem[] = [];

  const baseRate = Math.max(0, input.rate || 0);
  const baseQty = Math.max(0, input.quantity || 0);
  items.push({
    type: 'BASE',
    label: BASE_LABEL[input.rateType],
    rate: money(baseRate),
    quantity: baseQty,
    amount: money(baseRate * baseQty),
  });

  for (const raw of input.additionalItems ?? []) {
    const r = Math.max(0, raw.rate || 0);
    const q = Math.max(0, raw.quantity || 0);
    const label =
      raw.type === 'OTHER'
        ? raw.label?.trim() || ITEM_LABEL.OTHER
        : ITEM_LABEL[raw.type];
    items.push({
      type: raw.type,
      label,
      rate: money(r),
      quantity: q,
      amount: money(r * q),
    });
  }

  const subtotal = money(items.reduce((s, it) => s + it.amount, 0));
  const vatRate = input.vatRate && input.vatRate > 0 ? input.vatRate : 0;
  const vat = money(subtotal * vatRate);
  const total = subtotal + vat;

  return { items, subtotal, vatRate, vat, total };
}
