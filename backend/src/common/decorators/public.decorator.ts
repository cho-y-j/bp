import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/** 이 데코레이터가 붙은 라우트/컨트롤러는 JwtAuthGuard 를 건너뛴다. */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
