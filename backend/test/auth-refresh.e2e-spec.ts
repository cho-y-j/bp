import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * 리프레시 토큰 기반 자동 로그인 연장 e2e.
 * 시나리오: 로그인 → 액세스 만료 시뮬 → refresh → 새 토큰으로 /me 200
 *          → 구 리프레시 재사용 → 전체 폐기 401 → logout 후 refresh 401.
 * 실제 임시 postgres(DATABASE_URL) 에 마이그레이션 적용된 상태에서 실행.
 */
describe('Refresh token flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwt: JwtService;
  const phone = '010-9999-0101';
  const normalized = '01099990101';

  async function login(): Promise<{
    accessToken: string;
    refreshToken: string;
    profileId: string;
  }> {
    // OTP 쿨다운(30초) 회피: 직전 코드 제거 후 새로 요청
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    const reqRes = await request(app.getHttpServer())
      .post('/api/auth/phone/request')
      .send({ phone })
      .expect(200);
    const devCode: string = reqRes.body.data.devCode;
    const verifyRes = await request(app.getHttpServer())
      .post('/api/auth/phone/verify')
      .send({ phone, code: devCode, deviceId: 'e2e-device' })
      .expect(200);
    return {
      accessToken: verifyRes.body.data.accessToken,
      refreshToken: verifyRes.body.data.refreshToken,
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
    jwt = app.get(JwtService);
    await prisma.profile.deleteMany({ where: { phone: normalized } });
  });

  afterAll(async () => {
    await prisma.profile.deleteMany({ where: { phone: normalized } });
    await app.close();
  });

  afterEach(async () => {
    // 각 테스트 사이 세션 초기화(같은 전화번호 재사용)
    await prisma.otpCode.deleteMany({ where: { phone: normalized } });
    await prisma.profile.deleteMany({ where: { phone: normalized } });
  });

  it('verify 응답에 accessToken + refreshToken 동시 발급', async () => {
    const { accessToken, refreshToken } = await login();
    expect(accessToken).toBeTruthy();
    expect(refreshToken).toMatch(/^[0-9a-f]{64}$/);
  });

  it('액세스 만료 → refresh → 회전된 새 토큰으로 /me 200', async () => {
    const { refreshToken, profileId } = await login();

    // 액세스 강제 만료(이미 만료된 토큰 서명)
    const expiredAccess = jwt.sign(
      { sub: profileId },
      { expiresIn: -10 } as { expiresIn: number },
    );
    const expired = await request(app.getHttpServer())
      .get('/api/me')
      .set('Authorization', `Bearer ${expiredAccess}`)
      .expect(401);
    expect(expired.body.error.code).toBe('UNAUTHORIZED');

    // refresh → 새 액세스 + 회전된 새 리프레시
    const refreshed = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(200);
    const newAccess: string = refreshed.body.data.accessToken;
    const newRefresh: string = refreshed.body.data.refreshToken;
    expect(newAccess).toBeTruthy();
    expect(newRefresh).toMatch(/^[0-9a-f]{64}$/);
    expect(newRefresh).not.toBe(refreshToken); // 회전됨

    // 새 액세스로 /me 200
    const me = await request(app.getHttpServer())
      .get('/api/me')
      .set('Authorization', `Bearer ${newAccess}`)
      .expect(200);
    expect(me.body.data.phone).toBe(normalized);
  });

  it('구 리프레시 재사용 → 전체 폐기 + 401 REFRESH_REUSED, 이후 새 토큰도 무효', async () => {
    const { refreshToken } = await login();

    // 1차 회전
    const r1 = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(200);
    const newRefresh: string = r1.body.data.refreshToken;

    // 구(이미 회전된) 리프레시 재사용 → 재사용 감지
    const reuse = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(401);
    expect(reuse.body.error.code).toBe('REFRESH_REUSED');

    // 재사용 감지로 프로필 전체 폐기 → 방금 발급된 새 토큰도 무효
    const afterWipe = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken: newRefresh })
      .expect(401);
    expect(afterWipe.body.error.code).toBe('REFRESH_REUSED');
  });

  it('logout → 해당 리프레시 폐기 → 이후 refresh 401', async () => {
    const { accessToken, refreshToken } = await login();

    const out = await request(app.getHttpServer())
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ refreshToken })
      .expect(200);
    expect(out.body.data.revoked).toBe(true);

    const afterLogout = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken })
      .expect(401);
    // 폐기된 토큰 재사용 → 재사용 감지 경로(401)
    expect(afterLogout.body.error.code).toBe('REFRESH_REUSED');
  });

  it('잘못된 리프레시 토큰 → 401 REFRESH_INVALID', async () => {
    const res = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken: 'f'.repeat(64) })
      .expect(401);
    expect(res.body.error.code).toBe('REFRESH_INVALID');
  });
});
