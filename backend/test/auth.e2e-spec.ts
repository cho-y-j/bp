import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * 인증 흐름 e2e: phone/request → verify → /me.
 * 실제 임시 postgres(DATABASE_URL) 에 마이그레이션이 적용된 상태에서 실행한다.
 * NODE_ENV=development 여야 devCode 를 응답으로 받아 검증할 수 있다.
 */
describe('Auth flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const phone = '010-9999-0001';
  const normalized = '01099990001';

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
    // 클린 상태 보장
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    await prisma.profile.deleteMany({ where: { phone: normalized } });
  });

  afterAll(async () => {
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    await prisma.profile.deleteMany({ where: { phone: normalized } });
    await app.close();
  });

  it('전체 흐름: request → verify → /me (200), 토큰 없으면 401', async () => {
    // 1) 코드 요청 → devCode 수신
    const reqRes = await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone })
      .expect(200);
    expect(reqRes.body.data.sent).toBe(true);
    const devCode: string = reqRes.body.data.devCode;
    expect(devCode).toMatch(/^\d{6}$/);

    // 2) 검증 → JWT + 신규 프로필
    const verifyRes = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone, code: devCode })
      .expect(200);
    const token: string = verifyRes.body.data.accessToken;
    expect(token).toBeTruthy();
    expect(verifyRes.body.data.isNew).toBe(true);
    expect(verifyRes.body.data.profile.name).toBeNull();
    expect(verifyRes.body.data.profile.hasBusiness).toBe(false);

    // 3) 토큰 없이 /me → 401
    const noAuth = await request(app.getHttpServer())
      .get('/api/me')
      .expect(401);
    expect(noAuth.body.error.code).toBe('UNAUTHORIZED');

    // 4) 토큰으로 /me → 200
    const meRes = await request(app.getHttpServer())
      .get('/api/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(meRes.body.data.phone).toBe(normalized);

    // 5) PATCH /me → 이름/동의 갱신
    const patchRes = await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '김작업', phoneSearchConsent: true })
      .expect(200);
    expect(patchRes.body.data.name).toBe('김작업');
    expect(patchRes.body.data.phoneSearchConsent).toBe(true);
  });

  it('잘못된 코드 5회 → 차단(OTP_TOO_MANY_ATTEMPTS)', async () => {
    const blockPhone = '010-9999-0002';
    const blockNorm = '01099990002';
    await prisma.otpCode.deleteMany({ where: { phone: blockNorm } });
    await prisma.profile.deleteMany({ where: { phone: blockNorm } });

    await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone: blockPhone })
      .expect(200);

    // 1~4회: 불일치
    for (let i = 0; i < 4; i++) {
      const r = await request(app.getHttpServer())
        .post('/api/auth/phone/verify')
        .send({ phone: blockPhone, code: '000000' })
        .expect(400);
      expect(r.body.error.code).toBe('OTP_MISMATCH');
    }
    // 5회째: 차단
    const blocked = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone: blockPhone, code: '000000' })
      .expect(429);
    expect(blocked.body.error.code).toBe('OTP_TOO_MANY_ATTEMPTS');

    await prisma.otpCode.deleteMany({ where: { phone: blockNorm } });
    await prisma.profile.deleteMany({ where: { phone: blockNorm } });
  });

  it('카카오 로그인 스텁 → 501', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/kakao')
      .send({ accessToken: 'dummy-access-token' })
      .expect(501);
    expect(res.body.error.code).toBe('NOT_IMPLEMENTED');
  });
});
