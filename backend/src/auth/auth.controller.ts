import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { AuthService } from './auth.service';
import { PhoneRequestDto } from './dto/phone-request.dto';
import { PhoneVerifyDto } from './dto/phone-verify.dto';
import { KakaoLoginDto } from './dto/kakao-login.dto';

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
    return this.auth.verifyPhoneCode(dto.phone, dto.code);
  }

  // POST /auth/kakao — 카카오 로그인 (키 없으면 501 스텁)
  @Public()
  @Post('kakao')
  @HttpCode(HttpStatus.OK)
  async kakao(@Body() dto: KakaoLoginDto) {
    return this.auth.kakaoLogin(dto.accessToken);
  }
}
