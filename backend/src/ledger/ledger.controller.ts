import {
  Body,
  Controller,
  Get,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { LedgerService } from './ledger.service';
import { ReminderService } from './reminder.service';
import { AddPaymentDto } from './dto/add-payment.dto';
import { UpdateLedgerDto } from './dto/update-ledger.dto';
import { MarkTaxInvoiceDto } from './dto/mark-tax-invoice.dto';

@Controller('ledger')
export class LedgerController {
  constructor(
    private readonly ledger: LedgerService,
    private readonly reminders: ReminderService,
  ) {}

  // GET /ledger/summary?month= — 월 합계
  @Get('summary')
  summary(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
  ) {
    return this.ledger.summary(userId, month);
  }

  // GET /ledger/by-company?month= — 상대별 집계
  @Get('by-company')
  byCompany(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
  ) {
    return this.ledger.byCompany(userId, month);
  }

  // GET /ledger/entries?month=&businessId= — 개별 장부 항목(입금 기록용 id 포함)
  @Get('entries')
  entries(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.ledger.entries(userId, month, businessId);
  }

  // GET /ledger/tax-invoice-data?month=&businessId= — 홈택스 세금계산서 입력용 데이터(JSON+텍스트)
  @Get('tax-invoice-data')
  taxInvoiceData(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Query('businessId') businessId?: string,
  ) {
    return this.ledger.taxInvoiceData(userId, month, businessId);
  }

  // POST /ledger/tax-invoice-data/mark — 발행 완료 표시(이후 집계 제외)
  @Post('tax-invoice-data/mark')
  markTaxInvoiced(
    @CurrentUser('userId') userId: string,
    @Body() dto: MarkTaxInvoiceDto,
  ) {
    return this.ledger.markTaxInvoiced(userId, dto.ledgerIds);
  }

  // GET /ledger/income-report?year=&from=&to= — 연간(기간별) 소득 리포트 JSON
  @Get('income-report')
  incomeReport(
    @CurrentUser('userId') userId: string,
    @Query('year') year?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.ledger.incomeReport(userId, { year, from, to });
  }

  // GET /ledger/income-report/pdf?year=&from=&to= — 소득 리포트 PDF(인증 blob)
  @Get('income-report/pdf')
  async incomeReportPdf(
    @CurrentUser('userId') userId: string,
    @Res() res: Response,
    @Query('year') year?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ): Promise<void> {
    const buf = await this.ledger.incomeReportPdf(userId, { year, from, to });
    const label = year || `${from ?? ''}_${to ?? ''}`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="income-report-${label}.pdf"`,
    );
    res.status(HttpStatus.OK).end(buf);
  }

  // GET /ledger/statement?month= — 월간 명세서 PDF
  @Get('statement')
  async statement(
    @CurrentUser('userId') userId: string,
    @Query('month') month: string,
    @Res() res: Response,
  ): Promise<void> {
    const buf = await this.ledger.statement(userId, month);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="statement-${month}.pdf"`,
    );
    res.status(HttpStatus.OK).end(buf);
  }

  // POST /ledger/:id/payments — 부분입금
  @Post(':id/payments')
  addPayment(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AddPaymentDto,
  ) {
    return this.ledger.addPayment(userId, id, dto);
  }

  // PATCH /ledger/:id — 수금예정일 수정 + 자동 수금 안내 토글
  @Patch(':id')
  update(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateLedgerDto,
  ) {
    return this.ledger.updateLedger(userId, id, dto);
  }

  // POST /ledger/:id/remind — 수동 즉시 수금 안내(쿨다운 3일, 409)
  @Post(':id/remind')
  remind(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.reminders.manualRemind(userId, id);
  }
}
