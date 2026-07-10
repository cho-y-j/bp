import { ConfigService } from '@nestjs/config';
import { DocumentSharesService } from './document-shares.service';
import { AppException } from '../common/errors';

const DAY_MS = 24 * 60 * 60 * 1000;

function makeShareRow(overrides: Record<string, unknown> = {}) {
  return {
    id: 'share-1',
    ownerId: 'owner-1',
    shareToken: 'tok_abc',
    expiresAt: new Date(Date.now() + 7 * DAY_MS),
    revokedAt: null,
    useMasked: true,
    viewLogs: [],
    createdAt: new Date(),
    documents: [
      {
        documentId: 'doc-1',
        useOriginal: false,
        document: {
          id: 'doc-1',
          type: '사업자등록증',
          filePath: 'owner-1/doc-1/normalized.pdf',
          maskedFilePath: 'owner-1/doc-1/masked.pdf',
          issuedDate: null,
          expiryDate: null,
        },
      },
      {
        documentId: 'doc-2',
        useOriginal: true,
        document: {
          id: 'doc-2',
          type: '신분증',
          filePath: 'owner-1/doc-2/normalized.pdf',
          maskedFilePath: null,
          issuedDate: null,
          expiryDate: null,
        },
      },
    ],
    ...overrides,
  };
}

function makeService(prismaOverrides: Record<string, any> = {}) {
  const prisma = {
    document: {
      findMany: jest.fn(),
    },
    documentShare: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn().mockResolvedValue({}),
    },
    ...prismaOverrides,
  };
  const config = {
    get: (k: string) =>
      k === 'PUBLIC_WEB_URL' ? 'https://app.example.com' : undefined,
  } as unknown as ConfigService;
  const service = new DocumentSharesService(prisma as never, config);
  return { service, prisma };
}

describe('DocumentSharesService', () => {
  describe('create (권한 검증)', () => {
    it('본인 서류가 아니면 DOCUMENT_NOT_FOUND', async () => {
      const { service, prisma } = makeService();
      // 2개 요청했는데 1개만 소유 → mismatch
      prisma.document.findMany.mockResolvedValue([{ id: 'doc-1' }]);
      await expect(
        service.create('owner-1', { documentIds: ['doc-1', 'doc-2'] }),
      ).rejects.toBeInstanceOf(AppException);
    });

    it('전부 본인 서류면 토큰+URL 발급, 유효기간은 최대 30일로 캡', async () => {
      const { service, prisma } = makeService();
      prisma.document.findMany.mockResolvedValue([
        { id: 'doc-1' },
        { id: 'doc-2' },
      ]);
      prisma.documentShare.create.mockImplementation(
        ({ data }: { data: { shareToken: string } }) =>
          Promise.resolve({ id: 'share-1', shareToken: data.shareToken }),
      );
      const res = await service.create('owner-1', {
        documentIds: ['doc-1', 'doc-2'],
        expiresInDays: 999,
        perDocument: [{ documentId: 'doc-2', useOriginal: true }],
      });
      expect(res.shareToken).toHaveLength(32);
      expect(res.url).toBe(`https://app.example.com/s/${res.shareToken}`);
      expect(res.documentCount).toBe(2);
      // 30일 캡 확인
      const capMs = 30 * DAY_MS;
      const diff = res.expiresAt.getTime() - Date.now();
      expect(diff).toBeLessThanOrEqual(capMs + 1000);
      expect(diff).toBeGreaterThan(capMs - 1000);
      // per-document useOriginal 반영
      const created = prisma.documentShare.create.mock.calls[0][0];
      const joinRows = created.data.documents.create;
      expect(joinRows).toContainEqual({
        documentId: 'doc-2',
        useOriginal: true,
      });
      expect(joinRows).toContainEqual({
        documentId: 'doc-1',
        useOriginal: false,
      });
    });
  });

  describe('revoke', () => {
    it('소유자가 아니면 SHARE_NOT_FOUND', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(
        makeShareRow({ ownerId: 'someone-else' }),
      );
      await expect(service.revoke('owner-1', 'share-1')).rejects.toBeInstanceOf(
        AppException,
      );
    });

    it('소유자면 revokedAt 설정', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(makeShareRow());
      const res = await service.revoke('owner-1', 'share-1');
      expect(res.revoked).toBe(true);
      expect(prisma.documentShare.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ revokedAt: expect.any(Date) }),
        }),
      );
    });
  });

  describe('publicView (만료/무효화)', () => {
    it('만료된 링크 → SHARE_EXPIRED (403)', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(
        makeShareRow({ expiresAt: new Date(Date.now() - 1000) }),
      );
      try {
        await service.publicView('tok_abc', '1.2.3.4', 'UA');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getStatus()).toBe(403);
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'SHARE_EXPIRED',
        });
      }
    });

    it('무효화된 링크 → SHARE_REVOKED (403)', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(
        makeShareRow({ revokedAt: new Date() }),
      );
      try {
        await service.publicView('tok_abc', '1.2.3.4', 'UA');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getStatus()).toBe(403);
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'SHARE_REVOKED',
        });
      }
    });

    it('알 수 없는 토큰 → SHARE_NOT_FOUND (404)', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(null);
      try {
        await service.publicView('nope', '1.2.3.4', 'UA');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getStatus()).toBe(404);
      }
    });

    it('유효한 링크 → viewLog append + 메타 반환', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(makeShareRow());
      const res = await service.publicView('tok_abc', '9.9.9.9', 'Mozilla');
      expect(res.documents).toHaveLength(2);
      // doc-1: 마스킹본 존재 + useOriginal=false → masked true
      expect(res.documents[0]).toMatchObject({
        documentId: 'doc-1',
        masked: true,
      });
      // doc-2: useOriginal=true → masked false
      expect(res.documents[1]).toMatchObject({
        documentId: 'doc-2',
        masked: false,
      });
      // 로그 append 확인
      const updateArg = prisma.documentShare.update.mock.calls[0][0];
      expect(updateArg.data.viewLogs).toHaveLength(1);
      expect(updateArg.data.viewLogs[0]).toMatchObject({
        ip: '9.9.9.9',
        ua: 'Mozilla',
      });
    });
  });

  describe('resolvePublicFile (마스킹 정책)', () => {
    it('useOriginal=false + 마스킹본 존재 → 마스킹본 경로', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(makeShareRow());
      const res = await service.resolvePublicFile('tok_abc', 'doc-1');
      expect(res.relPath).toBe('owner-1/doc-1/masked.pdf');
      expect(res.downloadName).toBe('사업자등록증.pdf');
    });

    it('useOriginal=true → 원본(정규화본) 경로', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(makeShareRow());
      const res = await service.resolvePublicFile('tok_abc', 'doc-2');
      expect(res.relPath).toBe('owner-1/doc-2/normalized.pdf');
    });

    it('공유에 없는 서류 → DOCUMENT_NOT_IN_SHARE', async () => {
      const { service, prisma } = makeService();
      prisma.documentShare.findUnique.mockResolvedValue(makeShareRow());
      await expect(
        service.resolvePublicFile('tok_abc', 'doc-999'),
      ).rejects.toBeInstanceOf(AppException);
    });
  });
});
