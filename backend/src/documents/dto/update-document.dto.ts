import { DocumentStatus } from '@prisma/client';
import { IsEnum, IsIn, IsOptional, IsString, Matches } from 'class-validator';
import { DOCUMENT_TYPES } from '../document-types';

/** 서류 수정 (만료일/발급일/유형/상태). 모두 선택. */
export class UpdateDocumentDto {
  @IsOptional()
  @IsIn(DOCUMENT_TYPES, { message: '허용되지 않은 서류 유형입니다.' })
  type?: (typeof DOCUMENT_TYPES)[number];

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '발급일은 YYYY-MM-DD 형식이어야 합니다.',
  })
  issueDate?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '만료일은 YYYY-MM-DD 형식이어야 합니다.',
  })
  expiryDate?: string;

  @IsOptional()
  @IsEnum(DocumentStatus)
  status?: DocumentStatus;
}
