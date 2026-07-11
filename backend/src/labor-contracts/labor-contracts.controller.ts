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
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import { LaborContractsService } from './labor-contracts.service';
import { CreateLaborContractDto } from './dto/create-labor-contract.dto';
import { UpdateLaborContractDto } from './dto/update-labor-contract.dto';
import { SignLaborContractDto } from './dto/sign-labor-contract.dto';

/** 사업장 모드 — 표준근로계약서 발행·관리. 인증 필요. */
@Controller('biz/contracts')
export class LaborContractsBizController {
  constructor(private readonly service: LaborContractsService) {}

  @Post()
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateLaborContractDto,
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
    @Body() dto: UpdateLaborContractDto,
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

  // 사업장(사용자) 서명 — 전송 전 필수 선행
  @Post(':id/sign-employer')
  signEmployer(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SignLaborContractDto,
  ) {
    return this.service.signEmployer(userId, id, dto);
  }

  // 전송 — 사업장 서명 완료 후. 연결 작업자 알림 or 링크 발급.
  @Post(':id/send')
  send(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.send(userId, id);
  }

  @Get(':id/pdf')
  async pdf(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.service.renderPdfForBusiness(userId, id);
    sendPdf(res, buf, `labor-contract-${id}.pdf`);
  }
}

/** 작업자(근로자) — 내 계약서(받은/서명한) 조회·앱내 서명. 인증 필요. */
@Controller('contracts')
export class LaborContractsWorkerController {
  constructor(private readonly service: LaborContractsService) {}

  @Get()
  list(@CurrentUser('userId') userId: string) {
    return this.service.listForWorker(userId);
  }

  @Get(':id')
  getOne(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.service.getForWorker(userId, id);
  }

  @Get(':id/pdf')
  async pdf(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.service.renderPdfForWorker(userId, id);
    sendPdf(res, buf, `labor-contract-${id}.pdf`);
  }

  // 작업자 앱 내 서명(연결 작업자)
  @Post(':id/sign')
  sign(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SignLaborContractDto,
  ) {
    return this.service.signWorkerInApp(userId, id, dto);
  }
}

/** 미가입(외부) 열람·서명 — 토큰 기반, 로그인 불필요. */
@Controller('public/contracts')
export class PublicLaborContractsController {
  constructor(private readonly service: LaborContractsService) {}

  @Public()
  @Get(':token')
  view(@Param('token') token: string, @Req() req: Request) {
    const ip = clientIp(req);
    const ua = req.headers['user-agent'] ?? '';
    return this.service.publicView(token, ip, ua);
  }

  @Public()
  @Get(':token/pdf')
  async pdf(
    @Param('token') token: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.service.publicPdf(token);
    sendPdf(res, buf, `labor-contract-${token}.pdf`);
  }

  @Public()
  @Post(':token/sign')
  sign(@Param('token') token: string, @Body() dto: SignLaborContractDto) {
    return this.service.publicSign(token, dto);
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
