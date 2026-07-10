import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { AppException } from '../errors';

export interface JwtPayload {
  sub: string; // profile id
}

/**
 * 전역 인증 가드.
 * - @Public() 라우트는 통과.
 * - 그 외에는 Authorization: Bearer <JWT> 필수, 검증 후 request.user = { userId } 설정.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const req = context
      .switchToHttp()
      .getRequest<Request & { user?: { userId: string } }>();
    const token = this.extractToken(req);
    if (!token) {
      throw new AppException(
        'UNAUTHORIZED',
        '인증 토큰이 필요합니다.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    try {
      const payload = this.jwt.verify<JwtPayload>(token);
      req.user = { userId: payload.sub };
      return true;
    } catch {
      throw new AppException(
        'UNAUTHORIZED',
        '유효하지 않거나 만료된 토큰입니다.',
        HttpStatus.UNAUTHORIZED,
      );
    }
  }

  private extractToken(req: Request): string | undefined {
    const auth = req.headers.authorization;
    if (!auth) return undefined;
    const [type, token] = auth.split(' ');
    return type === 'Bearer' && token ? token : undefined;
  }
}
