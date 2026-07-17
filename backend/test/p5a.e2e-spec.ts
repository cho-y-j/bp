import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P5a 사업장 강화 3종 API e2e (임시 postgres 5438):
 *  1) GET /biz/site-costs (+/pdf) — 현장별 인건비 집계(작업자/팀, 소계·총계)
 *  2) GET /biz/wage-statement (+ POST /mark) — 일용근로소득 지급명세서 도우미(지급 기준·세액)
 *  3) GET /biz/today-attendance — 오늘의 출역 현황판(현장별·상태)
 *  + 권한 격리 / businessId 스코프 / PDF / mark 멱등
 */
describe('P5a 사업장 강화 (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const owner = {
    phone: '010-7777-0501',
    norm: '01077770501',
    token: '',
    name: '사장님',
  };
  const outsider = {
    phone: '010-7777-0502',
    norm: '01077770502',
    token: '',
    name: '남사장',
  };
  const w1 = {
    phone: '010-7777-0511',
    norm: '01077770511',
    token: '',
    name: '김철수',
    id: '',
  };
  const w2 = {
    phone: '010-7777-0512',
    norm: '01077770512',
    token: '',
    name: '이영호',
    id: '',
  };
  const boss = {
    phone: '010-7777-0513',
    norm: '01077770513',
    token: '',
    name: '박반장',
    id: '',
  };
  const all = [owner, outsider, w1, w2, boss];
  const store: Record<string, string> = {};

  async function signup(phone: string): Promise<string> {
    const r = await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone })
      .expect(200);
    const code = r.body.data.devCode;
    const v = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone, code })
      .expect(200);
    return v.body.data.accessToken;
  }
  const auth = (t: string) => `Bearer ${t}`;

  async function signPng(): Promise<string> {
    const png = await sharp({
      create: {
        width: 160,
        height: 60,
        channels: 4,
        background: { r: 0, g: 0, b: 180, alpha: 1 },
      },
    })
      .png()
      .toBuffer();
    return `data:image/png;base64,${png.toString('base64')}`;
  }

  /** 워커가 businessId 대상 확인서 작성 → send → 사업주 서명(SIGNED). ledgerEntryId 반환. */
  async function signedConfirmation(
    workerToken: string,
    body: Record<string, unknown>,
  ): Promise<{ confId: string; ledgerId: string }> {
    const c = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth(workerToken))
      .send({ businessId: store.bizId, ...body })
      .expect(201);
    const confId = c.body.data.id;
    await request(app.getHttpServer())
      .post(`/api/confirmations/${confId}/send`)
      .set('Authorization', auth(workerToken))
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/biz/confirmations/${confId}/sign`)
      .set('Authorization', auth(owner.token))
      .send({ signerName: owner.name, signImageBase64: await signPng() })
      .expect(201);
    const le = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: confId },
    });
    return { confId, ledgerId: le!.id };
  }

  async function connect(workerToken: string): Promise<void> {
    const r = await request(app.getHttpServer())
      .post('/api/connections')
      .set('Authorization', auth(workerToken))
      .send({ businessId: store.bizId, path: 'INVITE_CODE' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/connections/${r.body.data.id}/accept`)
      .set('Authorization', auth(owner.token))
      .expect(201);
  }

  function kstTodayStr(): string {
    return new Date(Date.now() + 9 * 3600 * 1000).toISOString().slice(0, 10);
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

    for (const p of all) {
      await prisma.profile.deleteMany({ where: { phone: p.norm } });
      await prisma.otpCode.deleteMany({ where: { phone: p.norm } });
    }

    for (const p of all) p.token = await signup(p.phone);
    // 이름/동의 설정
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', auth(owner.token))
      .send({ name: owner.name })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', auth(outsider.token))
      .send({ name: outsider.name })
      .expect(200);
    for (const w of [w1, w2, boss]) {
      const me = await request(app.getHttpServer())
        .patch('/api/me')
        .set('Authorization', auth(w.token))
        .send({ name: w.name, phoneSearchConsent: true })
        .expect(200);
      w.id = me.body.data.id;
    }

    // 사업장 2개(스코프 격리용) + outsider 사업장
    const biz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', auth(owner.token))
      .send({ name: '대한건설' })
      .expect(201);
    store.bizId = biz.body.data.id;
    const biz2 = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', auth(owner.token))
      .send({ name: '제2현장사업' })
      .expect(201);
    store.biz2Id = biz2.body.data.id;
    const obiz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', auth(outsider.token))
      .send({ name: '남건설' })
      .expect(201);
    store.outBizId = obiz.body.data.id;

    // 연결(ACCEPTED)
    for (const w of [w1, w2, boss]) await connect(w.token);

    // --- SIGNED 확인서 시드 (2026-06, businessId=대한건설) ---
    // 역삼 현장: w1 일당 20만×3일=60만, w2 일당 15만×1=15만
    const s1 = await signedConfirmation(w1.token, {
      date: '2026-06-05',
      siteName: '역삼 현장',
      workDescription: '항타',
      startTime: '08:00',
      endTime: '17:00',
      rateType: 'DAILY',
      rate: 200000,
      quantity: 3,
      dueDate: '2026-06-25',
    });
    store.w1DailyLedger = s1.ledgerId;
    const s2 = await signedConfirmation(w2.token, {
      date: '2026-06-06',
      siteName: '역삼 현장',
      workDescription: '미장',
      startTime: '08:00',
      endTime: '17:00',
      rateType: 'DAILY',
      rate: 150000,
      quantity: 1,
      dueDate: '2026-06-25',
    });
    store.w2Ledger = s2.ledgerId;
    // 판교 현장: w1 공수 1.5 × 18만 = 27만 (미지급 → 지급명세서 제외)
    await signedConfirmation(w1.token, {
      date: '2026-06-10',
      siteName: '판교 현장',
      workDescription: '방수',
      startTime: '08:00',
      endTime: '17:00',
      rateType: 'GONGSU',
      rate: 180000,
      quantity: 1.5,
    });

    // 반포 현장: 반장 팀 확인서 — 팀원 2명(수기), 합계 42만
    const team = await request(app.getHttpServer())
      .post('/api/teams')
      .set('Authorization', auth(boss.token))
      .send({ name: '박반장팀' })
      .expect(201);
    store.teamId = team.body.data.id;
    const m1 = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', auth(boss.token))
      .send({ name: '팀원가', phone: '010-1000-0001', defaultRate: 180000 })
      .expect(201);
    const m2 = await request(app.getHttpServer())
      .post(`/api/teams/${store.teamId}/members`)
      .set('Authorization', auth(boss.token))
      .send({ name: '팀원나', phone: '010-1000-0002', defaultRate: 150000 })
      .expect(201);
    const tc = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth(boss.token))
      .send({
        businessId: store.bizId,
        date: '2026-06-08',
        siteName: '반포 현장',
        workDescription: '골조(팀)',
        startTime: '08:00',
        endTime: '17:00',
        teamId: store.teamId,
        teamEntries: [
          { memberId: m1.body.data.id, quantity: 1.5, rate: 180000 },
          { memberId: m2.body.data.id, quantity: 1 },
        ],
        dueDate: '2026-06-25',
      })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/confirmations/${tc.body.data.id}/send`)
      .set('Authorization', auth(boss.token))
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/biz/confirmations/${tc.body.data.id}/sign`)
      .set('Authorization', auth(owner.token))
      .send({ signerName: owner.name, signImageBase64: await signPng() })
      .expect(201);
    const tle = await prisma.ledgerEntry.findFirst({
      where: { confirmationId: tc.body.data.id },
    });
    store.teamLedger = tle!.id;

    // 다른 사업장(제2현장사업)에 확인서 1건 — 스코프 격리 확인용
    await connectTo(store.biz2Id, w1.token);
    const other = await request(app.getHttpServer())
      .post('/api/confirmations')
      .set('Authorization', auth(w1.token))
      .send({
        businessId: store.biz2Id,
        date: '2026-06-11',
        siteName: '제2현장',
        workDescription: '기타',
        startTime: '08:00',
        endTime: '17:00',
        rateType: 'DAILY',
        rate: 300000,
        quantity: 1,
      })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/confirmations/${other.body.data.id}/send`)
      .set('Authorization', auth(w1.token))
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/biz/confirmations/${other.body.data.id}/sign`)
      .set('Authorization', auth(owner.token))
      .send({ signerName: owner.name, signImageBase64: await signPng() })
      .expect(201);

    // --- 지급(paidAt 2026-06-20): w1 역삼 60만, w2 15만, 반장 팀 42만 (판교 27만 미지급) ---
    await request(app.getHttpServer())
      .post('/api/biz/settlements/pay')
      .set('Authorization', auth(owner.token))
      .send({
        ledgerEntryIds: [store.w1DailyLedger, store.w2Ledger, store.teamLedger],
        paidAt: '2026-06-20',
      })
      .expect(201);

    // --- 오늘의 출역: 오늘 KST jobs 4건(예정/수락/시작/완료) ---
    const today = kstTodayStr();
    const at = (h: string) => `${today}T${h}:00+09:00`;
    async function makeJob(workerId: string, site: string): Promise<string> {
      const r = await request(app.getHttpServer())
        .post('/api/jobs')
        .set('Authorization', auth(owner.token))
        .send({
          businessId: store.bizId,
          workerProfileId: workerId,
          site,
          scheduledAt: at('08:00'),
          rateType: 'DAILY',
          rate: 200000,
        })
        .expect(201);
      return r.body.data.id;
    }
    store.jobScheduled = await makeJob(w1.id, '오늘현장A'); // 예정(미수락)
    const jAccept = await makeJob(w2.id, '오늘현장A');
    await request(app.getHttpServer())
      .post(`/api/jobs/${jAccept}/confirm`)
      .set('Authorization', auth(w2.token))
      .expect(201); // 수락
    const jStart = await makeJob(boss.id, '오늘현장B');
    await request(app.getHttpServer())
      .post(`/api/jobs/${jStart}/confirm`)
      .set('Authorization', auth(boss.token))
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/jobs/${jStart}/start`)
      .set('Authorization', auth(boss.token))
      .send({ lat: 37.5, lng: 127.0, condition: 'OK' })
      .expect(201); // 시작
    const jDone = await makeJob(boss.id, '오늘현장B');
    await request(app.getHttpServer())
      .post(`/api/jobs/${jDone}/confirm`)
      .set('Authorization', auth(boss.token))
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/jobs/${jDone}/start`)
      .set('Authorization', auth(boss.token))
      .send({ lat: 37.5, lng: 127.0, condition: 'OK' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/jobs/${jDone}/complete`)
      .set('Authorization', auth(boss.token))
      .send({ lat: 37.5, lng: 127.0 })
      .expect(201); // 완료
  }, 60000);

  async function connectTo(bizId: string, workerToken: string): Promise<void> {
    const r = await request(app.getHttpServer())
      .post('/api/connections')
      .set('Authorization', auth(workerToken))
      .send({ businessId: bizId, path: 'INVITE_CODE' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/api/connections/${r.body.data.id}/accept`)
      .set('Authorization', auth(owner.token))
      .expect(201);
  }

  afterAll(async () => {
    for (const p of all) {
      await prisma.profile.deleteMany({ where: { phone: p.norm } });
      await prisma.otpCode.deleteMany({ where: { phone: p.norm } });
    }
    await app.close();
  });

  // ==================== 1. site-costs ====================
  it('site-costs — 현장별 집계(작업자/팀·소계·총계)', async () => {
    const res = await request(app.getHttpServer())
      .get(
        `/api/biz/site-costs?from=2026-06&to=2026-06&businessId=${store.bizId}`,
      )
      .set('Authorization', auth(owner.token))
      .expect(200);
    const d = res.body.data;
    expect(d.businessName).toContain('대한건설');
    // 총계: 60만 + 15만 + 27만 + 42만 = 144만 (제2현장은 businessId 스코프로 제외)
    expect(d.totals.totalAmount).toBe(1440000);
    expect(d.totals.siteCount).toBe(3);
    // 현장 금액 내림차순: 역삼(75만) > 반포(42만) > 판교(27만)
    expect(d.sites[0].site).toBe('역삼 현장');
    expect(d.sites[0].subtotalAmount).toBe(750000);
    expect(d.sites[0].subtotalDays).toBe(4); // 3 + 1 man-days
    const yeoksam = d.sites[0];
    const w1row = yeoksam.entries.find(
      (e: { amount: number }) => e.amount === 600000,
    );
    expect(w1row.days).toBe(3);
    expect(w1row.isTeam).toBe(false);
    // 반포 = 팀 행
    const banpo = d.sites.find((s: { site: string }) => s.site === '반포 현장');
    expect(banpo.entries[0].isTeam).toBe(true);
    expect(banpo.entries[0].teamMemberCount).toBe(2);
    expect(banpo.entries[0].amount).toBe(420000);
    expect(banpo.entries[0].gongsu).toBe(2.5);
    // 판교 = 공수
    const pangyo = d.sites.find(
      (s: { site: string }) => s.site === '판교 현장',
    );
    expect(pangyo.entries[0].gongsu).toBe(1.5);
    // 이름 마스킹
    expect(w1row.workerName).toBe('김*수');
  });

  it('site-costs — businessId 스코프(제2사업장만 지정 시 제2현장)', async () => {
    const res = await request(app.getHttpServer())
      .get(
        `/api/biz/site-costs?from=2026-06&to=2026-06&businessId=${store.biz2Id}`,
      )
      .set('Authorization', auth(owner.token))
      .expect(200);
    expect(res.body.data.totals.totalAmount).toBe(300000);
    expect(res.body.data.sites[0].site).toBe('제2현장');
    // businessId 미지정 → 소유 전체 집계(대한건설 144만 + 제2현장 30만 = 174만)
    const allRes = await request(app.getHttpServer())
      .get('/api/biz/site-costs?from=2026-06&to=2026-06')
      .set('Authorization', auth(owner.token))
      .expect(200);
    expect(allRes.body.data.totals.totalAmount).toBe(1740000);
  });

  it('site-costs — 권한 격리(outsider 빈 결과·미인증 401)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/site-costs?from=2026-06&to=2026-06')
      .set('Authorization', auth(outsider.token))
      .expect(200);
    expect(res.body.data.totals.totalAmount).toBe(0);
    // 남의 businessId 지정 → 빈 결과(유출 차단)
    const leak = await request(app.getHttpServer())
      .get(
        `/api/biz/site-costs?from=2026-06&to=2026-06&businessId=${store.bizId}`,
      )
      .set('Authorization', auth(outsider.token))
      .expect(200);
    expect(leak.body.data.totals.totalAmount).toBe(0);
    await request(app.getHttpServer())
      .get('/api/biz/site-costs?from=2026-06&to=2026-06')
      .expect(401);
  });

  it('site-costs — 범위 검증(13개월 초과 400, from>to 400)', async () => {
    await request(app.getHttpServer())
      .get('/api/biz/site-costs?from=2025-01&to=2026-06')
      .set('Authorization', auth(owner.token))
      .expect(400);
    await request(app.getHttpServer())
      .get('/api/biz/site-costs?from=2026-06&to=2026-01')
      .set('Authorization', auth(owner.token))
      .expect(400);
  });

  it('site-costs PDF — 인증 blob(%PDF)·미인증 401', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/site-costs/pdf?from=2026-06&to=2026-06')
      .set('Authorization', auth(owner.token))
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(res.body.length).toBeGreaterThan(2000);
    await request(app.getHttpServer())
      .get('/api/biz/site-costs/pdf?from=2026-06&to=2026-06')
      .expect(401);
  });

  // ==================== 2. wage-statement ====================
  it('wage-statement — 지급 기준 작업자별 세액(사업3.3·일용)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/wage-statement?month=2026-06')
      .set('Authorization', auth(owner.token))
      .expect(200);
    const d = res.body.data;
    // 지급총액: 60만 + 15만 + 42만 = 117만 (판교 27만 미지급 제외)
    expect(d.totals.paidTotal).toBe(1170000);
    expect(d.totals.workerCount).toBe(3);
    const byName = Object.fromEntries(
      d.workers.map((w: { workerName: string }) => [w.workerName, w]),
    );
    // 김철수(김*수): 60만/3일 → 3.3% 소득세 18,000 / 일용 소득세 4,050(=1,350×3)
    const kim = byName['김*수'];
    expect(kim.paidTotal).toBe(600000);
    expect(kim.workDays).toBe(3);
    expect(kim.business3_3.incomeTax).toBe(18000);
    expect(kim.business3_3.totalTax).toBe(19800);
    expect(kim.dailyWage.incomeTax).toBe(4050);
    expect(kim.dailyWage.localTax).toBe(400); // floor10(405)
    expect(kim.dailyWage.netPay).toBe(595550);
    // 이영호(이*호): 15만/1일 → 일용 0(150,000 이하), 3.3% 4,500
    const lee = byName['이*호'];
    expect(lee.dailyWage.incomeTax).toBe(0);
    expect(lee.business3_3.incomeTax).toBe(4500);
    // 박반장(박*장): 팀 42만 → 3.3% 12,600
    const bak = byName['박*장'];
    expect(bak.business3_3.incomeTax).toBe(12600);
    // 안내/주민번호/복사텍스트
    expect(d.notes.join(' ')).toContain('세무 상담이 아닙니다');
    expect(d.hometaxNote).toContain('직접 입력');
    expect(d.copyText).toContain('지급총액');
    expect(d.marked).toBe(false);
  });

  it('wage-statement mark — 멱등(2회 호출·재조회 marked=true)', async () => {
    const r1 = await request(app.getHttpServer())
      .post('/api/biz/wage-statement/mark')
      .set('Authorization', auth(owner.token))
      .send({ month: '2026-06', businessId: store.bizId })
      .expect(201);
    expect(r1.body.data.marked).toBe(true);
    expect(r1.body.data.alreadyMarked).toBe(false);
    const r2 = await request(app.getHttpServer())
      .post('/api/biz/wage-statement/mark')
      .set('Authorization', auth(owner.token))
      .send({ month: '2026-06', businessId: store.bizId })
      .expect(201);
    expect(r2.body.data.marked).toBe(true);
    expect(r2.body.data.alreadyMarked).toBe(true);
    // 재조회 — 여전히 데이터 조회 가능 + marked 표시
    const res = await request(app.getHttpServer())
      .get(`/api/biz/wage-statement?month=2026-06&businessId=${store.bizId}`)
      .set('Authorization', auth(owner.token))
      .expect(200);
    expect(res.body.data.marked).toBe(true);
    expect(res.body.data.totals.paidTotal).toBe(1170000);
  });

  it('wage-statement — 권한 격리(outsider 빈·미인증 401)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/wage-statement?month=2026-06')
      .set('Authorization', auth(outsider.token))
      .expect(200);
    expect(res.body.data.totals.paidTotal).toBe(0);
    await request(app.getHttpServer())
      .get('/api/biz/wage-statement?month=2026-06')
      .expect(401);
  });

  // ==================== 3. today-attendance ====================
  it('today-attendance — 현장별 상태(예정/수락/시작/완료)+인원 요약', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/today-attendance')
      .set('Authorization', auth(owner.token))
      .expect(200);
    const d = res.body.data;
    expect(d.date).toBe(kstTodayStr());
    expect(d.summary.total).toBe(4);
    expect(d.summary.attended).toBe(2); // 시작 + 완료
    expect(d.summary.completed).toBe(1);
    expect(d.summary.absent).toBe(2); // 예정 + 수락
    // 현장 그룹
    const siteA = d.sites.find((s: { site: string }) => s.site === '오늘현장A');
    const siteB = d.sites.find((s: { site: string }) => s.site === '오늘현장B');
    const statusesA = siteA.workers
      .map((w: { status: string }) => w.status)
      .sort();
    expect(statusesA).toEqual(['ACCEPTED', 'SCHEDULED']);
    const statusesB = siteB.workers
      .map((w: { status: string }) => w.status)
      .sort();
    expect(statusesB).toEqual(['DONE', 'STARTED']);
    // 시작 작업엔 시각·컨디션
    const started = siteB.workers.find(
      (w: { status: string }) => w.status === 'STARTED',
    );
    expect(started.startedAt).toMatch(/^\d{2}:\d{2}$/);
    expect(started.condition).toBe('OK');
    const done = siteB.workers.find(
      (w: { status: string }) => w.status === 'DONE',
    );
    expect(done.finishedAt).toMatch(/^\d{2}:\d{2}$/);
    // 이름 마스킹
    expect(started.workerName).toBe('박*장');
  });

  it('today-attendance — 권한 격리(outsider 빈·미인증 401)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/today-attendance')
      .set('Authorization', auth(outsider.token))
      .expect(200);
    expect(res.body.data.summary.total).toBe(0);
    expect(res.body.data.sites).toHaveLength(0);
    await request(app.getHttpServer())
      .get('/api/biz/today-attendance')
      .expect(401);
  });
});
