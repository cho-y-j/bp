import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { FileStorageService } from '../src/documents/file-storage.service';

/**
 * 서류 파일 미리보기 e2e (백로그 보강 — S4b 추가 엔드포인트):
 *  GET /documents/:id/file
 *    - variant 기본(original): 원본 이미지 스트림 (image/png)
 *    - variant=normalized: 정규화본 PDF
 *    - variant=masked: 마스킹본 PDF (없으면 정규화본)
 *  권한 격리: 타인 서류 접근 → 404 / 미인증 → 401 / 잘못된 UUID → 400.
 * 실제 임시 postgres(DATABASE_URL) + 로컬 파일 저장소에서 실행한다.
 */
describe('Document file preview (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storage: FileStorageService;

  // 소유자 A / 타인 B (권한 격리 검증용)
  const phoneA = '010-8888-0201';
  const normA = '01088880201';
  const phoneB = '010-8888-0202';
  const normB = '01088880202';
  let tokenA: string;
  let userA: string;
  let tokenB: string;
  let userB: string;
  let docId: string;

  async function makePng(): Promise<Buffer> {
    return sharp({
      create: {
        width: 400,
        height: 260,
        channels: 3,
        background: { r: 210, g: 220, b: 230 },
      },
    })
      .png()
      .toBuffer();
  }

  async function loginAs(
    phone: string,
  ): Promise<{ token: string; userId: string }> {
    const reqRes = await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone })
      .expect(200);
    const devCode: string = reqRes.body.data.devCode;
    const verifyRes = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone, code: devCode })
      .expect(200);
    return {
      token: verifyRes.body.data.accessToken,
      userId: verifyRes.body.data.profile.id,
    };
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api', { exclude: ['health'] });
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    prisma = app.get(PrismaService);
    storage = app.get(FileStorageService);
    for (const p of [normA, normB]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    ({ token: tokenA, userId: userA } = await loginAs(phoneA));
    ({ token: tokenB, userId: userB } = await loginAs(phoneB));

    const up = await request(app.getHttpServer())
      .post('/api/documents')
      .set('Authorization', `Bearer ${tokenA}`)
      .field('type', '신분증')
      .field('ownerType', 'PROFILE')
      .attach('file', await makePng(), {
        filename: 'id.png',
        contentType: 'image/png',
      })
      .expect(201);
    docId = up.body.data.id;
  });

  afterAll(async () => {
    await storage.removeDocumentDir(userA, userA).catch(() => {});
    await storage.removeDocumentDir(userB, userB).catch(() => {});
    for (const p of [normA, normB]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  it('소유자: 기본(original) → 원본 이미지 스트림 + inline disposition', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file`)
      .set('Authorization', `Bearer ${tokenA}`)
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('image/png');
    expect(res.headers['content-disposition']).toContain('inline');
    // PNG 매직넘버 (\x89PNG)
    expect(res.body[0]).toBe(0x89);
    expect(res.body.subarray(1, 4).toString('latin1')).toBe('PNG');
  });

  it('소유자: variant=normalized → 정규화본 PDF', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file?variant=normalized`)
      .set('Authorization', `Bearer ${tokenA}`)
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  it('소유자: variant=masked (마스킹 전) → 정규화본 PDF 폴백', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file?variant=masked`)
      .set('Authorization', `Bearer ${tokenA}`)
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  it('소유자: 마스킹 후 variant=masked → 마스킹본 PDF', async () => {
    await request(app.getHttpServer())
      .post(`/api/documents/${docId}/mask`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        regions: [{ page: 0, x: 0.1, y: 0.2, width: 0.4, height: 0.08 }],
      })
      .expect(201);
    const res = await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file?variant=masked`)
      .set('Authorization', `Bearer ${tokenA}`)
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  it('권한 격리: 타인(B)이 A의 서류 파일 요청 → 404 DOCUMENT_NOT_FOUND', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);
    expect(res.body.error.code).toBe('DOCUMENT_NOT_FOUND');
  });

  it('권한 격리: 타인(B)은 variant=masked 로도 접근 불가 → 404', async () => {
    await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file?variant=masked`)
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(404);
  });

  it('미인증 → 401', async () => {
    await request(app.getHttpServer())
      .get(`/api/documents/${docId}/file`)
      .expect(401);
  });

  it('잘못된 UUID → 400', async () => {
    await request(app.getHttpServer())
      .get('/api/documents/not-a-uuid/file')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(400);
  });

  it('존재하지 않는 서류 → 404', async () => {
    await request(app.getHttpServer())
      .get('/api/documents/00000000-0000-4000-8000-000000000000/file')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(404);
  });
});
