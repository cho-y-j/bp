import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);

  // 전역 prefix: /api (health 는 제외해 GET /health 로 직접 접근 가능)
  app.setGlobalPrefix('api', { exclude: ['health'] });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  const webOrigin = config.get<string>('WEB_ORIGIN') ?? 'http://localhost:3001';
  app.enableCors({ origin: webOrigin, credentials: true });

  const port = config.get<number>('PORT') ?? 3000;
  await app.listen(port, '0.0.0.0');

  Logger.log(`작업온 API 실행 중 → http://localhost:${port}`, 'Bootstrap');
  Logger.log(`헬스체크 → http://localhost:${port}/health`, 'Bootstrap');
}

void bootstrap();
