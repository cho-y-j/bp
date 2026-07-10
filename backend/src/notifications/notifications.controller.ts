import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@Controller()
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  // GET /notifications?unread=true — 내 알림 목록
  @Get('notifications')
  list(
    @CurrentUser('userId') userId: string,
    @Query('unread') unread?: string,
  ) {
    return this.notifications.list(userId, unread === 'true');
  }

  // POST /notifications/:id/read — 읽음 처리
  @Post('notifications/:id/read')
  read(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.markRead(userId, id);
  }

  // POST /device-tokens — FCM 디바이스 토큰 등록
  @Post('device-tokens')
  register(
    @CurrentUser('userId') userId: string,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.notifications.registerDeviceToken(
      userId,
      dto.token,
      dto.platform,
    );
  }
}
