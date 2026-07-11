import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @Length(1, 40, { message: '이름은 1~40자입니다.' })
  name?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  industryTags?: string[];

  // 전화번호 검색 동의 토글 (법적 필수 항목)
  @IsOptional()
  @IsBoolean()
  phoneSearchConsent?: boolean;

  // 세금계산서 공급자(내 사업자) 정보 — 홈택스 작성용
  @IsOptional()
  @IsString()
  @Length(0, 20, { message: '사업자번호는 20자 이내입니다.' })
  bizNumber?: string;

  @IsOptional()
  @IsString()
  @Length(0, 60, { message: '상호는 60자 이내입니다.' })
  bizName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 200, { message: '주소는 200자 이내입니다.' })
  bizAddress?: string;

  // 수금 안내용 입금 계좌 (P3a, 선택 입력)
  @IsOptional()
  @IsString()
  @Length(0, 30, { message: '은행명은 30자 이내입니다.' })
  payoutBank?: string;

  @IsOptional()
  @IsString()
  @Length(0, 40, { message: '계좌번호는 40자 이내입니다.' })
  payoutAccount?: string;

  @IsOptional()
  @IsString()
  @Length(0, 40, { message: '예금주는 40자 이내입니다.' })
  payoutHolder?: string;

  // QR 명함 (P3b) — 공개 노출 ON/OFF · 한 줄 소개
  @IsOptional()
  @IsBoolean()
  cardEnabled?: boolean;

  @IsOptional()
  @IsString()
  @Length(0, 80, { message: '한 줄 소개는 80자 이내입니다.' })
  cardIntro?: string;
}
