import { IsString, MaxLength, MinLength } from 'class-validator';

/** 외부(미가입) 서명 body. signImageBase64 는 PNG data URI (최대 1MB). */
export class SignConfirmationDto {
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  signerName!: string;

  // "data:image/png;base64,...." — 검증/디코드는 서비스에서 (크기 1MB 제한)
  @IsString()
  @MinLength(1)
  signImageBase64!: string;
}
