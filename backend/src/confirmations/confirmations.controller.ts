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
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { ConfirmationsService } from './confirmations.service';
import { CreateConfirmationDto } from './dto/create-confirmation.dto';
import { UpdateConfirmationDto } from './dto/update-confirmation.dto';
import { SignConfirmationDto } from './dto/sign-confirmation.dto';

/** 인증 필요 — 내 작업확인서 관리. */
@Controller('confirmations')
export class ConfirmationsController {
  constructor(private readonly confirmations: ConfirmationsService) {}

  // POST /confirmations — 작성(금액 자동계산 + ledger 자동생성)
  @Post()
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateConfirmationDto,
  ) {
    return this.confirmations.create(userId, dto);
  }

  // GET /confirmations?month=YYYY-MM — 목록 + 일자별 집계
  @Get()
  list(@CurrentUser('userId') userId: string, @Query('month') month?: string) {
    return this.confirmations.list(userId, month);
  }

  // GET /confirmations/:id
  @Get(':id')
  getOne(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.confirmations.getOne(userId, id);
  }

  // GET /confirmations/:id/pdf — 확인서 PDF
  @Get(':id/pdf')
  async pdf(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.confirmations.renderPdf(userId, id);
    sendPdf(res, buf, `confirmation-${id}.pdf`);
  }

  // POST /confirmations/:id/duplicate — 복제(날짜만 오늘로)
  @Post(':id/duplicate')
  duplicate(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.confirmations.duplicate(userId, id);
  }

  // POST /confirmations/:id/send — 전송(연동 알림 or 링크)
  @Post(':id/send')
  send(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.confirmations.send(userId, id);
  }

  // PATCH /confirmations/:id — DRAFT 만 수정(금액 변경 시 ledger 동기화)
  @Patch(':id')
  update(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateConfirmationDto,
  ) {
    return this.confirmations.update(userId, id, dto);
  }

  // DELETE /confirmations/:id — DRAFT 만 삭제
  @Delete(':id')
  remove(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.confirmations.remove(userId, id);
  }
}

/** 미가입자(외부) 접근 — 토큰 기반, 로그인 불필요. */
@Controller('public/confirmations')
export class PublicConfirmationsController {
  constructor(private readonly confirmations: ConfirmationsService) {}

  // GET /public/confirmations/:token — 열람(만료 없음, 무효화만) + viewLog
  @Public()
  @Get(':token')
  view(@Param('token') token: string, @Req() req: Request) {
    const ip = clientIp(req);
    const ua = req.headers['user-agent'] ?? '';
    return this.confirmations.publicView(token, ip, ua);
  }

  // GET /public/confirmations/:token/pdf — 서명 반영 PDF
  @Public()
  @Get(':token/pdf')
  async pdf(
    @Param('token') token: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.confirmations.publicPdf(token);
    sendPdf(res, buf, `confirmation-${token}.pdf`);
  }

  // POST /public/confirmations/:token/sign — 외부 서명 → SIGNED
  @Public()
  @Post(':token/sign')
  sign(@Param('token') token: string, @Body() dto: SignConfirmationDto) {
    return this.confirmations.publicSign(token, dto);
  }
}

function sendPdf(res: Response, buf: Buffer, filename: string): void {
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
  res.status(HttpStatus.OK).end(buf);
}

function clientIp(req: Request): string {
  const xff = req.headers['x-forwarded-for'];
  if (typeof xff === 'string' && xff.length > 0) {
    return xff.split(',')[0].trim();
  }
  return req.ip ?? req.socket?.remoteAddress ?? 'unknown';
}
