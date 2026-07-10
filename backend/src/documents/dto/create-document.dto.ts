import { DocumentOwnerType } from '@prisma/client';
import {
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
} from 'class-validator';
import { DOCUMENT_TYPES } from '../document-types';

/**
 * 서류 업로드 body (multipart form 필드).
 * 파일은 FileInterceptor 로 별도 처리, 이 DTO 는 텍스트 필드만 검증한다.
 * multipart 필드는 모두 문자열로 들어온다.
 */
export class CreateDocumentDto {
  @IsIn(DOCUMENT_TYPES, { message: '허용되지 않은 서류 유형입니다.' })
  type!: (typeof DOCUMENT_TYPES)[number];

  @IsEnum(DocumentOwnerType, {
    message: 'ownerType 은 PROFILE 또는 EQUIPMENT 여야 합니다.',
  })
  ownerType!: DocumentOwnerType;

  // ownerType=EQUIPMENT 일 때 필수 (서비스에서 교차 검증)
  @IsOptional()
  @IsUUID('4', { message: 'equipmentId 는 UUID 형식이어야 합니다.' })
  equipmentId?: string;

  // 발급일 (YYYY-MM-DD)
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '발급일은 YYYY-MM-DD 형식이어야 합니다.',
  })
  issueDate?: string;

  // 만료일 (YYYY-MM-DD)
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '만료일은 YYYY-MM-DD 형식이어야 합니다.',
  })
  expiryDate?: string;
}
