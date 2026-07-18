import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * 거래처 수동 생성 — 확인서를 쓴 적 없는 상대(문자로 서류만 보내는 곳,
 * 추후 세금계산서 발행 대상)를 사용자가 직접 등록한다.
 *  - name 은 필수. 서비스에서 trim 후 빈 값이면 400.
 *  - phone 은 자유 형식(수기 확인서 contact 규칙 재사용 — 별도 정규식 검증 없음).
 *  - 빈 문자열은 서비스에서 null 로 정규화한다.
 */
export class CreatePartnerDto {
  @IsString()
  @MaxLength(100)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  phone?: string;

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
