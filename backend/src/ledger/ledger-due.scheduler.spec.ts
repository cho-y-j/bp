import { LedgerStatus, NotificationType } from '@prisma/client';
import { LedgerDueScheduler } from './ledger-due.scheduler';

function makeScheduler(opts: {
  entries: Array<Record<string, unknown>>;
  existing?: boolean;
}) {
  const notifications = { create: jest.fn().mockResolvedValue({}) };
  const prisma = {
    ledgerEntry: { findMany: jest.fn().mockResolvedValue(opts.entries) },
    notification: {
      findFirst: jest
        .fn()
        .mockResolvedValue(opts.existing ? { id: 'n1' } : null),
    },
  };
  const scheduler = new LedgerDueScheduler(
    prisma as never,
    notifications as never,
  );
  return { scheduler, notifications, prisma };
}

describe('LedgerDueScheduler', () => {
  const now = new Date('2026-07-11T00:00:00+09:00');
  const d0 = new Date('2026-07-11T05:00:00+09:00'); // 오늘(D-0)
  const d1 = new Date('2026-07-12T05:00:00+09:00'); // 내일(D-1)
  const d3 = new Date('2026-07-14T05:00:00+09:00'); // D-3 (대상 아님)

  it('수금예정 D-1/D-0 미수 항목마다 PAYMENT_DUE 알림 생성', async () => {
    const { scheduler, notifications } = makeScheduler({
      entries: [
        {
          id: 'l1',
          profileId: 'p1',
          amount: 100000,
          payments: [],
          dueDate: d0,
          status: LedgerStatus.PENDING,
          counterpartyName: 'A건설',
          business: null,
        },
        {
          id: 'l2',
          profileId: 'p1',
          amount: 100000,
          payments: [{ amount: 40000 }],
          dueDate: d1,
          status: LedgerStatus.PARTIAL,
          counterpartyName: null,
          business: { name: 'B산업' },
        },
        {
          id: 'l3',
          profileId: 'p1',
          amount: 100000,
          payments: [],
          dueDate: d3,
          status: LedgerStatus.PENDING,
          counterpartyName: 'C',
          business: null,
        },
      ],
    });
    const created = await scheduler.runDueScan(now);
    expect(created).toBe(2);
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({
        profileId: 'p1',
        type: NotificationType.PAYMENT_DUE,
        data: expect.objectContaining({ ledgerId: 'l1', dday: 0 }),
      }),
    );
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ ledgerId: 'l2', dday: 1 }),
      }),
    );
  });

  it('완납(미수 0) 항목은 알림 제외', async () => {
    const { scheduler, notifications } = makeScheduler({
      entries: [
        {
          id: 'l9',
          profileId: 'p1',
          amount: 100000,
          payments: [{ amount: 100000 }],
          dueDate: d0,
          status: LedgerStatus.PARTIAL, // status 필터 통과했다고 가정, 재확인으로 걸러짐
          counterpartyName: 'X',
          business: null,
        },
      ],
    });
    const created = await scheduler.runDueScan(now);
    expect(created).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('같은 장부·같은 D-day 중복 알림 방지', async () => {
    const { scheduler, notifications } = makeScheduler({
      entries: [
        {
          id: 'l1',
          profileId: 'p1',
          amount: 100000,
          payments: [],
          dueDate: d0,
          status: LedgerStatus.PENDING,
          counterpartyName: 'A',
          business: null,
        },
      ],
      existing: true,
    });
    const created = await scheduler.runDueScan(now);
    expect(created).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });
});
