import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';
import { DevicePlatform } from '@prisma/client';

export const DEVICE_PLATFORMS = ['ANDROID', 'IOS', 'WEB'] as const;

export class RegisterDeviceTokenDto {
  @IsString()
  @MinLength(8)
  @MaxLength(4096)
  token!: string;

  @IsIn(DEVICE_PLATFORMS)
  platform!: DevicePlatform;
}
