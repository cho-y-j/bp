import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { PDFDocument } from 'pdf-lib';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { FileStorageService } from '../src/documents/file-storage.service';

/**
 * 서류 도메인 e2e:
 *  업로드(PNG) → PDF 정규화 확인 → 마스킹 → 묶음 공유 → public 열람 → 로그 기록
 *  → 만료 링크 403 / 무효화 403.
 * 실제 임시 postgres(DATABASE_URL) + 로컬 파일 저장소에서 실행한다.
 */
describe('Documents flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let storage: FileStorageService;
  let token: string;
  let userId: string;
  const phone = '010-8888-0001';
  const normalized = '01088880001';
  // 오늘(KST 달력일) YYYY-MM-DD — D-0(오늘 만료) 검증용 동적 날짜.
  // dday.util 이 KST(UTC+9) 자정을 기준으로 D-day 를 계산하므로 동일 기준으로 산출.
  const kstTodayIso = new Date(Date.now() + 9 * 60 * 60 * 1000)
    .toISOString()
    .slice(0, 10);

  async function makePng(): Promise<Buffer> {
    return sharp({
      create: {
        width: 400,
        height: 260,
        channels: 3,
        background: { r: 230, g: 230, b: 230 },
      },
    })
      .png()
      .toBuffer();
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
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    await prisma.profile.deleteMany({ where: { phone: normalized } });

    const reqRes = await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone })
      .expect(200);
    const devCode: string = reqRes.body.data.devCode;
    const verifyRes = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone, code: devCode })
      .expect(200);
    token = verifyRes.body.data.accessToken;
    userId = verifyRes.body.data.profile.id;
  });

  afterAll(async () => {
    await prisma.profile.deleteMany({ where: { phone: normalized } });
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    await storage.removeDocumentDir(userId, userId).catch(() => {}); // best-effort; 실제 정리는 아래 rm
    await app.close();
  });

  const auth = () => `Bearer ${token}`;

  it('업로드(PNG) → PDF 정규화 + 원본 보존', async () => {
    const png = await makePng();
    const res = await request(app.getHttpServer())
      .post('/api/documents')
      .set('Authorization', auth())
      .field('type', '신분증')
      .field('ownerType', 'PROFILE')
      .field('expiryDate', kstTodayIso) // 오늘 만료 → D-0 (동적: 오늘 KST 날짜)
      .attach('file', png, { filename: 'id.png', contentType: 'image/png' })
      .expect(201);

    const doc = res.body.data;
    expect(doc.mimeType).toBe('image/png');
    expect(doc.type).toBe('신분증');
    expect(doc.hasMask).toBe(false);
    expect(doc.dday).toBe(0);
    expect(doc.derivedStatus).toBe('EXPIRING');

    // 정규화본은 PDF (헤더 %PDF), 원본은 PNG (헤더 \x89PNG)
    const dbDoc = await prisma.document.findUniqueOrThrow({
      where: { id: doc.id },
    });
    const normalizedBuf = await storage.readFile(dbDoc.filePath);
    expect(normalizedBuf.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    const originalBuf = await storage.readFile(dbDoc.originalFilePath!);
    expect(originalBuf[0]).toBe(0x89);
    expect(originalBuf.subarray(1, 4).toString('latin1')).toBe('PNG');
    const pageCount = (await PDFDocument.load(normalizedBuf)).getPageCount();
    expect(pageCount).toBe(1);

    (globalThis as Record<string, unknown>).__docId = doc.id;
    (globalThis as Record<string, unknown>).__normalizedSize =
      normalizedBuf.length;
  });

  it('허용되지 않은 파일 형식 → 400', async () => {
    await request(app.getHttpServer())
      .post('/api/documents')
      .set('Authorization', auth())
      .field('type', '신분증')
      .field('ownerType', 'PROFILE')
      .attach('file', Buffer.from('hello'), {
        filename: 'a.txt',
        contentType: 'text/plain',
      })
      .expect(400);
  });

  it('마스킹본 생성 → 검정 사각형 오버레이된 PDF 산출', async () => {
    const docId = (globalThis as Record<string, unknown>).__docId as string;
    const normalizedSize = (globalThis as Record<string, unknown>)
      .__normalizedSize as number;

    const res = await request(app.getHttpServer())
      .post(`/api/documents/${docId}/mask`)
      .set('Authorization', auth())
      .send({
        regions: [
          { page: 0, x: 0.1, y: 0.2, width: 0.4, height: 0.08 },
          { page: 0, x: 0.1, y: 0.35, width: 0.5, height: 0.08 },
        ],
      })
      .expect(201);
    expect(res.body.data.hasMask).toBe(true);
    expect(res.body.data.maskRegions).toBe(2);

    const dbDoc = await prisma.document.findUniqueOrThrow({
      where: { id: docId },
    });
    expect(dbDoc.maskedFilePath).toBeTruthy();
    const maskedBuf = await storage.readFile(dbDoc.maskedFilePath!);
    expect(maskedBuf.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    const maskedPdf = await PDFDocument.load(maskedBuf);
    expect(maskedPdf.getPageCount()).toBe(1);
    // 사각형이 추가되어 정규화본보다 크기가 커진다
    expect(maskedBuf.length).toBeGreaterThan(normalizedSize);
  });

  it('묶음 공유 → public 열람 → 마스킹본 스트림 + 열람 로그', async () => {
    const docId = (globalThis as Record<string, unknown>).__docId as string;

    const shareRes = await request(app.getHttpServer())
      .post('/api/document-shares')
      .set('Authorization', auth())
      .send({ documentIds: [docId], expiresInDays: 7 })
      .expect(201);
    const shareToken: string = shareRes.body.data.shareToken;
    expect(shareToken).toHaveLength(32);
    expect(shareRes.body.data.url).toContain(`/s/${shareToken}`);

    // public 메타 열람 (로그인 없이)
    const viewRes = await request(app.getHttpServer())
      .get(`/api/public/shares/${shareToken}`)
      .set('User-Agent', 'e2e-agent')
      .expect(200);
    expect(viewRes.body.data.documents).toHaveLength(1);
    expect(viewRes.body.data.documents[0].masked).toBe(true);
    const fileUrl: string = viewRes.body.data.documents[0].fileUrl;

    // public 파일 스트림 → PDF (바이너리 응답)
    const fileRes = await request(app.getHttpServer())
      .get(fileUrl)
      .responseType('blob')
      .expect(200);
    expect(fileRes.headers['content-type']).toContain('application/pdf');
    expect(fileRes.headers['content-disposition']).toContain(
      "filename*=UTF-8''",
    );
    expect(fileRes.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');

    // 열람 로그 기록 확인
    const listRes = await request(app.getHttpServer())
      .get('/api/document-shares')
      .set('Authorization', auth())
      .expect(200);
    const share = listRes.body.data.items.find(
      (s: { shareToken: string }) => s.shareToken === shareToken,
    );
    expect(share.viewCount).toBeGreaterThanOrEqual(1);
    expect(share.viewLogs[0].ua).toBe('e2e-agent');

    (globalThis as Record<string, unknown>).__shareToken = shareToken;
    (globalThis as Record<string, unknown>).__shareId = shareRes.body.data.id;
  });

  it('만료된 공유 링크 → 403', async () => {
    const shareId = (globalThis as Record<string, unknown>).__shareId as string;
    const shareToken = (globalThis as Record<string, unknown>)
      .__shareToken as string;
    // 만료 시각을 과거로 조정
    await prisma.documentShare.update({
      where: { id: shareId },
      data: { expiresAt: new Date(Date.now() - 1000) },
    });
    const res = await request(app.getHttpServer())
      .get(`/api/public/shares/${shareToken}`)
      .expect(403);
    expect(res.body.error.code).toBe('SHARE_EXPIRED');
  });

  it('무효화된 공유 링크 → 403', async () => {
    // 새 공유 생성 후 즉시 무효화
    const docId = (globalThis as Record<string, unknown>).__docId as string;
    const shareRes = await request(app.getHttpServer())
      .post('/api/document-shares')
      .set('Authorization', auth())
      .send({ documentIds: [docId] })
      .expect(201);
    const shareId = shareRes.body.data.id;
    const shareToken = shareRes.body.data.shareToken;

    await request(app.getHttpServer())
      .delete(`/api/document-shares/${shareId}`)
      .set('Authorization', auth())
      .expect(200);

    const res = await request(app.getHttpServer())
      .get(`/api/public/shares/${shareToken}`)
      .expect(403);
    expect(res.body.error.code).toBe('SHARE_REVOKED');
  });

  it('만료 임박 목록(?days=30)에 오늘 만료 서류 포함', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/documents/expiring?days=30')
      .set('Authorization', auth())
      .expect(200);
    const docId = (globalThis as Record<string, unknown>).__docId as string;
    const ids = res.body.data.items.map((d: { id: string }) => d.id);
    expect(ids).toContain(docId);
  });

  it('진위확인: 비-사업자등록증 → UNSUPPORTED(수동확인), 상태 유지', async () => {
    const docId = (globalThis as Record<string, unknown>).__docId as string;
    const res = await request(app.getHttpServer())
      .post(`/api/documents/${docId}/verify`)
      .set('Authorization', auth())
      .send({})
      .expect(201);
    expect(res.body.data.verification.result).toBe('UNSUPPORTED');
    expect(res.body.data.verification.manualCheck).toBe(true);
  });

  it('진위확인: 사업자등록증 + 키 미설정 → 501', async () => {
    const png = await makePng();
    const up = await request(app.getHttpServer())
      .post('/api/documents')
      .set('Authorization', auth())
      .field('type', '사업자등록증')
      .field('ownerType', 'PROFILE')
      .attach('file', png, { filename: 'biz.png', contentType: 'image/png' })
      .expect(201);
    const bizId = up.body.data.id;
    const res = await request(app.getHttpServer())
      .post(`/api/documents/${bizId}/verify`)
      .set('Authorization', auth())
      .send({
        businessNumber: '123-45-67890',
        openingDate: '20200101',
        representativeName: '홍길동',
      })
      .expect(501);
    expect(res.body.error.code).toBe('NOT_IMPLEMENTED');
  });

  it('장비 서류: 장비 생성 → 장비 소속 서류 업로드 + 그룹 조회', async () => {
    const eqRes = await request(app.getHttpServer())
      .post('/api/equipments')
      .set('Authorization', auth())
      .send({ type: '굴삭기', spec: '06W' })
      .expect(201);
    const equipmentId = eqRes.body.data.id;

    const png = await makePng();
    await request(app.getHttpServer())
      .post('/api/documents')
      .set('Authorization', auth())
      .field('type', '장비검사증')
      .field('ownerType', 'EQUIPMENT')
      .field('equipmentId', equipmentId)
      .attach('file', png, { filename: 'eq.png', contentType: 'image/png' })
      .expect(201);

    const grouped = await request(app.getHttpServer())
      .get('/api/documents?groupByEquipment=true')
      .set('Authorization', auth())
      .expect(200);
    const eqGroup = grouped.body.data.equipments.find(
      (g: { equipment: { id: string } }) => g.equipment.id === equipmentId,
    );
    expect(eqGroup.items.length).toBe(1);
    expect(eqGroup.items[0].type).toBe('장비검사증');
  });
});
