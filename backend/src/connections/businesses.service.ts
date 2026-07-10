import { HttpStatus, Injectable } from '@nestjs/common';
import { Business, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { PromotionService } from './promotion.service';
import { CreateBusinessDto } from './dto/create-business.dto';
import { UpdateBusinessDto } from './dto/update-business.dto';

function toBusinessDto(b: Business) {
  return {
    id: b.id,
    name: b.name,
    businessNumber: b.businessNumber,
    inviteCode: b.inviteCode,
    address: b.address,
    lat: b.lat,
    lng: b.lng,
    createdAt: b.createdAt,
  };
}

@Injectable()
export class BusinessesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly promotion: PromotionService,
  ) {}

  // --------------------------------------------------------------------------
  // 생성 — 6자리 초대코드 자동 발급(중복 회피) + 미가입 상대 승격
  // --------------------------------------------------------------------------
  async create(userId: string, dto: CreateBusinessDto) {
    const inviteCode = await this.generateUniqueInviteCode();
    const business = await this.prisma.business.create({
      data: {
        name: dto.name.trim(),
        businessNumber: dto.businessNumber?.trim() || null,
        address: dto.address?.trim() || null,
        lat: dto.lat ?? null,
        lng: dto.lng ?? null,
        inviteCode,
        ownerId: userId,
      },
    });
    // 기존 확인서·장부의 수기 상대(사업주 전화 매칭) → 이 사업장으로 승격
    const promoted = await this.promotion.promoteForBusiness(business.id);
    return { ...toBusinessDto(business), promoted };
  }

  // --------------------------------------------------------------------------
  // 검색 — 상호 부분일치 or 코드 정확일치
  // --------------------------------------------------------------------------
  async search(q: string) {
    const query = (q ?? '').trim();
    if (query.length < 2) {
      throw new AppException(
        'QUERY_TOO_SHORT',
        '검색어는 2자 이상이어야 합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const isCode = /^\d{6}$/.test(query);
    const where: Prisma.BusinessWhereInput = isCode
      ? { OR: [{ inviteCode: query }, { name: { contains: query } }] }
      : { name: { contains: query, mode: 'insensitive' } };

    const rows = await this.prisma.business.findMany({
      where,
      take: 20,
      orderBy: { createdAt: 'desc' },
      include: { owner: { select: { name: true } } },
    });
    // 코드 정확일치는 초대코드도 노출(연결에 필요), 상호검색은 코드 숨김
    return {
      count: rows.length,
      items: rows.map((b) => ({
        id: b.id,
        name: b.name,
        businessNumber: b.businessNumber,
        ownerName: b.owner?.name ?? null,
        matchedByCode: isCode && b.inviteCode === query,
      })),
    };
  }

  async getMine(userId: string) {
    const rows = await this.prisma.business.findMany({
      where: { ownerId: userId },
      orderBy: { createdAt: 'asc' },
    });
    return { count: rows.length, businesses: rows.map(toBusinessDto) };
  }

  async updateMine(userId: string, dto: UpdateBusinessDto) {
    const target = await this.resolveOwned(userId, dto.id);
    const data: Prisma.BusinessUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name.trim();
    if (dto.businessNumber !== undefined)
      data.businessNumber = dto.businessNumber?.trim() || null;
    if (dto.address !== undefined) data.address = dto.address?.trim() || null;
    if (dto.lat !== undefined) data.lat = dto.lat;
    if (dto.lng !== undefined) data.lng = dto.lng;
    const updated = await this.prisma.business.update({
      where: { id: target.id },
      data,
    });
    return toBusinessDto(updated);
  }

  // --------------------------------------------------------------------------
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  private async resolveOwned(userId: string, id?: string): Promise<Business> {
    if (id) {
      const b = await this.prisma.business.findUnique({ where: { id } });
      if (!b || b.ownerId !== userId) {
        throw new AppException(
          'BUSINESS_NOT_FOUND',
          '내 사업장을 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      return b;
    }
    const owned = await this.prisma.business.findMany({
      where: { ownerId: userId },
      orderBy: { createdAt: 'asc' },
    });
    if (owned.length === 0) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        '보유한 사업장이 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (owned.length > 1) {
      throw new AppException(
        'BUSINESS_ID_REQUIRED',
        '사업장이 여러 개입니다. id 를 지정하세요.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return owned[0];
  }

  /** 6자리 숫자 초대코드 생성(중복 회피, 최대 재시도). */
  private async generateUniqueInviteCode(): Promise<string> {
    for (let i = 0; i < 12; i++) {
      const code = String(Math.floor(100000 + Math.random() * 900000));
      const exists = await this.prisma.business.findUnique({
        where: { inviteCode: code },
        select: { id: true },
      });
      if (!exists) return code;
    }
    throw new AppException(
      'INVITE_CODE_EXHAUSTED',
      '초대코드 발급에 실패했습니다. 다시 시도하세요.',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}
