import { computeDday, expiryStateFromDday } from './dday.util';

describe('computeDday (KST 기준)', () => {
  it('같은 날(KST) → 0', () => {
    const now = new Date('2026-07-11T05:00:00+09:00');
    const expiry = new Date('2026-07-11T23:00:00+09:00');
    expect(computeDday(expiry, now)).toBe(0);
  });

  it('30일 남음 → 30', () => {
    const now = new Date('2026-07-11T09:00:00+09:00');
    const expiry = new Date('2026-08-10T09:00:00+09:00');
    expect(computeDday(expiry, now)).toBe(30);
  });

  it('7일 남음 → 7', () => {
    const now = new Date('2026-07-11T09:00:00+09:00');
    const expiry = new Date('2026-07-18T01:00:00+09:00');
    expect(computeDday(expiry, now)).toBe(7);
  });

  it('어제 만료 → -1 (음수)', () => {
    const now = new Date('2026-07-11T09:00:00+09:00');
    const expiry = new Date('2026-07-10T09:00:00+09:00');
    expect(computeDday(expiry, now)).toBe(-1);
  });

  it('서버 타임존과 무관하게 KST 달력일 기준으로 계산한다', () => {
    // UTC 로는 7/11, KST 로는 7/12 00:30 → 만료가 KST 7/12 이면 D-0
    const now = new Date('2026-07-11T15:30:00Z'); // KST 2026-07-12 00:30
    const expiry = new Date('2026-07-12T10:00:00+09:00'); // KST 7/12
    expect(computeDday(expiry, now)).toBe(0);
  });
});

describe('expiryStateFromDday', () => {
  it('만료일 없음(null) → ACTIVE', () => {
    expect(expiryStateFromDday(null)).toBe('ACTIVE');
  });
  it('음수 → EXPIRED', () => {
    expect(expiryStateFromDday(-1)).toBe('EXPIRED');
  });
  it('0 → EXPIRING', () => {
    expect(expiryStateFromDday(0)).toBe('EXPIRING');
  });
  it('30 → EXPIRING (경계)', () => {
    expect(expiryStateFromDday(30)).toBe('EXPIRING');
  });
  it('31 → ACTIVE', () => {
    expect(expiryStateFromDday(31)).toBe('ACTIVE');
  });
});
