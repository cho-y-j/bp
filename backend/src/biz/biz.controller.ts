import {
  Body,
  Controller,
  Get,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { BizService } from './biz.service';
import { ConfirmationsService } from '../confirmations/confirmations.service';
import { SignConfirmationDto } from '../confirmations/dto/sign-confirmation.dto';
import { PaySettlementDto } from './dto/pay-settlement.dto';

/** /biz — 사업장 모드(수신함·앱내서명·정산·안전리포트). 인증 필요. */
@Controller('biz')
export class BizController {
  constructor(
    private readonly biz: BizService,
    private readonly confirmations: ConfirmationsService,
  ) {}

  // GET /biz/inbox — 수신 확인서 목록·상태
  @Get('inbox')
  inbox(@CurrentUser('userId') userId: string) {
    return this.biz.inbox(userId);
  }

  // GET /biz/confirmations/:id — 수신 확인서 상세(소유자+자기 사업장 대상만)
  @Get('confirmations/:id')
  confirmationDetail(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.confirmations.bizConfirmationDetail(userId, id);
  }

  // POST /biz/confirmations/:id/sign — 앱 내 서명(사업장 소유자)
  @Post('confirmations/:id/sign')
  sign(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SignConfirmationDto,
  ) {
    return this.confirmations.bizSign(userId, id, dto);
  }

  // GET /biz/settlements?month= — 작업자별 미지급 집계
  @Get('settlements')
  settlements(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
  ) {
    return this.biz.settlements(userId, month);
  }

  // POST /biz/settlements/pay — 지급 처리(각 ledger 반영)
  @Post('settlements/pay')
  pay(@CurrentUser('userId') userId: string, @Body() dto: PaySettlementDto) {
    return this.biz.pay(userId, dto);
  }

  // GET /biz/safety-report?month= — 안전관리 이행 리포트 PDF
  @Get('safety-report')
  async safetyReport(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.biz.safetyReport(userId, month);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="safety-report-${month}.pdf"`,
    );
    res.status(HttpStatus.OK).end(buf);
  }
}
