import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { DocumentsController } from './documents.controller';
import { DocumentsService } from './documents.service';
import { FileStorageService } from './file-storage.service';
import { PdfService } from './pdf.service';
import { BizVerifyService } from './verify/bizverify.service';
import { DocumentExpiryScheduler } from './document-expiry.scheduler';

@Module({
  imports: [NotificationsModule],
  controllers: [DocumentsController],
  providers: [
    DocumentsService,
    FileStorageService,
    PdfService,
    BizVerifyService,
    DocumentExpiryScheduler,
  ],
  exports: [DocumentsService, FileStorageService, PdfService],
})
export class DocumentsModule {}
