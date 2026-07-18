import { ConfirmationsService } from './confirmations.service';

/**
 * 서명 TOCTOU(동시성) 단위 검증.
 *  applySignature 는 `updateMany where status != SIGNED` 원자적 전이를 쓴다.
 *  두 요청이 동시에 SENT 스냅샷을 읽어도, 실제 전이는 하나만 성공(count=1)하고
 *  나머지는 count=0 → 409(ALREADY_SIGNED) 로 거부돼야 한다.
 */
describe('ConfirmationsService.applySignature — 서명 동시성(TOCTOU)', () => {
  // 1x1 유효 PNG data URI (decodeSignPng 통과용)
  const PNG_DATA_URI =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  function makeService(updateManyCounts: number[]) {
    const sent = {
      id: 'C1',
      profileId: 'worker1',
      businessId: null,
      shareToken: 'tok',
      revokedAt: null,
      site: '현장',
      status: 'SENT',
    };
    let call = 0;
    const prisma = {
      confirmation: {
        // loadValidByToken: 두 요청 모두 아직 SENT 스냅샷을 읽는다(경합 전제)
        findUnique: jest.fn().mockResolvedValue(sent),
        // 원자적 전이: 첫 호출만 count=1, 이후 count=0
        updateMany: jest.fn().mockImplementation(() => {
          const count = updateManyCounts[call++] ?? 0;
          return Promise.resolve({ count });
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          ...sent,
          status: 'SIGNED',
          signerName: '김사장',
          signedAt: new Date(),
        }),
      },
    };
    const storage = {
      buildKey: jest.fn().mockReturnValue('uploads/worker1/C1/signature.png'),
      writeFile: jest.fn().mockResolvedValue(undefined),
    };
    const notifications = { create: jest.fn().mockResolvedValue({}) };
    const partners = {
      safeUpsertFromManualCounterparty: jest.fn().mockResolvedValue(undefined),
    };
    const svc = new ConfirmationsService(
      prisma as never,
      storage as never,
      {} as never,
      notifications as never,
      {} as never,
      partners as never,
    );
    return { svc, prisma };
  }

  it('동시 서명 경합: 하나만 성공하고 나머지는 409', async () => {
    const { svc } = makeService([1, 0]);
    const dto = { signerName: '김사장', signImageBase64: PNG_DATA_URI };

    const first = await svc.publicSign('tok', dto as never);
    expect(first.signed).toBe(true);
    expect(first.status).toBe('SIGNED');

    await expect(svc.publicSign('tok', dto as never)).rejects.toMatchObject({
      response: { code: 'ALREADY_SIGNED' },
    });
  });

  it('전이 실패(count=0) 는 409 로 거부', async () => {
    const { svc } = makeService([0]);
    const dto = { signerName: '김사장', signImageBase64: PNG_DATA_URI };
    await expect(svc.publicSign('tok', dto as never)).rejects.toMatchObject({
      response: { code: 'ALREADY_SIGNED' },
    });
  });
});
