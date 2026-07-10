/**
 * 폭염 판정 유틸 (순수 함수 — 단위 테스트 대상).
 *  - 기준: 최고기온 또는 체감온도가 임계(기본 33°C) 이상이면 폭염.
 */

export const HEAT_THRESHOLD_C = 33;

export interface HeatReading {
  maxTempC: number | null; // 최고기온
  feelsLikeC?: number | null; // 체감온도(있으면)
}

/** 최고기온/체감온도 중 하나라도 임계 이상이면 폭염. */
export function isHeatwave(
  reading: HeatReading,
  threshold: number = HEAT_THRESHOLD_C,
): boolean {
  const candidates = [reading.maxTempC, reading.feelsLikeC ?? null].filter(
    (v): v is number => typeof v === 'number' && Number.isFinite(v),
  );
  if (candidates.length === 0) return false;
  return Math.max(...candidates) >= threshold;
}

/**
 * 기상청 격자 좌표 변환(위경도 → nx, ny). LCC DFS 좌표계.
 * 기상청 단기예보 API 가 격자 좌표를 요구하므로 필요.
 */
export function latLngToGrid(
  lat: number,
  lng: number,
): { nx: number; ny: number } {
  const RE = 6371.00877; // 지구 반경(km)
  const GRID = 5.0; // 격자 간격(km)
  const SLAT1 = 30.0;
  const SLAT2 = 60.0;
  const OLON = 126.0;
  const OLAT = 38.0;
  const XO = 43;
  const YO = 136;
  const DEGRAD = Math.PI / 180.0;

  const re = RE / GRID;
  const slat1 = SLAT1 * DEGRAD;
  const slat2 = SLAT2 * DEGRAD;
  const olon = OLON * DEGRAD;
  const olat = OLAT * DEGRAD;

  let sn =
    Math.tan(Math.PI * 0.25 + slat2 * 0.5) /
    Math.tan(Math.PI * 0.25 + slat1 * 0.5);
  sn = Math.log(Math.cos(slat1) / Math.cos(slat2)) / Math.log(sn);
  let sf = Math.tan(Math.PI * 0.25 + slat1 * 0.5);
  sf = (Math.pow(sf, sn) * Math.cos(slat1)) / sn;
  let ro = Math.tan(Math.PI * 0.25 + olat * 0.5);
  ro = (re * sf) / Math.pow(ro, sn);

  let ra = Math.tan(Math.PI * 0.25 + lat * DEGRAD * 0.5);
  ra = (re * sf) / Math.pow(ra, sn);
  let theta = lng * DEGRAD - olon;
  if (theta > Math.PI) theta -= 2.0 * Math.PI;
  if (theta < -Math.PI) theta += 2.0 * Math.PI;
  theta *= sn;

  const nx = Math.floor(ra * Math.sin(theta) + XO + 0.5);
  const ny = Math.floor(ro - ra * Math.cos(theta) + YO + 0.5);
  return { nx, ny };
}
