import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { FcmService } from './fcm.service';
import { ALIMTALK_SERVICE } from './alimtalk/alimtalk.types';
import { SolapiAdapter } from './alimtalk/solapi.adapter';

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    FcmService,
    // 알림톡 어댑터: Solapi 구현. 실제 발송사 교체 시 이 provider 만 바꾼다.
    { provide: ALIMTALK_SERVICE, useClass: SolapiAdapter },
  ],
  exports: [NotificationsService],
})
export class NotificationsModule {}
