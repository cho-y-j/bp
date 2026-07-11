/**
 * 간편 TBM 기본 위험요인 프리셋 (건설 현장 일반) — 코드 기반 (P2c).
 *  - 앱은 이 코드로 6개 언어(작업자 자기 언어) 번역 칩을 노출한다.
 *  - 서버(PDF/리포트 정본은 한국어)는 아래 한국어 라벨로 코드를 치환한다.
 *  - 사업장 커스텀 프리셋(tbm_presets)은 원문 문구 그대로 저장·표시한다.
 */
export const TBM_DEFAULT_HAZARD_CODES = [
  'HEAVY_EQUIP',
  'FALL_HEIGHT',
  'HEAT_ILLNESS',
  'ELECTRIC_SHOCK',
  'FALLING_OBJECT',
  'COLLAPSE',
  'FIRE_EXPLOSION',
  'DUST_NOISE',
  'SLIP_TRIP',
  'CONFINED_SPACE',
] as const;

export type TbmHazardCode = (typeof TBM_DEFAULT_HAZARD_CODES)[number];

/** 기본 위험요인 코드 → 한국어 라벨 (PDF/리포트 정본용). */
export const TBM_HAZARD_LABEL_KO: Record<string, string> = {
  HEAVY_EQUIP: '중장비 협착·충돌(굴착기·지게차)',
  FALL_HEIGHT: '고소작업 추락',
  HEAT_ILLNESS: '폭염 온열질환',
  ELECTRIC_SHOCK: '감전',
  FALLING_OBJECT: '낙하물',
  COLLAPSE: '붕괴·매몰',
  FIRE_EXPLOSION: '화재·폭발',
  DUST_NOISE: '분진·소음',
  SLIP_TRIP: '전도·미끄러짐',
  CONFINED_SPACE: '밀폐공간 질식',
};

export const isTbmHazardCode = (code: string): boolean =>
  code in TBM_HAZARD_LABEL_KO;

/** 위험요인 항목: 기본 프리셋 코드(code) 또는 커스텀/직접입력 문구(text). */
export interface TbmHazardItem {
  code?: string; // 기본 프리셋 코드 (있으면 우선)
  text?: string; // 커스텀/직접입력 원문
}

/** 위험요인 항목 → 한국어 표시 문구 (code 는 한국어 라벨로 치환). */
export function tbmHazardToKo(item: TbmHazardItem): string {
  if (item.code && TBM_HAZARD_LABEL_KO[item.code]) {
    return TBM_HAZARD_LABEL_KO[item.code];
  }
  return (item.text ?? '').trim();
}

/** 위험요인 배열 → 한국어 요약(쉼표 구분). 빈 항목 제거. */
export function tbmHazardsSummaryKo(hazards: TbmHazardItem[]): string {
  return hazards
    .map(tbmHazardToKo)
    .filter((s) => s.length > 0)
    .join(', ');
}
