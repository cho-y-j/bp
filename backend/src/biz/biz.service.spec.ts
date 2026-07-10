import { BizService } from './biz.service';

/**
 * 정산 지급(pay) 양측 일치 단위 검증.
 *  - pay 는 작업자 장부(ledger_entry)에 직접 미수 전액을 입금 기록하고 PAID 전이한다.
 *  - 즉 작업자가 읽는 것과 사업장이 쓰는 것이 동일한 단일 레코드/데이터임을 확인.
 */
describe('BizService.pay — 정산 양측 일치', () => {
  it('미수 전액을 해당 ledger 에 입금 기록하고 PAID 로 전이한다', async () => {
    const entry = {
      id: 'L1',
      profileId: 'worker1',
      businessId: 'B1',
      amount: '715000',
      dueDate: null,
      payments: [] as unknown[],
    };
    const updateArgs: unknown[] = [];
    const prisma = {
      business: {
        findMany: jest.fn().mockResolvedValue([{ id: 'B1' }]),
      },
      ledgerEntry: {
        findMany: jest.fn().mockResolvedValue([entry]),
        update: jest.fn().mockImplementation((args: unknown) => {
          updateArgs.push(args);
          return Promise.resolve({});
        }),
      },
      // pay 는 read-modify-write 를 트랜잭션으로 감싼다 — 콜백에 tx(=자기 자신) 전달
      $transaction: jest
        .fn()
        .mockImplementation((cb: (tx: unknown) => unknown) => cb(prisma)),
    };
    const notifications = { create: jest.fn().mockResolvedValue({}) };
    const svc = new BizService(
      prisma as never,
      {} as never,
      notifications as never,
    );

    const res = await svc.pay('owner1', {
      ledgerEntryIds: ['L1'],
      memo: '7월 정산',
    });

    expect(res.paidCount).toBe(1);
    expect(res.totalPaid).toBe(715000);

    // 동일 ledger 레코드에 미수 전액(715000) 이 입금으로 기록되고 PAID 전이
    const arg = updateArgs[0] as {
      where: { id: string };
      data: { status: string; payments: Array<{ amount: number }> };
    };
    expect(arg.where.id).toBe('L1');
    expect(arg.data.status).toBe('PAID');
    expect(arg.data.payments[arg.data.payments.length - 1].amount).toBe(715000);

    // 작업자에게 입금 알림 (장부 PAID 를 작업자도 인지 → 양측 일치)
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({ profileId: 'worker1' }),
    );
  });

  it('이미 완납된 항목은 중복 입금하지 않는다', async () => {
    const entry = {
      id: 'L2',
      profileId: 'worker1',
      businessId: 'B1',
      amount: '100000',
      dueDate: null,
      payments: [{ amount: 100000 }],
    };
    const prisma = {
      business: { findMany: jest.fn().mockResolvedValue([{ id: 'B1' }]) },
      ledgerEntry: {
        findMany: jest.fn().mockResolvedValue([entry]),
        update: jest.fn().mockResolvedValue({}),
      },
      $transaction: jest
        .fn()
        .mockImplementation((cb: (tx: unknown) => unknown) => cb(prisma)),
    };
    const notifications = { create: jest.fn() };
    const svc = new BizService(
      prisma as never,
      {} as never,
      notifications as never,
    );
    const res = await svc.pay('owner1', { ledgerEntryIds: ['L2'] });
    expect(res.paidCount).toBe(0);
    expect(res.totalPaid).toBe(0);
    expect(prisma.ledgerEntry.update).not.toHaveBeenCalled();
  });
});
