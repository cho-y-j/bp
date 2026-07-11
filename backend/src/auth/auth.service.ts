import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import {
  profileCountInclude,
  toProfileDto,
  ProfileDto,
} from '../users/profile.mapper';
import { SMS_SERVICE, SmsService } from './sms/sms.service';

const OTP_TTL_MS = 3 * 60 * 1000; // 만료 3분
const OTP_COOLDOWN_MS = 30 * 1000; // 재요청 쿨다운 30초
const OTP_MAX_ATTEMPTS = 5; // 검증 시도 5회 제한
const BCRYPT_ROUNDS = 10;

export interface AuthResult {
  accessToken: string;
  isNew: boolean;
  profile: ProfileDto;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger('AuthService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    @Inject(SMS_SERVICE) private readonly sms: SmsService,
  ) {}

  private isDev(): boolean {
    return (
      (this.config.get<string>('NODE_ENV') ?? 'development') !== 'production'
    );
  }

  /** 하이픈/공백 제거 → 저장·조회 키 정규화. */
  private normalizePhone(phone: string): string {
    return phone.replace(/[^0-9]/g, '');
  }

  private generateCode(): string {
    // 6자리, 앞자리 0 허용
    return Math.floor(Math.random() * 1_000_000)
      .toString()
      .padStart(6, '0');
  }

  private signToken(profileId: string): string {
    return this.jwt.sign({ sub: profileId });
  }

