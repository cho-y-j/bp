import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Public } from '../common/decorators/public.decorator';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  // GET /health — DB 연결 확인 포함 (인증 불필요)
  @Public()
  @Get()
  async check() {
    let db: 'up' | 'down' = 'down';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      db = 'up';
    } catch {
      db = 'down';
    }

    const body = {
      status: db === 'up' ? 'ok' : 'error',
      service: 'jakeobon-api',
      timestamp: new Date().toISOString(),
      checks: { database: db },
    };

    if (db === 'down') {
      throw new ServiceUnavailableException(body);
    }
    return body;
  }
}
