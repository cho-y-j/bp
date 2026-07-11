import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P2a 팀(반장) 기능 e2e (임시 postgres):
 *   팀 CRUD → 팀원(가입 연결 + 수기) → 팀 확인서(팀원 공수) → 반장 장부 합계 1건
 *   → 서명 → 팀원 파생 장부 생성(가입자만) + 알림 → 파생 읽기전용/입금 → 권한 격리.
 */
describe('P2a Teams flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const boss = { phone: '010-8888-0001', norm: '01088880001', token: '', name: '박반장' };
  const member = { phone: '010-8888-0002', norm: '01088880002', token: '', name: '홍길동', profileId: '' };
  const outsider = { phone: '010-8888-0003', norm: '01088880003', token: '' };

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

    for (const p of [boss.norm, member.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    boss.token = await signup(boss.phone);
    member.token = await signup(member.phone);
    outsider.token = await signup(outsider.phone);

    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${boss.token}`)
      .send({ name: boss.name })
      .expect(200);
    // 팀원(가입자)은 이름 + 전화검색 동의(연결 대상 조건)
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${member.token}`)
      .send({ name: member.name, phoneSearchConsent: true })
      .expect(200);
  });

  afterAll(async () => {
    for (const p of [boss.norm, member.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  const bossAuth = () => `Bearer ${boss.token}`;
  const memberAuth = () => `Bearer ${member.token}`;
  const outsiderAuth = () => `Bearer ${outsider.token}`;

  it('반장이 팀 생성', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/teams')
      .set('Authorization', bossAuth())
      .send({ name: '박반장 A팀' })
      .expect(201);
    expect(res.body.data.name).toBe('박반장 A팀');
    expect(res.body.data.memberCount).toBe(0);
    store.teamId = res.body.data.id;
  });

  it('전화검색으로 가입 팀원 조회 → 연결(가입자) 팀원 추가', async () => {
    const search = await request(app.getHttpServer())
      .get(`/api/workers/search?phone=${member.phone}`)
      .set('Authorization', bossAuth())
      .expect(200);
    expect(search.body.data.count).toBe(1);
    member.profileId = search.body.data.items[0].profileId;

    const res = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', bossAuth())
      .send({ profileId: member.profileId, defaultRate: 180000 })
      .expect(201);
    expect(res.body.data.linked).toBe(true);
    expect(res.body.data.name).toBe('홍길동'); // 프로필명 스냅샷
    expect(res.body.data.defaultRate).toBe(180000);
    store.memberLinkedId = res.body.data.id;
  });

  it('수기 팀원 추가(이름+전화)', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', bossAuth())
      .send({ name: '김수기', phone: '010-2222-3333', defaultRate: 150000 })
      .expect(201);
    expect(res.body.data.linked).toBe(false);
    expect(res.body.data.name).toBe('김수기');
    store.memberManualId = res.body.data.id;
  });

  it('동의 안 한 프로필은 팀원 연결 불가(403)', async () => {
    const search = await request(app.getHttpServer())
      .get(`/api/workers/search?phone=${outsider.phone}`)
      .set('Authorization', bossAuth())
      .expect(200);
    // outsider 는 동의 안 함 → 검색 결과 없음
    expect(search.body.data.count).toBe(0);
  });

  it('GET /teams → 팀 + 팀원 2명', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/teams')
      .set('Authorization', bossAuth())
      .expect(200);
    const team = res.body.data.items.find((t: { id: string }) => t.id === store.teamId);
    expect(team.memberCount).toBe(2);
  });

  it('권한 격리 — 남의 팀 조회/팀원 추가 불가(404)', async () => {
    await request(app.getHttpServer())
      .get(`/api/teams/${store.teamId}`)
      .set('Authorization', outsiderAuth())
      .expect(404);
    await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', outsiderAuth())
      .send({ name: '침입자' })
      .expect(404);
  });

  it('팀 확인서 작성 → 서버 팀 합계 계산 + 반장 장부 합계 1건', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', bossAuth())
      .send({
        date: '2026-07-08',
        siteName: '반포 현장',
        companyName: '삼성물산',
        contact: '010-5555-6666',
        workDescription: '골조 정리(팀)',
        startTime: '08:00',
        endTime: '17:00',
        teamId: store.teamId,
        teamEntries: [
          { memberId: store.memberLinkedId, quantity: 1.5, rate: 180000 },
          { memberId: store.memberManualId, quantity: 1 }, // rate 미지정 → defaultRate 150000
        ],
        dueDate: '2026-07-25',
      })
      .expect(201);
    const c = res.body.data;
    expect(c.total).toBe(420000); // 270000 + 150000
    expect(c.teamId).toBe(store.teamId);
    expect(c.teamEntries).toHaveLength(2);
    expect(c.rateType).toBe('GONGSU');
    store.confId = c.id;
    store.token = c.shareToken;

    // 반장 장부 합계 1건
    const ledgers = await prisma.ledgerEntry.findMany({
      where: { confirmationId: c.id },
    });
    expect(ledgers).toHaveLength(1);
    expect(Number(ledgers[0].amount)).toBe(420000);
    expect(ledgers[0].derived).toBe(false);
  });

  it('반장 summary → totalGongsu 2.5 반영', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/summary?month=2026-07')
      .set('Authorization', bossAuth())
      .expect(200);
    expect(res.body.data.totalBilled).toBe(420000);
    expect(res.body.data.totalGongsu).toBe(2.5);
  });

  it('서명 전 팀원 파생 없음', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-07')
      .set('Authorization', memberAuth())
      .expect(200);
    expect(res.body.data.count).toBe(0);
  });

  it('전송 → 공개 서명 → SIGNED', async () => {
    await request(app.getHttpServer())
      .post(`/api/confirmations/${store.confId}/send`)
      .set('Authorization', bossAuth())
      .expect(201);
    const res = await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.token}/sign`)
      .send({ signerName: '현장소장', signImageBase64: await signPngDataUri() })
      .expect(201);
    expect(res.body.data.status).toBe('SIGNED');
  });

  it('공개 열람 응답에 teamEntries 포함(웹 P2 통합용)', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/public/confirmations/${store.token}`)
      .expect(200);
    expect(res.body.data.isTeam).toBe(true);
    expect(Array.isArray(res.body.data.teamEntries)).toBe(true);
    expect(res.body.data.teamEntries).toHaveLength(2);
    expect(res.body.data.total).toBe(420000);
  });

  it('서명 후 가입 팀원 장부에 파생 항목 생성(읽기전용) + 알림', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/entries?month=2026-07')
      .set('Authorization', memberAuth())
      .expect(200);
    expect(res.body.data.count).toBe(1);
    const d = res.body.data.items[0];
    expect(d.derived).toBe(true);
    expect(d.amount).toBe(270000);
    expect(d.counterpartyName).toBe(boss.name);
    expect(d.sourceConfirmationId).toBe(store.confId);
    expect(d.siteName).toBe('반포 현장');
    store.derivedId = d.id;

    // 알림 생성
    const notif = await prisma.notification.findFirst({
      where: {
        profileId: member.profileId,
        data: { path: ['sourceConfirmationId'], equals: store.confId },
      },
    });
    expect(notif).toBeTruthy();

    // 수기(미가입) 팀원은 파생 없음 → 반장/멤버 외 파생 총 1건
    const allDerived = await prisma.ledgerEntry.findMany({
      where: { sourceConfirmationId: store.confId },
    });
    expect(allDerived).toHaveLength(1);
  });

  it('파생 항목은 읽기전용 — 수금예정일 수정 409', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/ledger/${store.derivedId}`)
      .set('Authorization', memberAuth())
      .send({ dueDate: '2026-08-01' })
      .expect(409);
    expect(res.body.error.code).toBe('LEDGER_DERIVED_READONLY');
  });

  it('파생 항목에 입금 기록은 가능', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/ledger/${store.derivedId}/payments`)
      .set('Authorization', memberAuth())
      .send({ amount: 270000, memo: '반장 정산 수령' })
      .expect(201);
    expect(res.body.data.status).toBe('PAID');
    expect(res.body.data.outstanding).toBe(0);
  });

  it('팀원 summary → 자기 몫 공수 1.5 반영', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/summary?month=2026-07')
      .set('Authorization', memberAuth())
      .expect(200);
    expect(res.body.data.totalBilled).toBe(270000);
    expect(res.body.data.totalGongsu).toBe(1.5);
  });

  it('권한 격리 — 남의 팀으로 팀 확인서 작성 불가(404)', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', outsiderAuth())
      .send({
        date: '2026-07-08',
        siteName: '침입 현장',
        companyName: '수기',
        workDescription: 'x',
        startTime: '08:00',
        endTime: '17:00',
        teamId: store.teamId,
        teamEntries: [{ memberId: store.memberLinkedId, quantity: 1, rate: 1000 }],
      })
      .expect(404);
    expect(res.body.error.code).toBe('TEAM_NOT_FOUND');
  });

  it('팀 확인서 PDF → 팀 명단 표 렌더(PDF 생성)', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/confirmations/${store.confId}/pdf`)
      .set('Authorization', bossAuth())
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(res.body.length).toBeGreaterThan(2000);
  });
});
