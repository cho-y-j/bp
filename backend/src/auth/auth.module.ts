import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SMS_SERVICE } from './sms/sms.service';
import { MockSmsService } from './sms/mock-sms.service';
import { RefreshTokenService } from './refresh-token.service';
import { RefreshTokenScheduler } from './refresh-token.scheduler';

@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET'),
        signOptions: {
          // ms 문자열(예: '7d') 또는 초 단위 숫자
          expiresIn: (config.get<string>('JWT_EXPIRES_IN') ??
            '7d') as `${number}${'d' | 'h' | 'm' | 's'}`,
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    RefreshTokenService,
    RefreshTokenScheduler,
    // SMS 발송: dev/mock 구현. 실제 발송사로 교체 시 이 provider 만 바꾼다.
    { provide: SMS_SERVICE, useClass: MockSmsService },
  ],
  exports: [JwtModule, RefreshTokenService],
})
export class AuthModule {}
