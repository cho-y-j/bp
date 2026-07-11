import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { SocialInsuranceDto, WAGE_TYPES } from './create-labor-contract.dto';

/** 표준근로계약서 수정 (DRAFT 만). 모든 필드 선택. */
export class UpdateLaborContractDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  workerName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  workerPhone?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '시작일은 YYYY-MM-DD 형식입니다.',
  })
  startDate?: string;

  // 빈 문자열이면 종료일 해제(기간의 정함 없음)
  @IsOptional()
  @IsString()
  endDate?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  workplace?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  jobDescription?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '시업 시각은 HH:mm 형식입니다.',
  })
  workStartTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '종업 시각은 HH:mm 형식입니다.',
  })
  workEndTime?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  breakTime?: string;

  @IsOptional()
  @IsIn(WAGE_TYPES, { message: '임금 유형은 DAILY | HOURLY 중 하나입니다.' })
  wageType?: (typeof WAGE_TYPES)[number];

  @IsOptional()
  @IsNumber()
  @Min(0)
  wageAmount?: number;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  payday?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  payMethod?: string;

  @IsOptional()
  @IsBoolean()
  weeklyHolidayAllowance?: boolean;

  @IsOptional()
  @IsBoolean()
  overtimeAllowance?: boolean;

  @IsOptional()
  @ValidateNested()
  @Type(() => SocialInsuranceDto)
  @IsObject()
  socialInsurance?: SocialInsuranceDto;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  specialTerms?: string;
}
