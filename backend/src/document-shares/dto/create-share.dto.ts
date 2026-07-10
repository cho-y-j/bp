import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

/** 서류별 원본 노출 선택 (마스킹본 대신 원본 정규화본 공유). */
export class PerDocumentOptionDto {
  @IsUUID('4')
  documentId!: string;

  @IsBoolean()
  useOriginal!: boolean;
}

export class CreateShareDto {
  @IsArray()
  @ArrayMinSize(1, { message: '공유할 서류를 1개 이상 선택하세요.' })
  @ArrayMaxSize(50)
  @IsUUID('4', { each: true })
  documentIds!: string[];

  // 유효기간(일). 기본 7, 최대 30.
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(30, { message: '유효기간은 최대 30일입니다.' })
  expiresInDays?: number;

  // 서류별 원본 노출 선택 (지정 안 하면 마스킹본 우선)
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => PerDocumentOptionDto)
  perDocument?: PerDocumentOptionDto[];
}
