import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import {
  DocumentSharesController,
  PublicSharesController,
} from './document-shares.controller';
import { DocumentSharesService } from './document-shares.service';

@Module({
  imports: [DocumentsModule], // FileStorageService 재사용
  controllers: [DocumentSharesController, PublicSharesController],
  providers: [DocumentSharesService],
})
export class DocumentSharesModule {}
