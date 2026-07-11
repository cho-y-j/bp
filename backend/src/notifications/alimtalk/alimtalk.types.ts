/**
 * 카카오 알림톡 발송 추상화 (SMS/FCM 어댑터와 동일 패턴).
 *  - 실제 발송사(Solapi 등)는 이 인터페이스를 구현해 provider 로 교체한다.
 *  - 키 미보유 시 어댑터는 비활성(로그만) 동작한다.
 */

/** DI 토큰. */
export const ALIMTALK_SERVICE = Symbol('ALIMTALK_SERVICE');

/** 알림톡 템플릿 키(운영 승인 템플릿과 1:1 매핑). */
export type AlimtalkTemplateKey =
  | 'CONFIRMATION_SIGN' // 확인서 서명 요청(미가입 상대)
  | 'PAYMENT_DUE' // 수금 예정 안내
  | 'PAYMENT_REMINDER' // 수금 독촉(작업자 대신 사업장/수기 상대에게 점잖은 대금 안내) — P3a
  | 'HEAT_ALERT'; // 폭염 경고

export interface AlimtalkSendResult {
  enabled: boolean; // 어댑터 활성 여부
  sent: boolean; // 실제 발송 시도 성공 여부
  reason?: string; // 비활성/미발송 사유(로그/디버깅용)
}

export interface AlimtalkService {
  isEnabled(): boolean;
  /**
   * 알림톡 발송.
   * @param to 수신 전화번호(하이픈 유무 무관, 어댑터가 정규화)
   * @param templateKey 승인 템플릿 키
   * @param variables 템플릿 치환 변수(#{key})
   */
  send(
    to: string,
    templateKey: AlimtalkTemplateKey,
    variables: Record<string, string>,
  ): Promise<AlimtalkSendResult>;
}
