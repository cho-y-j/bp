import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

/** 위험요인 항목 — 기본 프리셋 코드(code) 또는 커스텀/직접입력 문구(text). 최소 하나. */
export class TbmHazardItemDto {
  @IsOptional()
  @IsString()
  @MaxLength(40)
  code?: string;

  @ValidateIf((o: TbmHazardItemDto) => !o.code)
  @IsString()
  @MaxLength(200)
  text?: string;
}

/** TBM 참석자 — 가입 연결(profileId) 또는 수기(name). */
export class TbmAttendeeDto {
  @IsOptional()
  @IsString()
  @Matches(UUID_RE, { message: 'profileId 는 UUID 형식이어야 합니다.' })
  profileId?: string;

  // 수기(미연결)면 이름 필수. 연결이면 프로필명 스냅샷 사용(선택).
  @ValidateIf((o: TbmAttendeeDto) => !o.profileId)
  @IsString()
  @MaxLength(50)
  name?: string;
}

/** 간편 TBM 기록 작성 (사업장 모드). */
export class CreateTbmRecordDto {
  @IsString()
  @Matches(UUID_RE, { message: 'businessId 는 UUID 형식이어야 합니다.' })
  businessId!: string;

  @IsString()
  @MaxLength(100)
  site!: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: '일자는 YYYY-MM-DD 형식입니다.' })
  date!: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '시각은 HH:mm 형식입니다.',
  })
  time?: string;

  @IsArray()
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => TbmHazardItemDto)
  hazards!: TbmHazardItemDto[];

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  measures?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(60)
  @ValidateNested({ each: true })
  @Type(() => TbmAttendeeDto)
  attendees?: TbmAttendeeDto[];
}
