import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Request } from 'express';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * 전역 성공 응답 봉투: { data: <payload> } (API-SPEC 규약).
 * - /health 는 인프라 헬스체크용이라 봉투를 씌우지 않는다(원형 유지).
 */
@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, unknown> {
  intercept(
    context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<unknown> {
    const req = context.switchToHttp().getRequest<Request>();
    const isHealth = req.path === '/health' || req.path.startsWith('/health/');

    return next.handle().pipe(
      map((data) => {
        if (isHealth) return data;
        return { data: data ?? null };
      }),
    );
  }
}
