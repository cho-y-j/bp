import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { AppException } from '../common/errors';
import { FileStorageService } from '../documents/file-storage.service';
import { DocumentSharesService } from './document-shares.service';
import { CreateShareDto } from './dto/create-share.dto';

/** 인증 필요 — 내 서류 공유 관리. */
@Controller('document-shares')
export class DocumentSharesController {
  constructor(private readonly shares: DocumentSharesService) {}

  // POST /document-shares — 선택 묶음 공유 생성
  @Post()
  create(@CurrentUser('userId') userId: string, @Body() dto: CreateShareDto) {
    return this.shares.create(userId, dto);
  }

  // GET /document-shares — 내 공유 목록 + 열람 로그
  @Get()
  listMine(@CurrentUser('userId') userId: string) {
    return this.shares.listMine(userId);
  }

  // DELETE /document-shares/:id — 즉시 무효화
  @Delete(':id')
  revoke(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.shares.revoke(userId, id);
  }
}

/** 미가입자(외부) 접근 — 토큰 기반, 로그인 불필요. */
@Controller('public/shares')
export class PublicSharesController {
  constructor(
    private readonly shares: DocumentSharesService,
    private readonly storage: FileStorageService,
  ) {}

  // GET /public/shares/:token — 유효기간 검증 → 서류 메타 목록 + 열람 로그 기록
  @Public()
  @Get(':token')
  view(@Param('token') token: string, @Req() req: Request) {
    const ip = this.clientIp(req);
    const ua = req.headers['user-agent'] ?? '';
    return this.shares.publicView(token, ip, ua);
  }

  // GET /public/shares/:token/files/:documentId — 파일 스트림(마스킹 정책 적용)
  @Public()
  @Get(':token/files/:documentId')
  async file(
    @Param('token') token: string,
    @Param('documentId', ParseUUIDPipe) documentId: string,
    @Query('download') download: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const { relPath, downloadName } = await this.shares.resolvePublicFile(
      token,
      documentId,
    );
    const exists = await this.storage.fileExists(relPath);
    if (!exists) {
      throw new AppException(
        'FILE_NOT_FOUND',
        '파일을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }

    // download=1 → 첨부(다운로드) 강제, 그 외 → inline(브라우저 미리보기).
    const isDownload = download === '1' || download === 'true';
    const disposition = isDownload ? 'attachment' : 'inline';
    // Content-Disposition: 한글 파일명은 RFC 5987 (filename*) 로, ASCII 폴백 병행
    const asciiFallback = 'document.pdf';
    const encoded = encodeURIComponent(downloadName);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `${disposition}; filename="${asciiFallback}"; filename*=UTF-8''${encoded}`,
    );

    const stream = this.storage.createReadStream(relPath);
    stream.on('error', () => {
      if (!res.headersSent) {
        res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
          error: { code: 'FILE_READ_ERROR', message: '파일 읽기 오류.' },
        });
      } else {
        res.end();
      }
    });
    stream.pipe(res);
  }

  /** 프록시 뒤(X-Forwarded-For)를 고려한 클라이언트 IP. */
  private clientIp(req: Request): string {
    const xff = req.headers['x-forwarded-for'];
    if (typeof xff === 'string' && xff.length > 0) {
      return xff.split(',')[0].trim();
    }
    return req.ip ?? req.socket?.remoteAddress ?? 'unknown';
  }
}
