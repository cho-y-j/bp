import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P2b 표준근로계약서 e2e (임시 postgres):
 *   작성 → 사업장 서명 → send → 외부 서명 → SIGNED → 재서명 409 → PDF 양측 서명
 *   → 권한 격리 → 가입 작업자 지갑("내 계약서") 연결 → 수기 작업자 링크 발급 흐름.
 */
describe('P2b Labor contracts flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const boss = { phone: '010-9111-0001', norm: '01091110001', token: '', name: '사장님' };
  const worker = { phone: '010-9111-0002', norm: '01091110002', token: '', name: '김근로', profileId: '' };
  const outsider = { phone: '010-9111-0003', norm: '01091110003', token: '' };
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

    for (const p of [boss.norm, worker.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }

    boss.token = await signup(boss.phone);
    worker.token = await signup(worker.phone);
    outsider.token = await signup(outsider.phone);

    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${boss.token}`)
      .send({ name: boss.name })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${worker.token}`)
      .send({ name: worker.name, phoneSearchConsent: true })
      .expect(200);

    // 사업장 생성
    const biz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', `Bearer ${boss.token}`)
      .send({ name: '대성건설', businessNumber: '123-45-67890', address: '서울 강남구' })
      .expect(201);
    store.businessId = biz.body.data.id;

    // 가입 작업자 profileId (전화검색 동의)
    const search = await request(app.getHttpServer())
      .get(`/api/workers/search?phone=${worker.phone}`)
      .set('Authorization', `Bearer ${boss.token}`)
      .expect(200);
    worker.profileId = search.body.data.items[0].profileId;
  });

  afterAll(async () => {
    for (const p of [boss.norm, worker.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
      await prisma.otpCode.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  const bossAuth = () => `Bearer ${boss.token}`;
  const workerAuth = () => `Bearer ${worker.token}`;
  const outsiderAuth = () => `Bearer ${outsider.token}`;

  const contractBody = (over: Record<string, unknown> = {}) => ({
    businessId: store.businessId,
    workerProfileId: worker.profileId,
    startDate: '2026-07-10',
    endDate: '2026-07-31',
    workplace: '반포 현장',
    jobDescription: '철근 배근 및 정리',
    workStartTime: '08:00',
    workEndTime: '17:00',
    breakTime: '12:00~13:00 (60분)',
    wageType: 'DAILY',
    wageAmount: 180000,
    payday: '매월 말일',
    payMethod: '근로자 명의 계좌 입금',
    weeklyHolidayAllowance: true,
    overtimeAllowance: true,
    socialInsurance: { employment: true, health: true, pension: true, industrialAccident: true },
    specialTerms: '우천 시 작업 조정',
    ...over,
  });

  it('작성 — 가입 작업자 연결, DRAFT + 사업장 미서명', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/biz/contracts')
      .set('Authorization', bossAuth())
      .send(contractBody())
      .expect(201);
    const c = res.body.data;
    expect(c.status).toBe('DRAFT');
    expect(c.workerLinked).toBe(true);
    expect(c.workerName).toBe('김근로');
    expect(c.employerSigned).toBe(false);
    expect(c.wageTypeLabel).toBe('일급');
    store.contractId = c.id;
    store.token = c.shareToken;
  });

  it('사업장 서명 전 전송 불가 — 409 EMPLOYER_SIGNATURE_REQUIRED', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${store.contractId}/send`)
      .set('Authorization', bossAuth())
      .expect(409);
    expect(res.body.error.code).toBe('EMPLOYER_SIGNATURE_REQUIRED');
  });

  it('사업장(사용자) 서명 → employerSigned true, 상태 유지 DRAFT', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${store.contractId}/sign-employer`)
      .set('Authorization', bossAuth())
      .send({ signerName: '대성건설 대표', signImageBase64: await signPngDataUri() })
      .expect(201);
    expect(res.body.data.employerSigned).toBe(true);
    expect(res.body.data.employerSignerName).toBe('대성건설 대표');
    expect(res.body.data.status).toBe('DRAFT');
  });

  it('사업장 서명 후 수정 불가 — 409 NOT_EDITABLE', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/api/biz/contracts/${store.contractId}`)
      .set('Authorization', bossAuth())
      .send({ workplace: '변경 현장' })
      .expect(409);
    expect(res.body.error.code).toBe('NOT_EDITABLE');
  });

  it('전송 → SENT, 연결 작업자 notified + 알림 생성', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${store.contractId}/send`)
      .set('Authorization', bossAuth())
      .expect(201);
    expect(res.body.data.linked).toBe(true);
    expect(res.body.data.notified).toBe(true);
    expect(res.body.data.url).toContain(`/lc/${store.token}`);

    const notif = await prisma.notification.findFirst({
      where: {
        profileId: worker.profileId,
        data: { path: ['laborContractId'], equals: store.contractId },
      },
    });
    expect(notif).toBeTruthy();
  });

  it('공개 열람 — viewCount 증가 + 정본 필드·미서명(작업자)', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/public/contracts/${store.token}`)
      .expect(200);
    const v = res.body.data;
    expect(v.status).toBe('SENT');
    expect(v.workerSigned).toBe(false);
    expect(v.businessName).toBe('대성건설');
    expect(v.wageAmount).toBe(180000);
    expect(v.employerSignerName).toBe('대성건설 대표');
    expect(v.socialInsurance.employment).toBe(true);
  });

  it('작업자 "내 계약서" 목록에 자동 연결(SENT)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/contracts')
      .set('Authorization', workerAuth())
      .expect(200);
    expect(res.body.data.count).toBe(1);
    expect(res.body.data.items[0].id).toBe(store.contractId);
    expect(res.body.data.items[0].businessName).toBe('대성건설');
  });

  it('외부(작업자) 서명 → SIGNED', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/public/contracts/${store.token}/sign`)
      .send({ signerName: '김근로', signImageBase64: await signPngDataUri() })
      .expect(201);
    expect(res.body.data.status).toBe('SIGNED');
    expect(res.body.data.workerSignerName).toBe('김근로');
  });

  it('재서명 → 409 ALREADY_SIGNED', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/public/contracts/${store.token}/sign`)
      .send({ signerName: '김근로', signImageBase64: await signPngDataUri() })
      .expect(409);
    expect(res.body.error.code).toBe('ALREADY_SIGNED');
  });

  it('서명 후 작업자 "내 계약서" SIGNED + 양측 알림', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/contracts/${store.contractId}`)
      .set('Authorization', workerAuth())
      .expect(200);
    expect(res.body.data.status).toBe('SIGNED');
    expect(res.body.data.workerSigned).toBe(true);
    expect(res.body.data.employerSigned).toBe(true);

    const bossNotif = await prisma.notification.findFirst({
      where: {
        profileId: (await prisma.profile.findUnique({ where: { phone: boss.norm } }))!.id,
        title: '표준근로계약서가 서명되었습니다',
      },
    });
    expect(bossNotif).toBeTruthy();
  });

  it('PDF — 양측 서명 포함 %PDF', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/biz/contracts/${store.contractId}/pdf`)
      .set('Authorization', bossAuth())
      .responseType('blob')
      .expect(200);
    expect(res.headers['content-type']).toContain('application/pdf');
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
    expect(res.body.length).toBeGreaterThan(3000);
  });

  it('작업자도 PDF 열람 가능', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/contracts/${store.contractId}/pdf`)
      .set('Authorization', workerAuth())
      .responseType('blob')
      .expect(200);
    expect(res.body.subarray(0, 5).toString('latin1')).toBe('%PDF-');
  });

  it('권한 격리 — 남(외부인)은 사업장 계약서 조회 불가 404', async () => {
    await request(app.getHttpServer())
      .get(`/api/biz/contracts/${store.contractId}`)
      .set('Authorization', outsiderAuth())
      .expect(404);
  });

  it('권한 격리 — 남의 사업장으로 계약서 작성 불가 404', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/biz/contracts')
      .set('Authorization', outsiderAuth())
      .send(contractBody({ workerProfileId: undefined, workerName: '아무개' }))
      .expect(404);
    expect(res.body.error.code).toBe('BUSINESS_NOT_FOUND');
  });

  it('수기 작업자 계약서 — 링크 발급(linked=false) → 외부 서명', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/biz/contracts')
      .set('Authorization', bossAuth())
      .send(contractBody({ workerProfileId: undefined, workerName: '이수기', workerPhone: '010-3333-4444' }))
      .expect(201);
    const id = created.body.data.id;
    const token = created.body.data.shareToken;
    expect(created.body.data.workerLinked).toBe(false);

    await request(app.getHttpServer())
      .post(`/api/biz/contracts/${id}/sign-employer`)
      .set('Authorization', bossAuth())
      .send({ signerName: '대표', signImageBase64: await signPngDataUri() })
      .expect(201);
    const sent = await request(app.getHttpServer())
      .post(`/api/biz/contracts/${id}/send`)
      .set('Authorization', bossAuth())
      .expect(201);
    expect(sent.body.data.linked).toBe(false);
    expect(sent.body.data.url).toContain(`/lc/${token}`);

    const signed = await request(app.getHttpServer())
      .post(`/api/public/contracts/${token}/sign`)
      .send({ signerName: '이수기', signImageBase64: await signPngDataUri() })
      .expect(201);
    expect(signed.body.data.status).toBe('SIGNED');

    // 수기 작업자는 가입 작업자 목록에 나타나지 않음
    const wlist = await request(app.getHttpServer())
      .get('/api/contracts')
      .set('Authorization', workerAuth())
      .expect(200);
    expect(wlist.body.data.items.find((x: { id: string }) => x.id === id)).toBeUndefined();
  });

  it('DRAFT 삭제 가능 / SIGNED 삭제 불가 409', async () => {
    const draft = await request(app.getHttpServer())
      .post('/api/biz/contracts')
      .set('Authorization', bossAuth())
      .send(contractBody({ workerProfileId: undefined, workerName: '삭제대상' }))
      .expect(201);
    await request(app.getHttpServer())
      .delete(`/api/biz/contracts/${draft.body.data.id}`)
      .set('Authorization', bossAuth())
      .expect(200);
    // SIGNED 는 삭제 불가
    const res = await request(app.getHttpServer())
      .delete(`/api/biz/contracts/${store.contractId}`)
      .set('Authorization', bossAuth())
      .expect(409);
    expect(res.body.error.code).toBe('NOT_DELETABLE');
  });
});
