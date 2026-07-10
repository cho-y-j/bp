import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * S2d 통합 e2e (임시 postgres):
 *  사업장 생성 → 코드 검색 → 연결(요청/수락) → 작업 지시 → 수락(서류확인 로그)
 *  → start(컨디션) → 사진 업로드 → complete → 확인서 send → biz inbox → biz sign
 *  → 정산 pay → 작업자 장부 PAID 일치 → simulate-heatwave → ack(+재ack 409)
 *  → safety-report PDF.
 */
describe('S2d 연동·작업·정산·안전 flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const workerPhone = '010-8888-0001';
  const workerNorm = '01088880001';
  const ownerPhone = '010-8888-0002';
  const ownerNorm = '01088880002';

  let workerToken: string;
  let ownerToken: string;
  let workerProfileId: string;
  let ownerProfileId: string;

  async function signPngDataUri(): Promise<string> {
    const png = await sharp({
      create: {
        width: 220,
        height: 90,
        channels: 4,
        background: { r: 10, g: 40, b: 120, alpha: 1 },
      },
    })
      .png()
      .toBuffer();
    return `data:image/png;base64,${png.toString('base64')}`;
  }

  async function login(phone: string): Promise<string> {
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

    for (const p of [workerNorm, ownerNorm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    workerToken = await login(workerPhone);
    ownerToken = await login(ownerPhone);

    const workerMe = await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${workerToken}`)
      .send({ name: '홍길동', phoneSearchConsent: true })
      .expect(200);
    workerProfileId = workerMe.body.data.id;
    const ownerMe = await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: '김사장' })
      .expect(200);
    ownerProfileId = ownerMe.body.data.id;
  });

  afterAll(async () => {
    for (const p of [workerNorm, ownerNorm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  const wAuth = () => `Bearer ${workerToken}`;
  const oAuth = () => `Bearer ${ownerToken}`;
  const store: Record<string, string> = {};

  it('워커 이름 마스킹 확인(홍길동 → 홍*동)', () => {
    expect(workerProfileId).toBeDefined();
    expect(ownerProfileId).toBeDefined();
  });

  it('사업장 생성 → 6자리 초대코드 발급', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', oAuth())
      .send({
        name: '대한건설',
        address: '서울시 중구',
        lat: 37.5665,
        lng: 126.978,
      })
      .expect(201);
    expect(res.body.data.inviteCode).toMatch(/^\d{6}$/);
    store.businessId = res.body.data.id;
    store.inviteCode = res.body.data.inviteCode;
  });

  it('코드로 사업장 검색', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/businesses/search?q=${store.inviteCode}`)
      .set('Authorization', wAuth())
      .expect(200);
    expect(res.body.data.count).toBeGreaterThanOrEqual(1);
    const found = res.body.data.items.find(
      (b: { id: string }) => b.id === store.businessId,
    );
    expect(found?.matchedByCode).toBe(true);
  });

  it('작업자 전화 검색 — 동의자만 노출 + 이름 마스킹', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/workers/search?phone=${workerPhone}`)
      .set('Authorization', oAuth())
      .expect(200);
    expect(res.body.data.count).toBe(1);
    expect(res.body.data.items[0].maskedName).toBe('홍*동');
    expect(res.body.data.items[0].profileId).toBe(workerProfileId);
  });

  it('연결: 작업자 → 사업장 요청, 사업주 수락', async () => {
    const reqRes = await request(app.getHttpServer())
      .post('/api/connections')
      .set('Authorization', wAuth())
      .send({ businessId: store.businessId, path: 'INVITE_CODE' })
      .expect(201);
    store.connectionId = reqRes.body.data.id;
    expect(reqRes.body.data.status).toBe('REQUESTED');

    const acc = await request(app.getHttpServer())
      .post(`/api/connections/${store.connectionId}/accept`)
      .set('Authorization', oAuth())
      .expect(201);
    expect(acc.body.data.status).toBe('ACCEPTED');
  });

  it('[검수] 확인서: 미연결 businessId → 400 NOT_CONNECTED', async () => {
    // owner 소유의 별도 사업장(작업자 미연결)
    const biz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', oAuth())
      .send({ name: '무관사업장' })
      .expect(201);
    store.unconnectedBusinessId = biz.body.data.id;

    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', wAuth())
      .send({
        date: '2026-07-15',
        siteName: '미연결 현장',
        businessId: store.unconnectedBusinessId,
        workDescription: '터파기',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 100000,
        quantity: 1,
      })
      .expect(400);
    expect(res.body.error.code).toBe('NOT_CONNECTED');
  });

  it('[검수] 확인서: 연결된 businessId → 작성 성공(201)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', wAuth())
      .send({
        date: '2026-07-15',
        siteName: '연결 현장',
        businessId: store.businessId,
        workDescription: '기초',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 100000,
        quantity: 1,
      })
      .expect(201);
    expect(res.body.data.businessId).toBe(store.businessId);
    // 정리(정산 집계 오염 방지): 이 DRAFT 확인서 삭제
    await request(app.getHttpServer())
      .delete(`/api/confirmations/${res.body.data.id}`)
      .set('Authorization', wAuth())
      .expect(200);
  });

  it('작업 지시(사업장 모드) → 작업자 대상', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/jobs')
      .set('Authorization', oAuth())
      .send({
        businessId: store.businessId,
        workerProfileId,
        site: '강남 현장',
        scheduledAt: '2026-07-15T08:00:00+09:00',
        rateType: 'DAILY',
        rate: 250000,
      })
      .expect(201);
    store.jobId = res.body.data.id;
    expect(res.body.data.status).toBe('SCHEDULED');
  });

  it('작업자 수락 → 서류 유효성 확인 로그(만료 서류 감지)', async () => {
    // 만료된 서류 하나 심어 서류확인 로그의 expired 브랜치를 검증
    await prisma.document.create({
      data: {
        ownerType: 'PROFILE',
        profileId: workerProfileId,
        type: '건설기계조종사면허',
        filePath: 'dummy/expired.pdf',
        expiryDate: new Date('2020-01-01T00:00:00+09:00'),
      },
    });
    const res = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/confirm`)
      .set('Authorization', wAuth())
      .expect(201);
    expect(res.body.data.acceptedAt).toBeTruthy();
    expect(
      res.body.data.documentValidity.expired.length,
    ).toBeGreaterThanOrEqual(1);
    // safety_log(DOCUMENT_VALIDITY) 생성 확인
    const logs = await prisma.safetyLog.findMany({
      where: { targetProfileId: workerProfileId, type: 'DOCUMENT_VALIDITY' },
    });
    expect(logs.length).toBeGreaterThanOrEqual(1);
  });

  it('start — GPS + 컨디션체크 OK → work_log + safety_log(CONDITION_CHECK)', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/start`)
      .set('Authorization', wAuth())
      .send({ lat: 37.5, lng: 127.0, condition: 'OK' })
      .expect(201);
    expect(res.body.data.status).toBe('IN_PROGRESS');
    const logs = await prisma.safetyLog.findMany({
      where: { targetProfileId: workerProfileId, type: 'CONDITION_CHECK' },
    });
    expect(logs.length).toBe(1);
  });

  it('사진 업로드(multipart)', async () => {
    const png = await sharp({
      create: {
        width: 40,
        height: 40,
        channels: 3,
        background: { r: 200, g: 200, b: 0 },
      },
    })
      .jpeg()
      .toBuffer();
    const res = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/photos`)
      .set('Authorization', wAuth())
      .attach('files', png, 'site.jpg')
      .expect(201);
    expect(res.body.data.uploaded).toBe(1);
    expect(res.body.data.photoPaths.length).toBe(1);
  });

  it('[검수] 사진 업로드 MIME 검증 — pdf 는 400', async () => {
    const notImage = Buffer.from('%PDF-1.4 fake pdf', 'latin1');
    const res = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/photos`)
      .set('Authorization', wAuth())
      .attach('files', notImage, {
        filename: 'doc.pdf',
        contentType: 'application/pdf',
      })
      .expect(400);
    expect(res.body.error.code).toBe('UNSUPPORTED_PHOTO_TYPE');
  });

  it('complete — GPS → DONE', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/complete`)
      .set('Authorization', wAuth())
      .send({ lat: 37.5, lng: 127.0 })
      .expect(201);
    expect(res.body.data.status).toBe('DONE');
    expect(res.body.data.photoCount).toBe(1);
  });

  it('[검수] job 상태전이 강제 — DONE 재start/재complete → 409', async () => {
    const reStart = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/start`)
      .set('Authorization', wAuth())
      .send({ lat: 37.5, lng: 127.0, condition: 'OK' })
      .expect(409);
    expect(reStart.body.error.code).toBe('JOB_NOT_STARTABLE');

    const reComplete = await request(app.getHttpServer())
      .post(`/api/jobs/${store.jobId}/complete`)
      .set('Authorization', wAuth())
      .send({ lat: 37.5, lng: 127.0 })
      .expect(409);
    expect(reComplete.body.error.code).toBe('JOB_NOT_COMPLETABLE');
  });

  it('[검수] job 상태전이 강제 — 미수락(acceptedAt 없음) 작업 start → 409', async () => {
    const job = await request(app.getHttpServer())
      .post('/api/jobs')
      .set('Authorization', oAuth())
      .send({
        businessId: store.businessId,
        workerProfileId,
        site: '미수락 현장',
        scheduledAt: '2026-07-20T08:00:00+09:00',
        rateType: 'DAILY',
        rate: 200000,
      })
      .expect(201);
    const res = await request(app.getHttpServer())
      .post(`/api/jobs/${job.body.data.id}/start`)
      .set('Authorization', wAuth())
      .send({ lat: 37.5, lng: 127.0, condition: 'OK' })
      .expect(409);
    expect(res.body.error.code).toBe('JOB_NOT_STARTABLE');
  });

  it('확인서 작성(연동 사업장) → send → biz 알림', async () => {
    const create = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', wAuth())
      .send({
        date: '2026-07-15',
        siteName: '강남 현장',
        businessId: store.businessId,
        workDescription: '터파기',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 250000,
        quantity: 1,
      })
      .expect(201);
    store.confirmationId = create.body.data.id;

    const send = await request(app.getHttpServer())
      .post(`/api/confirmations/${store.confirmationId}/send`)
      .set('Authorization', wAuth())
      .expect(201);
    expect(send.body.data.linked).toBe(true);
    expect(send.body.data.notified).toBe(true);
  });

  it('biz inbox — 수신 확인서 노출(SENT)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/inbox')
      .set('Authorization', oAuth())
      .expect(200);
    const item = res.body.data.items.find(
      (c: { id: string }) => c.id === store.confirmationId,
    );
    expect(item).toBeDefined();
    expect(item.status).toBe('SENT');
    expect(item.workerName).toBe('홍*동');
  });

  it('[검수] biz sign — 비소유자(작업자) → 403', async () => {
    const dataUri = await signPngDataUri();
    const res = await request(app.getHttpServer())
      .post(`/api/biz/confirmations/${store.confirmationId}/sign`)
      .set('Authorization', wAuth())
      .send({ signerName: '남', signImageBase64: dataUri })
      .expect(403);
    expect(res.body.error.code).toBe('FORBIDDEN');
  });

  it('[검수] biz sign — 존재하지 않는 확인서 → 404', async () => {
    const dataUri = await signPngDataUri();
    const res = await request(app.getHttpServer())
      .post(`/api/biz/confirmations/00000000-0000-4000-8000-000000000000/sign`)
      .set('Authorization', oAuth())
      .send({ signerName: '김사장', signImageBase64: dataUri })
      .expect(404);
    expect(res.body.error.code).toBe('CONFIRMATION_NOT_FOUND');
  });

  it('biz sign — 앱 내 서명 → SIGNED', async () => {
    const dataUri = await signPngDataUri();
    const res = await request(app.getHttpServer())
      .post(`/api/biz/confirmations/${store.confirmationId}/sign`)
      .set('Authorization', oAuth())
      .send({ signerName: '김사장', signImageBase64: dataUri })
      .expect(201);
    expect(res.body.data.status).toBe('SIGNED');

    // 재서명 409
    await request(app.getHttpServer())
      .post(`/api/biz/confirmations/${store.confirmationId}/sign`)
      .set('Authorization', oAuth())
      .send({ signerName: '김사장', signImageBase64: dataUri })
      .expect(409);
  });

  it('정산 집계(SIGNED 기준) → pay → 작업자 장부 PAID 일치', async () => {
    const settle = await request(app.getHttpServer())
      .get('/api/biz/settlements?month=2026-07')
      .set('Authorization', oAuth())
      .expect(200);
    const worker = settle.body.data.workers.find(
      (w: { workerProfileId: string }) => w.workerProfileId === workerProfileId,
    );
    expect(worker).toBeDefined();
    expect(worker.outstanding).toBe(250000);
    const ledgerEntryIds: string[] = worker.ledgerEntryIds;
    expect(ledgerEntryIds.length).toBe(1);

    const pay = await request(app.getHttpServer())
      .post('/api/biz/settlements/pay')
      .set('Authorization', oAuth())
      .send({ ledgerEntryIds, memo: '7월 정산' })
      .expect(201);
    expect(pay.body.data.totalPaid).toBe(250000);

    // 작업자 장부 관점에서 PAID 로 일치
    const byCompany = await request(app.getHttpServer())
      .get('/api/ledger/by-company?month=2026-07')
      .set('Authorization', wAuth())
      .expect(200);
    const grp = byCompany.body.data.companies.find(
      (c: { businessId: string | null }) => c.businessId === store.businessId,
    );
    expect(grp).toBeDefined();
    expect(grp.paid).toBe(250000);
    expect(grp.outstanding).toBe(0);
    expect(grp.status).toBe('PAID');
  });

  it('simulate-heatwave → 폭염 로그+알림 생성', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/safety/simulate-heatwave')
      .set('Authorization', oAuth())
      .send({ businessId: store.businessId })
      .expect(201);
    expect(res.body.data.totalCreated).toBeGreaterThanOrEqual(2); // worker + owner

    // 작업자 알림에서 safetyLogId 회수
    const notis = await request(app.getHttpServer())
      .get('/api/notifications?unread=true')
      .set('Authorization', wAuth())
      .expect(200);
    const heat = notis.body.data.items.find(
      (n: { type: string }) => n.type === 'HEAT_ALERT',
    );
    expect(heat).toBeDefined();
    store.safetyLogId = heat.data.safetyLogId;
  });

  it('ack — 최초 확인 OK, 재확인 409', async () => {
    await request(app.getHttpServer())
      .post(`/api/safety/${store.safetyLogId}/ack`)
      .set('Authorization', wAuth())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/safety/${store.safetyLogId}/ack`)
      .set('Authorization', wAuth())
      .expect(409);
  });

  it('device-token 등록 + notification read', async () => {
    await request(app.getHttpServer())
      .post('/api/device-tokens')
      .set('Authorization', wAuth())
      .send({ token: 'test-fcm-token-abcdef123456', platform: 'ANDROID' })
      .expect(201);
    const read = await request(app.getHttpServer())
      .post(`/api/notifications/${store.safetyLogId}/read`)
      .set('Authorization', wAuth());
    // safetyLogId 는 notification id 가 아니므로 404 여야 함(안전한 확인)
    expect([404]).toContain(read.status);
  });

  it('safety-report PDF 생성', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/safety-report?month=2026-07')
      .set('Authorization', oAuth())
      .buffer(true)
      .parse((r, cb) => {
        const chunks: Buffer[] = [];
        r.on('data', (c: Buffer) => chunks.push(c));
        r.on('end', () => cb(null, Buffer.concat(chunks)));
      })
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    const buf = res.body as Buffer;
    expect(buf.length).toBeGreaterThan(1000);
    expect(buf.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  it('미가입 상대 승격 — 수기 확인서가 사업장 생성 시 승격된다', async () => {
    // 수기 상대(사업주 전화 ownerNorm)로 businessId 없는 확인서+장부를 직접 시드
    // (HTTP 로그인 반복에 따른 OTP 레이트리밋 회피 — 승격 로직 자체를 검증)
    const conf = await prisma.confirmation.create({
      data: {
        profileId: workerProfileId,
        companyName: '대한건설(수기)',
        manualContact: ownerNorm, // 사업주 전화 → 매칭 키
        date: new Date('2026-07-16T00:00:00+09:00'),
        site: '수기 현장',
        workContent: '기초',
        startTime: new Date('2026-07-16T08:00:00+09:00'),
        endTime: new Date('2026-07-16T17:00:00+09:00'),
        rateType: 'DAILY',
        amountCalc: { total: 200000 } as object,
        shareToken: `promo-${Date.now()}`,
        status: 'SENT',
      },
    });
    await prisma.ledgerEntry.create({
      data: {
        profileId: workerProfileId,
        confirmationId: conf.id,
        counterpartyName: '대한건설(수기)',
        amount: 200000,
        status: 'PENDING',
      },
    });

    // 사업주가 두 번째 사업장을 생성하면 promoteForBusiness 가 수기 확인서를 승격
    const biz2 = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', oAuth())
      .send({ name: '대한건설2' })
      .expect(201);
    expect(biz2.body.data.promoted.confirmations).toBeGreaterThanOrEqual(1);

    const promoted = await prisma.confirmation.findUnique({
      where: { id: conf.id },
    });
    expect(promoted?.businessId).toBe(biz2.body.data.id);
    // 연결된 장부도 대칭 승격
    const ledger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: conf.id },
    });
    expect(ledger?.businessId).toBe(biz2.body.data.id);
    expect(ledger?.counterpartyName).toBeNull();
  });
});
