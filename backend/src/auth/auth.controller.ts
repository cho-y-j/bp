import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthService } from './auth.service';
import { PhoneRequestDto } from './dto/phone-request.dto';
import { PhoneVerifyDto } from './dto/phone-verify.dto';
import { KakaoLoginDto } from './dto/kakao-login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { LogoutDto } from './dto/logout.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  // POST /auth/phone/request — 인증코드 발송 (dev 는 응답에 devCode 포함)
  @Public()
  @Post('phone/request')
  @HttpCode(HttpStatus.OK)
  async requestPhone(@Body() dto: PhoneRequestDto) {
    const result = await this.auth.requestPhoneCode(dto.phone);
    return { sent: true, ...result };
  }

  // POST /auth/phone/verify — 코드 검증 → 가입/로그인 + JWT
  @Public()
  @Post('phone/verify')
  @HttpCode(HttpStatus.OK)
  async verifyPhone(@Body() dto: PhoneVerifyDto) {
    return this.auth.verifyPhoneCode(dto.phone, dto.code, dto.deviceId);
  }

  // POST /auth/kakao — 카카오 로그인 (키 없으면 501 스텁)
  @Public()
  @Post('kakao')
  @HttpCode(HttpStatus.OK)
  async kakao(@Body() dto: KakaoLoginDto) {
    return this.auth.kakaoLogin(dto.accessToken, dto.deviceId);
  }

  // POST /auth/refresh — 유효 리프레시 → 새 액세스 + 리프레시 회전 (인증 불필요)
  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto.refreshToken, dto.deviceId);
  }

  // POST /auth/logout — 해당 리프레시 토큰 폐기(해당 기기 세션 종료)
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  async logout(
    @CurrentUser('userId') userId: string,
    @Body() dto: LogoutDto,
  ) {
    return this.auth.logout(userId, dto.refreshToken);
  }

  // POST /auth/kakao/link — 로그인 상태에서 카카오 계정 연결(인증 필요)
  @Post('kakao/link')
  @HttpCode(HttpStatus.OK)
  async kakaoLink(
    @CurrentUser('userId') userId: string,
    @Body() dto: KakaoLoginDto,
  ) {
    return this.auth.linkKakao(userId, dto.accessToken);
  }
}
