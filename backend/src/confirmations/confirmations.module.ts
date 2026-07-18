import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PartnersModule } from '../partners/partners.module';
import { ConfirmationsService } from './confirmations.service';
import {
  ConfirmationsController,
  PublicConfirmationsController,
} from './confirmations.controller';

@Module({
  imports: [DocumentsModule, NotificationsModule, PartnersModule],
  controllers: [ConfirmationsController, PublicConfirmationsController],
  providers: [ConfirmationsService],
  exports: [ConfirmationsService],
})
export class ConfirmationsModule {}
