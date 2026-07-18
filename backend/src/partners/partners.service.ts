import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import {
  buildPartnerList,
  type PartnerListItem,
  type PartnerLedgerRef,
} from './partners.util';
import { UpdatePartnerDto } from './dto/update-partner.dto';

@Injectable()
export class PartnersService {
  private readonly logger = new Logger(PartnersService.name);

  constructor(private readonly prisma: PrismaService) {}

  // --------------------------------------------------------------------------
  // 자동 수집 훅 — 확인서 생성/수정 시 수기 상대를 partners 에 upsert.
  //   - businessId 있는(연결) 상대는 businesses 가 원천이므로 행을 만들지 않는다.
  //   - 식별 키 (profileId, name). phone 은 제공되면 최신값으로 갱신.
  //   - 실패해도 확인서 저장을 막지 않도록 호출부에서 catch (여기서도 방어적 로그).
  // --------------------------------------------------------------------------
  async upsertFromManualCounterparty(
    profileId: string,
    name: string | null | undefined,
    phone: string | null | undefined,
  ): Promise<void> {
    const trimmed = name?.trim();
    if (!trimmed) return;
    const trimmedPhone = phone?.trim() || null;
    await this.prisma.partner.upsert({
      where: { profileId_name: { profileId, name: trimmed } },
      create: { profileId, name: trimmed, phone: trimmedPhone },
      // phone 이 새로 오면 갱신, 없으면 기존값 유지(빈값으로 덮어쓰지 않음).
      update: trimmedPhone ? { phone: trimmedPhone } : {},
    });
  }

  /** 예외를 삼키는 안전 래퍼 — 확인서 서비스 훅에서 사용. */
  async safeUpsertFromManualCounterparty(
    profileId: string,
    name: string | null | undefined,
    phone: string | null | undefined,
  ): Promise<void> {
    try {
      await this.upsertFromManualCounterparty(profileId, name, phone);
    } catch (err) {
      this.logger.warn(
        `[partner-upsert] ${profileId}/${name ?? ''}: ${(err as Error).message}`,
      );
    }
  }

  // --------------------------------------------------------------------------
  // 목록 — 확인서(원천) + 장부(미수) + partners 보강행 병합.
  //   백필: 조회 시 확인서에만 있고 partners 행이 없는 수기 상대를 lazy 생성
  //   (별도 백필 엔드포인트/데이터 마이그레이션 불필요). 매 조회 idempotent.
  // --------------------------------------------------------------------------
  async list(userId: string): Promise<{ count: number; items: PartnerListItem[] }> {
    // 1) 확인서 최소 참조
    const confirmations = await this.prisma.confirmation.findMany({
      where: { profileId: userId },
      select: {
        businessId: true,
        companyName: true,
        manualContact: true,
        date: true,
      },
    });

    // 2) lazy 백필 — 확인서의 수기 상대 이름 중 partners 행이 없는 것을 생성.
    await this.backfillMissing(userId, confirmations);

    // 3) partners 보강행
    const partnerRows = await this.prisma.partner.findMany({
      where: { profileId: userId },
      select: {
        id: true,
        name: true,
        phone: true,
        alias: true,
        bizNumber: true,
        email: true,
        memo: true,
      },
    });

    // 4) 장부 미수(파생 제외 — 팀원 몫은 거래처 미수가 아님)
    const ledgerRows = await this.prisma.ledgerEntry.findMany({
      where: { profileId: userId, derived: false },
      select: {
        businessId: true,
        counterpartyName: true,
        amount: true,
        payments: true,
        dueDate: true,
      },
    });
    const ledgerEntries: PartnerLedgerRef[] = ledgerRows.map((e) => ({
      businessId: e.businessId,
      counterpartyName: e.counterpartyName,
      amount: Number(e.amount),
      payments: e.payments,
      dueDate: e.dueDate,
    }));

    // 5) 연결(승격) 사업장 — 이름·소유자 전화
    const businessIds = [
      ...new Set(
        confirmations
          .map((c) => c.businessId)
          .filter((b): b is string => !!b),
      ),
    ];
    const businessRows = businessIds.length
      ? await this.prisma.business.findMany({
          where: { id: { in: businessIds } },
          select: { id: true, name: true, owner: { select: { phone: true } } },
        })
      : [];
    const businesses = businessRows.map((b) => ({
      id: b.id,
      name: b.name,
      ownerPhone: b.owner?.phone ?? null,
    }));

    const items = buildPartnerList({
      confirmations,
      ledgerEntries,
      partnerRows,
      businesses,
    });
    return { count: items.length, items };
  }

