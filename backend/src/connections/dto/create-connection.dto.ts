import { IsIn, IsOptional, IsString, Matches } from 'class-validator';
import { ConnectionPath } from '@prisma/client';

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export const CONNECTION_PATHS = [
  'PHONE_SEARCH',
  'INVITE_CODE',
  'QR',
  'LINK',
] as const;

export class CreateConnectionDto {
  @IsString()
  @Matches(UUID_RE, { message: 'businessId 는 UUID 형식이어야 합니다.' })
  businessId!: string;

  // 사업장→작업자 방향일 때: 대상 작업자 프로필. 생략 시 작업자→사업장(요청자=작업자).
  @IsOptional()
  @IsString()
  @Matches(UUID_RE, { message: 'workerProfileId 는 UUID 형식이어야 합니다.' })
  workerProfileId?: string;

  @IsOptional()
  @IsIn(CONNECTION_PATHS)
  path?: ConnectionPath;
}
