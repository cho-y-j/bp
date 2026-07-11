import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { LaborContractsService } from './labor-contracts.service';
import {
  LaborContractsBizController,
  LaborContractsWorkerController,
  PublicLaborContractsController,
} from './labor-contracts.controller';

@Module({
  imports: [DocumentsModule, NotificationsModule],
  controllers: [
    LaborContractsBizController,
    LaborContractsWorkerController,
    PublicLaborContractsController,
  ],
  providers: [LaborContractsService],
  exports: [LaborContractsService],
})
export class LaborContractsModule {}
