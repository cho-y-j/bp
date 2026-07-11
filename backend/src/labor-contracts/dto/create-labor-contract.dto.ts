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
  ValidateIf,
  ValidateNested,
} from 'class-validator';

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export const WAGE_TYPES = ['DAILY', 'HOURLY'] as const;

/** 4대보험 적용 체크 — 고용/건강/국민연금/산재. */
export class SocialInsuranceDto {
  @IsOptional()
  @IsBoolean()
  employment?: boolean; // 고용보험

  @IsOptional()
  @IsBoolean()
  health?: boolean; // 건강보험

  @IsOptional()
  @IsBoolean()
  pension?: boolean; // 국민연금

  @IsOptional()
  @IsBoolean()
  industrialAccident?: boolean; // 산재보험
}

/**
 * 표준근로계약서 작성 (사업장 모드).
 *  - 상대(작업자): 가입 연결(workerProfileId) 또는 수기(workerName + workerPhone).
 *  - 고용노동부 일용직 표준근로계약서 필드 기반.
 */
export class CreateLaborContractDto {
  @IsString()
  @Matches(UUID_RE, { message: 'businessId 는 UUID 형식이어야 합니다.' })
  businessId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  title?: string;

  // 작업자 — 가입 연결 또는 수기
  @IsOptional()
  @IsString()
  @Matches(UUID_RE, { message: 'workerProfileId 는 UUID 형식이어야 합니다.' })
  workerProfileId?: string;

  // 수기(미연결)면 이름 필수. 연결이면 프로필명 스냅샷 사용(선택).
  @ValidateIf((o: CreateLaborContractDto) => !o.workerProfileId)
  @IsString()
  @MaxLength(50)
  workerName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  workerPhone?: string;

  // 계약 기간
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '시작일은 YYYY-MM-DD 형식입니다.',
  })
  startDate!: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '종료일은 YYYY-MM-DD 형식입니다.',
  })
  endDate?: string;

  // 근무 조건
  @IsString()
  @MaxLength(100)
  workplace!: string;

  @IsString()
  @MaxLength(1000)
  jobDescription!: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '시업 시각은 HH:mm 형식입니다.',
  })
  workStartTime!: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '종업 시각은 HH:mm 형식입니다.',
  })
  workEndTime!: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  breakTime?: string;

  // 임금
  @IsIn(WAGE_TYPES, { message: '임금 유형은 DAILY | HOURLY 중 하나입니다.' })
  wageType!: (typeof WAGE_TYPES)[number];

  @IsNumber()
  @Min(0)
  wageAmount!: number;

  @IsString()
  @MaxLength(100)
  payday!: string;

  @IsString()
  @MaxLength(100)
  payMethod!: string;

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
