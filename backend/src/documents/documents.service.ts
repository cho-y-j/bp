import { HttpStatus, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Document, DocumentOwnerType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { computeDday } from '../common/dday.util';
import { FileStorageService } from './file-storage.service';
import { PdfService } from './pdf.service';
import { BizVerifyService } from './verify/bizverify.service';
import { CreateDocumentDto } from './dto/create-document.dto';
import { UpdateDocumentDto } from './dto/update-document.dto';
import { MaskDocumentDto } from './dto/mask-document.dto';
import { VerifyDocumentDto } from './dto/verify-document.dto';
import { toDocumentDto } from './documents.mapper';
import { VERIFIABLE_TYPE } from './document-types';

type DocWithEquipment = Document & {
  equipment: { profileId: string } | null;
};

const MIME_TO_EXT: Record<string, string> = {
  'application/pdf': 'pdf',
  'image/jpeg': 'jpg',
  'image/jpg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/heic': 'heic',
  'image/heif': 'heif',
};

const ALLOWED_UPLOAD_MIME = new Set(Object.keys(MIME_TO_EXT));

@Injectable()
export class DocumentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: FileStorageService,
    private readonly pdf: PdfService,
    private readonly bizVerify: BizVerifyService,
  ) {}

  // --------------------------------------------------------------------------
  // 업로드 (multipart) → PDF 정규화 저장
  // --------------------------------------------------------------------------
  async create(
    userId: string,
    dto: CreateDocumentDto,
    file: Express.Multer.File | undefined,
  ) {
    if (!file) {
      throw new AppException(
        'FILE_REQUIRED',
        '업로드할 파일이 필요합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const mime = file.mimetype;
    if (!ALLOWED_UPLOAD_MIME.has(mime)) {
      throw new AppException(
        'UNSUPPORTED_FILE_TYPE',
        'jpg/png/heic/webp/pdf 파일만 업로드할 수 있습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }

    // 소유자 검증
    let equipmentId: string | null = null;
    let profileId: string | null = null;
    if (dto.ownerType === DocumentOwnerType.EQUIPMENT) {
      if (!dto.equipmentId) {
        throw new AppException(
          'EQUIPMENT_ID_REQUIRED',
          'ownerType=EQUIPMENT 이면 equipmentId 가 필요합니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      const equipment = await this.prisma.equipment.findUnique({
        where: { id: dto.equipmentId },
      });
      if (!equipment || equipment.profileId !== userId) {
        throw new AppException(
          'EQUIPMENT_NOT_FOUND',
          '장비를 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      equipmentId = equipment.id;
    } else {
      profileId = userId;
    }

    // PDF 정규화 (이미지는 PDF 로 변환, 원본은 별도 보존)
    const normalized = await this.pdf.normalizeToPdf(file.buffer, mime);

    // 파일 저장: uploads/{userId}/{documentId}/
    const documentId = randomUUID();
    const ext = MIME_TO_EXT[mime];
    const originalKey = this.storage.buildKey(
      userId,
      documentId,
      `original.${ext}`,
    );
    const normalizedKey = this.storage.buildKey(
      userId,
      documentId,
      'normalized.pdf',
    );

    await this.storage.writeFile(originalKey, file.buffer);
    await this.storage.writeFile(normalizedKey, normalized);

    try {
      const doc = await this.prisma.document.create({
        data: {
          id: documentId,
          ownerType: dto.ownerType,
          profileId,
          equipmentId,
          type: dto.type,
          filePath: normalizedKey,
          originalFilePath: originalKey,
          originalFileName: file.originalname ?? null,
          fileSize: file.size ?? file.buffer.length,
          mimeType: mime,
          issuedDate: dto.issueDate ? new Date(dto.issueDate) : null,
          expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
        },
      });
      return toDocumentDto(doc);
    } catch (e) {
      // DB 실패 시 저장한 파일 정리
      await this.storage.removeDocumentDir(userId, documentId).catch(() => {});
      throw e;
    }
  }

  // --------------------------------------------------------------------------
  // 목록 (D-day 포함, 장비별 그룹 옵션)
  // --------------------------------------------------------------------------
  async list(userId: string, groupByEquipment: boolean) {
    const docs = await this.prisma.document.findMany({
      where: this.ownedWhere(userId),
      orderBy: [
        { expiryDate: { sort: 'asc', nulls: 'last' } },
        { createdAt: 'desc' },
      ],
    });
    const now = new Date();
    const items = docs.map((d) => toDocumentDto(d, now));

    if (!groupByEquipment) {
      return { items };
    }

    // 장비별 그룹 + 프로필(개인) 그룹
    const equipments = await this.prisma.equipment.findMany({
      where: { profileId: userId },
      orderBy: { createdAt: 'desc' },
    });
    const byEquipment = equipments.map((eq) => ({
      equipment: eq,
      items: items.filter((it) => it.equipmentId === eq.id),
    }));
    const profileItems = items.filter((it) => it.ownerType === 'PROFILE');
    return {
      profile: profileItems,
      equipments: byEquipment,
    };
  }

  // --------------------------------------------------------------------------
  // 만료 임박 (?days=30)
  // --------------------------------------------------------------------------
  async expiring(userId: string, days: number) {
    const now = new Date();
    const docs = await this.prisma.document.findMany({
      where: {
        ...this.ownedWhere(userId),
        expiryDate: { not: null },
      },
      orderBy: { expiryDate: 'asc' },
    });
    const items = docs
      .map((d) => toDocumentDto(d, now))
      .filter((it) => it.dday !== null && it.dday <= days);
    return { days, items };
  }

  async getOne(userId: string, id: string) {
    const doc = await this.ownedOrThrow(userId, id);
    return toDocumentDto(doc);
  }

  // --------------------------------------------------------------------------
  // 수정 (만료일/발급일/유형/상태)
  // --------------------------------------------------------------------------
  async update(userId: string, id: string, dto: UpdateDocumentDto) {
    await this.ownedOrThrow(userId, id);
    const data: Prisma.DocumentUpdateInput = {};
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.issueDate !== undefined)
      data.issuedDate = dto.issueDate ? new Date(dto.issueDate) : null;
    if (dto.expiryDate !== undefined)
      data.expiryDate = dto.expiryDate ? new Date(dto.expiryDate) : null;
    if (dto.status !== undefined) data.status = dto.status;

    const doc = await this.prisma.document.update({ where: { id }, data });
    return toDocumentDto(doc);
  }

  // --------------------------------------------------------------------------
  // 삭제 (파일도 삭제)
  // --------------------------------------------------------------------------
  async remove(userId: string, id: string) {
    await this.ownedOrThrow(userId, id);
    await this.prisma.document.delete({ where: { id } });
    // 파일은 uploads/{userId}/{documentId}/ 아래에 저장됨
    await this.storage.removeDocumentDir(userId, id).catch(() => {});
    return { deleted: true };
  }

  // --------------------------------------------------------------------------
  // 마스킹본 생성
  // --------------------------------------------------------------------------
  async mask(userId: string, id: string, dto: MaskDocumentDto) {
    const doc = await this.ownedOrThrow(userId, id);
    const source = await this.storage.readFile(doc.filePath);
    const masked = await this.pdf.applyMask(source, dto.regions);
    const maskedKey = this.storage.buildKey(userId, id, 'masked.pdf');
    await this.storage.writeFile(maskedKey, masked);
    const updated = await this.prisma.document.update({
      where: { id },
      data: { maskedFilePath: maskedKey },
    });
    return {
      ...toDocumentDto(updated),
      maskRegions: dto.regions.length,
    };
  }

  // --------------------------------------------------------------------------
  // 파일 미리보기용 경로 해석 (인증된 소유자 전용)
  //  - variant=masked: 마스킹본(PDF) — 없으면 정규화본
  //  - variant=normalized: 정규화본(PDF)
  //  - 그 외(original): 원본(이미지/PDF) — 마스킹 편집기 미리보기에 사용
  // --------------------------------------------------------------------------
  async resolveOwnedFile(
    userId: string,
    id: string,
    variant?: string,
  ): Promise<{ relPath: string; mime: string; name: string }> {
    const doc = await this.ownedOrThrow(userId, id);
    if (variant === 'masked') {
      const relPath = doc.maskedFilePath ?? doc.filePath;
      return { relPath, mime: 'application/pdf', name: `${doc.type}.pdf` };
    }
    if (variant === 'normalized') {
      return {
        relPath: doc.filePath,
        mime: 'application/pdf',
        name: `${doc.type}.pdf`,
      };
    }
    const relPath = doc.originalFilePath ?? doc.filePath;
    const mime = doc.originalFilePath
      ? (doc.mimeType ?? 'application/octet-stream')
      : 'application/pdf';
    return { relPath, mime, name: doc.originalFileName ?? `${doc.type}` };
  }

  // --------------------------------------------------------------------------
  // 진위확인
  //  - 사업자등록증: 국세청 API (키 없으면 501, 있으면 실호출)
  //  - 그 외: UNSUPPORTED + manualCheck (문서 상태 유지)
  // --------------------------------------------------------------------------
  async verify(userId: string, id: string, dto: VerifyDocumentDto) {
    const doc = await this.ownedOrThrow(userId, id);

    if (doc.type !== VERIFIABLE_TYPE) {
      const result = {
        result: 'UNSUPPORTED' as const,
        manualCheck: true,
        message:
          '이 서류 유형은 자동 진위확인을 지원하지 않습니다. 만료일 등록과 서류 열람으로 수동 확인하세요.',
        checkedAt: new Date().toISOString(),
      };
      await this.prisma.document.update({
        where: { id },
        data: { verificationResult: result },
      });
      return { document: toDocumentDto(doc), verification: result };
    }

    // 사업자등록증 실연동 (키 없으면 BizVerifyService 가 501)
    const verification = await this.bizVerify.validate({
      businessNumber: dto.businessNumber ?? '',
      openingDate: dto.openingDate ?? '',
      representativeName: dto.representativeName ?? '',
      businessName: dto.businessName,
    });
    const updated = await this.prisma.document.update({
      where: { id },
      data: {
        verificationResult: verification as unknown as Prisma.InputJsonValue,
      },
    });
    return { document: toDocumentDto(updated), verification };
  }

  // --------------------------------------------------------------------------
  // 내부: 소유권 필터 / 검증
  // --------------------------------------------------------------------------
  /** 내 서류: PROFILE 은 profileId=나, EQUIPMENT 는 소유 장비의 서류. */
  private ownedWhere(userId: string): Prisma.DocumentWhereInput {
    return {
      OR: [{ profileId: userId }, { equipment: { profileId: userId } }],
    };
  }

  private async ownedOrThrow(
    userId: string,
    id: string,
  ): Promise<DocWithEquipment> {
    const doc = await this.prisma.document.findUnique({
      where: { id },
      include: { equipment: { select: { profileId: true } } },
    });
    if (
      !doc ||
      (doc.profileId !== userId && doc.equipment?.profileId !== userId)
    ) {
      throw new AppException(
        'DOCUMENT_NOT_FOUND',
        '서류를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return doc;
  }

  /**
   * 만료 임박/만료 문서 조회 (스케줄러용): 특정 D-day 목록에 해당하는 문서.
   * ownerProfileId 는 알림 대상(PROFILE 은 소유자, EQUIPMENT 는 장비 소유자).
   */
  async findByDdayTargets(
    targetDdays: number[],
    now: Date = new Date(),
  ): Promise<Array<{ doc: Document; dday: number; ownerProfileId: string }>> {
    const docs = await this.prisma.document.findMany({
      where: {
        expiryDate: { not: null },
        status: { not: 'ARCHIVED' },
      },
      include: { equipment: { select: { profileId: true } } },
    });
    const set = new Set(targetDdays);
    const out: Array<{ doc: Document; dday: number; ownerProfileId: string }> =
      [];
    for (const doc of docs) {
      if (!doc.expiryDate) continue;
      const dday = computeDday(doc.expiryDate, now);
      if (!set.has(dday)) continue;
      const ownerProfileId = doc.profileId ?? doc.equipment?.profileId;
      if (!ownerProfileId) continue;
      out.push({ doc, dday, ownerProfileId });
    }
    return out;
  }
}
