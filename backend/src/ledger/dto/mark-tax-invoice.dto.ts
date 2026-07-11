import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';

/**
 * 세금계산서 발행(홈택스 입력) 완료 표시 — 대상 장부 항목 id 배열.
 * 표시된 항목은 이후 tax-invoice-data 집계에서 제외된다.
 */
export class MarkTaxInvoiceDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(500)
  @IsUUID('4', { each: true, message: 'ledgerIds 는 UUID 배열이어야 합니다.' })
  ledgerIds!: string[];
}
