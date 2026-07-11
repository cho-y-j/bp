import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { ReminderService } from '../src/ledger/reminder.service';
import { BadgeService } from '../src/ledger/badge.service';

/**
 * P3a e2e — 수금 독촉 자동화 + 지급 평판 배지.
 *  ① autoRemind 토글(PATCH) → 크론 시뮬(runReminderScan) → 발송 이력·중복 방지 → D+30 추가
 *  ② 수동 즉시 독촉 → 쿨다운 3일 409
 *  ③ 배지 집계 표본 3건 경계 → 검색/단건 응답 배지 → 사업장 본인 배지 → 권한 격리
 */
describe('P3a — 독촉·평판 (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let reminders: ReminderService;
  let badges: BadgeService;

  const phoneW = '010-8888-0401'; // 작업자
  const normW = '01088880401';
  const phoneOwner = '010-8888-0402'; // 사업장 소유자
  const normOwner = '01088880402';
  let tokenW: string;
  let tokenOwner: string;
  let manualEntryId: string;
  let bizId: string;

  async function loginAs(phone: string): Promise<string> {
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
    reminders = app.get(ReminderService);
    badges = app.get(BadgeService);

    for (const p of [normW, normOwner]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await prisma.business.deleteMany({ where: { name: 'P3A평판테스트건설' } });

    tokenW = await loginAs(phoneW);
    tokenOwner = await loginAs(phoneOwner);

    // 작업자 프로필에 이름 + 계좌 등록(안내 문구용)
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({
        name: '김작업',
        payoutBank: '국민은행',
        payoutAccount: '123-45-6789',
        payoutHolder: '김작업',
      })
      .expect(200);

    // 수기 상대(미가입, 전화 있음) 확인서 → 장부 항목 자동생성 (독촉 대상)
    const conf = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({
        date: '2026-07-08',
        siteName: '판교 현장',
        companyName: '대성건설',
        contact: '010-2222-3333',
        workDescription: '항타',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 300000,
        quantity: 1,
        dueDate: '2026-07-25',
      })
      .expect(201);
    const ledger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: conf.body.data.id },
    });
    manualEntryId = ledger!.id;

    // 사업장 생성(소유자)
    const biz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', `Bearer ${tokenOwner}`)
      .send({ name: 'P3A평판테스트건설' })
      .expect(201);
    bizId = biz.body.data.id;
  });

  afterAll(async () => {
    await prisma.business.deleteMany({ where: { name: 'P3A평판테스트건설' } });
    for (const p of [normW, normOwner]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  // --------------------------------------------------------------------------
  // ① 자동 독촉 토글 + 크론 시뮬
  // --------------------------------------------------------------------------
  it('PATCH autoRemind 토글 → 응답에 autoRemind=true', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/ledger/${manualEntryId}`)
      .set('Authorization', `Bearer ${tokenW}`)
      .send({ autoRemind: true })
      .expect(200);
    expect(res.body.data.autoRemind).toBe(true);
    expect(Array.isArray(res.body.data.reminders)).toBe(true);
  });

  it('크론 시뮬 D+7: 발송 1건, 이력에 stage=D7 append', async () => {
    const now7 = new Date('2026-08-01T10:00:00+09:00'); // dueDate 2026-07-25 + 7일
    const sent = await reminders.runReminderScan(now7);
    expect(sent).toBeGreaterThanOrEqual(1);
    const e = await prisma.ledgerEntry.findUnique({
      where: { id: manualEntryId },
    });
    const rems = e!.reminders as unknown as Array<{
      stage: string;
      channel: string;
    }>;
    expect(rems.some((r) => r.stage === 'D7')).toBe(true);
    // 수기 상대 → 알림톡 채널
    expect(rems.find((r) => r.stage === 'D7')?.channel).toBe('alimtalk');
  });

  it('같은 단계(D7) 재실행 → 중복 발송 방지(이력 증가 없음)', async () => {
    const before = await prisma.ledgerEntry.findUnique({
      where: { id: manualEntryId },
    });
    const beforeCount = (before!.reminders as unknown[]).length;
    const now7 = new Date('2026-08-01T10:00:00+09:00');
    await reminders.runReminderScan(now7);
    const after = await prisma.ledgerEntry.findUnique({
      where: { id: manualEntryId },
    });
    expect((after!.reminders as unknown[]).length).toBe(beforeCount);
  });

  it('크론 시뮬 D+30: stage=D30 추가 append', async () => {
    const now30 = new Date('2026-08-24T10:00:00+09:00'); // +30일
    await reminders.runReminderScan(now30);
    const e = await prisma.ledgerEntry.findUnique({
      where: { id: manualEntryId },
    });
    const rems = e!.reminders as unknown as Array<{ stage: string }>;
    expect(rems.some((r) => r.stage === 'D30')).toBe(true);
  });

  // --------------------------------------------------------------------------
  // ② 수동 즉시 독촉 + 쿨다운
  // --------------------------------------------------------------------------
  it('수동 독촉: 새 항목은 즉시 발송 성공, 재요청은 3일 쿨다운 409', async () => {
    // 별도 새 항목(이력 없음) 생성
    const conf = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({
        date: '2026-07-09',
        siteName: '수동 현장',
        companyName: '수동상대',
        contact: '010-4444-5555',
        workDescription: '작업',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 200000,
        quantity: 1,
        dueDate: '2026-07-25',
      })
      .expect(201);
    const ledger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: conf.body.data.id },
    });
    const id = ledger!.id;

    const ok = await request(app.getHttpServer())
      .post(`/api/ledger/${id}/remind`)
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(201);
    expect(ok.body.data.sent).toBe(true);

    const dup = await request(app.getHttpServer())
      .post(`/api/ledger/${id}/remind`)
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(409);
    expect(dup.body.error.code).toBe('REMIND_COOLDOWN');
  });

  it('권한 격리: 타인은 내 장부에 독촉 못 보냄 → 404', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/ledger/${manualEntryId}/remind`)
      .set('Authorization', `Bearer ${tokenOwner}`)
      .expect(404);
    expect(res.body.error.code).toBe('LEDGER_NOT_FOUND');
  });

  // --------------------------------------------------------------------------
  // ③ 지급 평판 배지
  // --------------------------------------------------------------------------
  /** 이 사업장에 SIGNED→전액 PAID 확인서/장부를 direct 시드. days 만큼 소요. */
  async function seedPaidConfirmation(days: number, idx: number) {
    const signedAt = new Date('2026-06-01T00:00:00+09:00');
    const paidAt = new Date(signedAt.getTime() + days * 24 * 60 * 60 * 1000);
    const conf = await prisma.confirmation.create({
      data: {
        profileId: (await prisma.profile.findUnique({
          where: { phone: normW },
        }))!.id,
        businessId: bizId,
        companyName: 'P3A평판테스트건설',
        date: signedAt,
        site: `현장${idx}`,
        workContent: '작업',
        startTime: signedAt,
        endTime: paidAt,
        rateType: 'DAILY',
        amountCalc: { subtotal: 100000, total: 100000 },
        shareToken: `p3a-badge-${idx}-${Date.now()}`,
        status: 'SIGNED',
        signedAt,
        signerName: '소유자',
      },
    });
    await prisma.ledgerEntry.create({
      data: {
        profileId: conf.profileId,
        confirmationId: conf.id,
        businessId: bizId,
        amount: 100000,
        status: 'PAID',
        payments: [{ amount: 100000, paidAt: paidAt.toISOString() }],
      },
    });
  }

  it('표본 2건 → 배지 없음(데이터 부족)', async () => {
    await seedPaidConfirmation(10, 1);
    await seedPaidConfirmation(12, 2);
    await badges.recomputeBusiness(
      bizId,
      new Date('2026-07-11T00:00:00+09:00'),
    );
    const byId = await request(app.getHttpServer())
      .get(`/api/businesses/${bizId}`)
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(200);
    expect(byId.body.data.paymentBadge).toBeNull();
  });

  it('표본 3건(평균 ≤15일) → 우수 배지 노출(검색·단건·본인)', async () => {
    await seedPaidConfirmation(14, 3); // 10,12,14 → avg 12 → 우수
    await badges.recomputeBusiness(
      bizId,
      new Date('2026-07-11T00:00:00+09:00'),
    );

    // 단건 조회
    const byId = await request(app.getHttpServer())
      .get(`/api/businesses/${bizId}`)
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(200);
    expect(byId.body.data.paymentBadge).toEqual({
      grade: 'EXCELLENT',
      avgDays: 12,
      sampleSize: 3,
    });

    // 검색 응답
    const search = await request(app.getHttpServer())
      .get('/api/businesses/search?q=P3A평판테스트건설')
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(200);
    const item = search.body.data.items.find(
      (b: { id: string }) => b.id === bizId,
    );
    expect(item.paymentBadge.grade).toBe('EXCELLENT');

    // 사업장 본인 배지
    const self = await request(app.getHttpServer())
      .get('/api/biz/payment-badge')
      .set('Authorization', `Bearer ${tokenOwner}`)
      .expect(200);
    expect(self.body.data.status).toBe('EXCELLENT');
    expect(self.body.data.sampleSize).toBe(3);
  });

  it('권한 격리: 사업장 없는 작업자는 본인 배지 조회 → 404', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/payment-badge')
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(404);
    expect(res.body.error.code).toBe('BUSINESS_NOT_FOUND');
  });
});
