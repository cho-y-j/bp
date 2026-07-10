import { Logger } from '@nestjs/common';

/**
 * ConfigModule validation.
 * - production 에서 JWT_SECRET 이 없거나 "change-me" 계열이면 기동 실패(fail-fast).
 * - development 에서는 경고만 남기고 진행한다.
 */
const WEAK_SECRET_MARKERS = ['change-me', 'changeme', 'secret', 'your-secret'];

function isWeakSecret(secret: string | undefined): boolean {
  if (!secret || secret.trim().length < 16) return true;
  const lower = secret.toLowerCase();
  return WEAK_SECRET_MARKERS.some((m) => lower.includes(m));
}

export function validateEnv(
  config: Record<string, unknown>,
): Record<string, unknown> {
  const logger = new Logger('EnvValidation');
  const nodeEnv = (config.NODE_ENV as string) ?? 'development';
  const jwtSecret = config.JWT_SECRET as string | undefined;

  if (isWeakSecret(jwtSecret)) {
    const msg =
      'JWT_SECRET 이 설정되지 않았거나 약한 기본값입니다 (16자 이상의 무작위 값 필요).';
    if (nodeEnv === 'production') {
      // fail-fast: 운영 환경에서는 기동을 중단한다.
      throw new Error(
        `[FATAL] ${msg} production 환경에서는 기동할 수 없습니다.`,
      );
    }
    logger.warn(`${msg} (development 이므로 경고만; 운영 배포 전 반드시 교체)`);
  }

  return config;
}
