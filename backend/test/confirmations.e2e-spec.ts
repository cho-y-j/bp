import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * 확인서·장부 도메인 e2e (임시 postgres):
 *  작성 → ledger 자동생성 → 수정(금액 동기화) → send(수기 상대) → public 열람
 *  → 서명 → SIGNED·재서명 409 → 서명 PDF → 부분입금 → by-company 상태 변화 → 명세서 PDF.
 */
describe('Confirmations & Ledger flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  const phone = '010-7777-0002';
  const normalized = '01077770002';

  async function signPngDataUri(): Promise<string> {
    const png = await sharp({
      create: {
        width: 200,
        height: 80,
        channels: 4,
        background: { r: 0, g: 0, b: 200, alpha: 1 },
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
    // 프로필 이름 설정 (PDF 작업자명)
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

  it('작성 → amountCalc 서버계산 + ledger 자동생성', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth())
      .send({
        date: '2026-07-05',
        siteName: '판교 현장',
        companyName: '대한건설',
        contact: '010-1234-5678',
        workDescription: '터파기 및 정리',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 150000,
        quantity: 1,
        additionalItems: [{ type: 'OVERTIME', rate: 30000, quantity: 2 }],
        equipmentSection: {
          name: '굴삭기',
          vehicleNumber: '12가3456',
          spec: '06W',
          guide: true,
        },
        dueDate: '2026-07-20',
      })
      .expect(201);
    const c = res.body.data;
    expect(c.status).toBe('DRAFT');
    expect(c.total).toBe(210000); // 150000 + 60000
    expect(c.shareToken).toHaveLength(32);
    store.id = c.id;
    store.token = c.shareToken;

    // ledger 자동생성 확인
    const ledger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: c.id },
    });
    expect(ledger).toBeTruthy();
    expect(Number(ledger!.amount)).toBe(210000);
    expect(ledger!.counterpartyName).toBe('대한건설');
    store.ledgerId = ledger!.id;
  });

  it('수정(DRAFT) → 금액 재계산 + ledger 동기화', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/confirmations/${store.id}`)
      .set('Authorization', auth())
      .send({ rate: 200000, quantity: 1 })
      .expect(200);
    // 기본 200000 + 기존 연장 60000 유지 = 260000
    expect(res.body.data.total).toBe(260000);
    const ledger = await prisma.ledgerEntry.findUnique({
      where: { id: store.ledgerId },
    });
    expect(Number(ledger!.amount)).toBe(260000);
  });

  it('GET ?month= → 목록 + 일자별 집계', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/confirmations?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    expect(res.body.data.count).toBeGreaterThanOrEqual(1);
    const day = res.body.data.byDate.find(
      (d: { date: string }) => d.date === '2026-07-05',
    );
    expect(day.count).toBe(1);
    expect(day.totalAmount).toBe(260000);
    // 정산 분리(additive): 아직 입금 전 → 전액 미수(UNPAID).
    expect(day.paidAmount).toBe(0);
    expect(day.outstandingAmount).toBe(260000);
    const item = res.body.data.items.find(
      (x: { id: string }) => x.id === store.id,
    );
    expect(item.settlement).toEqual({
      paidAmount: 0,
      outstandingAmount: 260000,
      status: 'UNPAID',
    });
  });

  it('send(수기 상대) → SENT + shareToken url', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/confirmations/${store.id}/send`)
      .set('Authorization', auth())
      .expect(201);
    expect(res.body.data.sent).toBe(true);
    expect(res.body.data.linked).toBe(false);
    expect(res.body.data.url).toContain(`/c/${store.token}`);
  });

  it('public 열람(@Public) → 무인증 조회 + viewLog', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/public/confirmations/${store.token}`)
      .set('User-Agent', 'e2e-signer')
      .expect(200);
    expect(res.body.data.companyName).toBe('대한건설');
    expect(res.body.data.total).toBe(260000);
    expect(res.body.data.signed).toBe(false);
    // 미서명 상태에서는 손글씨 서명 이미지가 노출되지 않아야 한다.
    expect(res.body.data.signImageDataUrl).toBeFalsy();

    const c = await prisma.confirmation.findUnique({
      where: { id: store.id },
    });
    expect(Array.isArray(c!.viewLogs)).toBe(true);
    expect((c!.viewLogs as unknown[]).length).toBeGreaterThanOrEqual(1);
  });

  it('public 서명 → SIGNED + 발행자 알림', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.token}/sign`)
      .send({ signerName: '현장소장', signImageBase64: await signPngDataUri() })
      .expect(201);
    expect(res.body.data.signed).toBe(true);
    expect(res.body.data.status).toBe('SIGNED');

    const c = await prisma.confirmation.findUnique({
      where: { id: store.id },
    });
    expect(c!.status).toBe('SIGNED');
    expect(c!.signImagePath).toBeTruthy();

    // 발행자 알림 레코드
    const notif = await prisma.notification.findFirst({
      where: {
        type: 'CONFIRMATION',
        data: { path: ['confirmationId'], equals: store.id },
      },
    });
    expect(notif).toBeTruthy();
  });

  it('재서명 → 409 ALREADY_SIGNED', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.token}/sign`)
      .send({ signerName: '다른사람', signImageBase64: await signPngDataUri() })
      .expect(409);
    expect(res.body.error.code).toBe('ALREADY_SIGNED');
  });

  it('public 열람(SIGNED) → 손글씨 서명 이미지(PNG data URI) 포함', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/public/confirmations/${store.token}`)
      .expect(200);
    expect(res.body.data.signed).toBe(true);
    expect(typeof res.body.data.signImageDataUrl).toBe('string');
    expect(res.body.data.signImageDataUrl).toMatch(
      /^data:image\/png;base64,/,
    );
  });

  it('SIGNED 상태 수정 시도 → 409 NOT_EDITABLE', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/confirmations/${store.id}`)
      .set('Authorization', auth())
      .send({ rate: 1 })
      .expect(409);
    expect(res.body.error.code).toBe('NOT_EDITABLE');
  });

  it('확인서 PDF → 서명 이미지 포함(PDF 크기 증가)', async () => {
    const signedPdf = await request(app.getHttpServer())
      .get(`/api/confirmations/${store.id}/pdf`)
      .set('Authorization', auth())
      .responseType('blob')
      .expect(200);
    expect(signedPdf.headers['content-type']).toContain('application/pdf');
    expect(signedPdf.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(signedPdf.body.length).toBeGreaterThan(2000);
    store.signedPdfSize = String(signedPdf.body.length);
  });

  it('부분입금 → PARTIAL, 완납 → PAID', async () => {
    const p1 = await request(app.getHttpServer())
      .post(`/api/ledger/${store.ledgerId}/payments`)
      .set('Authorization', auth())
      .send({ amount: 100000, memo: '계좌이체 1차' })
      .expect(201);
    expect(p1.body.data.status).toBe('PARTIAL');
    expect(p1.body.data.outstanding).toBe(160000);

    const p2 = await request(app.getHttpServer())
      .post(`/api/ledger/${store.ledgerId}/payments`)
      .set('Authorization', auth())
      .send({ amount: 160000 })
      .expect(201);
    expect(p2.body.data.status).toBe('PAID');
    expect(p2.body.data.outstanding).toBe(0);
  });

  it('summary/by-company 상태 반영', async () => {
    const summary = await request(app.getHttpServer())
      .get('/api/ledger/summary?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    expect(summary.body.data.daysWorked).toBeGreaterThanOrEqual(1);
    expect(summary.body.data.totalBilled).toBe(260000);
    expect(summary.body.data.totalPaid).toBe(260000);
    expect(summary.body.data.totalOutstanding).toBe(0);

    const byCompany = await request(app.getHttpServer())
      .get('/api/ledger/by-company?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    const group = byCompany.body.data.companies.find(
      (g: { companyName: string }) => g.companyName === '대한건설',
    );
    expect(group.status).toBe('PAID');
    expect(group.statusLabel).toBe('전액입금');
    expect(group.days).toBe(1);
  });

  it('캘린더 정산 분리 — 완납 후 settlement PAID·미수 0, 홈 히어로(ledger summary)와 정합', async () => {
    const cal = await request(app.getHttpServer())
      .get('/api/confirmations?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    const item = cal.body.data.items.find(
      (x: { id: string }) => x.id === store.id,
    );
    expect(item.settlement.status).toBe('PAID');
    expect(item.settlement.paidAmount).toBe(260000);
    expect(item.settlement.outstandingAmount).toBe(0);
    const day = cal.body.data.byDate.find(
      (d: { date: string }) => d.date === '2026-07-05',
    );
    expect(day.paidAmount).toBe(260000);
    expect(day.outstandingAmount).toBe(0);
    // billed(청구) 는 무변경(기존 필드 보존).
    expect(cal.body.data.totalAmount).toBe(260000);

    // 홈 히어로(ledger summary)와 캘린더 미수/입금 총계 정의 일치.
    const summary = await request(app.getHttpServer())
      .get('/api/ledger/summary?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    expect(cal.body.data.totalOutstanding).toBe(
      summary.body.data.totalOutstanding,
    );
    expect(cal.body.data.totalPaid).toBe(summary.body.data.totalPaid);
  });

  it('수금예정일 수정(PATCH) → dueDate 반영', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/ledger/${store.ledgerId}`)
      .set('Authorization', auth())
      .send({ dueDate: '2026-07-25' })
      .expect(200);
    // KST 자정으로 저장되므로 instant 로 비교 (2026-07-25 00:00 KST)
    expect(new Date(res.body.data.dueDate).getTime()).toBe(
      new Date('2026-07-25T00:00:00+09:00').getTime(),
    );
  });

  it('duplicate → 오늘 날짜, DRAFT, 새 ledger', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/confirmations/${store.id}/duplicate`)
      .set('Authorization', auth())
      .expect(201);
    expect(res.body.data.status).toBe('DRAFT');
    expect(res.body.data.total).toBe(260000);
    const dupLedger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: res.body.data.id },
    });
    expect(dupLedger).toBeTruthy();
    store.dupId = res.body.data.id;
  });

  it('DRAFT 삭제 → ledger 도 제거', async () => {
    await request(app.getHttpServer())
      .delete(`/api/confirmations/${store.dupId}`)
      .set('Authorization', auth())
      .expect(200);
    const dupLedger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: store.dupId },
    });
    expect(dupLedger).toBeNull();
  });

  it('명세서 PDF(statement) → 한글 표 렌더', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/statement?month=2026-07')
      .set('Authorization', auth())
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  it('무효화된 링크 → 403 (revokedAt 설정 시)', async () => {
    await prisma.confirmation.update({
      where: { id: store.id },
      data: { revokedAt: new Date() },
    });
    const res = await request(app.getHttpServer())
      .get(`/api/public/confirmations/${store.token}`)
      .expect(403);
    expect(res.body.error.code).toBe('CONFIRMATION_REVOKED');
  });
});

/**
 * 팀원 파생 소득 캘린더(teamShares) e2e:
 *  반장이 팀 확인서(팀원 몫 포함)를 작성·서명 → 팀원(가입·연결) 본인 장부에 파생 소득 생성.
 *  팀원 월 조회(GET /confirmations?month=)에 teamShares 로 등장하고, 본인 확인서(items)와 병존하며
 *  미수/입금 총계가 홈 히어로(ledger summary, 파생 포함)와 정확히 일치함을 검증한다.
 */
describe('팀원 파생 소득 캘린더 teamShares (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let bossToken: string;
  let memberToken: string;
  let memberProfileId: string;
  const bossPhone = '010-7777-0003';
  const bossNorm = '01077770003';
  const memberPhone = '010-8888-0002';
  const memberNorm = '01088880002';
  const MONTH = '2026-08';
  const store: Record<string, string> = {};

  async function signPngDataUri(): Promise<string> {
    const png = await sharp({
      create: {
        width: 200,
        height: 80,
        channels: 4,
        background: { r: 0, g: 0, b: 200, alpha: 1 },
      },
    })
      .png()
      .toBuffer();
    return `data:image/png;base64,${png.toString('base64')}`;
  }

  async function login(
    phone: string,
  ): Promise<{ token: string; profileId: string }> {
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
      profileId: verifyRes.body.data.profile.id,
    };
  }

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api', { exclude: ['health'] });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
    prisma = app.get(PrismaService);

    for (const p of [bossNorm, memberNorm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    const boss = await login(bossPhone);
    bossToken = boss.token;
    const member = await login(memberPhone);
    memberToken = member.token;
    memberProfileId = member.profileId;

    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${bossToken}`)
      .send({ name: '박현장' })
      .expect(200);
    // 팀원: 이름 + 전화검색 동의 ON(반장이 전화검색으로 연결하는 전제).
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ name: '이팀원', phoneSearchConsent: true })
      .expect(200);
  });

  afterAll(async () => {
    for (const p of [bossNorm, memberNorm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  it('반장: 팀 생성 + 팀원(가입) 연결', async () => {
    const team = await request(app.getHttpServer())
      .post('/api/teams')
      .set('Authorization', `Bearer ${bossToken}`)
      .send({ name: '박현장 A팀' })
      .expect(201);
    store.teamId = team.body.data.id;

    const mem = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', `Bearer ${bossToken}`)
      .send({ profileId: memberProfileId, defaultRate: 180000 })
      .expect(201);
    expect(mem.body.data.linked).toBe(true);
    store.memberId = mem.body.data.id;
  });

  it('팀원: 본인 확인서 1건 작성(병존 확인용, 2026-08-05 100,000)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({
        date: '2026-08-05',
        siteName: '본인 직거래 현장',
        companyName: '직거래건설',
        contact: '010-2222-3333',
        workDescription: '개인 작업',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 100000,
        quantity: 1,
      })
      .expect(201);
    expect(res.body.data.total).toBe(100000);
    store.ownConfId = res.body.data.id;
  });

  it('반장: 팀 확인서 작성(팀원 몫 180,000) → 전송 → 서명 → 파생 소득 생성', async () => {
    const conf = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', `Bearer ${bossToken}`)
      .send({
        date: '2026-08-10',
        siteName: '판교 팀 현장',
        companyName: '종합건설',
        contact: '010-5555-0000',
        workDescription: '팀 작업',
        startTime: '07:00',
        endTime: '18:00',
        teamId: store.teamId,
        teamEntries: [{ memberId: store.memberId, quantity: 1, rate: 180000 }],
      })
      .expect(201);
    expect(conf.body.data.total).toBe(180000);
    store.teamConfToken = conf.body.data.shareToken;

    await request(app.getHttpServer())
      .post(`/api/confirmations/${conf.body.data.id}/send`)
      .set('Authorization', `Bearer ${bossToken}`)
      .expect(201);

    const signed = await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.teamConfToken}/sign`)
      .send({ signerName: '현장소장', signImageBase64: await signPngDataUri() })
      .expect(201);
    expect(signed.body.data.status).toBe('SIGNED');

    // 팀원 본인 장부에 파생 entry(derived=true) 생성 확인.
    const derived = await prisma.ledgerEntry.findFirst({
      where: { profileId: memberProfileId, derived: true },
    });
    expect(derived).toBeTruthy();
    expect(Number(derived!.amount)).toBe(180000);
    store.derivedId = derived!.id;
  });

  it('팀원 월 조회: teamShares 등장 + 본인 확인서 병존 + 홈 히어로 정합', async () => {
    const cal = await request(app.getHttpServer())
      .get(`/api/confirmations?month=${MONTH}`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    const d = cal.body.data;

    // 본인 확인서(items)는 1건, 팀 작업(teamShares)도 1건 — 병존.
    expect(d.items.length).toBe(1);
    expect(d.items[0].id).toBe(store.ownConfId);
    expect(d.teamShares.length).toBe(1);
    const ts = d.teamShares[0];
    expect(ts.id).toBe(store.derivedId);
    expect(ts.date).toBe('2026-08-10');
    expect(ts.site).toBe('판교 팀 현장');
    expect(ts.teamLeaderName).toBe('박현장');
    expect(ts.amount).toBe(180000);
    expect(ts.settlement).toEqual({
      paidAmount: 0,
      outstandingAmount: 180000,
      status: 'UNPAID',
    });

    // count·byDate 에 teamShares 포함(본인 100,000 + 팀 180,000).
    expect(d.count).toBe(2);
    expect(d.totalOutstanding).toBe(280000);
    const day10 = d.byDate.find((x: { date: string }) => x.date === '2026-08-10');
    expect(day10.count).toBe(1);
    expect(day10.outstandingAmount).toBe(180000);

    // 홈 히어로(ledger summary, 파생 포함)와 미수/입금 총계 정확 일치.
    const summary = await request(app.getHttpServer())
      .get(`/api/ledger/summary?month=${MONTH}`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(d.totalOutstanding).toBe(summary.body.data.totalOutstanding);
    expect(d.totalPaid).toBe(summary.body.data.totalPaid);
    expect(d.totalAmount).toBe(summary.body.data.totalBilled);
  });

  it('팀원: 파생 소득에 부분입금 → teamShares.settlement PARTIAL·총계 반영', async () => {
    const pay = await request(app.getHttpServer())
      .post(`/api/ledger/${store.derivedId}/payments`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ amount: 80000, memo: '반장 일부 지급' })
      .expect(201);
    expect(pay.body.data.status).toBe('PARTIAL');

    const cal = await request(app.getHttpServer())
      .get(`/api/confirmations?month=${MONTH}`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    const ts = cal.body.data.teamShares[0];
    expect(ts.settlement.status).toBe('PARTIAL');
    expect(ts.settlement.paidAmount).toBe(80000);
    expect(ts.settlement.outstandingAmount).toBe(100000);
    // 본인 미수 100,000 + 팀 미수 100,000 = 200,000, 입금 80,000.
    expect(cal.body.data.totalOutstanding).toBe(200000);
    expect(cal.body.data.totalPaid).toBe(80000);

    const summary = await request(app.getHttpServer())
      .get(`/api/ledger/summary?month=${MONTH}`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(cal.body.data.totalOutstanding).toBe(
      summary.body.data.totalOutstanding,
    );
    expect(cal.body.data.totalPaid).toBe(summary.body.data.totalPaid);
  });
});
