import {
  gradeForAvgDays,
  badgeFromCache,
  selfBadgeStatus,
  computeAvgDays,
  daysBetween,
} from './badge.util';

describe('badge.util — 지급 평판 배지', () => {
  describe('gradeForAvgDays 등급 경계', () => {
    it('≤15일 = 우수(EXCELLENT)', () => {
      expect(gradeForAvgDays(0)).toBe('EXCELLENT');
      expect(gradeForAvgDays(15)).toBe('EXCELLENT');
    });
    it('15 초과 ~ 30 이하 = 양호(GOOD)', () => {
      expect(gradeForAvgDays(15.1)).toBe('GOOD');
      expect(gradeForAvgDays(30)).toBe('GOOD');
    });
    it('30 초과 = 표시 없음(null, 부정 낙인 금지)', () => {
      expect(gradeForAvgDays(30.1)).toBeNull();
      expect(gradeForAvgDays(100)).toBeNull();
    });
    it('null/음수 = null', () => {
      expect(gradeForAvgDays(null)).toBeNull();
      expect(gradeForAvgDays(-1)).toBeNull();
    });
  });

  describe('computeAvgDays 표본 3건 경계', () => {
    it('표본 2건 → null(데이터 부족)', () => {
      expect(computeAvgDays([5, 10])).toEqual({ avgDays: null, sampleSize: 2 });
    });
    it('표본 3건 → 평균 산출', () => {
      expect(computeAvgDays([10, 20, 30])).toEqual({
        avgDays: 20,
        sampleSize: 3,
      });
    });
    it('음수/비유한 값은 표본에서 제외', () => {
      expect(computeAvgDays([10, -1, NaN, 20, 30])).toEqual({
        avgDays: 20,
        sampleSize: 3,
      });
    });
  });

  describe('badgeFromCache 공개 노출(우수/양호만)', () => {
    it('표본 3건 미만 → null', () => {
      expect(
        badgeFromCache({ paymentAvgDays: 5, paymentSampleSize: 2 }),
      ).toBeNull();
    });
    it('우수 배지', () => {
      expect(
        badgeFromCache({ paymentAvgDays: 12.34, paymentSampleSize: 5 }),
      ).toEqual({ grade: 'EXCELLENT', avgDays: 12.3, sampleSize: 5 });
    });
    it('양호 배지', () => {
      expect(
        badgeFromCache({ paymentAvgDays: 25, paymentSampleSize: 4 }),
      ).toEqual({ grade: 'GOOD', avgDays: 25, sampleSize: 4 });
    });
    it('>30일 → null(노출 안 함)', () => {
      expect(
        badgeFromCache({ paymentAvgDays: 45, paymentSampleSize: 10 }),
      ).toBeNull();
    });
  });

  describe('selfBadgeStatus 사업장 본인용(개선 안내)', () => {
    it('표본 부족 → INSUFFICIENT', () => {
      expect(
        selfBadgeStatus({ paymentAvgDays: null, paymentSampleSize: 1 }),
      ).toEqual({ status: 'INSUFFICIENT', avgDays: null, sampleSize: 1 });
    });
    it('>30일 → NONE(부정 낙인 없이, 개선 여지)', () => {
      expect(
        selfBadgeStatus({ paymentAvgDays: 40, paymentSampleSize: 5 }),
      ).toEqual({ status: 'NONE', avgDays: 40, sampleSize: 5 });
    });
    it('우수/양호는 등급 노출', () => {
      expect(
        selfBadgeStatus({ paymentAvgDays: 10, paymentSampleSize: 5 }).status,
      ).toBe('EXCELLENT');
      expect(
        selfBadgeStatus({ paymentAvgDays: 28, paymentSampleSize: 5 }).status,
      ).toBe('GOOD');
    });
  });

  describe('daysBetween', () => {
    it('경과 일수 내림(최소 0)', () => {
      const a = new Date('2026-01-01T00:00:00Z');
      const b = new Date('2026-01-11T12:00:00Z');
      expect(daysBetween(a, b)).toBe(10);
      expect(daysBetween(b, a)).toBe(0);
    });
  });
});
