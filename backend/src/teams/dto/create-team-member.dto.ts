import {
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  MinLength,
  ValidateIf,
} from 'class-validator';

/**
 * 팀원 추가 DTO — 두 경로:
 *  - 가입자 연결: profileId (전화 검색-동의자- 로 얻은 프로필). name 없으면 서버가 프로필명 스냅샷.
 *  - 수기: name (필수) + phone(선택).
 */
export class CreateTeamMemberDto {
  @IsOptional()
  @IsString()
  @Matches(
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/,
    { message: 'profileId 는 UUID 형식이어야 합니다.' },
  )
  profileId?: string; // 가입자 연결 시

  // 수기(가입자 미연결) 경로에서는 name 필수.
  @ValidateIf((o: CreateTeamMemberDto) => !o.profileId)
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  phone?: string; // 수기 전화 (미가입 상대)

  @IsOptional()
  @IsNumber()
  @Min(0)
  defaultRate?: number; // 기본 단가(공수 1일 단가)

  @IsOptional()
  @IsIn(['GONGSU', 'DAILY'])
  rateType?: string; // (예약) 기본 단가 유형 — 현재 공수 기준
}
