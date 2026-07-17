import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { RefreshTokenService } from './refresh-token.service';

/**
 * 리프레시 토큰 정리 스케줄러.
 *  - 매주 1회(일요일 03:00 KST) 만료·오래 폐기된 리프레시 토큰 삭제.
 */
@Injectable()
export class RefreshTokenScheduler {
  private readonly logger = new Logger('RefreshTokenScheduler');

  constructor(private readonly refreshTokens: RefreshTokenService) {}

  @Cron(CronExpression.EVERY_WEEK, {
    name: 'refresh-token-cleanup',
    timeZone: 'Asia/Seoul',
  })
  async handleWeeklyCleanup(): Promise<number> {
    const removed = await this.refreshTokens.cleanup();
    this.logger.log(`리프레시 토큰 정리 완료: ${removed}건 삭제`);
    return removed;
  }
}
