import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export class PaySettlementDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @Matches(UUID_RE, {
    each: true,
    message: 'ledgerEntryIds 는 UUID 배열이어야 합니다.',
  })
  ledgerEntryIds!: string[];

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'paidAt 은 YYYY-MM-DD 형식입니다.',
  })
  paidAt?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  memo?: string;
}
