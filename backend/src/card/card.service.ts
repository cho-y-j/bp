import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { nanoid } from 'nanoid';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { computeDday } from '../common/dday.util';
import {
  computeDocValidity,
  DocForValidity,
  DocValiditySummary,
} from './card.util';

const TOKEN_LENGTH = 32;

type CardProfile = {
  id: string;
  name: string | null;
  industryTags: string[];
  cardToken: string | null;
  cardEnabled: boolean;
  cardIntro: string | null;
  cardViewCount: number;
  createdAt: Date;
};

/**
 * QR 명함(작업자 공개 프로필) 서비스. P3b.
 *  - GET /me/card, POST /me/card/rotate 는 인증 사용자(본인).
 *  - GET /public/profiles/:token 는 @Public — 비노출 필드(전화·계좌·서류 파일) 절대 미포함.
 */
@Injectable()
export class CardService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  private baseUrl(): string {
    return (
      this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:3001'
    ).replace(/\/$/, '');
  }

  private cardUrl(token: string): string {
    return `${this.baseUrl()}/p/${token}`;
  }

  /** 앱 설치 유도 링크(비로그인 방문자용). env 없으면 자리표시 값. */
  private connectInfo() {
    return {
      // 비로그인 방문자는 계정이 없으므로: 앱에서 전화번호로 검색하도록 안내.
      message:
        '이 작업자와 연결하려면 작업온 앱에서 전화번호로 검색해 연결 요청을 보내세요.',
      appDeepLink:
        this.config.get<string>('APP_DEEP_LINK') ?? 'workon://connect',
      storeLinks: {
        ios:
          this.config.get<string>('APP_STORE_URL_IOS') ??
          'https://apps.apple.com/app/id0000000000',
        android:
          this.config.get<string>('APP_STORE_URL_ANDROID') ??
          'https://play.google.com/store/apps/details?id=kr.workon',
      },
    };
  }

  // --------------------------------------------------------------------------
  // GET /me/card — 내 QR 명함(토큰 lazy 생성) + 본인용 미리보기·서류 상태
  // --------------------------------------------------------------------------
  async getMyCard(userId: string) {
    let profile = await this.loadProfile(userId);

    // 온보딩 후 최초 조회 시 토큰 생성 (유일성 충돌 시 재시도).
    if (!profile.cardToken) {
      profile = await this.ensureToken(userId);
    }
    const token = profile.cardToken as string;

    const docs = await this.loadDocs(userId);
    const equipTypes = await this.loadEquipmentTypes(userId);
    const now = new Date();
    const validity = computeDocValidity(docs, now);

    // 본인에게만: 어떤 서류가 만료되어 문제인지 표시.
    const expiredDocs = docs
      .filter((d) => d.status !== 'ARCHIVED' && d.expiryDate != null)
      .map((d) => ({
        type: d.type,
        expiryDate: d.expiryDate,
        dday: computeDday(d.expiryDate as Date, now),
      }))
      .filter((d) => d.dday < 0);

    return {
      token,
      url: this.cardUrl(token),
      enabled: profile.cardEnabled,
      intro: profile.cardIntro,
      viewCount: profile.cardViewCount,
      // 공개 미리보기(방문자가 보는 것과 동일)
      preview: this.buildPublicProfile(profile, validity, equipTypes),
      // 본인 전용 서류 상태(만료 서류 목록은 본인에게만)
      docStatus: {
        valid: validity.valid,
        withExpiryCount: validity.withExpiryCount,
        totalCount: validity.totalCount,
        types: validity.types,
        expiredDocs, // 본인 전용: 문제 서류(유형·만료일·D-day)
      },
    };
  }

  // --------------------------------------------------------------------------
  // POST /me/card/rotate — 토큰 재발급(유출 대비). 구 토큰 즉시 무효화.
  // --------------------------------------------------------------------------
  async rotate(userId: string) {
    await this.loadProfile(userId);
    const profile = await this.ensureToken(userId, true);
    const token = profile.cardToken as string;
    return {
      token,
      url: this.cardUrl(token),
      enabled: profile.cardEnabled,
    };
  }

  // --------------------------------------------------------------------------
  // GET /public/profiles/:token — @Public. 민감정보 절대 비노출.
  // --------------------------------------------------------------------------
  async publicView(token: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { cardToken: token },
    });
    // 무효 토큰 · 명함 OFF → 404 (존재 여부도 숨김)
    if (!profile || !profile.cardEnabled) {
      throw new AppException(
        'PROFILE_CARD_NOT_FOUND',
        '공개 명함을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }

    const docs = await this.loadDocs(profile.id);
    const equipTypes = await this.loadEquipmentTypes(profile.id);
    const now = new Date();
    const validity = computeDocValidity(docs, now);

    // 조회수만 기록(로그 최소화 — IP/UA 등 저장 안 함).
    await this.prisma.profile.update({
      where: { id: profile.id },
      data: { cardViewCount: { increment: 1 } },
    });

    return this.buildPublicProfile(profile, validity, equipTypes);
  }

  // --------------------------------------------------------------------------
  // 내부
  // --------------------------------------------------------------------------
  private buildPublicProfile(
    profile: CardProfile,
    validity: DocValiditySummary,
    equipTypes: string[],
  ) {
    return {
      name: profile.name ?? '작업자',
      industryTags: profile.industryTags,
      intro: profile.cardIntro,
      // 서류 유효 배지 — 파일·상세·발급일 절대 비노출. 개수·유형명만.
      docValidity: {
        valid: validity.valid,
        count: validity.totalCount,
        withExpiryCount: validity.withExpiryCount,
        types: validity.types,
      },
      // 장비: 종류(type)만. 차량번호·규격 비노출.
      equipments: equipTypes.map((type) => ({ type })),
      joinedAt: profile.createdAt,
      connect: this.connectInfo(),
    };
  }

  private async loadProfile(userId: string): Promise<CardProfile> {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        industryTags: true,
        cardToken: true,
        cardEnabled: true,
        cardIntro: true,
        cardViewCount: true,
        createdAt: true,
      },
    });
    if (!profile) {
      throw new AppException(
        'PROFILE_NOT_FOUND',
        '프로필을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return profile;
  }

  private async loadDocs(profileId: string): Promise<DocForValidity[]> {
    return this.prisma.document.findMany({
      where: { profileId },
      select: { type: true, expiryDate: true, status: true },
    });
  }

  /** 장비 종류만(중복 제거·정렬). 차량번호·규격 등은 로딩하지 않는다. */
  private async loadEquipmentTypes(profileId: string): Promise<string[]> {
    const rows = await this.prisma.equipment.findMany({
      where: { profileId },
      select: { type: true },
    });
    return Array.from(new Set(rows.map((r) => r.type))).sort();
  }

  /** 토큰 생성/재발급(유일성 보장, 충돌 시 재시도). */
  private async ensureToken(
    userId: string,
    force = false,
  ): Promise<CardProfile> {
    for (let attempt = 0; attempt < 5; attempt++) {
      const token = nanoid(TOKEN_LENGTH);
      try {
        return await this.prisma.profile.update({
          where: { id: userId },
          data: { cardToken: token },
          select: {
            id: true,
            name: true,
            industryTags: true,
            cardToken: true,
            cardEnabled: true,
            cardIntro: true,
            cardViewCount: true,
            createdAt: true,
          },
        });
      } catch (e: unknown) {
        // unique 충돌(P2002)이면 다른 토큰으로 재시도
        if (
          typeof e === 'object' &&
          e !== null &&
          (e as { code?: string }).code === 'P2002'
        ) {
          if (!force) {
            // 동시 생성됐을 수 있음 → 최신 토큰 재조회
            const fresh = await this.loadProfile(userId);
            if (fresh.cardToken) return fresh;
          }
          continue;
        }
        throw e;
      }
    }
    throw new AppException(
      'CARD_TOKEN_GENERATION_FAILED',
      '명함 토큰 생성에 실패했습니다. 다시 시도해 주세요.',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}
