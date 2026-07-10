import { HttpStatus, Injectable } from '@nestjs/common';
import {
  ConnectionPath,
  ConnectionStatus,
  NotificationType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { NotificationsService } from '../notifications/notifications.service';
import { normalizePhone, maskName } from '../common/phone.util';
import { PromotionService } from './promotion.service';
import { CreateConnectionDto } from './dto/create-connection.dto';

@Injectable()
export class ConnectionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly promotion: PromotionService,
  ) {}

  // --------------------------------------------------------------------------
  // 작업자 전화 검색 — phoneSearchConsent=true 인 프로필만, 이름 마스킹
  // --------------------------------------------------------------------------
  async searchWorkers(phone: string) {
    const normalized = normalizePhone(phone);
    if (normalized.length < 8) {
      throw new AppException(
        'INVALID_PHONE',
        '검색할 전화번호를 정확히 입력하세요.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const rows = await this.prisma.profile.findMany({
      where: { phone: normalized, phoneSearchConsent: true },
      select: { id: true, name: true, industryTags: true },
    });
    return {
      count: rows.length,
      items: rows.map((p) => ({
        profileId: p.id,
        maskedName: maskName(p.name),
        industryTags: p.industryTags,
      })),
    };
  }

  // --------------------------------------------------------------------------
  // 연결 요청 — 사업장→작업자 or 작업자→사업장
  // --------------------------------------------------------------------------
  async request(userId: string, dto: CreateConnectionDto) {
    const business = await this.prisma.business.findUnique({
      where: { id: dto.businessId },
      select: { id: true, ownerId: true, name: true },
    });
    if (!business) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        '사업장을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }

    let workerProfileId: string;
    let path: ConnectionPath;
    if (dto.workerProfileId) {
      // 사업장 → 작업자 (요청자는 사업장 소유자여야 함)
      if (business.ownerId !== userId) {
        throw new AppException(
          'FORBIDDEN',
          '해당 사업장의 소유자만 작업자에게 연결을 요청할 수 있습니다.',
          HttpStatus.FORBIDDEN,
        );
      }
      const worker = await this.prisma.profile.findUnique({
        where: { id: dto.workerProfileId },
        select: { id: true },
      });
      if (!worker) {
        throw new AppException(
          'WORKER_NOT_FOUND',
          '작업자를 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      workerProfileId = worker.id;
      path = dto.path ?? ConnectionPath.PHONE_SEARCH;
    } else {
      // 작업자 → 사업장 (요청자 = 작업자)
      if (business.ownerId === userId) {
        throw new AppException(
          'INVALID_CONNECTION',
          '자기 사업장에는 작업자로 연결할 수 없습니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      workerProfileId = userId;
      path = dto.path ?? ConnectionPath.INVITE_CODE;
    }

    const existing = await this.prisma.connection.findUnique({
      where: {
        profileId_businessId: {
          profileId: workerProfileId,
          businessId: business.id,
        },
      },
    });
    if (existing) {
      throw new AppException(
        'CONNECTION_EXISTS',
        '이미 연결(또는 요청)이 존재합니다.',
        HttpStatus.CONFLICT,
      );
    }

    const connection = await this.prisma.connection.create({
      data: {
        profileId: workerProfileId,
        businessId: business.id,
        status: ConnectionStatus.REQUESTED,
        path,
      },
    });

    // 상대에게 알림 (요청 수신자)
    const requesterIsBusiness = !!dto.workerProfileId;
    if (requesterIsBusiness) {
      await this.notifications.create({
        profileId: workerProfileId,
        type: NotificationType.RESERVATION,
        title: '연결 요청이 도착했습니다',
        body: `${business.name} 사업장이 연결을 요청했습니다.`,
        data: { connectionId: connection.id, businessId: business.id },
      });
    } else {
      await this.notifications.create({
        profileId: business.ownerId,
        type: NotificationType.RESERVATION,
        title: '작업자 연결 요청이 도착했습니다',
        body: `작업자가 ${business.name} 사업장에 연결을 요청했습니다.`,
        data: { connectionId: connection.id, businessId: business.id },
      });
    }

    return this.toDto(connection.id, userId);
  }

  // --------------------------------------------------------------------------
  // 수락 — 요청 상대(작업자 또는 사업주)만 수락 가능. 수락 시 미가입 상대 승격.
  // --------------------------------------------------------------------------
  async accept(userId: string, id: string) {
    const conn = await this.prisma.connection.findUnique({
      where: { id },
      include: { business: { select: { ownerId: true, name: true } } },
    });
    if (!conn) {
      throw new AppException(
        'CONNECTION_NOT_FOUND',
        '연결 요청을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const isWorker = conn.profileId === userId;
    const isOwner = conn.business.ownerId === userId;
    if (!isWorker && !isOwner) {
      throw new AppException(
        'FORBIDDEN',
        '이 연결을 수락할 권한이 없습니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    if (conn.status === ConnectionStatus.ACCEPTED) {
      throw new AppException(
        'ALREADY_ACCEPTED',
        '이미 수락된 연결입니다.',
        HttpStatus.CONFLICT,
      );
    }

    await this.prisma.connection.update({
      where: { id },
      data: { status: ConnectionStatus.ACCEPTED },
    });

    // 연결 성립 → 기존 수기 상대(사업주 전화 매칭) 승격
    await this.promotion.promoteForBusiness(conn.businessId);

    return this.toDto(id, userId);
  }

  async list(userId: string) {
    const rows = await this.prisma.connection.findMany({
      where: {
        OR: [{ profileId: userId }, { business: { ownerId: userId } }],
      },
      include: {
        business: { select: { id: true, name: true, ownerId: true } },
        profile: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return {
      count: rows.length,
      items: rows.map((c) => ({
        id: c.id,
        status: c.status,
        path: c.path,
        role: c.business.ownerId === userId ? 'BUSINESS' : 'WORKER',
        business: { id: c.business.id, name: c.business.name },
        worker: { id: c.profile.id, name: maskName(c.profile.name) },
        createdAt: c.createdAt,
      })),
    };
  }

  async remove(userId: string, id: string) {
    const conn = await this.prisma.connection.findUnique({
      where: { id },
      include: { business: { select: { ownerId: true } } },
    });
    if (
      !conn ||
      (conn.profileId !== userId && conn.business.ownerId !== userId)
    ) {
      throw new AppException(
        'CONNECTION_NOT_FOUND',
        '연결을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    await this.prisma.connection.delete({ where: { id } });
    return { deleted: true };
  }

  private async toDto(id: string, userId: string) {
    const c = await this.prisma.connection.findUniqueOrThrow({
      where: { id },
      include: {
        business: { select: { id: true, name: true, ownerId: true } },
        profile: { select: { id: true, name: true } },
      },
    });
    return {
      id: c.id,
      status: c.status,
      path: c.path,
      role: c.business.ownerId === userId ? 'BUSINESS' : 'WORKER',
      business: { id: c.business.id, name: c.business.name },
      worker: { id: c.profile.id, name: maskName(c.profile.name) },
      createdAt: c.createdAt,
    };
  }
}
