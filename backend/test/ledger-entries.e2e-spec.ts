import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * 장부 개별 항목 e2e (백로그 보강 — S4a 추가 엔드포인트):
 *  GET /ledger/entries?month=&businessId=
 *    - 확인서 작성 → 자동생성된 장부 항목이 항목 id·상대명·현장·작업일과 함께 조회
 *    - month 유효성(YYYY-MM) 검증 → 400
 *    - businessId 필터 (수기 상대는 businessId=null 이므로 필터 시 제외)
 *  권한 격리: 타인은 내 장부 항목을 보지 못한다(count 0) / 미인증 → 401.
 */
describe('Ledger entries (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const phoneA = '010-7777-0301';
  const normA = '01077770301';
  const phoneB = '010-7777-0302';
  const normB = '01077770302';
  let tokenA: string;
  let tokenB: string;
  let entryId: string;

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
    for (const p of [normA, normB]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    tokenA = await loginAs(phoneA);
    tokenB = await loginAs(phoneB);

    // 확인서 작성 → 장부 항목 자동생성 (수기 상대)
    const conf = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        date: '2026-07-08',
        siteName: '역삼 현장',
        companyName: '삼성물산',
        contact: '010-1111-2222',
        workDescription: '항타',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 180000,
        quantity: 1,
        dueDate: '2026-07-25',
      })
      .expect(201);
    const ledger = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: conf.body.data.id },
    });
    entryId = ledger!.id;
  });

  afterAll(async () => {
    for (const p of [normA, normB]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  it('소유자: 월별 항목 조회 → id·상대명·현장·작업일·미수 포함', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-07')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);
    expect(res.body.data.month).toBe('2026-07');
    expect(res.body.data.count).toBeGreaterThanOrEqual(1);
    const item = res.body.data.items.find(
      (e: { id: string }) => e.id === entryId,
    );
    expect(item).toBeTruthy();
    expect(item.companyName).toBe('삼성물산');
    expect(item.siteName).toBe('역삼 현장');
    expect(item.date).toBe('2026-07-08');
    expect(item.amount).toBe(180000);
    expect(item.outstanding).toBe(180000);
    expect(item.status).toBe('PENDING');
  });

  it('부분입금 반영 후 outstanding 감소', async () => {
    await request(app.getHttpServer())
      .post(`/api/ledger/${entryId}/payments`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ amount: 80000 })
      .expect(201);
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-07')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);
    const item = res.body.data.items.find(
      (e: { id: string }) => e.id === entryId,
    );
    expect(item.paid).toBe(80000);
    expect(item.outstanding).toBe(100000);
    expect(item.status).toBe('PARTIAL');
  });

  it('businessId 필터: 존재하지 않는 사업장 → 수기 상대 제외(count 0)', async () => {
    const res = await request(app.getHttpServer())
      .get(
        '/api/ledger/entries?month=2026-07&businessId=00000000-0000-4000-8000-000000000000',
      )
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);
    expect(res.body.data.count).toBe(0);
  });

  it('다른 달 → 해당 항목 없음', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-06')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(200);
    const ids = res.body.data.items.map((e: { id: string }) => e.id);
    expect(ids).not.toContain(entryId);
  });

  it('month 형식 오류 → 400 INVALID_MONTH', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-7')
      .set('Authorization', `Bearer ${tokenA}`)
      .expect(400);
    expect(res.body.error.code).toBe('INVALID_MONTH');
  });

  it('권한 격리: 타인(B)은 A의 장부 항목을 보지 못한다(count 0)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-07')
      .set('Authorization', `Bearer ${tokenB}`)
      .expect(200);
    expect(res.body.data.count).toBe(0);
    const ids = res.body.data.items.map((e: { id: string }) => e.id);
    expect(ids).not.toContain(entryId);
  });

  it('미인증 → 401', async () => {
    await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-07')
      .expect(401);
  });
});
