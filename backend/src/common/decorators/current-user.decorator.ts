import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';

/** JwtAuthGuard 가 request.user 에 심는 인증 주체. */
export interface AuthUser {
  userId: string;
}

/**
 * @CurrentUser()          → AuthUser 전체
 * @CurrentUser('userId')  → 특정 속성만
 */
export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest<Request & { user?: AuthUser }>();
    const user = req.user;
    if (!user) return undefined;
    return data ? user[data] : user;
  },
);
