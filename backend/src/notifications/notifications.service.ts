import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { DevicePlatform, NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { FcmService } from './fcm.service';
import {
  ALIMTALK_SERVICE,
  AlimtalkService,
  AlimtalkTemplateKey,
} from './alimtalk/alimtalk.types';

/**
 * 알림톡 병행 채널.
 *  - templateKey/variables 로 알림톡 발송 문맥을 지정한다.
 *  - 정책: 알림톡은 "미가입(푸시 미도달) 상대 전용 우선" → 푸시가 도달하지 못한
 *    경우에만 fallback 으로 발송한다(가입자에게 중복 발송하지 않음).
 */
export interface NotificationAlimtalk {
  templateKey: AlimtalkTemplateKey;
  variables: Record<string, string>;
}

export interface CreateNotificationInput {
  profileId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Prisma.InputJsonValue;
  alimtalk?: NotificationAlimtalk; // 푸시 미도달 시 알림톡 fallback
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
    @Inject(ALIMTALK_SERVICE) private readonly alimtalk: AlimtalkService,
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

  /**
   * device_tokens 조회 → FCM 발송 → 무효 토큰 정리. 실패해도 예외 던지지 않음.
   * 푸시가 도달하지 못하면(토큰 없음/비활성/전부 실패) 알림톡 fallback 을 시도한다.
   */
  private async push(
    notificationId: string,
    input: CreateNotificationInput,
  ): Promise<void> {
    let pushDelivered = false;
    try {
      const tokens = await this.prisma.deviceToken.findMany({
        where: { profileId: input.profileId },
        select: { token: true },
      });
      if (tokens.length === 0) {
        this.logger.debug(`[push] ${input.profileId}: 등록 토큰 없음`);
      } else {
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
        pushDelivered = result.enabled && result.successCount > 0;
        this.logger.debug(
          `[push] ${input.profileId}: 성공 ${result.successCount} / 실패 ${result.failureCount} (enabled=${result.enabled})`,
        );
      }
    } catch (e) {
      this.logger.warn(`푸시 발송 처리 실패: ${(e as Error).message}`);
    }

    // 알림톡 fallback: 푸시가 도달하지 못한(미가입/미설치) 대상에게만 우선 발송.
    if (input.alimtalk && !pushDelivered) {
      await this.sendAlimtalkToProfile(input.profileId, input.alimtalk);
    }
  }

  /** 프로필의 전화번호로 알림톡 발송(fallback). 실패해도 예외 던지지 않음. */
  private async sendAlimtalkToProfile(
    profileId: string,
    alimtalk: NotificationAlimtalk,
  ): Promise<void> {
    try {
      const profile = await this.prisma.profile.findUnique({
        where: { id: profileId },
        select: { phone: true },
      });
      // 카카오 가입 임시 전화(kakao:...)는 실제 번호가 아니므로 제외.
      const phone = profile?.phone ?? '';
      if (!phone || phone.startsWith('kakao:')) return;
      await this.alimtalk.send(phone, alimtalk.templateKey, alimtalk.variables);
    } catch (e) {
      this.logger.warn(`알림톡 fallback 실패: ${(e as Error).message}`);
    }
  }

  /**
   * 미가입 상대(전화번호만 아는 수기 상대)에게 알림톡 직접 발송.
   *  - Notification 레코드 없이 알림톡만 발송(수신자가 우리 서비스 프로필이 아님).
   *  - 어댑터 비활성 시 로그만.
   */
  async sendExternalAlimtalk(
    phone: string,
    templateKey: AlimtalkTemplateKey,
    variables: Record<string, string>,
  ) {
    return this.alimtalk.send(phone, templateKey, variables);
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
