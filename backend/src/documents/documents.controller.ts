import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import type { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AppException } from '../common/errors';
import { FileStorageService } from './file-storage.service';
import { DocumentsService } from './documents.service';
import { CreateDocumentDto } from './dto/create-document.dto';
import { UpdateDocumentDto } from './dto/update-document.dto';
import { MaskDocumentDto } from './dto/mask-document.dto';
import { VerifyDocumentDto } from './dto/verify-document.dto';

const MAX_UPLOAD_BYTES = 20 * 1024 * 1024; // 20MB

@Controller('documents')
export class DocumentsController {
  constructor(
    private readonly documents: DocumentsService,
    private readonly storage: FileStorageService,
  ) {}

  // POST /documents — 업로드(multipart) → PDF 정규화
  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_UPLOAD_BYTES },
    }),
  )
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateDocumentDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.documents.create(userId, dto, file);
  }

  // GET /documents?groupByEquipment=true — 목록(D-day 포함)
  @Get()
  list(
    @CurrentUser('userId') userId: string,
    @Query('groupByEquipment') groupByEquipment?: string,
  ) {
    return this.documents.list(userId, groupByEquipment === 'true');
  }

  // GET /documents/expiring?days=30 — 만료 임박
  @Get('expiring')
  expiring(
    @CurrentUser('userId') userId: string,
    @Query('days') days?: string,
  ) {
    const parsed = days ? parseInt(days, 10) : 30;
    const d = Number.isFinite(parsed) && parsed > 0 ? parsed : 30;
    return this.documents.expiring(userId, d);
  }

  @Get(':id')
  getOne(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.documents.getOne(userId, id);
  }

  // GET /documents/:id/file?variant=original|normalized|masked — 인증 소유자 미리보기
  @Get(':id/file')
  async file(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Query('variant') variant: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const { relPath, mime, name } = await this.documents.resolveOwnedFile(
      userId,
      id,
      variant,
    );
    const exists = await this.storage.fileExists(relPath);
    if (!exists) {
      throw new AppException(
        'FILE_NOT_FOUND',
        '파일을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const encoded = encodeURIComponent(name);
    res.setHeader('Content-Type', mime);
    res.setHeader(
      'Content-Disposition',
      `inline; filename="preview"; filename*=UTF-8''${encoded}`,
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

  // PATCH /documents/:id — 만료일 등 수정
  @Patch(':id')
  update(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDocumentDto,
  ) {
    return this.documents.update(userId, id, dto);
  }

  // DELETE /documents/:id — 파일도 삭제
  @Delete(':id')
  remove(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.documents.remove(userId, id);
  }

  // POST /documents/:id/mask — 마스킹본 생성
  @Post(':id/mask')
  mask(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MaskDocumentDto,
  ) {
    return this.documents.mask(userId, id, dto);
  }

  // POST /documents/:id/verify — 진위확인
  @Post(':id/verify')
  verify(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: VerifyDocumentDto,
  ) {
    return this.documents.verify(userId, id, dto);
  }
}
