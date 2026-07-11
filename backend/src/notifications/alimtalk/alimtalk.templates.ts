import { AlimtalkTemplateKey } from './alimtalk.types';

/**
 * 알림톡 템플릿 문구(상수).
 *
 * ⚠️ 운영 발송 전 필수:
 *   1) 카카오 비즈메시지 센터에서 발신 프로필(채널)과 각 템플릿을 등록·심사 승인받는다.
 *   2) 승인된 templateId 를 아래 `envKey` 환경변수(ALIMTALK_TEMPLATE_*)로 주입한다.
 *   3) 실제 발송되는 문구는 "승인된 템플릿"과 정확히 일치해야 한다. 아래 fallbackText 는
 *      개발/로그 참고용 문구이며, 변수는 #{key} 형태로 치환된다.
 */
export interface AlimtalkTemplateDef {
  /** templateId 를 담는 환경변수명. */
  envKey: string;
  /** 개발/로그 참고용 문구(치환 전). 운영 승인 문구와 일치시켜야 한다. */
  fallbackText: string;
  /** 사용하는 치환 변수 키 목록. */
  variables: string[];
}

export const ALIMTALK_TEMPLATES: Record<
  AlimtalkTemplateKey,
  AlimtalkTemplateDef
> = {
  CONFIRMATION_SIGN: {
    envKey: 'ALIMTALK_TEMPLATE_CONFIRMATION_SIGN',
    fallbackText:
      '[작업온] #{companyName} 현장 작업확인서가 도착했습니다.\n' +
      '아래 링크에서 내용을 확인하고 서명해 주세요. (설치 없이 가능)\n#{url}',
    variables: ['companyName', 'url'],
  },
  PAYMENT_DUE: {
    envKey: 'ALIMTALK_TEMPLATE_PAYMENT_DUE',
    fallbackText:
      '[작업온] #{companyName} 수금 예정일 안내\n' +
      '미수 금액 #{amount}원의 수금 예정일이 #{dday} 입니다.',
    variables: ['companyName', 'amount', 'dday'],
  },
  PAYMENT_REMINDER: {
    envKey: 'ALIMTALK_TEMPLATE_PAYMENT_REMINDER',
    fallbackText:
      '[작업온] #{workerName}님이 #{month} 작업 대금 안내를 드립니다.\n' +
      '금액: #{amount}원#{account}\n' +
      '자세한 내역은 아래 링크에서 확인하실 수 있습니다.\n#{url}',
    variables: ['workerName', 'month', 'amount', 'account', 'url'],
  },
  HEAT_ALERT: {
    envKey: 'ALIMTALK_TEMPLATE_HEAT_ALERT',
    fallbackText:
      '[작업온] 폭염 경고\n#{site} 현장에 폭염이 예상됩니다.\n' +
      '충분한 수분 섭취와 그늘 휴식을 지켜 주세요.',
    variables: ['site'],
  },
};

/** 템플릿 fallbackText 에 #{key} 를 치환한 문구를 만든다(로그/미승인 발송 참고용). */
export function renderAlimtalkText(
  key: AlimtalkTemplateKey,
  variables: Record<string, string>,
): string {
  const def = ALIMTALK_TEMPLATES[key];
  return def.fallbackText.replace(/#\{(\w+)\}/g, (_, k: string) =>
    variables[k] !== undefined ? variables[k] : `#{${k}}`,
  );
}
