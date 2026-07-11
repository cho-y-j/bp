import { Injectable, Logger } from '@nestjs/common';
import { ConfirmationStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentRecord } from './ledger.util';
import {
  BadgeCache,
  computeAvgDays,
  daysBetween,
  PaymentBadge,
  badgeFromCache,
  selfBadgeStatus,
  SelfBadgeStatus,
} from './badge.util';

/**
 * 지급 평판 배지 집계·캐시 서비스 (P3a).
 *  - 평균 지급 소요일 = SIGNED(확인서 서명) → 전액 PAID 까지 일수(최근 12개월, 표본 3건↑).
 *  - 검색마다 실시간 집계 금지 → Business 캐시 컬럼에 저장, 일일 크론 + pay 시점 비동기 갱신.
 */
@Injectable()
export class BadgeService {
  private readonly logger = new Logger('BadgeService');

  constructor(private readonly prisma: PrismaService) {}

  /** 최근 12개월(now 기준) SIGNED→전액 PAID 소요일 표본으로 캐시 갱신. */
  async recomputeBusiness(
    businessId: string,
    now: Date = new Date(),
  ): Promise<BadgeCache> {
    const cutoff = new Date(now);
    cutoff.setMonth(cutoff.getMonth() - 12);

    // 이 사업장의 SIGNED 확인서 + 연결 장부(전액 PAID) 만 표본.
    const entries = await this.prisma.ledgerEntry.findMany({
      where: {
        businessId,
        confirmationId: { not: null },
        confirmation: {
          status: ConfirmationStatus.SIGNED,
          signedAt: { gte: cutoff, lte: now },
        },
      },
      include: { confirmation: { select: { signedAt: true } } },
    });

    const days: number[] = [];
    for (const e of entries) {
      const signedAt = e.confirmation?.signedAt;
      if (!signedAt) continue;
      const amount = Number(e.amount);
      const fullyPaidAt = this.fullyPaidAt(e.payments, amount);
      if (!fullyPaidAt) continue; // 전액 지급 완료 아님 → 표본 제외
      days.push(daysBetween(signedAt, fullyPaidAt));
    }

    const { avgDays, sampleSize } = computeAvgDays(days);
    const cache: BadgeCache = {
      paymentAvgDays: avgDays,
      paymentSampleSize: sampleSize,
    };
    await this.prisma.business.update({
      where: { id: businessId },
      data: {
        paymentAvgDays: avgDays,
        paymentSampleSize: sampleSize,
        paymentBadgeUpdatedAt: now,
      },
    });
    return cache;
  }

  /** pay 시점 비동기 갱신 — 실패해도 예외 던지지 않음(fire-and-forget). */
  async recomputeBusinessQuietly(businessId: string): Promise<void> {
    try {
      await this.recomputeBusiness(businessId);
    } catch (e) {
      this.logger.warn(
        `배지 비동기 갱신 실패(${businessId}): ${(e as Error).message}`,
      );
    }
  }

  /** 전 사업장 배지 캐시 재계산(일일 크론). 갱신 건수 반환. */
  async recomputeAll(now: Date = new Date()): Promise<number> {
    const businesses = await this.prisma.business.findMany({
      select: { id: true },
    });
    let updated = 0;
    for (const b of businesses) {
      try {
        await this.recomputeBusiness(b.id, now);
        updated += 1;
      } catch (e) {
        this.logger.warn(
          `배지 크론 갱신 실패(${b.id}): ${(e as Error).message}`,
        );
      }
    }
    this.logger.log(
      `지급 평판 배지 크론 완료: ${updated}/${businesses.length}건 갱신`,
    );
    return updated;
  }

  /** 캐시 컬럼 → 공개 배지 DTO(우수/양호만, 부정 낙인 없음). */
  toBadge(cache: BadgeCache): PaymentBadge | null {
    return badgeFromCache(cache);
  }

  /** 사업장 본인용 상태(데이터 부족/개선 안내 포함). */
  toSelfStatus(cache: BadgeCache): SelfBadgeStatus {
    return selfBadgeStatus(cache);
  }

  /**
   * payments 로부터 전액 지급 완료 시각을 계산.
   *  - 시간순 누적 합이 처음으로 amount 이상이 된 결제의 paidAt.
   *  - paidAt 누락 시 null(집계 제외 — 시각 불명).
   */
  private fullyPaidAt(payments: unknown, amount: number): Date | null {
    if (amount <= 0) return null;
    const list = Array.isArray(payments)
      ? (payments as PaymentRecord[])
          .filter(
            (p) =>
              p &&
              typeof p.amount === 'number' &&
              p.amount > 0 &&
              typeof p.paidAt === 'string',
          )
          .map((p) => ({
            amount: Math.round(p.amount),
            at: new Date(p.paidAt!),
          }))
          .filter((p) => Number.isFinite(p.at.getTime()))
          .sort((a, b) => a.at.getTime() - b.at.getTime())
      : [];
    let cumulative = 0;
    for (const p of list) {
      cumulative += p.amount;
      if (cumulative >= amount) return p.at;
    }
    return null;
  }
}
