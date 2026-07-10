/**
 * SMS 발송 추상화. 실제 발송사(NHN/Twilio 등)는 이 인터페이스를 구현해 교체한다.
 */
export interface SmsService {
  sendVerificationCode(phone: string, code: string): Promise<void>;
}

export const SMS_SERVICE = Symbol('SMS_SERVICE');