  /** 확인서에만 있는 수기 상대 이름을 partners 에 일괄 생성(중복 skip). */
  private async backfillMissing(
    userId: string,
    confirmations: Array<{
      businessId: string | null;
      companyName: string;
      manualContact: string | null;
      date: Date;
    }>,
  ): Promise<void> {
    // 수기 상대 이름 → 최근 작업일의 연락처 (대표 전화)
    const latest = new Map<string, { date: Date; phone: string | null }>();
    for (const c of confirmations) {
      if (c.businessId) continue;
      const name = c.companyName?.trim();
      if (!name) continue;
      const prev = latest.get(name);
      if (!prev || c.date.getTime() >= prev.date.getTime()) {
        latest.set(name, { date: c.date, phone: c.manualContact?.trim() || null });
      }
    }
    if (latest.size === 0) return;

    const existing = await this.prisma.partner.findMany({
      where: { profileId: userId, name: { in: [...latest.keys()] } },
      select: { name: true },
    });
    const have = new Set(existing.map((e) => e.name));
    const toCreate = [...latest.entries()]
      .filter(([name]) => !have.has(name))
      .map(([name, v]) => ({ profileId: userId, name, phone: v.phone }));
    if (toCreate.length === 0) return;
    try {
      await this.prisma.partner.createMany({
        data: toCreate,
        skipDuplicates: true, // 동시 조회 경합 방어
      });
    } catch (err) {
      this.logger.warn(`[partner-backfill] ${userId}: ${(err as Error).message}`);
    }
  }

  // --------------------------------------------------------------------------
  // 보강 정보 수정 — alias/bizNumber/email/memo 만. 본인 소유 행만.
  // --------------------------------------------------------------------------
  async patch(userId: string, id: string, dto: UpdatePartnerDto) {
    await this.ownedOrThrow(userId, id);
    const data: Prisma.PartnerUpdateInput = {};
    // 빈 문자열은 null 로 정규화(값 비우기 허용).
    const norm = (v: string | undefined) =>
      v === undefined ? undefined : v.trim() === '' ? null : v.trim();
    if (dto.alias !== undefined) data.alias = norm(dto.alias);
    if (dto.bizNumber !== undefined) data.bizNumber = norm(dto.bizNumber);
    if (dto.email !== undefined) data.email = norm(dto.email);
    if (dto.memo !== undefined) data.memo = norm(dto.memo);
    const updated = await this.prisma.partner.update({ where: { id }, data });
    return {
      id: updated.id,
      name: updated.name,
      phone: updated.phone,
      alias: updated.alias,
      bizNumber: updated.bizNumber,
      email: updated.email,
      memo: updated.memo,
    };
  }

  // --------------------------------------------------------------------------
  // 삭제 — hard delete. soft delete 불필요:
  //   자동 수집이라 같은 상대의 확인서가 다시 생기거나 GET 시 lazy 백필로 재등장한다.
  //   (보강 정보는 사라지지만, 이는 사용자가 명시 삭제한 의도에 부합)
  // --------------------------------------------------------------------------
  async remove(userId: string, id: string) {
    await this.ownedOrThrow(userId, id);
    await this.prisma.partner.delete({ where: { id } });
    return { deleted: true };
  }

  private async ownedOrThrow(userId: string, id: string) {
    const p = await this.prisma.partner.findUnique({ where: { id } });
    if (!p || p.profileId !== userId) {
      throw new AppException(
        'PARTNER_NOT_FOUND',
        '거래처를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return p;
  }
}
