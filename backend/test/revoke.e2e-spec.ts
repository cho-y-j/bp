import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * 백로그정리 — 공유 링크 무효화(revoke) e2e (임시 postgres):
 *   확인서(발행자 POST /confirmations/:id/revoke) + 계약서(사업장 POST /biz/contracts/:id/revoke).
 *   정책: SENT 만 무효화 가능(→ public 403). SIGNED 는 증빙 보존 → 409. DRAFT → 409. 권한 격리 404.
 */
describe('Share link revoke flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const worker = { phone: '010-8222-0001', norm: '01082220001', token: '', name: '김발행' };
  const boss = { phone: '010-8222-0002', norm: '01082220002', token: '', name: '사장님' };
  const outsider = { phone: '010-8222-0003', norm: '01082220003', token: '' };
  const store: Record<string, string> = {};

  async function signup(phone: string): Promise<string> {
    const reqRes = await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone })
      .expect(200);
    const devCode: string = reqRes.body.data.devCode;
    const verifyRes = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone, code: devCode })
      .expect(200);
    return verifyRes.body.data.accessToken;
  }

  async function signPngDataUri(): Promise<string> {
    const png = await sharp({
      create: { width: 200, height: 80, channels: 4, background: { r: 0, g: 0, b: 200, alpha: 1 } },
    })
      .png()
      .toBuffer();
    return `data:image/png;base64,${png.toString('base64')}`;
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api', { exclude: ['health'] });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
    prisma = app.get(PrismaService);

    for (const p of [worker.norm, boss.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    worker.token = await signup(worker.phone);
    boss.token = await signup(boss.phone);
    outsider.token = await signup(outsider.phone);

    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${worker.token}`)
      .send({ name: worker.name })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${boss.token}`)
      .send({ name: boss.name })
      .expect(200);

    const biz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', `Bearer ${boss.token}`)
      .send({ name: '무효화건설', businessNumber: '222-33-44444', address: '서울 강동구' })
      .expect(201);
    store.businessId = biz.body.data.id;
  });

  afterAll(async () => {
    for (const p of [worker.norm, boss.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  const workerAuth = () => `Bearer ${worker.token}`;
  const bossAuth = () => `Bearer ${boss.token}`;
  const outsiderAuth = () => `Bearer ${outsider.token}`;

  // ==========================================================================
  //  확인서 revoke
  // ==========================================================================
  const confBody = () => ({
    date: '2026-07-05',
    siteName: '강동 현장',
    companyName: '수기상대',
    contact: '010-5555-6666',
    workDescription: '정리 작업',
    startTime: '08:00',
    endTime: '17:00',
    rateType: 'DAILY',
    rate: 150000,
    quantity: 1,
  });

  it('확인서 — DRAFT 무효화 불가 409 NOT_REVOCABLE', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', workerAuth())
      .send(confBody())
      .expect(201);
    store.confDraftId = created.body.data.id;
    const res = await request(app.getHttpServer())
      .post(`/api/confirmations/${store.confDraftId}/revoke`)
      .set('Authorization', workerAuth())
      .expect(409);
    expect(res.body.error.code).toBe('NOT_REVOCABLE');
  });

  it('확인서 — SENT 무효화 → public 열람 403', async () => {
    // send → SENT + shareToken
    const sent = await request(app.getHttpServer())
      .post(`/api/confirmations/${store.confDraftId}/send`)
      .set('Authorization', workerAuth())
      .expect(201);
    store.confToken = sent.body.data.shareToken;

    // 무효화 전 public 열람 200
    await request(app.getHttpServer())
      .get(`/api/public/confirmations/${store.confToken}`)
      .expect(200);

    const revoked = await request(app.getHttpServer())
      .post(`/api/confirmations/${store.confDraftId}/revoke`)
      .set('Authorization', workerAuth())
      .expect(201);
    expect(revoked.body.data.revoked).toBe(true);

    // 무효화 후 public 열람 403
    const view = await request(app.getHttpServer())
      .get(`/api/public/confirmations/${store.confToken}`)
      .expect(403);
    expect(view.body.error.code).toBe('CONFIRMATION_REVOKED');

    // public 서명도 403
    await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.confToken}/sign`)
      .send({ signerName: '아무개', signImageBase64: await signPngDataUri() })
      .expect(403);
  });

  it('확인서 — SIGNED 무효화 불가 409 ALREADY_SIGNED (증빙 보존)', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', workerAuth())
      .send(confBody())
      .expect(201);
    const id = created.body.data.id;
    const sent = await request(app.getHttpServer())
      .post(`/api/confirmations/${id}/send`)
      .set('Authorization', workerAuth())
      .expect(201);
    const token = sent.body.data.shareToken;
    await request(app.getHttpServer())
      .post(`/api/public/confirmations/${token}/sign`)
      .send({ signerName: '서명자', signImageBase64: await signPngDataUri() })
      .expect(201);

    const res = await request(app.getHttpServer())
      .post(`/api/confirmations/${id}/revoke`)
      .set('Authorization', workerAuth())
      .expect(409);
    expect(res.body.error.code).toBe('ALREADY_SIGNED');

    // SIGNED 는 링크 열람 유지(증빙)
    await request(app.getHttpServer())
      .get(`/api/public/confirmations/${token}`)
      .expect(200);
  });

  it('확인서 — 권한 격리: 남의 확인서 무효화 404', async () => {
    await request(app.getHttpServer())
      .post(`/api/confirmations/${store.confDraftId}/revoke`)
      .set('Authorization', bossAuth())
      .expect(404);
  });

  // ==========================================================================
  //  계약서 revoke
  // ==========================================================================
  const contractBody = (over: Record<string, unknown> = {}) => ({
    businessId: store.businessId,
    workerName: '이수기',
    workerPhone: '010-7777-8888',
    startDate: '2026-07-10',
    workplace: '강동 현장',
    jobDescription: '형틀목공',
    workStartTime: '08:00',
    workEndTime: '17:00',
    wageType: 'DAILY',
    wageAmount: 170000,
    payday: '매월 말일',
    payMethod: '계좌 입금',
    ...over,
  });

  async function makeSentContract(): Promise<{ id: string; token: string }> {
    const created = await request(app.getHttpServer())
      .post('/api/biz/contracts')
      .set('Authorization', bossAuth())
      .send(contractBody())
      .expect(201);
    const id = created.body.data.id;
    const token = created.body.data.shareToken;
    await request(app.getHttpServer())
      .post(`/api/biz/contracts/${id}/sign-employer`)
      .set('Authorization', bossAuth())
      .send({ signerName: '대표', signImageBase64: await signPngDataUri() })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/biz/contracts/${id}/send`)
      .set('Authorization', bossAuth())
      .expect(201);
    return { id, token };
  }

  it('계약서 — DRAFT 무효화 불가 409 NOT_REVOCABLE', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/biz/contracts')
      .set('Authorization', bossAuth())
      .send(contractBody({ workerName: '초안대상' }))
      .expect(201);
    const res = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${created.body.data.id}/revoke`)
      .set('Authorization', bossAuth())
      .expect(409);
    expect(res.body.error.code).toBe('NOT_REVOCABLE');
  });

  it('계약서 — SENT 무효화 → public 열람 403', async () => {
    const { id, token } = await makeSentContract();
    store.contractSentId = id;

    await request(app.getHttpServer())
      .get(`/api/public/contracts/${token}`)
      .expect(200);

    const revoked = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${id}/revoke`)
      .set('Authorization', bossAuth())
      .expect(201);
    expect(revoked.body.data.revokedAt).toBeTruthy();

    const view = await request(app.getHttpServer())
      .get(`/api/public/contracts/${token}`)
      .expect(403);
    expect(view.body.error.code).toBe('LABOR_CONTRACT_REVOKED');

    await request(app.getHttpServer())
      .post(`/api/public/contracts/${token}/sign`)
      .send({ signerName: '이수기', signImageBase64: await signPngDataUri() })
      .expect(403);
  });

  it('계약서 — SIGNED 무효화 불가 409 ALREADY_SIGNED (증빙 보존)', async () => {
    const { id, token } = await makeSentContract();
    await request(app.getHttpServer())
      .post(`/api/public/contracts/${token}/sign`)
      .send({ signerName: '이수기', signImageBase64: await signPngDataUri() })
      .expect(201);

    const res = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${id}/revoke`)
      .set('Authorization', bossAuth())
      .expect(409);
    expect(res.body.error.code).toBe('ALREADY_SIGNED');

    await request(app.getHttpServer())
      .get(`/api/public/contracts/${token}`)
      .expect(200);
  });

  it('계약서 — 권한 격리: 남(외부인)의 사업장 계약서 무효화 404', async () => {
    await request(app.getHttpServer())
      .post(`/api/biz/contracts/${store.contractSentId}/revoke`)
      .set('Authorization', outsiderAuth())
      .expect(404);
  });
});
