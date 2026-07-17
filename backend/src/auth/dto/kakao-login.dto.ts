import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class KakaoLoginDto {
  // 카카오 로그인 SDK 로 발급받은 사용자 액세스토큰
  @IsString()
  @MinLength(10)
  accessToken!: string;

  // 기기 식별자(선택) — 발급되는 리프레시 토큰에 기록
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}
