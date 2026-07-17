import { IsOptional, IsString, Matches } from 'class-validator';

/** 일용근로소득 지급명세서 월 마감 표시. */
export class MarkWageStatementDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}$/, { message: 'month 는 YYYY-MM 형식이어야 합니다.' })
  month!: string;

  @IsOptional()
  @IsString()
  businessId?: string;
}
