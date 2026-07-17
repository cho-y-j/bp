import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { AppException } from '../common/errors';
import { SmsService } from './sms/sms.service';
import { RefreshTokenService } from './refresh-token.service';

/** 로그인 경로 단위 테스트용 리프레시 서비스 목. issue 만 사용. */
function makeRefreshMock() {
  return {
    issue: jest.fn().mockResolvedValue({
      token: 'refresh-opaque-token',
      expiresAt: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
    }),
    rotate: jest.fn(),
    revoke: jest.fn(),
    revokeAllForProfile: jest.fn(),
    cleanup: jest.fn(),
  } as unknown as RefreshTokenService;
}

/**
 * AuthService 단위 테스트: OTP 만료/시도 제한/쿨다운 + JWT 발급.
 * Prisma/JWT/SMS 는 모두 mock. bcrypt 는 실제 사용.
 */

type OtpRow = {
  id: string;
  phone: string;
  codeHash: string;
  expiresAt: Date;
  attempts: number;
  verified: boolean;
  createdAt: Date;
};

function makeService(overrides: {
  latestOtp?: OtpRow | null;
  profile?: unknown;
}) {
  const prisma = {
    otpCode: {
      findFirst: jest.fn().mockResolvedValue(overrides.latestOtp ?? null),
      create: jest
        .fn()
        .mockImplementation(({ data }: { data: Partial<OtpRow> }) =>
          Promise.resolve({
            id: 'otp-new',
            attempts: 0,
            verified: false,
            createdAt: new Date(),
            ...data,
          }),
        ),
      update: jest.fn().mockResolvedValue({}),
    },
    profile: {
      findUnique: jest.fn().mockResolvedValue(overrides.profile ?? null),
      create: jest.fn().mockResolvedValue({
        id: 'profile-new',
        name: null,
        phone: '01012345678',
        kakaoId: null,
        phoneSearchConsent: false,
        industryTags: [],
        createdAt: new Date(),
        updatedAt: new Date(),
        _count: { ownedBusinesses: 0 },
      }),
    },
  };

  const jwt = { sign: jest.fn().mockReturnValue('signed.jwt.token') };
  const config = {
    get: jest.fn((k: string) => (k === 'NODE_ENV' ? 'development' : undefined)),
  };
  const sms: SmsService = {
    sendVerificationCode: jest.fn().mockResolvedValue(undefined),
  };

  const refreshTokens = makeRefreshMock();
  const service = new AuthService(
    prisma as never,
    jwt as unknown as JwtService,
    config as unknown as ConfigService,
    sms,
    refreshTokens,
  );
  return { service, prisma, jwt, sms, refreshTokens };
}

