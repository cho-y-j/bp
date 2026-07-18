import { Module } from '@nestjs/common';
import { PartnersService } from './partners.service';
import { PartnersController } from './partners.controller';

@Module({
  controllers: [PartnersController],
  providers: [PartnersService],
  exports: [PartnersService], // 확인서 서비스의 자동 수집 훅에서 주입
})
export class PartnersModule {}
