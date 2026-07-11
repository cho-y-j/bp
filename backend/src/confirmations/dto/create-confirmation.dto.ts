import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
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

/** 팀(반장) 확인서 팀원 항목 — memberId(팀원) 별 공수·단가. 금액은 서버 계산. */
export class TeamEntryDto {
  @IsString()
  @Matches(UUID_RE, { message: 'memberId 는 UUID 형식이어야 합니다.' })
  memberId!: string;

  @IsNumber()
  @Min(0)
  quantity!: number; // 공수(0.1 단위)

  @IsOptional()
  @IsNumber()
  @Min(0)
  rate?: number; // 미지정 시 팀원 기본 단가(defaultRate) 사용
}

/** 확인서 단가 유형 (API 계약: DAILY | HOURLY | PER_CASE(건당) | GONGSU(공수)). */
export const CONFIRMATION_RATE_TYPES = [
  'DAILY',
  'HOURLY',
  'PER_CASE',
  'GONGSU',
] as const;
export const ADDITIONAL_ITEM_TYPES = [
  'OVERTIME',
  'EARLY',
  'NIGHT',
  'ALLNIGHT',
  'OTHER',
] as const;

export class AdditionalItemDto {
  @IsIn(ADDITIONAL_ITEM_TYPES)
  type!: (typeof ADDITIONAL_ITEM_TYPES)[number];

  @IsOptional()
  @IsString()
  @MaxLength(30)
  label?: string;

  @IsNumber()
  @Min(0)
  rate!: number;

  @IsNumber()
  @Min(0)
  quantity!: number;
}

export class EquipmentSectionDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  vehicleNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  spec?: string;

  @IsOptional()
  @IsBoolean()
  guide?: boolean; // 유도원 여부
}

export class CreateConfirmationDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: '날짜는 YYYY-MM-DD 형식입니다.' })
  date!: string;

  @IsString()
  @MaxLength(100)
  siteName!: string; // 현장/장소

  // 상대: businessId(연동) 또는 수기(companyName + contact) — 서비스에서 교차검증
  @IsOptional()
  @IsString()
  @Matches(
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/,
    { message: 'businessId 는 UUID 형식이어야 합니다.' },
  )
  businessId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  companyName?: string; // 수기 회사명

  @IsOptional()
  @IsString()
  @MaxLength(50)
  contact?: string; // 수기 연락처

  @IsString()
  @MaxLength(1000)
  workDescription!: string; // 작업 내용

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '시작 시각은 HH:mm 형식입니다.',
  })
  startTime!: string; // HH:mm

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '종료 시각은 HH:mm 형식입니다.',
  })
  endTime!: string; // HH:mm

  // 팀 확인서(teamId)면 단가 유형/단가/수량은 팀원 항목(teamEntries)이 대신하므로 선택.
  @ValidateIf((o: CreateConfirmationDto) => !o.teamId)
  @IsIn(CONFIRMATION_RATE_TYPES, {
    message: '단가 유형은 DAILY | HOURLY | PER_CASE | GONGSU 중 하나입니다.',
  })
  rateType?: (typeof CONFIRMATION_RATE_TYPES)[number];

  @ValidateIf((o: CreateConfirmationDto) => !o.teamId)
  @IsNumber()
  @Min(0)
  rate?: number;

  @ValidateIf((o: CreateConfirmationDto) => !o.teamId)
  @IsNumber()
  @Min(0)
  quantity?: number; // 일수/시간/건수

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AdditionalItemDto)
  additionalItems?: AdditionalItemDto[];

  @IsOptional()
  @IsNumber()
  @Min(0)
  vatRate?: number; // 부가세율 (예: 0.1)

  @IsOptional()
  @ValidateNested()
  @Type(() => EquipmentSectionDto)
  @IsObject()
  equipmentSection?: EquipmentSectionDto;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;

  // 장부 수금 예정일 (선택)
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '수금 예정일은 YYYY-MM-DD 형식입니다.',
  })
  dueDate?: string;

  // ---- 팀(반장) 확인서 (P2a) ----
  @IsOptional()
  @IsString()
  @Matches(UUID_RE, { message: 'teamId 는 UUID 형식이어야 합니다.' })
  teamId?: string;

  @ValidateIf((o: CreateConfirmationDto) => !!o.teamId)
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => TeamEntryDto)
  teamEntries?: TeamEntryDto[];
}
