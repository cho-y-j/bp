import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CompleteJobDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  // 이미 업로드된 사진 경로들(POST /jobs/:id/photos 결과) — 선택
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoPaths?: string[];
}
