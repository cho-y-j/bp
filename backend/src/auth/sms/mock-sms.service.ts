import { Injectable, Logger } from '@nestjs/common';
import { SmsService } from './sms.service';

/**
 * 개발/테스트용 mock SMS: 실제 발송 없이 콘솔에 코드를 남긴다.
 * (dev 환경에서는 API 응답의 devCode 로도 코드를 받을 수 있다.)
 */
@Injectable()
export class MockSmsService implements SmsService {
  private readonly logger = new Logger('MockSms');

  sendVerificationCode(phone: string, code: string): Promise<void> {
    this.logger.log(`[MOCK SMS] ${phone} → 인증코드: ${code}`);
    return Promise.resolve();
  }
}
