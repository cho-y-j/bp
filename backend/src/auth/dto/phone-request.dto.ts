import { IsString, Matches } from 'class-validator';

export class PhoneRequestDto {
  // 한국 휴대폰 번호: 하이픈 유무 모두 허용 (예: 01012345678 / 010-1234-5678)
  @IsString()
  @Matches(/^01[016789]-?\d{3,4}-?\d{4}$/, {
    message: '유효한 휴대폰 번호 형식이 아닙니다.',
  })
  phone!: string;
}
