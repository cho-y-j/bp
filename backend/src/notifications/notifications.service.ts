import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { DevicePlatform, NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { FcmService } from './fcm.service';

export interface CreateNotificationInput {
  profileId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Prisma.InputJsonValue;
}

/**
 * 알림 서비스.
 *  - Notification 레코드 생성 + device_tokens 조회 → FCM 실발송 시도(성공/실패 기록).
 *  - FCM 비활성(키 미보유) 시에는 레코드만 남고 발송은 로그로만(FcmService 처리).
 *  - 무효 토큰은 발송 결과에 따라 정리한다.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger('NotificationsService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly fcm: FcmService,
  ) {}

  /** 알림 레코드 생성 + 푸시 발송 시도. */
  async create(input: CreateNotificationInput) {
    const notification = await this.prisma.notification.create({
      data: {
        profileId: input.profileId,
        type: input.type,
        title: input.title,
        body: input.body,
        data: input.data,
      },
    });
    await this.push(notification.id, input);
    return notification;
  }

  /** device_tokens 조회 → FCM 발송 → 무효 토큰 정리. 실패해도 예외 던지지 않음. */
  private async push(
    notificationId: string,
    input: CreateNotificationInput,
  ): Promise<void> {
    try {
      const tokens = await this.prisma.deviceToken.findMany({
        where: { profileId: input.profileId },
        select: { token: true },
      });
      if (tokens.length === 0) {
        this.logger.debug(`[push] ${input.profileId}: 등록 토큰 없음`);
        return;
      }
      const result = await this.fcm.sendToTokens(
        tokens.map((t) => t.token),
        {
          title: input.title,
          body: input.body,
          data: { notificationId, type: input.type },
        },
      );
      if (result.invalidTokens.length > 0) {
        await this.prisma.deviceToken.deleteMany({
          where: { token: { in: result.invalidTokens } },
        });
      }
      this.logger.debug(
        `[push] ${input.profileId}: 성공 ${result.successCount} / 실패 ${result.failureCount} (enabled=${result.enabled})`,
      );
    } catch (e) {
      this.logger.warn(`푸시 발송 처리 실패: ${(e as Error).message}`);
    }
  }

  // --------------------------------------------------------------------------
  // 내 알림 조회 / 읽음
  // --------------------------------------------------------------------------
  async list(userId: string, unreadOnly: boolean) {
    const where: Prisma.NotificationWhereInput = { profileId: userId };
    if (unreadOnly) where.readAt = null;
    const rows = await this.prisma.notification.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const unreadCount = await this.prisma.notification.count({
      where: { profileId: userId, readAt: null },
    });
    return {
      count: rows.length,
      unreadCount,
      items: rows.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        read: n.readAt !== null,
        readAt: n.readAt,
        createdAt: n.createdAt,
      })),
    };
  }

  async markRead(userId: string, id: string) {
    const n = await this.prisma.notification.findUnique({ where: { id } });
    if (!n || n.profileId !== userId) {
      throw new AppException(
        'NOTIFICATION_NOT_FOUND',
        '알림을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (n.readAt) return { read: true, readAt: n.readAt };
    const updated = await this.prisma.notification.update({
      where: { id },
      data: { readAt: new Date() },
    });
    return { read: true, readAt: updated.readAt };
  }

  // --------------------------------------------------------------------------
  // 디바이스 토큰 등록 (FCM)
  // --------------------------------------------------------------------------
  async registerDeviceToken(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ) {
    // 토큰은 전역 unique — 다른 프로필에 붙어있었다면 이 프로필로 이전
    const saved = await this.prisma.deviceToken.upsert({
      where: { token },
      create: { profileId: userId, token, platform },
      update: { profileId: userId, platform },
    });
    return { id: saved.id, platform: saved.platform, registered: true };
  }
}
