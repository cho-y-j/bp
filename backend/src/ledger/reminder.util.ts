/**
 * 수금 독촉 유틸 (순수 함수 — 단위 테스트 대상). P3a.
 *
 *  - 자동 독촉 단계: 수금예정일(dueDate) 기준 D+7 / D+30 도달 시 발송.
 *    computeDday(dueDate, now) 는 "남은 일수"(양수=미래) → 지난 경우 음수.
 *    D+7 = dday -7, D+30 = dday -30.
 *  - 같은 단계 중복 발송 방지: reminders 이력에 같은 stage 가 있으면 재발송 안 함.
 *  - 수동 독촉 쿨다운: 마지막 발송으로부터 3일 이내면 차단(409).
 */

export type ReminderStage = 'D7' | 'D30' | 'MANUAL';

/** 발송 이력 1건. */
export interface ReminderRecord {
  at: string; // ISO
  channel: 'push' | 'alimtalk'; // 발송 채널
  stage: ReminderStage;
}

export const REMINDER_STAGE_DAYS: Record<'D7' | 'D30', number> = {
  D7: 7,
  D30: 30,
};

export const MANUAL_REMIND_COOLDOWN_DAYS = 3;

/**
 * dday(남은 일수, 음수=지남)로부터 자동 독촉 단계를 판정.
 *  - dday === -7  → D7
 *  - dday === -30 → D30
 *  - 그 외 → null (발송 대상 아님)
 */
export function autoReminderStage(dday: number): 'D7' | 'D30' | null {
  if (dday === -REMINDER_STAGE_DAYS.D7) return 'D7';
  if (dday === -REMINDER_STAGE_DAYS.D30) return 'D30';
  return null;
}

/** 이력 배열 정규화(잘못된 값 제거). */
export function normalizeReminders(reminders: unknown): ReminderRecord[] {
  if (!Array.isArray(reminders)) return [];
  return reminders.filter(
    (r): r is ReminderRecord =>
      !!r &&
      typeof (r as ReminderRecord).at === 'string' &&
      typeof (r as ReminderRecord).stage === 'string',
  );
}

/** 같은 단계(D7/D30)가 이미 발송되었는지. */
export function hasStageBeenSent(
  reminders: unknown,
  stage: 'D7' | 'D30',
): boolean {
  return normalizeReminders(reminders).some((r) => r.stage === stage);
}

/** 이력 중 가장 최근 발송 시각(없으면 null). */
export function lastReminderAt(reminders: unknown): Date | null {
  const list = normalizeReminders(reminders);
  let latest: number | null = null;
  for (const r of list) {
    const t = new Date(r.at).getTime();
    if (Number.isFinite(t) && (latest == null || t > latest)) latest = t;
  }
  return latest == null ? null : new Date(latest);
}

/**
 * 수동 독촉 쿨다운 검사. 마지막 발송으로부터 3일 이내면 남은 시간을 반환(차단).
 *  - 반환 null: 발송 가능.
 *  - 반환 { blocked: true, retryAfterMs }: 쿨다운 중.
 */
export function manualCooldown(
  reminders: unknown,
  now: Date = new Date(),
): { blocked: boolean; retryAfterMs: number; lastAt: Date | null } {
  const last = lastReminderAt(reminders);
  if (!last) return { blocked: false, retryAfterMs: 0, lastAt: null };
  const cooldownMs = MANUAL_REMIND_COOLDOWN_DAYS * 24 * 60 * 60 * 1000;
  const elapsed = now.getTime() - last.getTime();
  if (elapsed >= cooldownMs) {
    return { blocked: false, retryAfterMs: 0, lastAt: last };
  }
  return { blocked: true, retryAfterMs: cooldownMs - elapsed, lastAt: last };
}
