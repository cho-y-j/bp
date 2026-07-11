import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './health/health.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { EquipmentsModule } from './equipments/equipments.module';
import { DocumentsModule } from './documents/documents.module';
import { DocumentSharesModule } from './document-shares/document-shares.module';
import { ConfirmationsModule } from './confirmations/confirmations.module';
import { TeamsModule } from './teams/teams.module';
import { LaborContractsModule } from './labor-contracts/labor-contracts.module';
import { TbmModule } from './tbm/tbm.module';
import { LedgerModule } from './ledger/ledger.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ConnectionsModule } from './connections/connections.module';
import { JobsModule } from './jobs/jobs.module';
import { BizModule } from './biz/biz.module';
import { SafetyModule } from './safety/safety.module';
import { validateEnv } from './common/env.validation';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    ScheduleModule.forRoot(), // 만료 알림 크론 (매일 09:00)
    PrismaModule,
    HealthModule,
    AuthModule,
    UsersModule,
    EquipmentsModule,
    DocumentsModule,
    DocumentSharesModule,
    ConfirmationsModule,
    TeamsModule,
    LaborContractsModule,
    TbmModule,
    LedgerModule,
    NotificationsModule,
    ConnectionsModule,
    JobsModule,
    BizModule,
    SafetyModule,
  ],
  providers: [
    // 전역 성공 봉투 { data }
    { provide: APP_INTERCEPTOR, useClass: ResponseInterceptor },
    // 전역 에러 봉투 { error: { code, message } }
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    // 전역 JWT 인증 (@Public() 예외)
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule {}
