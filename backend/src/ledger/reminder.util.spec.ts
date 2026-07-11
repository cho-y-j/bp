import {
  appendReminder,
  autoReminderStage,
  hasStageBeenSent,
  manualCooldown,
  lastReminderAt,
  normalizeReminders,
  REMINDER_HISTORY_CAP,
  ReminderRecord,
} from './reminder.util';

describe('reminder.util — 수금 독촉', () => {
  describe('autoReminderStage 단계 판정 (dday=남은 일수, 음수=지남; "이상 경과"로 완화)', () => {
    it('D+7 도달(dday -7, 이력 없음) → D7', () => {
      expect(autoReminderStage(-7, [])).toBe('D7');
    });
    it('D+30 도달(dday -30, 이력 없음) → D30', () => {
      expect(autoReminderStage(-30, [])).toBe('D30');
    });
    it('미도달(dday > -7) → null', () => {
      expect(autoReminderStage(0, [])).toBeNull();
      expect(autoReminderStage(-6, [])).toBeNull();
    });
    it('reminders 인자 생략(기본 []) 하위호환', () => {
      expect(autoReminderStage(-7)).toBe('D7');
      expect(autoReminderStage(-30)).toBe('D30');
      expect(autoReminderStage(-6)).toBeNull();
    });

    // --- 완화 판정: 늦은 토글 / 크론 결번 시나리오 ---
    it('늦은 토글: D+10(dday -10)에 켬, 이력 없음 → D7 단계 발송', () => {
      expect(autoReminderStage(-10, [])).toBe('D7');
    });
    it('늦은 토글: D+35(dday -35)에 켬, 이력 없음 → 높은 단계 D30 하나만(스팸 방지)', () => {
      expect(autoReminderStage(-35, [])).toBe('D30');
    });
    it('이미 D+7 발송된 상태에서 D+30(dday -30) 도달 → D30 발송', () => {
      const reminders = [
        { at: '2026-07-01T00:00:00Z', channel: 'push', stage: 'D7' },
      ];
      expect(autoReminderStage(-30, reminders)).toBe('D30');
    });
    it('이미 D+7 발송된 상태에서 아직 D+30 미도달(dday -10) → null(중복 방지)', () => {
      const reminders = [
        { at: '2026-07-01T00:00:00Z', channel: 'push', stage: 'D7' },
      ];
      expect(autoReminderStage(-10, reminders)).toBeNull();
    });
    it('D7·D30 모두 발송된 상태(dday -40) → null(dedup 유지)', () => {
      const reminders = [
        { at: '2026-07-01T00:00:00Z', channel: 'push', stage: 'D7' },
        { at: '2026-07-24T00:00:00Z', channel: 'push', stage: 'D30' },
      ];
      expect(autoReminderStage(-40, reminders)).toBeNull();
    });
    it('D+35에서 D30만 발송된 상태 → null(D7 은 건너뛰고 재발송 안 함)', () => {
      const reminders = [
        { at: '2026-07-24T00:00:00Z', channel: 'push', stage: 'D30' },
      ];
      expect(autoReminderStage(-35, reminders)).toBeNull();
    });
  });

  describe('appendReminder — 이력 상한(cap 20)', () => {
    const rec = (i: number): ReminderRecord => ({
      at: `2026-07-01T00:00:${String(i).padStart(2, '0')}Z`,
      channel: 'push',
      stage: 'MANUAL',
    });
    it('cap 미만이면 그대로 append', () => {
      const out = appendReminder([rec(1), rec(2)], rec(3));
      expect(out).toHaveLength(3);
      expect(out[2].at).toBe(rec(3).at);
    });
    it('cap(20) 초과 시 최근 20건만 유지, 가장 오래된 것 drop', () => {
      const existing = Array.from({ length: 25 }, (_, i) => rec(i));
      const out = appendReminder(existing, rec(99));
      expect(out).toHaveLength(REMINDER_HISTORY_CAP);
      expect(out).toHaveLength(20);
      // 마지막 원소는 새 record, 첫 원소는 drop 후 남은 가장 오래된 것.
      expect(out[out.length - 1].at).toBe(rec(99).at);
      expect(out[0].at).toBe(rec(6).at); // 26건 중 뒤 20건 → index 6..25
    });
    it('정확히 20건이 되도록 append 하면 drop 없음', () => {
      const existing = Array.from({ length: 19 }, (_, i) => rec(i));
      const out = appendReminder(existing, rec(20));
      expect(out).toHaveLength(20);
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
