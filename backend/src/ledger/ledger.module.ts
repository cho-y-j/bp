import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { LedgerController } from './ledger.controller';
import { LedgerService } from './ledger.service';
import { LedgerDueScheduler } from './ledger-due.scheduler';
import { ReminderService } from './reminder.service';
import { BadgeService } from './badge.service';

@Module({
  imports: [DocumentsModule, NotificationsModule],
  controllers: [LedgerController],
  providers: [LedgerService, LedgerDueScheduler, ReminderService, BadgeService],
  exports: [LedgerService, ReminderService, BadgeService],
})
export class LedgerModule {}
