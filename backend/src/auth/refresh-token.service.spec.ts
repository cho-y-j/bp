import {
  RefreshTokenService,
  REFRESH_TTL_MS,
  MAX_ACTIVE_REFRESH,
} from './refresh-token.service';
import { AppException } from '../common/errors';

/**
 * RefreshTokenService 단위 테스트: 회전 · 재사용 감지 · 상한 · 슬라이딩 만료.
 * Prisma 는 인메모리 페이크로 대체(실제 회전/폐기 상태 변화를 검증).
 */

interface Row {
  id: string;
  profileId: string;
  tokenHash: string;
  expiresAt: Date;
  lastUsedAt: Date | null;
  deviceId: string | null;
  revokedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

function makeFakePrisma() {
  const rows: Row[] = [];
  let seq = 0;

  function matchWhere(r: Row, where: Record<string, unknown>): boolean {
    for (const [k, v] of Object.entries(where)) {
      if (k === 'OR') {
        const ors = v as Record<string, unknown>[];
        if (!ors.some((o) => matchWhere(r, o))) return false;
        continue;
      }
      if (k === 'id' && typeof v === 'object' && v !== null && 'in' in v) {
        if (!(v as { in: string[] }).in.includes(r.id)) return false;
        continue;
      }
      const cur = (r as unknown as Record<string, unknown>)[k];
      if (v !== null && typeof v === 'object') {
        const cond = v as Record<string, unknown>;
        if ('gt' in cond && !((cur as Date) > (cond.gt as Date))) return false;
        if ('lt' in cond && !((cur as Date) < (cond.lt as Date))) return false;
      } else {
        if (cur !== v) return false;
      }
    }
    return true;
  }

  const prisma = {
    refreshToken: {
      create: jest.fn(({ data }: { data: Partial<Row> }) => {
        const row: Row = {
          id: `rt-${++seq}`,
          profileId: data.profileId!,
          tokenHash: data.tokenHash!,
          expiresAt: data.expiresAt!,
          lastUsedAt: null,
          deviceId: data.deviceId ?? null,
          revokedAt: null,
          createdAt: new Date(Date.now() + seq), // 생성 순서 보존
          updatedAt: new Date(),
        };
        rows.push(row);
        return Promise.resolve(row);
      }),
      findUnique: jest.fn(({ where }: { where: { tokenHash: string } }) =>
        Promise.resolve(
          rows.find((r) => r.tokenHash === where.tokenHash) ?? null,
        ),
      ),
      findMany: jest.fn(
        ({
          where,
          orderBy,
        }: {
          where: Record<string, unknown>;
          orderBy?: { createdAt: 'asc' | 'desc' };
          select?: unknown;
        }) => {
          let res = rows.filter((r) => matchWhere(r, where));
          if (orderBy?.createdAt === 'asc') {
            res = res
              .slice()
              .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
          }
          return Promise.resolve(res.map((r) => ({ id: r.id })));
        },
      ),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<Row>;
        }) => {
          const row = rows.find((r) => r.id === where.id)!;
          Object.assign(row, data);
          return Promise.resolve(row);
        },
      ),
      updateMany: jest.fn(
        ({
          where,
          data,
        }: {
          where: Record<string, unknown>;
          data: Partial<Row>;
        }) => {
          const targets = rows.filter((r) => matchWhere(r, where));
          targets.forEach((r) => Object.assign(r, data));
          return Promise.resolve({ count: targets.length });
        },
      ),
      deleteMany: jest.fn(({ where }: { where: Record<string, unknown> }) => {
        const targets = rows.filter((r) => matchWhere(r, where));
        for (const t of targets) rows.splice(rows.indexOf(t), 1);
        return Promise.resolve({ count: targets.length });
      }),
    },
  };
  return { prisma, rows };
}

function makeService() {
  const { prisma, rows } = makeFakePrisma();
  const service = new RefreshTokenService(prisma as never);
  return { service, prisma, rows };
}

