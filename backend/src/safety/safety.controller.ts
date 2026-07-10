import {
  Body,
  Controller,
  ForbiddenException,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SafetyService } from './safety.service';
import { SimulateHeatwaveDto } from './dto/simulate-heatwave.dto';

@Controller('safety')
export class SafetyController {
  constructor(
    private readonly safety: SafetyService,
    private readonly config: ConfigService,
  ) {}

  // POST /safety/:logId/ack — 작업자 "확인" (최초 1회, 재확인 409)
  @Post(':logId/ack')
  ack(
    @CurrentUser('userId') userId: string,
    @Param('logId', ParseUUIDPipe) logId: string,
  ) {
    return this.safety.ack(userId, logId);
  }

  // POST /safety/simulate-heatwave — dev 전용 폭염 플로우 트리거(@Public 아님)
  @Post('simulate-heatwave')
  simulate(
    @CurrentUser('userId') userId: string,
    @Body() dto: SimulateHeatwaveDto,
  ) {
    const env = this.config.get<string>('NODE_ENV') ?? 'development';
    if (env === 'production') {
      throw new ForbiddenException({
        code: 'DEV_ONLY',
        message: '개발 환경에서만 사용할 수 있습니다.',
      });
    }
    return this.safety.simulateHeatwave(userId, dto.businessId);
  }
}
