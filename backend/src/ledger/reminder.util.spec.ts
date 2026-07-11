import {
  autoReminderStage,
  hasStageBeenSent,
  manualCooldown,
  lastReminderAt,
  normalizeReminders,
} from './reminder.util';

describe('reminder.util — 수금 독촉', () => {
  describe('autoReminderStage 단계 판정 (dday=남은 일수, 음수=지남)', () => {
    it('D+7 도달(dday -7) → D7', () => {
      expect(autoReminderStage(-7)).toBe('D7');
    });
    it('D+30 도달(dday -30) → D30', () => {
      expect(autoReminderStage(-30)).toBe('D30');
    });
    it('그 외(미도달/사이값) → null', () => {
      expect(autoReminderStage(0)).toBeNull();
      expect(autoReminderStage(-6)).toBeNull();
      expect(autoReminderStage(-8)).toBeNull();
      expect(autoReminderStage(-29)).toBeNull();
      expect(autoReminderStage(-31)).toBeNull();
    });
  });

  describe('hasStageBeenSent 같은 단계 중복 방지', () => {
    const reminders = [
      { at: '2026-07-01T01:00:00Z', channel: 'push', stage: 'D7' },
    ];
    it('이미 보낸 단계 → true', () => {
      expect(hasStageBeenSent(reminders, 'D7')).toBe(true);
    });
    it('아직 안 보낸 단계 → false', () => {
      expect(hasStageBeenSent(reminders, 'D30')).toBe(false);
    });
    it('빈/잘못된 이력 → false', () => {
      expect(hasStageBeenSent(null, 'D7')).toBe(false);
      expect(hasStageBeenSent([{ bad: 1 }], 'D7')).toBe(false);
    });
  });

  describe('normalizeReminders / lastReminderAt', () => {
    it('잘못된 항목 제거', () => {
      expect(
        normalizeReminders([
          { at: '2026-07-01T00:00:00Z', channel: 'push', stage: 'D7' },
          { bad: true },
          null,
        ]),
      ).toHaveLength(1);
    });
    it('가장 최근 발송 시각', () => {
      const last = lastReminderAt([
        { at: '2026-07-01T00:00:00Z', channel: 'push', stage: 'D7' },
        { at: '2026-07-05T00:00:00Z', channel: 'alimtalk', stage: 'MANUAL' },
      ]);
      expect(last?.toISOString()).toBe('2026-07-05T00:00:00.000Z');
    });
  });

  describe('manualCooldown 쿨다운 3일', () => {
    const base = { channel: 'push', stage: 'MANUAL' as const };
    it('이력 없음 → 발송 가능', () => {
      expect(manualCooldown([]).blocked).toBe(false);
    });
    it('2일 경과 → 차단(409)', () => {
      const now = new Date('2026-07-10T00:00:00Z');
      const reminders = [{ ...base, at: '2026-07-08T00:00:00Z' }];
      const cd = manualCooldown(reminders, now);
      expect(cd.blocked).toBe(true);
      expect(cd.retryAfterMs).toBeGreaterThan(0);
    });
    it('정확히 3일 경과 → 발송 가능', () => {
      const now = new Date('2026-07-11T00:00:00Z');
      const reminders = [{ ...base, at: '2026-07-08T00:00:00Z' }];
      expect(manualCooldown(reminders, now).blocked).toBe(false);
    });
    it('4일 경과 → 발송 가능', () => {
      const now = new Date('2026-07-12T00:00:00Z');
      const reminders = [{ ...base, at: '2026-07-08T00:00:00Z' }];
      expect(manualCooldown(reminders, now).blocked).toBe(false);
    });
  });
});
