import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { nanoid } from 'nanoid';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { computeDday, expiryStateFromDday } from '../common/dday.util';
import { CreateShareDto } from './dto/create-share.dto';

const DEFAULT_EXPIRES_DAYS = 7;
const MAX_EXPIRES_DAYS = 30;
const TOKEN_LENGTH = 32;
const DAY_MS = 24 * 60 * 60 * 1000;
const VIEW_LOG_CAP = 50; // 공개 열람 로그 최대 보관 개수 (초과분 drop, 총계는 viewCount)

interface ViewLog {
  at: string;
  ip: string;
  ua: string;
}

@Injectable()
export class DocumentSharesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  // --------------------------------------------------------------------------
  // 공유 생성
  // --------------------------------------------------------------------------
  async create(userId: string, dto: CreateShareDto) {
    // 중복 제거
    const documentIds = [...new Set(dto.documentIds)];

    // 전부 본인 서류인지 검증
    const docs = await this.prisma.document.findMany({
      where: {
        id: { in: documentIds },
        OR: [{ profileId: userId }, { equipment: { profileId: userId } }],
      },
      select: { id: true },
    });
    if (docs.length !== documentIds.length) {
      throw new AppException(
        'DOCUMENT_NOT_FOUND',
        '본인 소유가 아니거나 존재하지 않는 서류가 포함되어 있습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }

    const days = Math.min(
      dto.expiresInDays ?? DEFAULT_EXPIRES_DAYS,
      MAX_EXPIRES_DAYS,
    );
    const expiresAt = new Date(Date.now() + days * DAY_MS);
    const token = nanoid(TOKEN_LENGTH);

    // 서류별 useOriginal 매핑 (미지정은 false = 마스킹본 우선)
    const perDoc = new Map<string, boolean>();
    for (const p of dto.perDocument ?? []) {
      perDoc.set(p.documentId, p.useOriginal);
    }

    const share = await this.prisma.documentShare.create({
      data: {
        ownerId: userId,
        shareToken: token,
        expiresAt,
        useMasked: true, // 묶음 기본값: 마스킹본 우선
        documents: {
          create: documentIds.map((id) => ({
            documentId: id,
            useOriginal: perDoc.get(id) ?? false,
          })),
        },
      },
    });

    const baseUrl =
      this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:3001';
    return {
      id: share.id,
      shareToken: token,
      url: `${baseUrl.replace(/\/$/, '')}/s/${token}`,
      expiresAt,
      documentCount: documentIds.length,
    };
  }

  // --------------------------------------------------------------------------
  // 내 공유 목록 (+열람 로그)
  // --------------------------------------------------------------------------
  async listMine(userId: string) {
    const shares = await this.prisma.documentShare.findMany({
      where: { ownerId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        documents: {
          include: {
            document: {
              select: { id: true, type: true, maskedFilePath: true },
            },
          },
        },
      },
    });
    const now = new Date();
    return {
      items: shares.map((s) => ({
        id: s.id,
        shareToken: s.shareToken,
        expiresAt: s.expiresAt,
        revokedAt: s.revokedAt,
        active: !s.revokedAt && s.expiresAt.getTime() > now.getTime(),
        createdAt: s.createdAt,
        viewCount: s.viewCount, // 누적 총계(카운터). viewLogs 는 최근 50개만.
        viewLogs: s.viewLogs,
        documents: s.documents.map((sd) => ({
          documentId: sd.documentId,
          type: sd.document.type,
          useOriginal: sd.useOriginal,
          servesMasked: !sd.useOriginal && !!sd.document.maskedFilePath,
        })),
      })),
    };
  }

  // --------------------------------------------------------------------------
  // 즉시 무효화
  // --------------------------------------------------------------------------
  async revoke(userId: string, id: string) {
    const share = await this.prisma.documentShare.findUnique({ where: { id } });
    if (!share || share.ownerId !== userId) {
      throw new AppException(
        'SHARE_NOT_FOUND',
        '공유를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (share.revokedAt) {
      return { revoked: true, alreadyRevoked: true };
    }
    await this.prisma.documentShare.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
    return { revoked: true };
  }

  // --------------------------------------------------------------------------
  // 공개 열람 (@Public) — 메타 목록 + 열람 로그 append
  // --------------------------------------------------------------------------
  async publicView(token: string, ip: string, ua: string) {
    const share = await this.loadValidShare(token);

    // 열람 로그 append (증거 기록)
    const log: ViewLog = {
      at: new Date().toISOString(),
      ip: ip || 'unknown',
      ua: (ua || 'unknown').slice(0, 300),
    };
    const logs = Array.isArray(share.viewLogs) ? share.viewLogs : [];
    // 최근 VIEW_LOG_CAP 개만 유지(오래된 것 drop), 누적 총계는 viewCount 카운터로.
    const capped = [...logs, log].slice(-VIEW_LOG_CAP);
    await this.prisma.documentShare.update({
      where: { id: share.id },
      data: {
        viewLogs: capped as unknown as Prisma.InputJsonValue[],
        viewCount: { increment: 1 },
      },
    });

    const now = new Date();
    return {
      shareToken: token,
      expiresAt: share.expiresAt,
      documents: share.documents.map((sd) => {
        const d = sd.document;
        const dday = d.expiryDate ? computeDday(d.expiryDate, now) : null;
        const servesMasked = !sd.useOriginal && !!d.maskedFilePath;
        return {
          documentId: d.id,
          type: d.type,
          issuedDate: d.issuedDate,
          expiryDate: d.expiryDate,
          dday,
          status: expiryStateFromDday(dday),
          masked: servesMasked,
          fileUrl: `/api/public/shares/${token}/files/${d.id}`,
        };
      }),
    };
  }

  // --------------------------------------------------------------------------
  // 공개 파일 스트림용: 정책 적용된 파일 경로 해석 (@Public)
  //  - useOriginal=true → 원본(정규화본, 비마스킹)
  //  - 그 외 → 마스킹본이 있으면 마스킹본, 없으면 정규화본
  // --------------------------------------------------------------------------
  async resolvePublicFile(
    token: string,
    documentId: string,
  ): Promise<{ relPath: string; downloadName: string }> {
    const share = await this.loadValidShare(token);
    const entry = share.documents.find((sd) => sd.documentId === documentId);
    if (!entry) {
      throw new AppException(
        'DOCUMENT_NOT_IN_SHARE',
        '이 공유에 포함되지 않은 서류입니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const doc = entry.document;
    const relPath =
      entry.useOriginal || !doc.maskedFilePath
        ? doc.filePath
        : doc.maskedFilePath;
    // 공유는 항상 PDF 정규화본/마스킹본을 제공한다.
    const downloadName = `${doc.type}.pdf`;
    return { relPath, downloadName };
  }

  // --------------------------------------------------------------------------
  // 내부: 유효한 공유 로드 (만료/무효화 검증)
  // --------------------------------------------------------------------------
  private async loadValidShare(token: string) {
    const share = await this.prisma.documentShare.findUnique({
      where: { shareToken: token },
      include: {
        documents: {
          include: {
            document: {
              select: {
                id: true,
                type: true,
                filePath: true,
                maskedFilePath: true,
                issuedDate: true,
                expiryDate: true,
              },
            },
          },
        },
      },
    });
    if (!share) {
      throw new AppException(
        'SHARE_NOT_FOUND',
        '공유 링크를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (share.revokedAt) {
      throw new AppException(
        'SHARE_REVOKED',
        '무효화된 공유 링크입니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    if (share.expiresAt.getTime() <= Date.now()) {
      throw new AppException(
        'SHARE_EXPIRED',
        '유효기간이 지난 공유 링크입니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    return share;
  }
}
