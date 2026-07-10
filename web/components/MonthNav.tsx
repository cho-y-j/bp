'use client';

import { monthLabel, shiftMonth } from '@/lib/format';
import { Chevron, ChevronLeft } from './Icons';

export default function MonthNav({
  month,
  onChange,
}: {
  month: string;
  onChange: (m: string) => void;
}) {
  return (
    <div className="month-nav">
      <button
        onClick={() => onChange(shiftMonth(month, -1))}
        aria-label="이전 달"
      >
        <ChevronLeft />
      </button>
      <span className="label num">{monthLabel(month)}</span>
      <button
        onClick={() => onChange(shiftMonth(month, 1))}
        aria-label="다음 달"
      >
        <Chevron />
      </button>
    </div>
  );
}
