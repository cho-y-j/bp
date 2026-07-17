import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';

/** 리프레시 토큰 슬라이딩 만료: 180일. 발급/회전 시마다 재연장. */
export const REFRESH_TTL_MS = 180 * 24 * 60 * 60 * 1000;
/** 프로필당 활성 리프레시 상한(기기 5대). 초과 시 오래된 것부터 폐기. */
export const MAX_ACTIVE_REFRESH = 5;
/** 폐기된 토큰 보관 기간(정리 크론). 재사용 감사 여유. */
export const REVOKED_RETENTION_MS = 30 * 24 * 60 * 60 * 1000;

export interface IssuedRefresh {
  /** 클라이언트에 1회만 노출되는 불투명 원문 토큰(64자). */
  token: string;
  expiresAt: Date;
}

export interface RotateResult {
  profileId: string;
  refresh: IssuedRefresh;
}

/**
 * 리프레시 토큰 서비스.
 *  - 불투명 랜덤 토큰(hex 64자)의 sha256 해시만 저장(평문 저장 금지).
 *  - 발급 시 프로필당 활성 상한(5) 강제 — 초과분은 오래된 것부터 폐기.
 *  - 회전(rotation): 유효 토큰 검증 → 기존 폐기 + 새 토큰 발급(만료 180일 재연장).
 *  - 재사용 감지: 이미 폐기된 토큰 재사용 시 프로필 전체 폐기(탈취 방어) + 401.
 */
@Injectable()
export class RefreshTokenService {
  private readonly logger = new Logger('RefreshTokenService');

  constructor(private readonly prisma: PrismaService) {}

  /** 불투명 랜덤 토큰(hex 64자) 생성. */
  private generateToken(): string {
    return crypto.randomBytes(32).toString('hex'); // 32바이트 → 64 hex 문자
  }

  /** 원문 토큰 → sha256 해시(hex). 저장·조회 키. */
  static hash(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * 새 리프레시 토큰 발급. 활성 상한(5)을 넘기면 오래된 것부터 폐기한다.
   * 로그인 성공/회전 시 호출.
   */
  async issue(
    profileId: string,
    deviceId?: string,
    now: Date = new Date(),
  ): Promise<IssuedRefresh> {
    await this.enforceActiveCap(profileId, now);

    const token = this.generateToken();
    const tokenHash = RefreshTokenService.hash(token);
    const expiresAt = new Date(now.getTime() + REFRESH_TTL_MS);

    await this.prisma.refreshToken.create({
      data: {
        profileId,
        tokenHash,
        expiresAt,
        deviceId: deviceId ?? null,
      },
    });

    return { token, expiresAt };
  }

  /**
   * 리프레시 회전(rotation).
   *  - 미존재 토큰 → 401 REFRESH_INVALID
   *  - 이미 폐기된 토큰 재사용 → 프로필 전체 폐기 + 401 REFRESH_REUSED
   *  - 만료 토큰 → 401 REFRESH_EXPIRED
   *  - 유효 → 기존 폐기 + 새 토큰 발급(만료 180일 재연장)
   */
  async rotate(
    rawToken: string,
    deviceId?: string,
    now: Date = new Date(),
  ): Promise<RotateResult> {
    const tokenHash = RefreshTokenService.hash(rawToken);
    const record = await this.prisma.refreshToken.findUnique({
      where: { tokenHash },
    });

    if (!record) {
      throw new AppException(
        'REFRESH_INVALID',
        '유효하지 않은 리프레시 토큰입니다.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    // 재사용 감지: 이미 회전(폐기)된 토큰이 다시 제출됨 → 탈취 의심, 프로필 전체 폐기.
    if (record.revokedAt) {
      await this.revokeAllForProfile(record.profileId, now);
      this.logger.warn(
        `리프레시 재사용 감지 → 프로필 전체 폐기 (profileId=${record.profileId})`,
      );
      throw new AppException(
        'REFRESH_REUSED',
        '보안을 위해 모든 세션이 로그아웃되었습니다. 다시 로그인해 주세요.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (record.expiresAt.getTime() < now.getTime()) {
      // 만료 토큰은 폐기 처리(재사용 감지 대상에서 제외).
      await this.prisma.refreshToken.update({
        where: { id: record.id },
        data: { revokedAt: now },
      });
      throw new AppException(
        'REFRESH_EXPIRED',
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    // 회전: 기존 토큰 폐기 + 사용 시각 기록, 새 토큰 발급(슬라이딩 180일).
    await this.prisma.refreshToken.update({
      where: { id: record.id },
      data: { revokedAt: now, lastUsedAt: now },
    });

    const refresh = await this.issue(
      record.profileId,
      deviceId ?? record.deviceId ?? undefined,
      now,
    );
    return { profileId: record.profileId, refresh };
  }

  /**
   * 로그아웃: 해당 리프레시 토큰만 폐기(다른 기기 세션 유지).
   * 토큰이 해당 프로필 소유가 아니면 조용히 무시(멱등).
   */
  async revoke(
    profileId: string,
    rawToken: string,
    now: Date = new Date(),
  ): Promise<boolean> {
    const tokenHash = RefreshTokenService.hash(rawToken);
    const result = await this.prisma.refreshToken.updateMany({
      where: { tokenHash, profileId, revokedAt: null },
      data: { revokedAt: now },
    });
    return result.count > 0;
  }

  /** 프로필 전체 활성 리프레시 폐기(재사용 감지/전체 로그아웃). */
  async revokeAllForProfile(
    profileId: string,
    now: Date = new Date(),
  ): Promise<number> {
    const result = await this.prisma.refreshToken.updateMany({
      where: { profileId, revokedAt: null },
      data: { revokedAt: now },
    });
    return result.count;
  }

  /** 활성 토큰 수가 상한 이상이면 오래된 것부터 폐기해 여유를 만든다. */
  private async enforceActiveCap(profileId: string, now: Date): Promise<void> {
    const active = await this.prisma.refreshToken.findMany({
      where: { profileId, revokedAt: null, expiresAt: { gt: now } },
      orderBy: { createdAt: 'asc' },
      select: { id: true },
    });
    if (active.length < MAX_ACTIVE_REFRESH) return;
    // 새로 1개 추가되므로 활성 수가 상한을 유지하도록 (active - (MAX-1)) 개 폐기.
    const toRevoke = active.slice(0, active.length - (MAX_ACTIVE_REFRESH - 1));
    if (toRevoke.length === 0) return;
    await this.prisma.refreshToken.updateMany({
      where: { id: { in: toRevoke.map((t) => t.id) } },
      data: { revokedAt: now },
    });
  }

  /**
   * 만료·오래 폐기된 토큰 정리. 정리 크론에서 호출.
   * 반환: 삭제된 레코드 수.
   */
  async cleanup(now: Date = new Date()): Promise<number> {
    const revokedCutoff = new Date(now.getTime() - REVOKED_RETENTION_MS);
    const result = await this.prisma.refreshToken.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: now } },
          { revokedAt: { lt: revokedCutoff } },
        ],
      },
    });
    return result.count;
  }
}
