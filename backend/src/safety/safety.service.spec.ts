import { SafetyService } from './safety.service';
import { AppException } from '../common/errors';

/** ack 1회 제한(재확인 409) 단위 검증 — prisma/notifications 목킹. */
describe('SafetyService.ack — 확인 1회 제한', () => {
  const notifications = { create: jest.fn() };

  function makeService(log: unknown) {
    const prisma = {
      safetyLog: {
        findUnique: jest.fn().mockResolvedValue(log),
        update: jest
          .fn()
          .mockResolvedValue({ ackAt: new Date('2026-07-11T05:00:00Z') }),
      },
    };
    const svc = new SafetyService(prisma as never, notifications as never);
    return { svc, prisma };
  }

  it('대상 본인이 최초 확인하면 ackAt 기록', async () => {
    const { svc, prisma } = makeService({
      id: 'log1',
      targetProfileId: 'u1',
      ackAt: null,
    });
    const res = await svc.ack('u1', 'log1');
    expect(res.acked).toBe(true);
    expect(prisma.safetyLog.update).toHaveBeenCalledTimes(1);
  });

  it('이미 ackAt 있으면 409 (재확인 불가)', async () => {
    const { svc, prisma } = makeService({
      id: 'log1',
      targetProfileId: 'u1',
      ackAt: new Date('2026-07-11T04:00:00Z'),
    });
    await expect(svc.ack('u1', 'log1')).rejects.toBeInstanceOf(AppException);
    expect(prisma.safetyLog.update).not.toHaveBeenCalled();
  });

  it('대상이 아닌 사용자는 404', async () => {
    const { svc } = makeService({
      id: 'log1',
      targetProfileId: 'u1',
      ackAt: null,
    });
    await expect(svc.ack('other', 'log1')).rejects.toBeInstanceOf(AppException);
  });
});
