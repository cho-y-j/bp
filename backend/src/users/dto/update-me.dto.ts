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
}
