import {
  IsIn,
  IsISO8601,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';
import { RateType } from '@prisma/client';

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export const JOB_RATE_TYPES = [
  'DAILY',
  'HOURLY',
  'PER_CASE',
  'MONTHLY',
  'UNIT',
] as const;

export class CreateJobDto {
  @IsString()
  @Matches(UUID_RE, { message: 'businessId 는 UUID 형식이어야 합니다.' })
  businessId!: string;

  @IsString()
  @Matches(UUID_RE, { message: 'workerProfileId 는 UUID 형식이어야 합니다.' })
  workerProfileId!: string;

  @IsString()
  @MaxLength(100)
  site!: string;

  @IsISO8601()
  scheduledAt!: string; // ISO 8601 일시

  @IsIn(JOB_RATE_TYPES)
  rateType!: RateType;

  @IsNumber()
  @Min(0)
  rate!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  overtimeRate?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  nightRate?: number;
}
