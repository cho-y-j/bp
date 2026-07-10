import { NotificationType } from '@prisma/client';
import { DocumentExpiryScheduler } from './document-expiry.scheduler';

function makeScheduler(opts: {
  targets: Array<{
    doc: { id: string; type: string };
    dday: number;
    ownerProfileId: string;
  }>;
  existing?: boolean;
}) {
  const documents = {
    findByDdayTargets: jest.fn().mockResolvedValue(opts.targets),
  };
  const notifications = { create: jest.fn().mockResolvedValue({}) };
  const prisma = {
    notification: {
      findFirst: jest
        .fn()
        .mockResolvedValue(opts.existing ? { id: 'n1' } : null),
    },
  };
  const scheduler = new DocumentExpiryScheduler(
    documents as never,
    notifications as never,
    prisma as never,
  );
  return { scheduler, documents, notifications, prisma };
}

describe('DocumentExpiryScheduler', () => {
  it('D-30/7/0 대상마다 DOCUMENT_EXPIRY 알림을 생성한다', async () => {
    const { scheduler, notifications } = makeScheduler({
      targets: [
        { doc: { id: 'd1', type: '자격증' }, dday: 30, ownerProfileId: 'p1' },
        { doc: { id: 'd2', type: '보험증권' }, dday: 7, ownerProfileId: 'p1' },
        { doc: { id: 'd3', type: '신분증' }, dday: 0, ownerProfileId: 'p2' },
      ],
    });
    const created = await scheduler.runExpiryScan(new Date());
    expect(created).toBe(3);
    expect(notifications.create).toHaveBeenCalledTimes(3);
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({
        profileId: 'p2',
        type: NotificationType.DOCUMENT_EXPIRY,
        data: expect.objectContaining({ documentId: 'd3', dday: 0 }),
      }),
    );
  });

  it('이미 같은 서류·D-day 로 알림이 있으면 스킵(중복 방지)', async () => {
    const { scheduler, notifications } = makeScheduler({
      targets: [
        { doc: { id: 'd1', type: '자격증' }, dday: 30, ownerProfileId: 'p1' },
      ],
      existing: true,
    });
    const created = await scheduler.runExpiryScan(new Date());
    expect(created).toBe(0);
    expect(notifications.create).not.toHaveBeenCalled();
  });
});
