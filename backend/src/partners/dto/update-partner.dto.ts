import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * 거래처 보강 정보 수정 — 자동 수집 필드(name/phone)는 수정 불가.
 * 사용자가 채우는 보조 정보만 허용한다. 빈 문자열은 서비스에서 null 처리(비우기).
 */
export class UpdatePartnerDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  alias?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  bizNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  memo?: string;
}
