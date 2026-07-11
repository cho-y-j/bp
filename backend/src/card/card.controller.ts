import { Controller, Get, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { CardService } from './card.service';

/** 인증 필요 — 내 QR 명함 관리. */
@Controller()
export class CardController {
  constructor(private readonly card: CardService) {}

  // GET /me/card — 내 QR 명함(토큰·URL·미리보기·본인 서류 상태)
  @Get('me/card')
  getMyCard(@CurrentUser('userId') userId: string) {
    return this.card.getMyCard(userId);
  }

  // POST /me/card/rotate — 토큰 재발급(유출 대비, 구 토큰 무효화)
  @Post('me/card/rotate')
  rotate(@CurrentUser('userId') userId: string) {
    return this.card.rotate(userId);
  }
}

/** 미가입자(외부) 접근 — 토큰 기반 공개 프로필, 로그인 불필요. */
@Controller('public/profiles')
export class PublicProfilesController {
  constructor(private readonly card: CardService) {}

  // GET /public/profiles/:token — 공개 프로필(민감정보 비노출) + viewCount 기록
  @Public()
  @Get(':token')
  view(@Param('token') token: string) {
    return this.card.publicView(token);
  }
}
