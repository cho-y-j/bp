import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * 거래처(partners) 도메인 e2e (임시 postgres):
 *  확인서 작성 → 자동 수집 → GET 병합/통계 → PATCH 필드 제한 → 연결 상대 포함
 *  → 권한 격리 → hard delete → lazy 재수집.
 */
describe('Partners (거래처) flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string; // worker1
  let token2: string; // worker2 (격리 검증)
  let worker1Id: string;

  const phone1 = '010-7788-0001';
  const norm1 = '01077880001';
  const phone2 = '010-7788-0002';
  const norm2 = '01077880002';
  const bizOwnerPhone = '010-7788-0003';
  const bizOwnerNorm = '01077880003';

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

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api', { exclude: ['health'] });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
    prisma = app.get(PrismaService);

    for (const p of [norm1, norm2, bizOwnerNorm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    token = await signup(phone1);
    token2 = await signup(phone2);
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '김기사' })
      .expect(200);
    const me = await prisma.profile.findUnique({ where: { phone: norm1 } });
    worker1Id = me!.id;
  });

  afterAll(async () => {
    for (const p of [norm1, norm2, bizOwnerNorm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  const auth = () => `Bearer ${token}`;
  const store: Record<string, string> = {};

  async function createManualConfirmation(body: Record<string, unknown>) {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth())
      .send({
        date: '2026-07-05',
        siteName: '판교 현장',
        workDescription: '터파기',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 200000,
        quantity: 1,
        ...body,
      })
      .expect(201);
    return res.body.data;
  }

  it('수기 확인서 작성 → 거래처 자동 수집(GET /partners)', async () => {
    const c = await createManualConfirmation({
      companyName: '대성건설',
      contact: '010-1111-2222',
    });
    store.confId = c.id;

    const res = await request(app.getHttpServer())
      .get('/api/partners')
      .set('Authorization', auth())
      .expect(200);
    const items = res.body.data.items as Array<Record<string, unknown>>;
    const p = items.find((i) => i.name === '대성건설');
    expect(p).toBeTruthy();
    expect(p!.linked).toBe(false);
    expect(p!.id).toBeTruthy();
    expect(p!.businessId).toBeNull();
    expect(p!.confirmationCount).toBe(1);
    expect(p!.outstanding).toBe(200000);
    expect(p!.phone).toBe('010-1111-2222');
    expect(p!.lastWorkedDate).toBe('2026-07-05');
    store.partnerId = p!.id as string;
  });

  it('같은 상대 2번째 확인서(더 최근·다른 연락처) → 건수 2·대표 전화 최신값', async () => {
    await createManualConfirmation({
      date: '2026-07-12',
      companyName: '대성건설',
      contact: '010-3333-4444',
    });
    const res = await request(app.getHttpServer())
      .get('/api/partners')
      .set('Authorization', auth())
      .expect(200);
    const p = (res.body.data.items as Array<Record<string, unknown>>).find(
      (i) => i.name === '대성건설',
    )!;
    expect(p.confirmationCount).toBe(2);
    expect(p.phone).toBe('010-3333-4444');
    expect(p.lastWorkedDate).toBe('2026-07-12');
    // 두 확인서 각각 ledger 200,000 → 미수 400,000
    expect(p.outstanding).toBe(400000);
  });

  it('미수 통계가 ledger by-company 와 일치(부분입금 반영)', async () => {
    // 첫 확인서의 ledger 에 부분입금 150,000 기록(API 경로).
    const entry = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: store.confId },
    });
    await request(app.getHttpServer())
      .post(`/api/ledger/${entry!.id}/payments`)
      .set('Authorization', auth())
      .send({ amount: 150000 })
      .expect(201);

    const partnersRes = await request(app.getHttpServer())
      .get('/api/partners')
      .set('Authorization', auth())
      .expect(200);
    const p = (partnersRes.body.data.items as Array<Record<string, unknown>>).find(
      (i) => i.name === '대성건설',
    )!;
    expect(p.outstanding).toBe(250000); // 400,000 - 150,000
    expect(p.paid).toBe(150000);

    // ledger by-company(7월) 의 같은 상대 미수와 대조.
    const byco = await request(app.getHttpServer())
      .get('/api/ledger/by-company?month=2026-07')
      .set('Authorization', auth())
      .expect(200);
    const g = (byco.body.data.companies as Array<Record<string, unknown>>).find(
      (c) => c.companyName === '대성건설',
    )!;
    expect(g.outstanding).toBe(p.outstanding);
    expect(g.paid).toBe(p.paid);
  });

  it('PATCH — 보강 필드만 수정(name/phone 등 비허용 필드는 무시)', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/partners/${store.partnerId}`)
      .set('Authorization', auth())
      .send({
        alias: '대성',
        bizNumber: '123-45-67890',
        email: 'daesung@example.com',
        memo: '판교 담당',
        name: '해킹시도', // 비허용 → whitelist 로 제거
        phone: '000', // 비허용
        outstanding: 0, // 비허용
      })
      .expect(200);
    expect(res.body.data.alias).toBe('대성');
    expect(res.body.data.bizNumber).toBe('123-45-67890');
    expect(res.body.data.email).toBe('daesung@example.com');
    expect(res.body.data.memo).toBe('판교 담당');
    expect(res.body.data.name).toBe('대성건설'); // 변경 안 됨
    // DB 도 phone/name 유지
    const row = await prisma.partner.findUnique({
      where: { id: store.partnerId },
    });
    expect(row!.name).toBe('대성건설');
  });

  it('연결(승격) 상대: businessId 확인서 → 목록에 linked 로 포함', async () => {
    // 사업장 소유자 + ACCEPTED 연결을 직접 시드.
    const ownerToken = await signup(bizOwnerPhone);
    void ownerToken;
    const owner = await prisma.profile.findUnique({
      where: { phone: bizOwnerNorm },
    });
    const biz = await prisma.business.create({
      data: {
        name: '한빛종합건설',
        inviteCode: `PT${Date.now().toString().slice(-4)}`,
        ownerId: owner!.id,
      },
    });
    await prisma.connection.create({
      data: {
        profileId: worker1Id,
        businessId: biz.id,
        status: 'ACCEPTED',
        path: 'INVITE_CODE',
      },
    });
    store.bizId = biz.id;

    await createManualConfirmation({
      date: '2026-07-15',
      businessId: biz.id,
      companyName: '한빛종합건설',
    });

    const res = await request(app.getHttpServer())
      .get('/api/partners')
      .set('Authorization', auth())
      .expect(200);
    const linked = (res.body.data.items as Array<Record<string, unknown>>).find(
      (i) => i.businessId === biz.id,
    );
    expect(linked).toBeTruthy();
    expect(linked!.linked).toBe(true);
    expect(linked!.id).toBeNull();
    expect(linked!.name).toBe('한빛종합건설');
    expect(linked!.phone).toBe(bizOwnerNorm); // 소유자 전화
    expect(linked!.confirmationCount).toBe(1);
  });

  it('권한 격리: 타인은 내 거래처를 못 보고 PATCH/DELETE 404', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/partners')
      .set('Authorization', `Bearer ${token2}`)
      .expect(200);
    expect(res.body.data.count).toBe(0);

    await request(app.getHttpServer())
      .patch(`/api/partners/${store.partnerId}`)
      .set('Authorization', `Bearer ${token2}`)
      .send({ alias: '침입' })
      .expect(404);
    await request(app.getHttpServer())
      .delete(`/api/partners/${store.partnerId}`)
      .set('Authorization', `Bearer ${token2}`)
      .expect(404);
  });

  it('hard delete → 확인서가 남아 있으면 GET 시 lazy 재수집(보강값은 초기화)', async () => {
    await request(app.getHttpServer())
      .delete(`/api/partners/${store.partnerId}`)
      .set('Authorization', auth())
      .expect(200);

    const res = await request(app.getHttpServer())
      .get('/api/partners')
      .set('Authorization', auth())
      .expect(200);
    const p = (res.body.data.items as Array<Record<string, unknown>>).find(
      (i) => i.name === '대성건설',
    );
    expect(p).toBeTruthy(); // 재등장
    expect(p!.id).not.toBe(store.partnerId); // 새 행
    expect(p!.alias).toBeNull(); // 보강값은 사라짐
    expect(p!.confirmationCount).toBe(2); // 통계는 확인서에서 다시 파생
  });
});
