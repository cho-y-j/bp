import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ConfirmationsModule } from '../confirmations/confirmations.module';
import { LedgerModule } from '../ledger/ledger.module';
import { BizController } from './biz.controller';
import { BizService } from './biz.service';

@Module({
  imports: [
    DocumentsModule,
    NotificationsModule,
    ConfirmationsModule,
    LedgerModule,
  ],
  controllers: [BizController],
  providers: [BizService],
})
export class BizModule {}
