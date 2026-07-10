import { isHeatwave, latLngToGrid, HEAT_THRESHOLD_C } from './heatwave.util';

describe('heatwave.util — 폭염 판정', () => {
  it('최고기온 33°C 이상이면 폭염', () => {
    expect(isHeatwave({ maxTempC: 33 })).toBe(true);
    expect(isHeatwave({ maxTempC: 35.2 })).toBe(true);
    expect(isHeatwave({ maxTempC: 32.9 })).toBe(false);
  });

  it('체감온도가 임계 이상이면 최고기온이 낮아도 폭염', () => {
    expect(isHeatwave({ maxTempC: 31, feelsLikeC: 34 })).toBe(true);
    expect(isHeatwave({ maxTempC: 31, feelsLikeC: 32 })).toBe(false);
  });

  it('둘 다 없으면(측정 실패) 폭염 아님', () => {
    expect(isHeatwave({ maxTempC: null })).toBe(false);
    expect(isHeatwave({ maxTempC: null, feelsLikeC: null })).toBe(false);
  });

  it('임계값 조정 가능', () => {
    expect(isHeatwave({ maxTempC: 30 }, 28)).toBe(true);
    expect(HEAT_THRESHOLD_C).toBe(33);
  });

  it('위경도 → 기상청 격자 변환 (서울 시청 근처)', () => {
    const { nx, ny } = latLngToGrid(37.5665, 126.978);
    // 서울(중구) 표준 격자 ≈ (60, 127)
    expect(nx).toBe(60);
    expect(ny).toBe(127);
  });
});
