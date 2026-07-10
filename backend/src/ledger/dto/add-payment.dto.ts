import {
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';

/** 부분입금 기록. */
export class AddPaymentDto {
  @IsNumber()
  @Min(1, { message: '입금액은 1원 이상이어야 합니다.' })
  amount!: number;

  // 입금일 (YYYY-MM-DD). 미지정이면 서버 시각.
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '입금일은 YYYY-MM-DD 형식입니다.',
  })
  paidAt?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  memo?: string;
}
