import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { TbmAttendeeDto, TbmHazardItemDto } from './create-tbm-record.dto';

/** 간편 TBM 기록 수정 (당일만). 모든 필드 선택. attendees 지정 시 명단 전체 대체. */
export class UpdateTbmRecordDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  site?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: '일자는 YYYY-MM-DD 형식입니다.' })
  date?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: '시각은 HH:mm 형식입니다.' })
  time?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @ValidateNested({ each: true })
  @Type(() => TbmHazardItemDto)
  hazards?: TbmHazardItemDto[];

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