  // --------------------------------------------------------------------------
  // POST /auth/phone/request
  // --------------------------------------------------------------------------
  async requestPhoneCode(rawPhone: string): Promise<{ devCode?: string }> {
    const phone = this.normalizePhone(rawPhone);

    // 쿨다운: 가장 최근 발급이 30초 이내면 거부
    const recent = await this.prisma.otpCode.findFirst({
      where: { phone },
      orderBy: { createdAt: 'desc' },
    });
    if (recent) {
      const elapsed = Date.now() - recent.createdAt.getTime();
      if (elapsed < OTP_COOLDOWN_MS) {
        const wait = Math.ceil((OTP_COOLDOWN_MS - elapsed) / 1000);
        throw new AppException(
          'OTP_COOLDOWN',
          `${wait}초 후에 다시 요청할 수 있습니다.`,
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }

    const code = this.generateCode();
    const codeHash = await bcrypt.hash(code, BCRYPT_ROUNDS);
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);

    await this.prisma.otpCode.create({
      data: { phone, codeHash, expiresAt },
    });

    await this.sms.sendVerificationCode(phone, code);

    // dev 환경에서만 응답으로 코드 노출
    return this.isDev() ? { devCode: code } : {};
  }

  // --------------------------------------------------------------------------
  // POST /auth/phone/verify
  // --------------------------------------------------------------------------
  async verifyPhoneCode(rawPhone: string, code: string): Promise<AuthResult> {
    const phone = this.normalizePhone(rawPhone);

    // 가장 최근의 미검증 OTP 사용
    const otp = await this.prisma.otpCode.findFirst({
      where: { phone, verified: false },
      orderBy: { createdAt: 'desc' },
    });

    if (!otp) {
      throw new AppException(
        'OTP_NOT_FOUND',
        '인증코드를 먼저 요청해 주세요.',
        HttpStatus.BAD_REQUEST,
      );
    }

    if (otp.attempts >= OTP_MAX_ATTEMPTS) {
      throw new AppException(
        'OTP_TOO_MANY_ATTEMPTS',
        '인증 시도 횟수를 초과했습니다. 코드를 다시 요청해 주세요.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    if (otp.expiresAt.getTime() < Date.now()) {
      throw new AppException(
        'OTP_EXPIRED',
        '인증코드가 만료되었습니다. 다시 요청해 주세요.',
        HttpStatus.BAD_REQUEST,
      );
    }

    const matches = await bcrypt.compare(code, otp.codeHash);
    if (!matches) {
      const attempts = otp.attempts + 1;
      await this.prisma.otpCode.update({
        where: { id: otp.id },
        data: { attempts },
      });
      if (attempts >= OTP_MAX_ATTEMPTS) {
        throw new AppException(
          'OTP_TOO_MANY_ATTEMPTS',
          '인증 시도 횟수를 초과했습니다. 코드를 다시 요청해 주세요.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      const remaining = OTP_MAX_ATTEMPTS - attempts;
      throw new AppException(
        'OTP_MISMATCH',
        `인증코드가 일치하지 않습니다. (남은 시도 ${remaining}회)`,
        HttpStatus.BAD_REQUEST,
      );
    }

    // 검증 성공: OTP 소진 처리
    await this.prisma.otpCode.update({
      where: { id: otp.id },
      data: { verified: true },
    });

    // 기존 프로필이면 로그인, 없으면 가입 (이름은 온보딩에서 채움 → null)
    let profile = await this.prisma.profile.findUnique({
      where: { phone },
      include: profileCountInclude,
    });
    let isNew = false;
    if (!profile) {
      profile = await this.prisma.profile.create({
        data: { phone },
        include: profileCountInclude,
      });
      isNew = true;
    }

    return {
      accessToken: this.signToken(profile.id),
      isNew,
      profile: toProfileDto(profile),
    };
  }

  // --------------------------------------------------------------------------
  // POST /auth/kakao — 키 없으면 501 스텁, 있으면 실제 호출
  // --------------------------------------------------------------------------
  async kakaoLogin(accessToken: string): Promise<AuthResult> {
    if (!this.kakaoEnabled()) {
      throw new AppException(
        'NOT_IMPLEMENTED',
        '카카오 로그인은 아직 활성화되지 않았습니다.',
        HttpStatus.NOT_IMPLEMENTED,
      );
    }

    const kakaoId = await this.fetchKakaoId(accessToken);

    let profile = await this.prisma.profile.findUnique({
      where: { kakaoId },
      include: profileCountInclude,
    });
    let isNew = false;
    if (!profile) {
      // 카카오 가입: 전화번호는 카카오만으로 확보 불가 → 온보딩에서 전화 인증으로 보강.
      // 임시 placeholder 전화번호(고유)로 생성한다.
      profile = await this.prisma.profile.create({
        data: { kakaoId, phone: `kakao:${kakaoId}` },
        include: profileCountInclude,
      });
      isNew = true;
    }

    return {
      accessToken: this.signToken(profile.id),
      isNew,
      profile: toProfileDto(profile),
    };
  }

  private kakaoEnabled(): boolean {
    return (
      (this.config.get<string>('KAKAO_ENABLED') ?? 'false').toLowerCase() ===
      'true'
    );
  }

  // --------------------------------------------------------------------------
  // POST /auth/kakao/link — 로그인 상태에서 카카오 계정 연결
  //  - 기존 전화 인증 계정에 kakaoId 를 연결한다(이후 카카오로도 로그인 가능).
  // --------------------------------------------------------------------------
  async linkKakao(userId: string, accessToken: string): Promise<ProfileDto> {
    if (!this.kakaoEnabled()) {
      throw new AppException(
        'NOT_IMPLEMENTED',
        '카카오 로그인은 아직 활성화되지 않았습니다.',
        HttpStatus.NOT_IMPLEMENTED,
      );
    }
    const kakaoId = await this.fetchKakaoId(accessToken);

    const me = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: profileCountInclude,
    });
    if (!me) {
      throw new AppException(
        'PROFILE_NOT_FOUND',
        '프로필을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    // 이미 같은 kakaoId 로 연결돼 있으면 멱등 처리.
    if (me.kakaoId === kakaoId) {
      return toProfileDto(me);
    }
    // 내 계정이 이미 다른 카카오에 연결돼 있으면 거부.
    if (me.kakaoId && me.kakaoId !== kakaoId) {
      throw new AppException(
        'KAKAO_ALREADY_LINKED',
        '이미 다른 카카오 계정이 연결되어 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    // 이 kakaoId 가 이미 다른 프로필에 연결돼 있으면 거부.
    const other = await this.prisma.profile.findUnique({ where: { kakaoId } });
    if (other && other.id !== userId) {
      throw new AppException(
        'KAKAO_ALREADY_LINKED',
        '이 카카오 계정은 이미 다른 사용자에 연결되어 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.prisma.profile.update({
      where: { id: userId },
      data: { kakaoId },
      include: profileCountInclude,
    });
    return toProfileDto(updated);
  }

  /** kapi.kakao.com/v2/user/me 호출 → 카카오 사용자 id 반환. 실패 시 501. */
  private async fetchKakaoId(accessToken: string): Promise<string> {
    try {
      const res = await fetch('https://kapi.kakao.com/v2/user/me', {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        },
      });
      if (!res.ok) {
        this.logger.warn(`카카오 API 응답 오류: ${res.status}`);
        throw new Error(`kakao api ${res.status}`);
      }
      const body = (await res.json()) as { id?: number | string };
      if (body.id === undefined || body.id === null) {
        throw new Error('kakao id 없음');
      }
      return String(body.id);
    } catch (e) {
      this.logger.warn(`카카오 로그인 실패: ${(e as Error).message}`);
      throw new AppException(
        'NOT_IMPLEMENTED',
        '카카오 인증에 실패했습니다.',
        HttpStatus.NOT_IMPLEMENTED,
      );
    }
  }
}
