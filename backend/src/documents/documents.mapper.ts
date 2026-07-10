import { Document } from '@prisma/client';
import { computeDday, expiryStateFromDday } from '../common/dday.util';

export interface DocumentDto {
  id: string;
  type: string;
  ownerType: string;
  profileId: string | null;
  equipmentId: string | null;
  status: string;
  derivedStatus: string; // 만료일 기준 실시간 파생 상태
  dday: number | null; // 만료까지 남은 일수 (null = 만료일 없음)
  issuedDate: Date | null;
  expiryDate: Date | null;
  hasMask: boolean; // 마스킹본 존재 여부
  originalFileName: string | null;
  fileSize: number | null;
  mimeType: string | null;
  verificationResult: unknown;
  createdAt: Date;
  updatedAt: Date;
}

/** Document → API DTO. 내부 파일 경로(filePath 등)는 노출하지 않는다. */
export function toDocumentDto(
  doc: Document,
  now: Date = new Date(),
): DocumentDto {
  const dday = doc.expiryDate ? computeDday(doc.expiryDate, now) : null;
  return {
    id: doc.id,
    type: doc.type,
    ownerType: doc.ownerType,
    profileId: doc.profileId,
    equipmentId: doc.equipmentId,
    status: doc.status,
    derivedStatus: expiryStateFromDday(dday),
    dday,
    issuedDate: doc.issuedDate,
    expiryDate: doc.expiryDate,
    hasMask: !!doc.maskedFilePath,
    originalFileName: doc.originalFileName,
    fileSize: doc.fileSize,
    mimeType: doc.mimeType,
    verificationResult: doc.verificationResult ?? null,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt,
  };
}