describe('AuthService', () => {
  describe('requestPhoneCode', () => {
    it('신규 발급 → otp 생성 + dev 환경이면 devCode 반환', async () => {
      const { service, prisma } = makeService({ latestOtp: null });
      const res = await service.requestPhoneCode('010-1234-5678');
      expect(prisma.otpCode.create).toHaveBeenCalledTimes(1);
      expect(res.devCode).toMatch(/^\d{6}$/);
    });

    it('쿨다운(30초) 이내 재요청 → OTP_COOLDOWN', async () => {
      const { service, prisma } = makeService({
        latestOtp: {
          id: 'o1',
          phone: '01012345678',
          codeHash: 'x',
          expiresAt: new Date(Date.now() + 60_000),
          attempts: 0,
          verified: false,
          createdAt: new Date(Date.now() - 5_000), // 5초 전
        },
      });
      await expect(service.requestPhoneCode('01012345678')).rejects.toThrow(
        AppException,
      );
      expect(prisma.otpCode.create).not.toHaveBeenCalled();
    });
  });

  describe('verifyPhoneCode', () => {
    async function otpWith(partial: Partial<OtpRow>): Promise<OtpRow> {
      return {
        id: 'o1',
        phone: '01012345678',
        codeHash: await bcrypt.hash('123456', 10),
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 0,
        verified: false,
        createdAt: new Date(),
        ...partial,
      };
    }

    it('OTP 없음 → OTP_NOT_FOUND', async () => {
      const { service } = makeService({ latestOtp: null });
      await expect(
        service.verifyPhoneCode('01012345678', '123456'),
      ).rejects.toMatchObject({ getResponse: expect.any(Function) });
    });

    it('만료된 OTP → OTP_EXPIRED', async () => {
      const otp = await otpWith({ expiresAt: new Date(Date.now() - 1000) });
      const { service } = makeService({ latestOtp: otp });
      try {
        await service.verifyPhoneCode('01012345678', '123456');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'OTP_EXPIRED',
        });
      }
    });

    it('시도 5회 초과 상태 → OTP_TOO_MANY_ATTEMPTS', async () => {
      const otp = await otpWith({ attempts: 5 });
      const { service } = makeService({ latestOtp: otp });
      try {
        await service.verifyPhoneCode('01012345678', '123456');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'OTP_TOO_MANY_ATTEMPTS',
        });
      }
    });

    it('틀린 코드 → attempts 증가 + OTP_MISMATCH', async () => {
      const otp = await otpWith({ attempts: 0 });
      const { service, prisma } = makeService({ latestOtp: otp });
      try {
        await service.verifyPhoneCode('01012345678', '000000');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'OTP_MISMATCH',
        });
      }
      expect(prisma.otpCode.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { attempts: 1 } }),
      );
    });

    it('네 번째 틀린 코드(attempts=4) → OTP_TOO_MANY_ATTEMPTS 로 차단', async () => {
      const otp = await otpWith({ attempts: 4 });
      const { service } = makeService({ latestOtp: otp });
      try {
        await service.verifyPhoneCode('01012345678', '000000');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'OTP_TOO_MANY_ATTEMPTS',
        });
      }
    });

    it('정답 코드 → 신규 프로필 생성 + JWT 발급', async () => {
      const otp = await otpWith({});
      const { service, prisma, jwt } = makeService({
        latestOtp: otp,
        profile: null,
      });
      const res = await service.verifyPhoneCode('010-1234-5678', '123456');
      expect(prisma.otpCode.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { verified: true } }),
      );
      expect(prisma.profile.create).toHaveBeenCalledTimes(1);
      expect(jwt.sign).toHaveBeenCalledWith(
        { sub: 'profile-new' },
        { expiresIn: '30m' },
      );
      expect(res.accessToken).toBe('signed.jwt.token');
      expect(res.refreshToken).toBe('refresh-opaque-token');
      expect(res.isNew).toBe(true);
      expect(res.profile.name).toBeNull();
    });
  });

  describe('kakaoLogin', () => {
    it('KAKAO_ENABLED 미설정 → 501 NOT_IMPLEMENTED', async () => {
      const { service } = makeService({});
      try {
        await service.kakaoLogin('some-access-token');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getStatus()).toBe(501);
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'NOT_IMPLEMENTED',
        });
      }
    });
  });

  describe('linkKakao (전화 계정에 카카오 연결)', () => {
    const realFetch = global.fetch;
    afterEach(() => {
      global.fetch = realFetch;
      jest.restoreAllMocks();
    });

    const meBase = {
      id: 'u1',
      name: '김기사',
      phone: '01011112222',
      kakaoId: null as string | null,
      phoneSearchConsent: false,
      industryTags: [] as string[],
      bizNumber: null,
      bizName: null,
      bizAddress: null,
      createdAt: new Date(),
      updatedAt: new Date(),
      _count: { ownedBusinesses: 0 },
    };

    function makeLinkService(opts: {
      me: unknown;
      other: unknown;
      enabled: boolean;
    }) {
      const prisma = {
        profile: {
          findUnique: jest
            .fn()
            .mockResolvedValueOnce(opts.me) // me by id
            .mockResolvedValueOnce(opts.other), // other by kakaoId
          update: jest
            .fn()
            .mockImplementation(({ data }: { data: { kakaoId: string } }) =>
              Promise.resolve({ ...(opts.me as object), ...data }),
            ),
        },
      };
      const jwt = { sign: jest.fn().mockReturnValue('t') };
      const config = {
        get: jest.fn((k: string) =>
          k === 'KAKAO_ENABLED'
            ? opts.enabled
              ? 'true'
              : 'false'
            : k === 'NODE_ENV'
              ? 'development'
              : undefined,
        ),
      };
      const sms: SmsService = {
        sendVerificationCode: jest.fn().mockResolvedValue(undefined),
      };
      const service = new AuthService(
        prisma as never,
        jwt as unknown as JwtService,
        config as unknown as ConfigService,
        sms,
        makeRefreshMock(),
      );
      return { service, prisma };
    }

    function mockKakaoFetch(id: number) {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ id }),
      }) as unknown as typeof fetch;
    }

    it('KAKAO_ENABLED=false → 501', async () => {
      const { service } = makeLinkService({
        me: null,
        other: null,
        enabled: false,
      });
      await expect(
        service.linkKakao('u1', 'access-token-123'),
      ).rejects.toMatchObject({ getStatus: expect.any(Function) });
    });

    it('전화 계정에 kakaoId 연결 성공(mock kakao)', async () => {
      mockKakaoFetch(987654321);
      const { service, prisma } = makeLinkService({
        me: { ...meBase, kakaoId: null },
        other: null,
        enabled: true,
      });
      const res = await service.linkKakao('u1', 'access-token-123');
      expect(prisma.profile.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'u1' },
          data: { kakaoId: '987654321' },
        }),
      );
      expect(res.kakaoId).toBe('987654321');
    });

    it('같은 kakaoId 재연결 → 멱등(업데이트 없음)', async () => {
      mockKakaoFetch(987654321);
      const { service, prisma } = makeLinkService({
        me: { ...meBase, kakaoId: '987654321' },
        other: null,
        enabled: true,
      });
      const res = await service.linkKakao('u1', 'access-token-123');
      expect(prisma.profile.update).not.toHaveBeenCalled();
      expect(res.kakaoId).toBe('987654321');
    });

    it('다른 프로필에 이미 연결된 kakaoId → 409 KAKAO_ALREADY_LINKED', async () => {
      mockKakaoFetch(987654321);
      const { service } = makeLinkService({
        me: { ...meBase, kakaoId: null },
        other: { id: 'u2', kakaoId: '987654321' },
        enabled: true,
      });
      try {
        await service.linkKakao('u1', 'access-token-123');
        fail('should throw');
      } catch (e) {
        expect((e as AppException).getStatus()).toBe(409);
        expect((e as AppException).getResponse()).toMatchObject({
          code: 'KAKAO_ALREADY_LINKED',
        });
      }
    });
  });
});
