import { Module } from '@nestjs/common';
import { DocumentsModule } from '../documents/documents.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TbmService } from './tbm.service';
import { TbmBizController, TbmWorkerController } from './tbm.controller';

@Module({
  imports: [DocumentsModule, NotificationsModule],
  controllers: [TbmBizController, TbmWorkerController],
  providers: [TbmService],
  exports: [TbmService],
})
export class TbmModule {}
