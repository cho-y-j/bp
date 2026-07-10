import { IsOptional, IsString, Length, Matches } from 'class-validator';

/**
 * 진위확인 입력 (사업자등록증 실연동 시 필요).
 * Document 모델은 사업자번호/대표자/개업일을 저장하지 않으므로 요청 시 받는다.
 * 사업자등록증이 아닌 유형은 이 body 를 무시한다(UNSUPPORTED).
 */
export class VerifyDocumentDto {
  @IsOptional()
  @IsString()
  @Matches(/^\d{3}-?\d{2}-?\d{5}$/, {
    message: '사업자번호는 10자리(000-00-00000) 형식이어야 합니다.',
  })
  businessNumber?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{8}$/, { message: '개업일자는 YYYYMMDD 8자리여야 합니다.' })
  openingDate?: string;

  @IsOptional()
  @IsString()
  @Length(1, 40)
  representativeName?: string;

  @IsOptional()
  @IsString()
  @Length(1, 100)
  businessName?: string;
}
