import { IsIn, IsNumber, IsOptional, Max, Min } from 'class-validator';

export const CONDITION_RESULTS = ['OK', 'BAD'] as const;

export class StartJobDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  @IsIn(CONDITION_RESULTS)
  condition!: (typeof CONDITION_RESULTS)[number]; // 컨디션 체크 OK|BAD

  @IsOptional()
  conditionNote?: string;
}
