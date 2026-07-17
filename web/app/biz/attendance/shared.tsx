'use client';

/** 오늘 출역 현황 공유 타입·컴포넌트 (page.tsx 는 라우트 규약상 임의 export 불가 → 분리). */

export interface AttendanceWorker {
  jobId: string;
  workerName: string;
  status: 'SCHEDULED' | 'ACCEPTED' | 'STARTED' | 'DONE' | 'CANCELLED';
  scheduledAt: string;
  startedAt: string | null;
  finishedAt: string | null;
  condition: string | null;
}
export interface AttendanceSummary {
  total: number;
  attended: number;
  completed: number;
  absent: number;
}
export interface AttendanceSite {
  site: string;
  workers: AttendanceWorker[];
  summary: AttendanceSummary;
}
export interface TodayAttendance {
  date: string;
  sites: AttendanceSite[];
  summary: AttendanceSummary;
}

export const STATUS_META: Record<
  AttendanceWorker['status'],
  { cls: string; text: string }
> = {
  SCHEDULED: { cls: 'calm', text: '예정' },
  ACCEPTED: { cls: 'soon', text: '수락' },
  STARTED: { cls: 'accent', text: '작업중' },
  DONE: { cls: 'done', text: '완료' },
  CANCELLED: { cls: 'warn', text: '취소' },
};

export const CONDITION_LABEL: Record<string, string> = {
  OK: '양호',
  TIRED: '피로',
  BAD: '나쁨',
  SICK: '아픔',
};

/** 오늘 출역 요약 4지표 타일. inbox 요약 카드와 상세 페이지가 공유. */
export function AttendanceStats({ summary }: { summary: AttendanceSummary }) {
  const cells: { label: string; value: number; color?: string }[] = [
    { label: '오늘 인원', value: summary.total },
    { label: '출근', value: summary.attended, color: 'var(--deposited)' },
    { label: '완료', value: summary.completed, color: 'var(--accent-text)' },
    { label: '미출근', value: summary.absent, color: 'var(--receivable)' },
  ];
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: 10,
      }}
    >
      {cells.map((c) => (
        <div
          key={c.label}
          style={{
            background: 'var(--surface-2)',
            border: '1px solid var(--border)',
            borderRadius: 12,
            padding: '12px 8px',
            textAlign: 'center',
          }}
        >
          <div
            className="num"
            style={{ fontSize: 26, fontWeight: 800, color: c.color }}
          >
            {c.value}
          </div>
          <div style={{ fontSize: 13, color: 'var(--ink-2)', fontWeight: 600 }}>
            {c.label}
          </div>
        </div>
      ))}
    </div>
  );
}
