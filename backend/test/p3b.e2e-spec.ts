import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

/**
 * P3b e2e — QR 명함(작업자 공개 프로필).
 *  ① GET /me/card 발급(토큰 lazy 생성) → URL /p/{token}
 *  ② 서류 유효 배지: 만료 등록 0건(무효) → 미래 만료 등록(유효) → 만료 지난 서류(무효)
 *  ③ GET /public/profiles/:token 비노출 필드 검증(전화·계좌·서류 파일 절대 없음)
 *  ④ rotate 후 구 토큰 404
 *  ⑤ cardEnabled=false → 404
 *  ⑥ viewCount 증가
 */
describe('P3b — QR 명함 공개 프로필 (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const phoneW = '010-8888-0601';
  const normW = '01088880601';
  let tokenW: string;
  let cardToken: string;

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

    await prisma.profile.deleteMany({ where: { phone: normW } });
    await prisma.otpCode.deleteMany({ where: { phone: normW } });

    tokenW = await loginAs(phoneW);

    // 프로필: 이름·업종·소개·계좌(비노출 검증용)
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({
        name: '박기사',
        industryTags: ['굴삭기', '토목'],
        cardIntro: '20년 경력 굴삭기 기사입니다',
        payoutBank: '국민은행',
        payoutAccount: '999-88-77777',
        payoutHolder: '박기사',
      })
      .expect(200);

    // 장비 2종(종류만 노출 검증)
    await request(app.getHttpServer())
      .post('/api/equipments')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({ type: '굴삭기', vehicleNumber: '서울12가3456', spec: '06W' })
      .expect(201);
  });

  afterAll(async () => {
    await prisma.profile.deleteMany({ where: { phone: normW } });
    await prisma.otpCode.deleteMany({ where: { phone: normW } });
    await app.close();
  });

  // helper: 프로필에 서류 직접 생성(파일 없이 메타만 — 유효 판정용)
  async function addDoc(type: string, expiryDate: string | null) {
    const me = await prisma.profile.findUnique({ where: { phone: normW } });
    await prisma.document.create({
      data: {
        ownerType: 'PROFILE',
        profileId: me!.id,
        type,
        filePath: 'fake/normalized.pdf',
        expiryDate: expiryDate ? new Date(expiryDate) : null,
      },
    });
  }

  // --------------------------------------------------------------------------
  // ① 발급
  // --------------------------------------------------------------------------
  it('GET /me/card — 토큰 lazy 생성, URL 은 /p/{token}', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/me/card')
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(200);
    expect(typeof res.body.data.token).toBe('string');
    expect(res.body.data.token.length).toBe(32);
    expect(res.body.data.url).toContain(`/p/${res.body.data.token}`);
    expect(res.body.data.enabled).toBe(true);
    expect(res.body.data.preview.name).toBe('박기사');
    expect(res.body.data.preview.equipments).toEqual([{ type: '굴삭기' }]);
    cardToken = res.body.data.token;
  });

  it('GET /me/card 재조회 — 같은 토큰 유지(재생성 안 함)', async () => {
    const res = await request(app.getHttpServer())
      .get('/api/me/card')
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(200);
    expect(res.body.data.token).toBe(cardToken);
  });

  // --------------------------------------------------------------------------
  // ② 서류 유효 배지 판정 (경계)
  // --------------------------------------------------------------------------
  it('서류 유효: 만료일 등록 0건 → valid=false', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(200);
    expect(res.body.data.docValidity.valid).toBe(false);
    expect(res.body.data.docValidity.withExpiryCount).toBe(0);
  });

  it('서류 유효: 미래 만료 서류 1건 → valid=true, 유형명만 노출', async () => {
    await addDoc('건설기계조종사면허', '2027-12-31T00:00:00.000Z');
    const res = await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(200);
    expect(res.body.data.docValidity.valid).toBe(true);
    expect(res.body.data.docValidity.withExpiryCount).toBe(1);
    expect(res.body.data.docValidity.types).toContain('건설기계조종사면허');
  });

  it('서류 유효: 만료 지난 서류가 섞이면 → valid=false', async () => {
    await addDoc('보험증서', '2020-01-01T00:00:00.000Z'); // 지남
    const res = await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(200);
    expect(res.body.data.docValidity.valid).toBe(false);
    // 정리: 만료 지난 서류 제거해 이후 테스트 영향 없게
    const me = await prisma.profile.findUnique({ where: { phone: normW } });
    await prisma.document.deleteMany({
      where: { profileId: me!.id, type: '보험증서' },
    });
  });

  // --------------------------------------------------------------------------
  // ③ 비노출 필드 검증 (전화·계좌·서류 파일 절대 없음)
  // --------------------------------------------------------------------------
  it('공개 프로필 — 전화·계좌·서류 파일 등 민감 필드 절대 비노출', async () => {
    const res = await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(200);
    const body = JSON.stringify(res.body.data);
    // 민감 값이 응답 어디에도 없어야 함
    expect(body).not.toContain('01088880601'); // 전화
    expect(body).not.toContain('010-8888-0601');
    expect(body).not.toContain('999-88-77777'); // 계좌번호
    expect(body).not.toContain('국민은행'); // 은행
    expect(body).not.toContain('normalized.pdf'); // 파일 경로
    expect(body).not.toContain('filePath');
    // 키 자체도 없어야 함
    expect(res.body.data.phone).toBeUndefined();
    expect(res.body.data.payoutAccount).toBeUndefined();
    expect(res.body.data.payoutBank).toBeUndefined();
    // 장비는 종류만(차량번호·규격 없음)
    expect(res.body.data.equipments[0].vehicleNumber).toBeUndefined();
    expect(res.body.data.equipments[0].spec).toBeUndefined();
    expect(res.body.data.equipments).toEqual([{ type: '굴삭기' }]);
    // 노출되어야 하는 것
    expect(res.body.data.name).toBe('박기사');
    expect(res.body.data.industryTags).toEqual(['굴삭기', '토목']);
    expect(res.body.data.intro).toBe('20년 경력 굴삭기 기사입니다');
    expect(res.body.data.connect).toBeDefined();
    expect(res.body.data.joinedAt).toBeDefined();
  });

  // --------------------------------------------------------------------------
  // ⑥ viewCount 증가
  // --------------------------------------------------------------------------
  it('공개 조회 시 viewCount 만 증가(로그 최소화)', async () => {
    const me = await prisma.profile.findUnique({ where: { phone: normW } });
    const before = me!.cardViewCount;
    await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(200);
    const after = await prisma.profile.findUnique({ where: { phone: normW } });
    expect(after!.cardViewCount).toBe(before + 1);
  });

  // --------------------------------------------------------------------------
  // ④ rotate → 구 토큰 404
  // --------------------------------------------------------------------------
  it('POST /me/card/rotate — 새 토큰 발급, 구 토큰은 404', async () => {
    const oldToken = cardToken;
    const res = await request(app.getHttpServer())
      .post('/api/me/card/rotate')
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(201);
    expect(res.body.data.token).not.toBe(oldToken);
    expect(res.body.data.token.length).toBe(32);

    await request(app.getHttpServer())
      .get(`/api/public/profiles/${oldToken}`)
      .expect(404);

    // 새 토큰은 정상
    await request(app.getHttpServer())
      .get(`/api/public/profiles/${res.body.data.token}`)
      .expect(200);
    cardToken = res.body.data.token;
  });

  // --------------------------------------------------------------------------
  // ⑤ cardEnabled=false → 404
  // --------------------------------------------------------------------------
  it('PATCH /me cardEnabled=false → 공개 프로필 404', async () => {
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({ cardEnabled: false })
      .expect(200);

    await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(404);

    // 다시 켜면 200
    await request(app.getHttpServer())
      .patch('/api/me')
      .set('Authorization', `Bearer ${tokenW}`)
      .send({ cardEnabled: true })
      .expect(200);
    await request(app.getHttpServer())
      .get(`/api/public/profiles/${cardToken}`)
      .expect(200);
  });

  it('무효(랜덤) 토큰 → 404', async () => {
    await request(app.getHttpServer())
      .get('/api/public/profiles/nonexistenttoken1234567890abcd')
      .expect(404);
  });

  it('GET /me/card — 본인 전용 서류 상태에 만료 서류 목록 노출', async () => {
    // 만료 지난 서류 추가 → 본인에게만 expiredDocs 로 표시
    await addDoc('만료면허', '2019-01-01T00:00:00.000Z');
    const res = await request(app.getHttpServer())
      .get('/api/me/card')
      .set('Authorization', `Bearer ${tokenW}`)
      .expect(200);
    expect(res.body.data.docStatus.valid).toBe(false);
    const expired = res.body.data.docStatus.expiredDocs as Array<{
      type: string;
      dday: number;
    }>;
    expect(expired.some((d) => d.type === '만료면허' && d.dday < 0)).toBe(true);
  });
});
