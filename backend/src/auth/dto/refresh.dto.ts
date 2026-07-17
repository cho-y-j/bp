import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class RefreshDto {
  // 로그인/이전 회전 시 발급받은 불투명 리프레시 토큰
  @IsString()
  @MinLength(20)
  refreshToken!: string;

  // 기기 식별자(선택) — 회전 시 이어받아 기록
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;
}
