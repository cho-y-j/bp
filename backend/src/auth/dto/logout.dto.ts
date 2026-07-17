import { IsString, MinLength } from 'class-validator';

export class LogoutDto {
  // 폐기할 리프레시 토큰(해당 기기 세션만 종료)
  @IsString()
  @MinLength(20)
  refreshToken!: string;
}
