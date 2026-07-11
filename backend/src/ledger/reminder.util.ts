/**
 * 수금 독촉 유틸 (순수 함수 — 단위 테스트 대상). P3a.
 *
 *  - 자동 독촉 단계: 수금예정일(dueDate) 기준 D+7 이상 / D+30 이상 경과 시 발송.
 *    computeDday(dueDate, now) 는 "남은 일수"(양수=미래) → 지난 경우 음수.
 *    D+7 = dday <= -7, D+30 = dday <= -30 (경계 이상 경과이면서 해당 단계 미발송).
 *    정확 일치가 아닌 "이상 경과"로 완화 → 크론 결번·늦은 autoRemind 토글 시에도 미발송 방지.
 *  - 같은 단계 중복 발송 방지: reminders 이력에 같은 stage 가 있으면 재발송 안 함.
 *  - 두 단계 동시 조건이면 높은 단계(D30) 하나만 발송(스팸 방지).
 *  - 수동 독촉 쿨다운: 마지막 발송으로부터 3일 이내면 차단(409).
 *  - reminders 이력은 최근 REMINDER_HISTORY_CAP 건만 유지(오래된 것 drop).
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

/** reminders 이력 최대 보관 건수(초과분은 오래된 순으로 drop). viewLogs cap 패턴과 동일. */
export const REMINDER_HISTORY_CAP = 20;

/**
 * dday(남은 일수, 음수=지남) + 발송 이력으로부터 다음에 보낼 자동 독촉 단계를 판정.
 *  - dday <= -30 이면서 D30 미발송 → D30 (동시 조건이면 높은 단계 우선, 스팸 방지)
 *  - dday <= -7  이면서 D7·D30 모두 미발송 → D7 (D30 이 이미 나갔으면 역행 발송 안 함)
 *  - 그 외(미도달 / 이미 발송) → null (발송 대상 아님)
 *
 * 정확 일치(=== -7/-30)가 아닌 "이상 경과"로 완화 → 크론이 하루 건너뛰거나
 * 작업자가 D+7 경과 후 autoRemind 를 켜도 미발송 단계는 다음 스캔에서 발송된다.
 * 이미 보낸 단계는 hasStageBeenSent 로 걸러 중복 발송을 막는다(기존 dedup 정합 유지).
 */
export function autoReminderStage(
  dday: number,
  reminders: unknown = [],
): 'D7' | 'D30' | null {
  const d7Sent = hasStageBeenSent(reminders, 'D7');
  const d30Sent = hasStageBeenSent(reminders, 'D30');
  if (dday <= -REMINDER_STAGE_DAYS.D30 && !d30Sent) {
    return 'D30';
  }
  // D30 이 이미 나갔으면 더 낮은 D7 은 재발송하지 않음(에스컬레이션만, 역행 스팸 방지).
  if (dday <= -REMINDER_STAGE_DAYS.D7 && !d7Sent && !d30Sent) {
    return 'D7';
  }
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

/**
 * 발송 이력에 record 를 append 하되 최근 REMINDER_HISTORY_CAP 건만 유지(오래된 것 drop).
 * viewLogs cap 패턴과 동일 — 장기 미수 항목에 수동 발송을 반복해도 배열이 무한 증가하지 않음.
 */
export function appendReminder(
  reminders: unknown,
  record: ReminderRecord,
): ReminderRecord[] {
  return [...normalizeReminders(reminders), record].slice(
    -REMINDER_HISTORY_CAP,
  );
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
