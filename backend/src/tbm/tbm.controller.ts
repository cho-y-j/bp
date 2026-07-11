import {
  Body,
  Controller,
  Delete,
  Get,
  HttpStatus,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Res,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { TbmService } from './tbm.service';
import { CreateTbmRecordDto } from './dto/create-tbm-record.dto';
import { UpdateTbmRecordDto } from './dto/update-tbm-record.dto';
import { CreateTbmPresetDto } from './dto/create-tbm-preset.dto';

const MAX_PHOTO_BYTES = 20 * 1024 * 1024;

/** 사업장 모드 — 간편 TBM 기록·프리셋. 인증 필요. */
@Controller('biz/tbm')
export class TbmBizController {
  constructor(private readonly service: TbmService) {}

  // ── 프리셋 (사업장 커스텀 문구) — :id 라우트보다 먼저 선언(경로 충돌 방지) ──
  @Get('presets')
  listPresets(
    @CurrentUser('userId') userId: string,
    @Query('businessId', ParseUUIDPipe) businessId: string,
  ) {
    return this.service.listPresets(userId, businessId);
  }

  @Post('presets')
  createPreset(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateTbmPresetDto,
  ) {
    return this.service.createPreset(userId, dto);
  }

  @Delete('presets/:id')
  removePreset(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.removePreset(userId, id);
  }

  // ── TBM 기록 ──
  @Post()
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateTbmRecordDto,
  ) {
    return this.service.create(userId, dto);
  }

  @Get()
  list(@CurrentUser('userId') userId: string) {
    return this.service.listForBusiness(userId);
  }

  @Get(':id')
  getOne(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.getForBusiness(userId, id);
  }

  @Patch(':id')
  update(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateTbmRecordDto,
  ) {
    return this.service.update(userId, id, dto);
  }

  @Delete(':id')
  remove(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.remove(userId, id);
  }

  @Post(':id/photos')
  @UseInterceptors(
    FilesInterceptor('files', 10, {
      storage: memoryStorage(),
      limits: { fileSize: MAX_PHOTO_BYTES },
    }),
  )
  photos(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.service.uploadPhotos(userId, id, files);
  }

  @Get(':id/photos/:index')
  async photo(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('index', ParseIntPipe) index: number,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, mime } = await this.service.getPhotoForBusiness(
      userId,
      id,
      index,
    );
    sendImage(res, buffer, mime);
  }
}

/** 작업자(참석자) — 받은 TBM 목록·확인. 인증 필요. */
@Controller('tbm')
export class TbmWorkerController {
  constructor(private readonly service: TbmService) {}

  @Get()
  list(@CurrentUser('userId') userId: string) {
    return this.service.listForWorker(userId);
  }

  // 참석자 확인(ack) — 최초 1회, 재확인 409
  @Post(':attendeeId/ack')
  ack(
    @CurrentUser('userId') userId: string,
    @Param('attendeeId', ParseUUIDPipe) attendeeId: string,
  ) {
    return this.service.ack(userId, attendeeId);
  }

  @Get(':id/photos/:index')
  async photo(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('index', ParseIntPipe) index: number,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, mime } = await this.service.getPhotoForWorker(
      userId,
      id,
      index,
    );
    sendImage(res, buffer, mime);
  }
}

function sendImage(res: Response, buffer: Buffer, mime: string): void {
  res.setHeader('Content-Type', mime);
  res.setHeader('Cache-Control', 'private, max-age=60');
  res.status(HttpStatus.OK).end(buffer);
}
