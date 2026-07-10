import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import {
  BusinessesController,
  ConnectionsController,
  WorkersController,
} from './connections.controller';
import { BusinessesService } from './businesses.service';
import { ConnectionsService } from './connections.service';
import { PromotionService } from './promotion.service';

@Module({
  imports: [NotificationsModule],
  controllers: [BusinessesController, WorkersController, ConnectionsController],
  providers: [BusinessesService, ConnectionsService, PromotionService],
  exports: [PromotionService, BusinessesService],
})
export class ConnectionsModule {}
