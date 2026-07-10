import { IsString, Length, Matches } from 'class-validator';

export class PhoneVerifyDto {
  @IsString()
  @Matches(/^01[016789]-?\d{3,4}-?\d{4}$/, {
    message: '유효한 휴대폰 번호 형식이 아닙니다.',
  })
  phone!: string;

  @IsString()
  @Length(6, 6, { message: '인증코드는 6자리입니다.' })
  code!: string;
}
