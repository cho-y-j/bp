import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { SafetyController } from './safety.controller';
import { SafetyService } from './safety.service';
import { WeatherService } from './weather.service';
import { HeatwaveScheduler } from './heatwave.scheduler';

@Module({
  imports: [NotificationsModule],
  controllers: [SafetyController],
  providers: [SafetyService, WeatherService, HeatwaveScheduler],
  exports: [SafetyService],
})
export class SafetyModule {}
