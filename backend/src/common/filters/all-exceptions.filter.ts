import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

/**
 * 전역 에러 봉투: { error: { code, message } } (API-SPEC 규약).
 * - AppException 등 { code, message } 를 실은 예외는 그대로 사용.
 * - class-validator 검증 실패(400, message 배열)는 VALIDATION_ERROR 로 통일.
 * - 그 외 HttpException 은 상태코드 → code 매핑.
 * - 알 수 없는 에러는 500 INTERNAL_ERROR (상세 메시지는 숨김).
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_ERROR';
    let message = '서버 오류가 발생했습니다.';

    // Multer 업로드 오류 (파일 크기 초과 등) → 413/400 으로 매핑
    if (this.isMulterError(exception)) {
      const mErr = exception as { code?: string };
      if (mErr.code === 'LIMIT_FILE_SIZE') {
        res.status(HttpStatus.PAYLOAD_TOO_LARGE).json({
          error: {
            code: 'FILE_TOO_LARGE',
            message: '파일 크기가 최대 허용치(20MB)를 초과했습니다.',
          },
        });
        return;
      }
      res.status(HttpStatus.BAD_REQUEST).json({
        error: { code: 'UPLOAD_ERROR', message: '파일 업로드에 실패했습니다.' },
      });
      return;
    }

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const resp = exception.getResponse();
      code = this.defaultCodeForStatus(status);

      if (typeof resp === 'string') {
        message = resp;
      } else if (resp && typeof resp === 'object') {
        const r = resp as Record<string, unknown>;
        if (typeof r.code === 'string') code = r.code;
        if (typeof r.message === 'string') {
          message = r.message;
        } else if (Array.isArray(r.message)) {
          // class-validator: 메시지 배열 → 검증 오류로 통일
          code = 'VALIDATION_ERROR';
          message = r.message.join(', ');
        }
      }
    } else if (exception instanceof Error) {
      message = exception.message || message;
      this.logger.error(exception.stack ?? exception.message);
    }

    if (status >= 500) {
      this.logger.error(`[${req.method} ${req.url}] ${code}: ${message}`);
    }

    res.status(status).json({ error: { code, message } });
  }

  /** multer 오류 판별 (MulterError: name === 'MulterError'). */
  private isMulterError(exception: unknown): boolean {
    return (
      typeof exception === 'object' &&
      exception !== null &&
      (exception as { name?: string }).name === 'MulterError'
    );
  }

  private defaultCodeForStatus(status: number): string {
    const map: Record<number, string> = {
      400: 'BAD_REQUEST',
      401: 'UNAUTHORIZED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      429: 'TOO_MANY_REQUESTS',
      501: 'NOT_IMPLEMENTED',
      503: 'SERVICE_UNAVAILABLE',
    };
    return map[status] ?? 'ERROR';
  }
}
