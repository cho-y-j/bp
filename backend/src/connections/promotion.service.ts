import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePhone } from '../common/phone.util';
import { selectPromotable } from './promotion.util';

export interface PromotionResult {
  confirmations: number;
  ledgers: number;
  jobs: number;
}

/**
 * 미가입 상대 승격 서비스.
 *  - 사업장 생성/연결 수락 시, 기존 확인서·장부·작업지시의 수기 상대(manualContact)
 *    전화번호가 사업장(사업주 프로필) 전화와 일치하면 businessId 를 채워 연결로 승격한다.
 *  - 승격된 확인서에 연결된 ledger_entry 도 businessId 로 대칭 갱신한다(수기명 → 사업장).
 */
@Injectable()
export class PromotionService {
  private readonly logger = new Logger('PromotionService');

  constructor(private readonly prisma: PrismaService) {}

  /** 사업장 기준 승격: 사업주 프로필 전화(+추가 전화)로 수기 상대를 매칭한다. */
  async promoteForBusiness(
    businessId: string,
    extraPhones: string[] = [],
  ): Promise<PromotionResult> {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      include: { owner: { select: { phone: true } } },
    });
    if (!business) return { confirmations: 0, ledgers: 0, jobs: 0 };

    const phones = [business.owner?.phone ?? '', ...extraPhones]
      .map(normalizePhone)
      .filter((p) => p.length >= 8);
    if (phones.length === 0) return { confirmations: 0, ledgers: 0, jobs: 0 };

    // 1) 확인서: businessId 없고 manualContact 매칭 → 승격 (+연결 ledger 대칭 갱신)
    const confCandidates = await this.prisma.confirmation.findMany({
      where: { businessId: null, manualContact: { not: null } },
      select: { id: true, manualContact: true },
    });
    const confIds = selectPromotable(confCandidates, phones);

    // 2) 작업지시(jobs): businessId 없고 manualContact 매칭 → 승격
    const jobCandidates = await this.prisma.job.findMany({
      where: { businessId: null, manualContact: { not: null } },
      select: { id: true, manualContact: true },
    });
    const jobIds = selectPromotable(jobCandidates, phones);

    let ledgers = 0;
    if (confIds.length > 0 || jobIds.length > 0) {
      await this.prisma.$transaction(async (tx) => {
        if (confIds.length > 0) {
          await tx.confirmation.updateMany({
            where: { id: { in: confIds } },
            data: { businessId },
          });
          // 승격된 확인서에 연결된 장부를 사업장으로 대칭 갱신 (수기명 제거)
          const res = await tx.ledgerEntry.updateMany({
            where: { confirmationId: { in: confIds }, businessId: null },
            data: { businessId, counterpartyName: null },
          });
          ledgers = res.count;
        }
        if (jobIds.length > 0) {
          await tx.job.updateMany({
            where: { id: { in: jobIds } },
            data: { businessId },
          });
        }
      });
    }

    const result = {
      confirmations: confIds.length,
      ledgers,
      jobs: jobIds.length,
    };
    if (confIds.length || jobIds.length) {
      this.logger.log(
        `미가입 상대 승격(businessId=${businessId}): 확인서 ${result.confirmations} · 장부 ${result.ledgers} · 작업 ${result.jobs}`,
      );
    }
    return result;
  }
}
