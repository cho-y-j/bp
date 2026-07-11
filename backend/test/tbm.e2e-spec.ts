import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P2c 간편 TBM e2e (임시 postgres):
 *   작성(연결+수기 참석자) → 참석자 알림 → ack → 재ack 409 →
 *   당일 후 수정 차단 → 권한 격리 → safety_logs 반영 → 프리셋 CRUD →
 *   사진 업로드/열람 → 리포트 PDF 200.
 */
describe('P2c TBM flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const boss = {
    phone: '010-9221-0001',
    norm: '01092210001',
    token: '',
    name: '박사장',
  };
  const worker = {
    phone: '010-9221-0002',
    norm: '01092210002',
    token: '',
    name: '김근로',
    profileId: '',
  };
  const outsider = {
    phone: '010-9221-0003',
    norm: '01092210003',
    token: '',
    name: '남사장',
  };
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

  async function jpeg(): Promise<Buffer> {
    return sharp({
      create: {
        width: 60,
        height: 40,
        channels: 3,
        background: { r: 20, g: 120, b: 200 },
      },
    })
      .jpeg()
      .toBuffer();
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
    const wp = await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${worker.token}`)
      .send({ name: worker.name, phoneSearchConsent: true })
      .expect(200);
    worker.profileId = wp.body.data.id;
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${outsider.token}`)
      .send({ name: outsider.name })
      .expect(200);

    const biz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', `Bearer ${boss.token}`)
      .send({
        name: '대성건설',
        businessNumber: '123-45-67890',
        address: '서울 강남구',
      })
      .expect(201);
    store.businessId = biz.body.data.id;

    const obiz = await request(app.getHttpServer())
      .post('/api/businesses')
      .set('Authorization', `Bearer ${outsider.token}`)
      .send({ name: '남건설' })
      .expect(201);
    store.outsiderBusinessId = obiz.body.data.id;
  });

  afterAll(async () => {
    for (const p of [boss.norm, worker.norm, outsider.norm]) {
      await prisma.profile.deleteMany({ where: { phone: p } });
    }
    await app.close();
  });

  const auth = (t: string) => ({ Authorization: `Bearer ${t}` });

  it('TBM 프리셋 CRUD (HAZARD/MEASURE)', async () => {
    const p = await request(app.getHttpServer())
      .post('/api/biz/tbm/presets')
      .set(auth(boss.token))
      .send({
        businessId: store.businessId,
        kind: 'HAZARD',
        text: '개구부 덮개 미설치',
      })
      .expect(201);
    expect(p.body.data.kind).toBe('HAZARD');
    store.presetId = p.body.data.id;

    const list = await request(app.getHttpServer())
      .get('/api/biz/tbm/presets')
      .query({ businessId: store.businessId })
      .set(auth(boss.token))
      .expect(200);
    expect(list.body.data.count).toBe(1);

    // 권한 격리: 남이 남의 사업장 프리셋 조회 404
    await request(app.getHttpServer())
      .get('/api/biz/tbm/presets')
      .query({ businessId: store.businessId })
      .set(auth(outsider.token))
      .expect(404);
  });

  it('TBM 작성(연결+수기 참석자) → 참석자 알림 + safety_log 기록', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/biz/tbm')
      .set(auth(boss.token))
      .send({
        businessId: store.businessId,
        site: '강남 현장 3층',
        date: '2026-07-11',
        time: '08:30',
        hazards: [
          { code: 'FALL_HEIGHT' },
          { code: 'HEAVY_EQUIP' },
          { text: '자재 정리불량' },
        ],
        measures: '안전벨트 착용, 유도원 배치',
        notes: '오전 집중 우천 예보',
        attendees: [{ profileId: worker.profileId }, { name: '이수기' }],
      })
      .expect(201);
    expect(res.body.data.attendeeCount).toBe(2);
    expect(res.body.data.ackCount).toBe(0);
    expect(res.body.data.editable).toBe(true);
    expect(res.body.data.hazardLabelsKo).toContain('고소작업 추락');
    store.recordId = res.body.data.id;
    const linked = res.body.data.attendees.find(
      (a: { linked: boolean }) => a.linked,
    );
    store.attendeeId = linked.id;

    // 가입 참석자 알림 TBM 생성 확인
    const notis = await request(app.getHttpServer())
      .get('/api/notifications')
      .set(auth(worker.token))
      .expect(200);
    const tbmNoti = notis.body.data.items.find(
      (n: { type: string }) => n.type === 'TBM',
    );
    expect(tbmNoti).toBeTruthy();
    expect(tbmNoti.data.tbmAttendeeId).toBe(store.attendeeId);

    // safety_log TBM_RECORD append (작성자 대상)
    const logs = await prisma.safetyLog.findMany({
      where: { businessId: store.businessId, type: 'TBM' },
    });
    expect(logs.length).toBe(1);
    expect((logs[0].payload as { kind: string }).kind).toBe('TBM_RECORD');
  });

  it('작업자 "받은 TBM" 목록에 노출(내 안전 기록)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/tbm')
      .set(auth(worker.token))
      .expect(200);
    expect(res.body.data.count).toBe(1);
    expect(res.body.data.items[0].attendeeId).toBe(store.attendeeId);
    expect(res.body.data.items[0].acked).toBe(false);
    // 위험요인 키 기반(작업자 자기 언어 렌더용)
    expect(res.body.data.items[0].record.hazards[0].code).toBe('FALL_HEIGHT');
    expect(res.body.data.items[0].record.photoUrls).toBeDefined();
  });

  it('참석자 ack → safety_log 확인 append', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/tbm/${store.attendeeId}/ack`)
      .set(auth(worker.token))
      .expect(201);
    expect(res.body.data.acked).toBe(true);

    const ackLogs = await prisma.safetyLog.findMany({
      where: {
        businessId: store.businessId,
        type: 'TBM',
        targetProfileId: worker.profileId,
      },
    });
    expect(ackLogs.length).toBe(1);
    expect(ackLogs[0].ackAt).not.toBeNull();
    expect((ackLogs[0].payload as { kind: string }).kind).toBe('TBM_ACK');

    // 상세 ackCount 반영
    const detail = await request(app.getHttpServer())
      .get(`/api/biz/tbm/${store.recordId}`)
      .set(auth(boss.token))
      .expect(200);
    expect(detail.body.data.ackCount).toBe(1);
  });

  it('재ack 409 (ALREADY_ACKED)', async () => {
    const res = await request(app.getHttpServer())
      .post(`/api/tbm/${store.attendeeId}/ack`)
      .set(auth(worker.token))
      .expect(409);
    expect(res.body.error.code).toBe('ALREADY_ACKED');
  });

  it('권한 격리: 남이 남의 TBM 상세/수정/삭제/ack 404', async () => {
    await request(app.getHttpServer())
      .get(`/api/biz/tbm/${store.recordId}`)
      .set(auth(outsider.token))
      .expect(404);
    await request(app.getHttpServer())
      .patch(`/api/biz/tbm/${store.recordId}`)
      .set(auth(outsider.token))
      .send({ site: '해킹' })
      .expect(404);
    // 남이 남의 참석자 ack 404
    await request(app.getHttpServer())
      .post(`/api/tbm/${store.attendeeId}/ack`)
      .set(auth(outsider.token))
      .expect(404);
    // outsider "받은 TBM" 비어있음
    const empty = await request(app.getHttpServer())
      .get('/api/tbm')
      .set(auth(outsider.token))
      .expect(200);
    expect(empty.body.data.count).toBe(0);
  });

  it('사진 업로드 → 사업장/참석자 열람', async () => {
    const buf = await jpeg();
    const up = await request(app.getHttpServer())
      .post(`/api/biz/tbm/${store.recordId}/photos`)
      .set(auth(boss.token))
      .attach('files', buf, { filename: 'site.jpg', contentType: 'image/jpeg' })
      .expect(201);
    expect(up.body.data.uploaded).toBe(1);
    expect(up.body.data.photoCount).toBe(1);

    // 사업장 소유자 열람
    await request(app.getHttpServer())
      .get(`/api/biz/tbm/${store.recordId}/photos/0`)
      .set(auth(boss.token))
      .expect(200)
      .expect('Content-Type', /image\/jpeg/);
    // 참석 작업자 열람
    await request(app.getHttpServer())
      .get(`/api/tbm/${store.recordId}/photos/0`)
      .set(auth(worker.token))
      .expect(200);
    // 남은 열람 404
    await request(app.getHttpServer())
      .get(`/api/tbm/${store.recordId}/photos/0`)
      .set(auth(outsider.token))
      .expect(404);
  });

  it('당일 수정 허용 → 당일 후(어제 작성) 수정/삭제 차단 409', async () => {
    // 당일 수정 OK
    const patched = await request(app.getHttpServer())
      .patch(`/api/biz/tbm/${store.recordId}`)
      .set(auth(boss.token))
      .send({ measures: '안전벨트 착용, 유도원 배치, 신호수 추가' })
      .expect(200);
    expect(patched.body.data.measures).toContain('신호수');

    // createdAt 을 이틀 전으로 밀어 "당일 후" 재현
    await prisma.tbmRecord.update({
      where: { id: store.recordId },
      data: { createdAt: new Date(Date.now() - 2 * 24 * 3600 * 1000) },
    });
    const blocked = await request(app.getHttpServer())
      .patch(`/api/biz/tbm/${store.recordId}`)
      .set(auth(boss.token))
      .send({ site: '수정시도' })
      .expect(409);
    expect(blocked.body.error.code).toBe('NOT_EDITABLE');

    const delBlocked = await request(app.getHttpServer())
      .delete(`/api/biz/tbm/${store.recordId}`)
      .set(auth(boss.token))
      .expect(409);
    expect(delBlocked.body.error.code).toBe('NOT_DELETABLE');
  });

  it('안전 리포트 PDF 200 (TBM 집계 포함)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/biz/safety-report')
      .query({ month: '2026-07' })
      .set(auth(boss.token))
      .buffer()
      .parse((r, cb) => {
        const chunks: Buffer[] = [];
        r.on('data', (c: Buffer) => chunks.push(c));
        r.on('end', () => cb(null, Buffer.concat(chunks)));
      })
      .expect(200);
    expect(res.headers['content-type']).toMatch(/application\/pdf/);
    expect((res.body as Buffer).length).toBeGreaterThan(1000);
  });
});
