import { IsString, MinLength } from 'class-validator';

export class KakaoLoginDto {
  // 카카오 로그인 SDK 로 발급받은 사용자 액세스토큰
  @IsString()
  @MinLength(10)
  accessToken!: string;
}
