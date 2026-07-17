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
import { MarkWageStatementDto } from './dto/mark-wage-statement.dto';

/** /biz — 사업장 모드(수신함·앱내서명·정산·안전리포트). 인증 필요. */
@Controller('biz')
export class BizController {
  constructor(
    private readonly biz: BizService,
    private readonly confirmations: ConfirmationsService,
  ) {}

  // GET /biz/inbox?businessId= — 수신 확인서 목록·상태(businessId 지정 시 해당 사업장만)
  @Get('inbox')
  inbox(
    @CurrentUser('userId') userId: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.biz.inbox(userId, businessId);
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

  // GET /biz/settlements?month=&businessId= — 작업자별 미지급 집계
  @Get('settlements')
  settlements(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.biz.settlements(userId, month, businessId);
  }

  // POST /biz/settlements/pay — 지급 처리(각 ledger 반영)
  @Post('settlements/pay')
  pay(@CurrentUser('userId') userId: string, @Body() dto: PaySettlementDto) {
    return this.biz.pay(userId, dto);
  }

  // GET /biz/payment-badge?businessId= — 내 사업장 지급 평판 배지(본인용, 개선 안내 포함)
  @Get('payment-badge')
  paymentBadge(
    @CurrentUser('userId') userId: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.biz.paymentBadge(userId, businessId);
  }

  // GET /biz/site-costs?from=&to=&businessId= — 현장별 인건비 집계 (SIGNED 확인서)
  @Get('site-costs')
  siteCosts(
    @CurrentUser('userId') userId: string,
    @Query('from') from: string,
    @Query('to') to: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.biz.siteCosts(userId, from, to, businessId);
  }

  // GET /biz/site-costs/pdf?from=&to=&businessId= — 현장별 인건비 집계 PDF(발주처 제출용)
  @Get('site-costs/pdf')
  async siteCostsPdf(
    @CurrentUser('userId') userId: string,
    @Query('from') from: string,
    @Query('to') to: string,
    @Res() res: Response,
    @Query('businessId') businessId?: string,
  ): Promise<void> {
    const buf = await this.biz.siteCostsPdf(userId, from, to, businessId);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="site-costs-${from}_${to}.pdf"`,
    );
    res.status(HttpStatus.OK).end(buf);
  }

  // GET /biz/wage-statement?month=&businessId= — 일용근로소득 지급명세서 도우미
  @Get('wage-statement')
  wageStatement(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.biz.wageStatement(userId, month, businessId);
  }

  // POST /biz/wage-statement/mark — 월 마감 표시(멱등)
  @Post('wage-statement/mark')
  markWageStatement(
    @CurrentUser('userId') userId: string,
    @Body() dto: MarkWageStatementDto,
  ) {
    return this.biz.wageStatementMark(userId, dto.month, dto.businessId);
  }

  // GET /biz/today-attendance?businessId= — 오늘의 출역 현황판
  @Get('today-attendance')
  todayAttendance(
    @CurrentUser('userId') userId: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.biz.todayAttendance(userId, businessId);
  }

  // GET /biz/safety-report?month=&businessId= — 안전관리 이행 리포트 PDF
  @Get('safety-report')
  async safetyReport(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Res() res: Response,
    @Query('businessId') businessId?: string,
  ): Promise<void> {
    const buf = await this.biz.safetyReport(userId, month, businessId);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="safety-report-${month}.pdf"`,
    );
    res.status(HttpStatus.OK).end(buf);
  }
}
