import { SafetyLogType } from '@prisma/client';

/** 안전 로그 유형 한글 라벨 (리포트/알림 표시용). */
export const SAFETY_TYPE_LABEL: Record<SafetyLogType, string> = {
  HEAT_ALERT: '폭염알림',
  REST_GUIDE: '휴식안내',
  DOCUMENT_VALIDITY: '서류확인',
  CONDITION_CHECK: '컨디션체크',
};
