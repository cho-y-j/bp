import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JobsService } from './jobs.service';
import { CreateJobDto } from './dto/create-job.dto';
import { StartJobDto } from './dto/start-job.dto';
import { CompleteJobDto } from './dto/complete-job.dto';

const MAX_PHOTO_BYTES = 20 * 1024 * 1024;

@Controller('jobs')
export class JobsController {
  constructor(private readonly jobs: JobsService) {}

  // POST /jobs — 작업 지시/예약 (사업장 모드)
  @Post()
  create(@CurrentUser('userId') userId: string, @Body() dto: CreateJobDto) {
    return this.jobs.create(userId, dto);
  }

  // GET /jobs?month=YYYY-MM — 양측 조회
  @Get()
  list(@CurrentUser('userId') userId: string, @Query('month') month?: string) {
    return this.jobs.list(userId, month);
  }

  // POST /jobs/:id/confirm — 작업자 수락(+서류 유효성 확인)
  @Post(':id/confirm')
  confirm(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.jobs.confirm(userId, id);
  }

  // POST /jobs/:id/start — 시작(GPS + 컨디션체크)
  @Post(':id/start')
  start(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: StartJobDto,
  ) {
    return this.jobs.start(userId, id, dto);
  }

  // POST /jobs/:id/complete — 완료(GPS + 사진 경로)
  @Post(':id/complete')
  complete(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CompleteJobDto,
  ) {
    return this.jobs.complete(userId, id, dto);
  }

  // POST /jobs/:id/photos — 사진 업로드(multipart)
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
    return this.jobs.uploadPhotos(userId, id, files);
  }
}
