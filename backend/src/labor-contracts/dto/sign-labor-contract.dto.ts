import { IsString, MaxLength, MinLength } from 'class-validator';

/** 근로계약서 서명 body(사업장/작업자 공통). signImageBase64 는 PNG data URI(최대 1MB). */
export class SignLaborContractDto {
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  signerName!: string; // 사업장=대표자명, 작업자=서명자명

  @IsString()
  @MinLength(1)
  signImageBase64!: string; // "data:image/png;base64,...."
}