describe('RefreshTokenService', () => {
  it('issue: 불투명 64자 토큰 + sha256 해시 저장 + 만료 180일', async () => {
    const { service, rows } = makeService();
    const now = new Date('2026-07-17T00:00:00Z');
    const { token, expiresAt } = await service.issue('p1', 'dev-1', now);
    expect(token).toMatch(/^[0-9a-f]{64}$/);
    expect(rows).toHaveLength(1);
    expect(rows[0].tokenHash).toBe(RefreshTokenService.hash(token));
    expect(rows[0].tokenHash).not.toBe(token); // 평문 저장 금지
    expect(expiresAt.getTime()).toBe(now.getTime() + REFRESH_TTL_MS);
  });

  it('rotate: 유효 토큰 → 기존 폐기 + 새 토큰 발급 + 만료 슬라이딩 재연장', async () => {
    const { service, rows } = makeService();
    const t0 = new Date('2026-07-17T00:00:00Z');
    const { token: first } = await service.issue('p1', undefined, t0);

    const t1 = new Date(t0.getTime() + 60 * 24 * 60 * 60 * 1000); // 60일 후 회전
    const { profileId, refresh } = await service.rotate(first, undefined, t1);

    expect(profileId).toBe('p1');
    expect(refresh.token).not.toBe(first);
    // 구 토큰 폐기됨
    const old = rows.find((r) => r.tokenHash === RefreshTokenService.hash(first))!;
    expect(old.revokedAt).not.toBeNull();
    expect(old.lastUsedAt).toEqual(t1);
    // 새 토큰 만료 = 회전 시각 + 180일 (슬라이딩)
    expect(refresh.expiresAt.getTime()).toBe(t1.getTime() + REFRESH_TTL_MS);
  });

  it('rotate 재사용 감지: 이미 회전된(폐기된) 토큰 재사용 → 프로필 전체 폐기 + REFRESH_REUSED', async () => {
    const { service, rows } = makeService();
    const t0 = new Date('2026-07-17T00:00:00Z');
    const { token: first } = await service.issue('p1', undefined, t0);
    // 두 번째 기기 세션도 하나 존재
    await service.issue('p1', 'dev-2', t0);

    // 정상 회전 1회 → first 는 폐기됨
    await service.rotate(first, undefined, new Date(t0.getTime() + 1000));

    // 폐기된 first 를 다시 제출 → 재사용 감지
    await expect(
      service.rotate(first, undefined, new Date(t0.getTime() + 2000)),
    ).rejects.toMatchObject({
      constructor: AppException,
    });
    try {
      await service.rotate(first, undefined, new Date(t0.getTime() + 3000));
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'REFRESH_REUSED',
      });
      expect((e as AppException).getStatus()).toBe(401);
    }
    // 프로필 p1 의 모든 리프레시가 폐기됨(탈취 방어)
    const active = rows.filter((r) => r.profileId === 'p1' && !r.revokedAt);
    expect(active).toHaveLength(0);
  });

  it('rotate: 미존재 토큰 → REFRESH_INVALID 401', async () => {
    const { service } = makeService();
    try {
      await service.rotate('deadbeef', undefined, new Date());
      fail('should throw');
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'REFRESH_INVALID',
      });
      expect((e as AppException).getStatus()).toBe(401);
    }
  });

  it('rotate: 만료된 토큰 → REFRESH_EXPIRED 401 + 폐기', async () => {
    const { service, rows } = makeService();
    const t0 = new Date('2026-01-01T00:00:00Z');
    const { token } = await service.issue('p1', undefined, t0);
    const afterExpiry = new Date(t0.getTime() + REFRESH_TTL_MS + 1000);
    try {
      await service.rotate(token, undefined, afterExpiry);
      fail('should throw');
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'REFRESH_EXPIRED',
      });
    }
    expect(rows[0].revokedAt).not.toBeNull();
  });

  it('상한 5개: 6번째 발급 시 가장 오래된 토큰 폐기(활성 5 유지)', async () => {
    const { service, rows } = makeService();
    const base = new Date('2026-07-17T00:00:00Z');
    for (let i = 0; i < MAX_ACTIVE_REFRESH; i++) {
      await service.issue('p1', `dev-${i}`, new Date(base.getTime() + i));
    }
    let active = rows.filter((r) => r.profileId === 'p1' && !r.revokedAt);
    expect(active).toHaveLength(5);

    // 6번째 발급 → 가장 오래된(dev-0) 폐기
    await service.issue('p1', 'dev-5', new Date(base.getTime() + 100));
    active = rows.filter((r) => r.profileId === 'p1' && !r.revokedAt);
    expect(active).toHaveLength(5);
    const dev0 = rows.find((r) => r.deviceId === 'dev-0')!;
    expect(dev0.revokedAt).not.toBeNull();
    const dev5 = rows.find((r) => r.deviceId === 'dev-5')!;
    expect(dev5.revokedAt).toBeNull();
  });

  it('revoke(logout): 해당 토큰만 폐기, 다른 기기 세션 유지', async () => {
    const { service, rows } = makeService();
    const { token: a } = await service.issue('p1', 'dev-a');
    await service.issue('p1', 'dev-b');
    const ok = await service.revoke('p1', a);
    expect(ok).toBe(true);
    const devA = rows.find((r) => r.deviceId === 'dev-a')!;
    const devB = rows.find((r) => r.deviceId === 'dev-b')!;
    expect(devA.revokedAt).not.toBeNull();
    expect(devB.revokedAt).toBeNull();
  });

  it('revoke: 타 프로필 토큰은 폐기하지 않음(멱등 false)', async () => {
    const { service } = makeService();
    const { token } = await service.issue('p1', 'dev-a');
    const ok = await service.revoke('p2', token);
    expect(ok).toBe(false);
  });

  it('cleanup: 만료 토큰 삭제', async () => {
    const { service, rows } = makeService();
    const t0 = new Date('2026-01-01T00:00:00Z');
    await service.issue('p1', undefined, t0); // 만료 t0+180일
    const later = new Date(t0.getTime() + REFRESH_TTL_MS + 1000);
    const removed = await service.cleanup(later);
    expect(removed).toBe(1);
    expect(rows).toHaveLength(0);
  });
});
