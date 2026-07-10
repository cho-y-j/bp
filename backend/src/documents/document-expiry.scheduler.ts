import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DocumentsService } from './documents.service';

const TARGET_DDAYS = [30, 7, 0]; // D-30 / D-7 / D-0

/**
 * 서류 만료 알림 스케줄러.
 *  - 매일 09:00 (KST 기준으로 서버 TZ 설정) 실행.
 *  - D-30/D-7/D-0 대상 서류 → Notification 레코드 생성(발송은 S2d).
 *  - 같은 서류·같은 D-day 중복 생성은 스킵(하루 2회 실행 대비).
 */
@Injectable()
export class DocumentExpiryScheduler {
  private readonly logger = new Logger('DocumentExpiryScheduler');

  constructor(
    private readonly documents: DocumentsService,
    private readonly notifications: NotificationsService,
    private readonly prisma: PrismaService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_9AM, {
    name: 'document-expiry',
    timeZone: 'Asia/Seoul',
  })
  async handleDailyExpiryScan(): Promise<number> {
    return this.runExpiryScan();
  }

  /** 실제 스캔 로직 (테스트/수동 트리거에서 재사용). 생성한 알림 수 반환. */
  async runExpiryScan(now: Date = new Date()): Promise<number> {
    const targets = await this.documents.findByDdayTargets(TARGET_DDAYS, now);
    let created = 0;
    for (const { doc, dday, ownerProfileId } of targets) {
      const already = await this.alreadyNotified(ownerProfileId, doc.id, dday);
      if (already) continue;
      await this.notifications.create({
        profileId: ownerProfileId,
        type: NotificationType.DOCUMENT_EXPIRY,
        title: this.title(dday),
        body: this.body(doc.type, dday),
        data: { documentId: doc.id, dday, documentType: doc.type },
      });
      created += 1;
    }
    this.logger.log(
      `만료 알림 스캔 완료: 대상 ${targets.length}건, 신규 알림 ${created}건`,
    );
    return created;
  }

  private title(dday: number): string {
    if (dday === 0) return '서류 만료일입니다';
    return `서류 만료 ${dday}일 전`;
  }

  private body(type: string, dday: number): string {
    if (dday === 0) return `[${type}] 오늘 만료됩니다. 갱신을 확인하세요.`;
    return `[${type}] 만료까지 ${dday}일 남았습니다. 갱신을 준비하세요.`;
  }

  /** 같은 서류·같은 D-day 로 이미 생성된 알림이 있으면 true. */
  private async alreadyNotified(
    profileId: string,
    documentId: string,
    dday: number,
  ): Promise<boolean> {
    const existing = await this.prisma.notification.findFirst({
      where: {
        profileId,
        type: NotificationType.DOCUMENT_EXPIRY,
        AND: [
          { data: { path: ['documentId'], equals: documentId } },
          { data: { path: ['dday'], equals: dday } },
        ],
      },
    });
    return !!existing;
  }
}
