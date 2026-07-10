import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNumber,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

/** 마스킹 사각형 (페이지별 정규화 0~1 좌표, 좌상단 원점). */
export class MaskRegionDto {
  @IsInt()
  @Min(0)
  page!: number;

  @IsNumber()
  @Min(0)
  @Max(1)
  x!: number;

  @IsNumber()
  @Min(0)
  @Max(1)
  y!: number;

  @IsNumber()
  @Min(0)
  @Max(1)
  width!: number;

  @IsNumber()
  @Min(0)
  @Max(1)
  height!: number;
}

export class MaskDocumentDto {
  @IsArray()
  @ArrayMinSize(1, { message: '마스킹 영역을 1개 이상 지정해야 합니다.' })
  @ArrayMaxSize(200)
  @ValidateNested({ each: true })
  @Type(() => MaskRegionDto)
  regions!: MaskRegionDto[];
}
