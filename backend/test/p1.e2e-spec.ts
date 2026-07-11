import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P1 기능 e2e (임시 postgres):
 *  1) 공수(GONGSU) 확인서 작성(1.5공수×180,000=270,000) → amountCalc unit=공수 → PDF 200
 *     → ledger summary totalGongsu 집계.
 *  2) 세금계산서 1단계: 프로필 bizNumber 등록 → 확인서 서명(SIGNED) →
 *     tax-invoice-data 조회(포함) → mark → 재조회(제외).
 *  3) 카카오 연결 엔드포인트: KAKAO_ENABLED 미설정 → 501.
 */
describe('P1 features (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  const phone = '010-7777-9001';
  const normalized = '01077779001';

  async function signPngDataUri(): Promise<string> {
    const png = await sharp({
      create: {
        width: 160,
        height: 60,
        channels: 4,
        background: { r: 10, g: 20, b: 200, alpha: 1 },
      },
    })
      .png()
      .toBuffer();
    return `data:image/png;base64,${png.toString('base64')}`;
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
    await prisma.profile.deleteMany({ where: { phone: normalized } });
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });

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
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '김기사' })
      .expect(200);
  });

  afterAll(async () => {
    await prisma.profile.deleteMany({ where: { phone: normalized } });
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    await app.close();
  });

  const auth = () => `Bearer ${token}`;
  const store: Record<string, string> = {};

  it('공수 확인서 작성: 1.5공수 × 180,000 = 270,000 (unit=공수)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth())
      .send({
        date: '2026-07-08',
        siteName: '공수현장',
        companyName: '공수건설',
        contact: '010-2222-3333',
        workDescription: '굴착기 공수 작업',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'GONGSU',
        rate: 180000,
        quantity: 1.5,
      })
      .expect(201);
    const data = res.body.data;
    store.gongsuId = data.id;
    store.gongsuToken = data.shareToken;
    expect(data.rateType).toBe('GONGSU');
    expect(data.rateTypeLabel).toBe('공수');
    expect(data.total).toBe(270000);
    const base = data.amountCalc.items[0];
    expect(base.unit).toBe('공수');
    expect(base.quantity).toBe(1.5);
    expect(base.amount).toBe(270000);
  });

  it('공수 수량 0.1 단위 위반 → 400', async () => {
    await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth())
      .send({
        date: '2026-07-08',
        siteName: '공수현장',
        companyName: '공수건설',
        workDescription: 'x',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'GONGSU',
        rate: 180000,
        quantity: 0.05,
      })
      .expect(400);
  });

  it('공수 확인서 PDF 200 (%PDF)', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/confirmations/${store.gongsuId}/pdf`)
      .set('Authorization', auth())
      .buffer(true)
      .parse((r, cb) => {
        const chunks: Buffer[] = [];
        r.on('data', (c: Buffer) => chunks.push(c));
        r.on('end', () => cb(null, Buffer.concat(chunks)));
      })
      .expect(200);
    const buf = res.body as Buffer;
    expect(buf.subarray(0, 4).toString('latin1')).toBe('%PDF');
  });

  it('ledger summary: totalGongsu = 1.5', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/summary?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    expect(res.body.data.totalGongsu).toBe(1.5);
  });

  it('세금계산서: bizNumber 등록 → 서명 → tax-invoice-data 포함', async () => {
    // 공급자 사업자번호 등록
    const meRes = await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', auth())
      .send({
        bizNumber: '111-22-33333',
        bizName: '김기사중기',
        bizAddress: '서울시 강남구',
      })
      .expect(200);
    expect(meRes.body.data.bizNumber).toBe('111-22-33333');

    // 서명 전: 아직 SIGNED 아님 → 집계에 없음
    const before = await request(app.getHttpServer())
      .get('/api/ledger/tax-invoice-data?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    expect(before.body.data.supplierReady).toBe(true);
    expect(before.body.data.groupCount).toBe(0);

    // 전송 후 공개 서명 → SIGNED
    await request(app.getHttpServer())
      .post(`/api/confirmations/${store.gongsuId}/send`)
      .set('Authorization', auth())
      .expect(201);
    const dataUri = await signPngDataUri();
    await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.gongsuToken}/sign`)
      .send({ signerName: '공수건설담당', signImageBase64: dataUri })
      .expect(201);

    // 서명 후: 집계에 포함
    const after = await request(app.getHttpServer())
      .get('/api/ledger/tax-invoice-data?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    const d = after.body.data;
    expect(d.groupCount).toBe(1);
    const g = d.groups[0];
    expect(g.buyerName).toBe('공수건설');
    expect(g.supplyTotal).toBe(270000);
    expect(g.taxTotal).toBe(27000);
    expect(g.grandTotal).toBe(297000);
    expect(g.ledgerIds.length).toBe(1);
    expect(d.text).toContain('111-22-33333');
    expect(d.text).toContain('공급가액: 270,000원');
    store.markLedgerId = g.ledgerIds[0];
  });

  it('세금계산서: mark → 재조회 시 제외', async () => {
    const mark = await request(app.getHttpServer())
      .post('/api/ledger/tax-invoice-data/mark')
      .set('Authorization', auth())
      .send({ ledgerIds: [store.markLedgerId] })
      .expect(201);
    expect(mark.body.data.marked).toBe(1);

    const after = await request(app.getHttpServer())
      .get('/api/ledger/tax-invoice-data?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    expect(after.body.data.groupCount).toBe(0);

    // 재마킹 → alreadyMarked
    const remark = await request(app.getHttpServer())
      .post('/api/ledger/tax-invoice-data/mark')
      .set('Authorization', auth())
      .send({ ledgerIds: [store.markLedgerId] })
      .expect(201);
    expect(remark.body.data.marked).toBe(0);
    expect(remark.body.data.alreadyMarked).toBe(1);
  });

  it('카카오 연결: KAKAO_ENABLED 미설정 → 501', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/kakao/link')
      .set('Authorization', auth())
      .send({ accessToken: 'dummy-access-token-123' })
      .expect(501);
  });
});
