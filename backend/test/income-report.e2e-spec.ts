import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P2d 연간 소득 리포트 e2e (임시 postgres):
 *   일반(DAILY) + 공수(GONGSU) + 팀(반장 합계 / 팀원 파생) 시나리오 집계 정확성 + 권한 격리.
 *   - GET /ledger/income-report?year= (월별 추이·상대별·총계·팀 지급분·종소세 안내)
 *   - GET /ledger/income-report?from=&to= (분기 등 기간)
 *   - GET /ledger/income-report/pdf (인증 blob)
 */
describe('P2d Income report (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const boss = {
    phone: '010-8888-0401',
    norm: '01088880401',
    token: '',
    name: '박반장',
  };
  const member = {
    phone: '010-8888-0402',
    norm: '01088880402',
    token: '',
    name: '홍길동',
    profileId: '',
  };
  const outsider = { phone: '010-8888-0403', norm: '01088880403', token: '' };
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

  const bossAuth = () => `Bearer ${boss.token}`;
  const memberAuth = () => `Bearer ${member.token}`;
  const outsiderAuth = () => `Bearer ${outsider.token}`;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
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
      .set('Authorization', bossAuth())
      .send({ name: boss.name })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', memberAuth())
      .send({ name: member.name, phoneSearchConsent: true })
      .expect(200);

    // 반장: 일반 확인서 2건(삼성물산: 3월 입금 완료, 4월 미수) + 공수 확인서 1건(5월)
    const c1 = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', bossAuth())
      .send({
        date: '2026-03-05',
        siteName: '역삼 현장',
        companyName: '삼성물산',
        contact: '010-1111-2222',
        workDescription: '항타',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 180000,
        quantity: 1,
        dueDate: '2026-03-25',
      })
      .expect(201);
    const l1 = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: c1.body.data.id },
    });
    await request(app.getHttpServer())
      .post(`/api/ledger/${l1!.id}/payments`)
      .set('Authorization', bossAuth())
      .send({ amount: 180000 })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', bossAuth())
      .send({
        date: '2026-04-06',
        siteName: '역삼 현장',
        companyName: '삼성물산',
        contact: '010-1111-2222',
        workDescription: '항타',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 200000,
        quantity: 1,
        dueDate: '2026-04-25',
      })
      .expect(201);

    // 공수 확인서(GONGSU) 1.5공수 × 180,000 = 270,000 (현대건설 수기)
    await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', bossAuth())
      .send({
        date: '2026-05-10',
        siteName: '판교 현장',
        companyName: '현대건설',
        contact: '010-3333-4444',
        workDescription: '미장',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'GONGSU',
        rate: 180000,
        quantity: 1.5,
        dueDate: '2026-05-25',
      })
      .expect(201);

    // 팀: 팀 생성 → 가입 팀원 연결 + 수기 팀원 → 팀 확인서(6월) → 서명 → 파생
    const team = await request(app.getHttpServer())
      .post('/api/teams')
      .set('Authorization', bossAuth())
      .send({ name: '박반장 A팀' })
      .expect(201);
    store.teamId = team.body.data.id;

    const search = await request(app.getHttpServer())
      .get(`/api/workers/search?phone=${member.phone}`)
      .set('Authorization', bossAuth())
      .expect(200);
    member.profileId = search.body.data.items[0].profileId;

    const linked = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', bossAuth())
      .send({ profileId: member.profileId, defaultRate: 180000 })
      .expect(201);
    store.memberLinkedId = linked.body.data.id;

    const manual = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', bossAuth())
      .send({ name: '김수기', phone: '010-2222-3333', defaultRate: 150000 })
      .expect(201);
    store.memberManualId = manual.body.data.id;

    // 팀 확인서: 홍길동 1.5공수×180,000=270,000 + 김수기 1공수×150,000=150,000 = 420,000
    const tc = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', bossAuth())
      .send({
        date: '2026-06-08',
        siteName: '반포 현장',
        companyName: '삼성물산',
        contact: '010-5555-6666',
        workDescription: '골조(팀)',
        startTime: '08:00',
        endTime: '17:00',
        teamId: store.teamId,
        teamEntries: [
          { memberId: store.memberLinkedId, quantity: 1.5, rate: 180000 },
          { memberId: store.memberManualId, quantity: 1 },
        ],
        dueDate: '2026-06-25',
      })
      .expect(201);
    store.teamConfId = tc.body.data.id;
    store.teamToken = tc.body.data.shareToken;

    await request(app.getHttpServer())
      .post(`/api/confirmations/${store.teamConfId}/send`)
      .set('Authorization', bossAuth())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/public/confirmations/${store.teamToken}/sign`)
      .send({
        signerName: '현장소장',
        signImageBase64: await signPngDataUri(),
      })
      .expect(201);
  });

  afterAll(async () => {
    for (const p of [boss.norm, member.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  it('반장 연간 리포트 — 총계(일반+공수+팀 합계) 정확', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .set('Authorization', bossAuth())
      .expect(200);
    const d = res.body.data;
    // 청구액: 180,000(3월) + 200,000(4월) + 270,000(5월 공수) + 420,000(6월 팀) = 1,070,000
    expect(d.totals.totalBilled).toBe(1070000);
    // 입금: 3월 180,000
    expect(d.totals.totalPaid).toBe(180000);
    // 미수: 200,000 + 270,000 + 420,000 = 890,000
    expect(d.totals.totalOutstanding).toBe(890000);
    // 일한 날: 3/5, 4/6, 5/10, 6/8 = 4일
    expect(d.totals.totalDays).toBe(4);
    // 공수: 5월 1.5 + 6월 팀 2.5 = 4.0
    expect(d.totals.totalGongsu).toBe(4);
    // 팀 지급분: 270,000 + 150,000 = 420,000 (반장 본인 몫 없음)
    expect(d.totals.teamPayout).toBe(420000);
    // 순소득 참고: 1,070,000 - 420,000 = 650,000
    expect(d.totals.netBilled).toBe(650000);
    expect(d.totals.entryCount).toBe(4);
  });

  it('반장 연간 리포트 — 월별 추이(12개월, 데이터 월만 값)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .set('Authorization', bossAuth())
      .expect(200);
    const m = res.body.data.monthly as Array<{
      month: string;
      billed: number;
      paid: number;
      outstanding: number;
      daysWorked: number;
      gongsu: number;
    }>;
    expect(m).toHaveLength(12);
    const byMonth = Object.fromEntries(m.map((x) => [x.month, x]));
    expect(byMonth['2026-03'].billed).toBe(180000);
    expect(byMonth['2026-03'].paid).toBe(180000);
    expect(byMonth['2026-04'].billed).toBe(200000);
    expect(byMonth['2026-04'].outstanding).toBe(200000);
    expect(byMonth['2026-05'].billed).toBe(270000);
    expect(byMonth['2026-05'].gongsu).toBe(1.5);
    expect(byMonth['2026-06'].billed).toBe(420000);
    expect(byMonth['2026-06'].gongsu).toBe(2.5);
    expect(byMonth['2026-01'].billed).toBe(0);
  });

  it('반장 연간 리포트 — 상대별 합계(삼성물산 합산)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .set('Authorization', bossAuth())
      .expect(200);
    const companies = res.body.data.companies as Array<{
      companyName: string;
      count: number;
      total: number;
    }>;
    const samsung = companies.find((c) => c.companyName === '삼성물산')!;
    // 3월 180,000 + 4월 200,000 + 6월 팀 420,000 = 800,000, 3건
    expect(samsung.total).toBe(800000);
    expect(samsung.count).toBe(3);
    const hyundai = companies.find((c) => c.companyName === '현대건설')!;
    expect(hyundai.total).toBe(270000);
    // 총액 내림차순 정렬
    expect(companies[0].companyName).toBe('삼성물산');
  });

  it('종소세 안내 문구 포함(5월 신고·3.3%·세무상담 아님)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .set('Authorization', bossAuth())
      .expect(200);
    const note = res.body.data.taxNote;
    expect(note.lines.join(' ')).toContain('5월');
    expect(note.lines.join(' ')).toContain('3.3%');
    expect(note.lines.join(' ')).toContain('세무 상담');
  });

  it('팀원 연간 리포트 — 파생 항목이 본인 소득으로 집계(팀 지급분 0)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .set('Authorization', memberAuth())
      .expect(200);
    const d = res.body.data;
    expect(d.totals.totalBilled).toBe(270000); // 홍길동 몫
    expect(d.totals.teamPayout).toBe(0);
    expect(d.totals.netBilled).toBe(270000);
    expect(d.totals.totalGongsu).toBe(1.5);
    expect(d.companies[0].companyName).toBe(boss.name); // 반장 이름 상대
  });

  it('기간(from&to) — 분기(4~6월)만 집계', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?from=2026-04&to=2026-06')
      .set('Authorization', bossAuth())
      .expect(200);
    const d = res.body.data;
    expect(d.monthly).toHaveLength(3);
    // 4월 200,000 + 5월 270,000 + 6월 420,000 = 890,000 (3월 제외)
    expect(d.totals.totalBilled).toBe(890000);
    expect(d.range.from).toBe('2026-04');
    expect(d.range.to).toBe('2026-06');
  });

  it('권한 격리 — outsider 는 빈 리포트, 미인증 401', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .set('Authorization', outsiderAuth())
      .expect(200);
    expect(res.body.data.totals.totalBilled).toBe(0);
    expect(res.body.data.companies).toHaveLength(0);

    await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=2026')
      .expect(401);
  });

  it('잘못된 파라미터 — year/from-to 누락 400, year 형식 400', async () => {
    await request(app.getHttpServer())
      .get('/api/ledger/income-report')
      .set('Authorization', bossAuth())
      .expect(400);
    await request(app.getHttpServer())
      .get('/api/ledger/income-report?year=20xx')
      .set('Authorization', bossAuth())
      .expect(400);
  });

  it('소득 리포트 PDF — 인증 blob(%PDF)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/ledger/income-report/pdf?year=2026')
      .set('Authorization', bossAuth())
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(res.body.length).toBeGreaterThan(2000);

    // 미인증 401
    await request(app.getHttpServer())
      .get('/api/ledger/income-report/pdf?year=2026')
      .expect(401);
  });
});
