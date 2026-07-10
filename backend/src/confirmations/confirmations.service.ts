import { HttpStatus, Injectable } from '@nestjs/common';
import { nanoid } from 'nanoid';
import {
  Confirmation,
  ConfirmationStatus,
  ConnectionStatus,
  LedgerStatus,
  NotificationType,
  Prisma,
  RateType,
} from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { FileStorageService } from '../documents/file-storage.service';
import { PdfService } from '../documents/pdf.service';
import type { ConfirmationPdfData } from '../documents/pdf.types';
import { NotificationsService } from '../notifications/notifications.service';
import { maskName } from '../common/phone.util';
import { calcAmount, type AmountCalcResult } from './amount.util';
import { CreateConfirmationDto } from './dto/create-confirmation.dto';
import { UpdateConfirmationDto } from './dto/update-confirmation.dto';
import { SignConfirmationDto } from './dto/sign-confirmation.dto';
import { toConfirmationDto, RATE_TYPE_LABEL } from './confirmations.mapper';
import {
  kstDate,
  kstDateTime,
  kstMonthRange,
  toKstDateStr,
  toKstTimeStr,
  toKstDateTimeStr,
} from './time.util';

const TOKEN_LENGTH = 32;
const MAX_SIGN_BYTES = 1024 * 1024; // 1MB
const VIEW_LOG_CAP = 50; // 공개 열람 로그 최대 보관 개수 (초과분 drop, 총계는 viewCount)

@Injectable()
export class ConfirmationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: FileStorageService,
    private readonly pdf: PdfService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {}

  // --------------------------------------------------------------------------
  // 생성 — amountCalc 서버 계산 + ledger_entry 자동 생성 (같은 트랜잭션)
  // --------------------------------------------------------------------------
  async create(userId: string, dto: CreateConfirmationDto) {
    const { businessId, companyName, manualContact } =
      await this.resolveCounterparty(
        userId,
        dto.businessId,
        dto.companyName,
        dto.contact,
      );

    const calc = calcAmount({
      rateType: dto.rateType,
      rate: dto.rate,
      quantity: dto.quantity,
      additionalItems: dto.additionalItems,
      vatRate: dto.vatRate,
    });

    const token = nanoid(TOKEN_LENGTH);
    const dueDate = dto.dueDate ? kstDate(dto.dueDate) : null;

    const created = await this.prisma.$transaction(async (tx) => {
      const confirmation = await tx.confirmation.create({
        data: {
          profileId: userId,
          businessId,
          companyName,
          manualContact,
          date: kstDate(dto.date),
          site: dto.siteName,
          workContent: dto.workDescription,
          startTime: kstDateTime(dto.date, dto.startTime),
          endTime: kstDateTime(dto.date, dto.endTime),
          rateType: dto.rateType as RateType,
          amountCalc: calc as unknown as Prisma.InputJsonValue,
          equipmentSection: dto.equipmentSection
            ? (dto.equipmentSection as unknown as Prisma.InputJsonValue)
            : Prisma.JsonNull,
          notes: dto.notes ?? null,
          shareToken: token,
          status: ConfirmationStatus.DRAFT,
        },
      });

      // 장부(ledger_entry) 자동 생성 — 금액=합계, 수금예정일=dueDate(기본 null)
      await tx.ledgerEntry.create({
        data: {
          profileId: userId,
          confirmationId: confirmation.id,
          businessId,
          counterpartyName: businessId ? null : companyName,
          amount: new Prisma.Decimal(calc.total),
          dueDate,
          status: LedgerStatus.PENDING,
        },
      });

      return confirmation;
    });

    return toConfirmationDto(created);
  }

  // --------------------------------------------------------------------------
  // 복제 (날짜만 오늘로) — 새 확인서 + 새 ledger
  // --------------------------------------------------------------------------
  async duplicate(userId: string, id: string) {
    const src = await this.ownedOrThrow(userId, id);
    // 원본이 사업장 연동본이면 복제 시점에도 ACCEPTED 연결이 유지돼야 한다.
    if (src.businessId) {
      await this.assertConnectedToBusiness(userId, src.businessId);
    }
    const today = toKstDateStr(new Date());
    const startHm = toKstTimeStr(src.startTime);
    const endHm = toKstTimeStr(src.endTime);
    const calc = src.amountCalc as unknown as AmountCalcResult;
    const total = typeof calc?.total === 'number' ? calc.total : 0;
    const token = nanoid(TOKEN_LENGTH);

    const created = await this.prisma.$transaction(async (tx) => {
      const confirmation = await tx.confirmation.create({
        data: {
          profileId: userId,
          businessId: src.businessId,
          companyName: src.companyName,
          manualContact: src.manualContact,
          date: kstDate(today),
          site: src.site,
          workContent: src.workContent,
          startTime: kstDateTime(today, startHm),
          endTime: kstDateTime(today, endHm),
          rateType: src.rateType,
          amountCalc: src.amountCalc as unknown as Prisma.InputJsonValue,
          equipmentSection:
            src.equipmentSection === null
              ? Prisma.JsonNull
              : (src.equipmentSection as unknown as Prisma.InputJsonValue),
          notes: src.notes,
          shareToken: token,
          status: ConfirmationStatus.DRAFT,
        },
      });
      await tx.ledgerEntry.create({
        data: {
          profileId: userId,
          confirmationId: confirmation.id,
          businessId: src.businessId,
          counterpartyName: src.businessId ? null : src.companyName,
          amount: new Prisma.Decimal(total),
          dueDate: null,
          status: LedgerStatus.PENDING,
        },
      });
      return confirmation;
    });
    return toConfirmationDto(created);
  }

  // --------------------------------------------------------------------------
  // 목록 (?month=YYYY-MM) + 일자별 집계 (캘린더 월/주 뷰)
  // --------------------------------------------------------------------------
  async list(userId: string, month?: string) {
    let where: Prisma.ConfirmationWhereInput = { profileId: userId };
    if (month) {
      if (!/^\d{4}-\d{2}$/.test(month)) {
        throw new AppException(
          'INVALID_MONTH',
          'month 는 YYYY-MM 형식이어야 합니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      const { start, end } = kstMonthRange(month);
      where = { profileId: userId, date: { gte: start, lt: end } };
    }
    const rows = await this.prisma.confirmation.findMany({
      where,
      orderBy: [{ date: 'asc' }, { createdAt: 'asc' }],
    });
    const items = rows.map(toConfirmationDto);

    // 일자별 집계
    const byDateMap = new Map<
      string,
      { date: string; count: number; totalAmount: number }
    >();
    let monthTotal = 0;
    for (const it of items) {
      const g = byDateMap.get(it.date) ?? {
        date: it.date,
        count: 0,
        totalAmount: 0,
      };
      g.count += 1;
      g.totalAmount += it.total;
      monthTotal += it.total;
      byDateMap.set(it.date, g);
    }
    const byDate = [...byDateMap.values()].sort((a, b) =>
      a.date.localeCompare(b.date),
    );
    return {
      month: month ?? null,
      count: items.length,
      totalAmount: monthTotal,
      byDate,
      items,
    };
  }

  async getOne(userId: string, id: string) {
    const c = await this.ownedOrThrow(userId, id);
    return toConfirmationDto(c);
  }

  // --------------------------------------------------------------------------
  // 수정 (DRAFT 만) — 금액 변경 시 ledger 금액 동기화
  // --------------------------------------------------------------------------
  async update(userId: string, id: string, dto: UpdateConfirmationDto) {
    const c = await this.ownedOrThrow(userId, id);
    if (c.status !== ConfirmationStatus.DRAFT) {
      throw new AppException(
        'NOT_EDITABLE',
        '작성됨(DRAFT) 상태의 확인서만 수정할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    // 사업장 연동본은 수정 시점에도 ACCEPTED 연결이 유지돼야 한다.
    if (c.businessId) {
      await this.assertConnectedToBusiness(userId, c.businessId);
    }

    const data: Prisma.ConfirmationUpdateInput = {};
    // 날짜/시간
    const newDate = dto.date ?? toKstDateStr(c.date);
    if (dto.date !== undefined) data.date = kstDate(dto.date);
    if (dto.siteName !== undefined) data.site = dto.siteName;
    if (dto.workDescription !== undefined)
      data.workContent = dto.workDescription;
    if (dto.startTime !== undefined)
      data.startTime = kstDateTime(newDate, dto.startTime);
    if (dto.endTime !== undefined)
      data.endTime = kstDateTime(newDate, dto.endTime);
    // 날짜만 바뀌고 시간이 안 왔으면 기존 시각의 HH:mm 을 새 날짜에 재조합
    if (dto.date !== undefined && dto.startTime === undefined)
      data.startTime = kstDateTime(newDate, toKstTimeStr(c.startTime));
    if (dto.date !== undefined && dto.endTime === undefined)
      data.endTime = kstDateTime(newDate, toKstTimeStr(c.endTime));
    if (dto.companyName !== undefined && !c.businessId)
      data.companyName = dto.companyName;
    if (dto.contact !== undefined && !c.businessId)
      data.manualContact = dto.contact;
    if (dto.notes !== undefined) data.notes = dto.notes;
    if (dto.equipmentSection !== undefined)
      data.equipmentSection =
        dto.equipmentSection as unknown as Prisma.InputJsonValue;

    // 금액 재계산 여부 (금액 관련 필드가 하나라도 오면 재계산)
    const amountTouched =
      dto.rateType !== undefined ||
      dto.rate !== undefined ||
      dto.quantity !== undefined ||
      dto.additionalItems !== undefined ||
      dto.vatRate !== undefined;

    let newTotal: number | null = null;
    if (amountTouched) {
      const prev = c.amountCalc as unknown as {
        items?: Array<{
          type: string;
          rate: number;
          quantity: number;
          label?: string;
        }>;
        vatRate?: number;
      };
      // 기존 amountCalc 에서 기본/추가 항목을 복원해 부분 수정 지원
      const prevBase = prev?.items?.find((i) => i.type === 'BASE');
      const prevAdd = (prev?.items ?? []).filter((i) => i.type !== 'BASE');
      const calc = calcAmount({
        rateType: (dto.rateType ?? c.rateType) as
          'DAILY' | 'HOURLY' | 'PER_CASE',
        rate: dto.rate ?? prevBase?.rate ?? 0,
        quantity: dto.quantity ?? prevBase?.quantity ?? 0,
        additionalItems:
          dto.additionalItems ??
          prevAdd.map((i) => ({
            type: i.type as
              'OVERTIME' | 'EARLY' | 'NIGHT' | 'ALLNIGHT' | 'OTHER',
            label: i.label,
            rate: i.rate,
            quantity: i.quantity,
          })),
        vatRate: dto.vatRate ?? prev?.vatRate ?? 0,
      });
      data.amountCalc = calc as unknown as Prisma.InputJsonValue;
      newTotal = calc.total;
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.confirmation.update({ where: { id }, data });
      // ledger 동기화 (금액/수금예정일)
      const ledgerData: Prisma.LedgerEntryUpdateManyMutationInput = {};
      if (newTotal !== null) ledgerData.amount = new Prisma.Decimal(newTotal);
      if (dto.dueDate !== undefined)
        ledgerData.dueDate = dto.dueDate ? kstDate(dto.dueDate) : null;
      if (Object.keys(ledgerData).length > 0) {
        await tx.ledgerEntry.updateMany({
          where: { confirmationId: id },
          data: ledgerData,
        });
      }
      return u;
    });
    return toConfirmationDto(updated);
  }

  // --------------------------------------------------------------------------
  // 삭제 (DRAFT 만) — 연결 ledger 도 함께 제거
  // --------------------------------------------------------------------------
  async remove(userId: string, id: string) {
    const c = await this.ownedOrThrow(userId, id);
    if (c.status !== ConfirmationStatus.DRAFT) {
      throw new AppException(
        'NOT_DELETABLE',
        '작성됨(DRAFT) 상태의 확인서만 삭제할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.ledgerEntry.deleteMany({ where: { confirmationId: id } });
      await tx.confirmation.delete({ where: { id } });
    });
    await this.storage.removeDocumentDir(userId, id).catch(() => {});
    return { deleted: true };
  }

  // --------------------------------------------------------------------------
  // 전송 — 연동 사업장이면 SENT+알림, 수기면 shareToken 링크. 두 경우 모두 url 반환.
  // --------------------------------------------------------------------------
  async send(userId: string, id: string) {
    const c = await this.ownedOrThrow(userId, id);

    if (c.status === ConfirmationStatus.DRAFT) {
      await this.prisma.confirmation.update({
        where: { id },
        data: { status: ConfirmationStatus.SENT, revokedAt: null },
      });
    }

    let notified = false;
    if (c.businessId) {
      const business = await this.prisma.business.findUnique({
        where: { id: c.businessId },
        select: { ownerId: true, name: true },
      });
      if (business) {
        await this.notifications.create({
          profileId: business.ownerId,
          type: NotificationType.CONFIRMATION,
          title: '작업확인서가 도착했습니다',
          body: `${c.companyName} 현장(${c.site}) 작업확인서를 확인하고 서명해 주세요.`,
          data: { confirmationId: c.id, shareToken: c.shareToken },
        });
        notified = true;
      }
    }

    const baseUrl = (
      this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:3001'
    ).replace(/\/$/, '');
    return {
      shareToken: c.shareToken,
      url: `${baseUrl}/c/${c.shareToken}`,
      sent: true,
      linked: !!c.businessId,
      notified,
    };
  }

  // --------------------------------------------------------------------------
  // PDF (작업확인서 레이아웃 + 한글 폰트 + 서명 이미지 영역)
  // --------------------------------------------------------------------------
  async renderPdf(userId: string, id: string): Promise<Buffer> {
    const c = await this.ownedOrThrow(userId, id);
    return this.buildPdf(c);
  }

  private async buildPdf(c: Confirmation): Promise<Buffer> {
    const worker = await this.prisma.profile.findUnique({
      where: { id: c.profileId },
      select: { name: true },
    });
    const calc = c.amountCalc as unknown as AmountCalcResult;
    let signImagePng: Buffer | null = null;
    if (c.signImagePath) {
      signImagePng = await this.storage
        .readFile(c.signImagePath)
        .catch(() => null);
    }
    const equip = c.equipmentSection as {
      name?: string;
      vehicleNumber?: string;
      spec?: string;
      guide?: boolean;
    } | null;

    const data: ConfirmationPdfData = {
      title: '작업확인서',
      date: toKstDateStr(c.date),
      companyName: c.companyName,
      contact: c.manualContact,
      workerName: worker?.name ?? '작업자',
      site: c.site,
      workContent: c.workContent,
      timeRange: `${toKstTimeStr(c.startTime)} ~ ${toKstTimeStr(c.endTime)}`,
      rateTypeLabel: RATE_TYPE_LABEL[c.rateType] ?? c.rateType,
      lines: (calc?.items ?? []).map((it) => ({
        label: it.label,
        detail: `${it.rate.toLocaleString('ko-KR')} × ${it.quantity}`,
        amount: it.amount,
      })),
      subtotal: calc?.subtotal ?? 0,
      vatRate: calc?.vatRate ?? 0,
      vat: calc?.vat ?? 0,
      total: calc?.total ?? 0,
      notes: c.notes,
      equipment: equip
        ? {
            name: equip.name,
            vehicleNumber: equip.vehicleNumber,
            spec: equip.spec,
            guide: equip.guide,
          }
        : null,
      signerName: c.signerName,
      signedAt: c.signedAt ? toKstDateTimeStr(c.signedAt) : null,
      signImagePng,
      statusLabel:
        c.status === 'SIGNED'
          ? '서명됨'
          : c.status === 'SENT'
            ? '전송됨'
            : '작성됨',
    };
    return this.pdf.renderConfirmationPdf(data);
  }

  // --------------------------------------------------------------------------
  // 공개 열람 (@Public) — 만료 없음, 무효화만 체크 + viewLog
  // --------------------------------------------------------------------------
  async publicView(token: string, ip: string, ua: string) {
    const c = await this.loadValidByToken(token);
    const log = {
      at: new Date().toISOString(),
      ip: ip || 'unknown',
      ua: (ua || 'unknown').slice(0, 300),
    };
    const logs = Array.isArray(c.viewLogs) ? c.viewLogs : [];
    // 최근 VIEW_LOG_CAP 개만 유지(오래된 것 drop), 누적 총계는 viewCount 카운터로.
    const capped = [...logs, log].slice(-VIEW_LOG_CAP);
    await this.prisma.confirmation.update({
      where: { id: c.id },
      data: {
        viewLogs: capped as unknown as Prisma.InputJsonValue[],
        viewCount: { increment: 1 },
      },
    });

    const calc = c.amountCalc as unknown as AmountCalcResult;
    const worker = await this.prisma.profile.findUnique({
      where: { id: c.profileId },
      select: { name: true },
    });
    return {
      shareToken: token,
      status: c.status,
      signed: c.status === ConfirmationStatus.SIGNED,
      title: '작업확인서',
      date: toKstDateStr(c.date),
      companyName: c.companyName,
      contact: c.manualContact,
      workerName: worker?.name ?? '작업자',
      site: c.site,
      workContent: c.workContent,
      startTime: toKstTimeStr(c.startTime),
      endTime: toKstTimeStr(c.endTime),
      rateTypeLabel: RATE_TYPE_LABEL[c.rateType] ?? c.rateType,
      amountCalc: calc,
      total: calc?.total ?? 0,
      equipmentSection: c.equipmentSection ?? null,
      notes: c.notes,
      signerName: c.signerName,
      signedAt: c.signedAt ? toKstDateTimeStr(c.signedAt) : null,
      pdfUrl: `/api/public/confirmations/${token}/pdf`,
    };
  }

  // --------------------------------------------------------------------------
  // 공개 PDF (@Public) — 서명 반영본
  // --------------------------------------------------------------------------
  async publicPdf(token: string): Promise<Buffer> {
    const c = await this.loadValidByToken(token);
    return this.buildPdf(c);
  }

  // --------------------------------------------------------------------------
  // 공개 서명 (@Public) — 이미 SIGNED 면 409. 서명 후 발행자 알림.
  // --------------------------------------------------------------------------
  async publicSign(token: string, dto: SignConfirmationDto) {
    const c = await this.loadValidByToken(token);
    const updated = await this.applySignature(c, dto);
    return {
      signed: true,
      status: updated.status,
      signerName: updated.signerName,
      signedAt: updated.signedAt ? toKstDateTimeStr(updated.signedAt) : null,
      pdfUrl: `/api/public/confirmations/${token}/pdf`,
    };
  }

  /**
   * 사업장(앱 내) 서명 — 연동 상대(사업장 소유자)가 앱에서 서명.
   * public sign 로직(applySignature)을 재사용하되 권한은 사업장 소유자만.
   */
  async bizSign(ownerUserId: string, id: string, dto: SignConfirmationDto) {
    const c = await this.prisma.confirmation.findUnique({ where: { id } });
    if (!c || !c.businessId) {
      throw new AppException(
        'CONFIRMATION_NOT_FOUND',
        '수신 확인서를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const business = await this.prisma.business.findUnique({
      where: { id: c.businessId },
      select: { ownerId: true },
    });
    if (!business || business.ownerId !== ownerUserId) {
      throw new AppException(
        'FORBIDDEN',
        '이 확인서에 서명할 권한이 없습니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    // 전송(SENT)된 확인서만 앱 내 서명 가능. (DRAFT=미전송, SIGNED=이미 서명 → applySignature 가 409)
    if (c.status !== ConfirmationStatus.SENT) {
      throw new AppException(
        'NOT_SIGNABLE',
        '전송(SENT)된 확인서만 서명할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.applySignature(c, dto);
    return {
      signed: true,
      status: updated.status,
      signerName: updated.signerName,
      signedAt: updated.signedAt ? toKstDateTimeStr(updated.signedAt) : null,
    };
  }

  /**
   * 사업장 수신 확인서 상세 — 소유자 + 자기 사업장 대상 확인서만.
   * 코어 필드 + amountCalc(시간·금액 내역) + equipmentSection 전부 반환.
   * (수신함 목록은 요약만 주므로, 모달 오픈 시 이 상세로 완전 렌더)
   */
  async bizConfirmationDetail(ownerUserId: string, id: string) {
    const c = await this.prisma.confirmation.findUnique({ where: { id } });
    if (!c || !c.businessId) {
      throw new AppException(
        'CONFIRMATION_NOT_FOUND',
        '수신 확인서를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const business = await this.prisma.business.findUnique({
      where: { id: c.businessId },
      select: { ownerId: true },
    });
    if (!business || business.ownerId !== ownerUserId) {
      throw new AppException(
        'FORBIDDEN',
        '이 확인서를 조회할 권한이 없습니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    const calc = c.amountCalc as unknown as AmountCalcResult;
    const worker = await this.prisma.profile.findUnique({
      where: { id: c.profileId },
      select: { name: true },
    });
    return {
      id: c.id,
      status: c.status,
      signed: c.status === ConfirmationStatus.SIGNED,
      date: toKstDateStr(c.date),
      companyName: c.companyName,
      contact: c.manualContact,
      workerName: maskName(worker?.name ?? '작업자'),
      site: c.site,
      workContent: c.workContent,
      startTime: toKstTimeStr(c.startTime),
      endTime: toKstTimeStr(c.endTime),
      rateTypeLabel: RATE_TYPE_LABEL[c.rateType] ?? c.rateType,
      amountCalc: calc,
      total: calc?.total ?? 0,
      equipmentSection: c.equipmentSection ?? null,
      notes: c.notes,
      signerName: c.signerName,
      signedAt: c.signedAt ? toKstDateTimeStr(c.signedAt) : null,
    };
  }

  /** 서명 적용 공통 로직 — PNG 검증·저장, SIGNED 전이, 발행자 알림. 이미 SIGNED 면 409. */
  private async applySignature(
    c: Confirmation,
    dto: SignConfirmationDto,
  ): Promise<Confirmation> {
    // 이미지 검증(400)은 DB 상태 전이 전에 수행.
    const png = this.decodeSignPng(dto.signImageBase64);
    if (c.status === ConfirmationStatus.SIGNED) {
      throw new AppException(
        'ALREADY_SIGNED',
        '이미 서명된 확인서입니다.',
        HttpStatus.CONFLICT,
      );
    }
    // 서명 이미지 저장: uploads/{profileId}/{confirmationId}/signature.png
    const key = this.storage.buildKey(c.profileId, c.id, 'signature.png');
    await this.storage.writeFile(key, png);

    const signedAt = new Date();
    // TOCTOU 방지: SIGNED 아닌 경우에만 원자적 전이. count=0 이면 동시 서명 경합 → 409.
    const res = await this.prisma.confirmation.updateMany({
      where: { id: c.id, status: { not: ConfirmationStatus.SIGNED } },
      data: {
        signImagePath: key,
        signerName: dto.signerName,
        signedAt,
        status: ConfirmationStatus.SIGNED,
      },
    });
    if (res.count === 0) {
      throw new AppException(
        'ALREADY_SIGNED',
        '이미 서명된 확인서입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.prisma.confirmation.findUniqueOrThrow({
      where: { id: c.id },
    });

    // 발행자(작업자)에게 서명 완료 알림
    await this.notifications.create({
      profileId: c.profileId,
      type: NotificationType.CONFIRMATION,
      title: '작업확인서가 서명되었습니다',
      body: `${dto.signerName} 님이 ${c.site} 현장 확인서에 서명했습니다.`,
      data: { confirmationId: c.id, signerName: dto.signerName },
    });

    return updated;
  }

  // --------------------------------------------------------------------------
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  private async resolveCounterparty(
    userId: string,
    businessId: string | undefined,
    companyName: string | undefined,
    contact: string | undefined,
  ): Promise<{
    businessId: string | null;
    companyName: string;
    manualContact: string | null;
  }> {
    if (businessId) {
      const business = await this.prisma.business.findUnique({
        where: { id: businessId },
        select: { id: true, name: true },
      });
      if (!business) {
        throw new AppException(
          'BUSINESS_NOT_FOUND',
          '연결할 사업장을 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      // 요청자(작업자)와 해당 사업장 간 ACCEPTED 연결이 있어야 상대 businessId 로 지정 가능.
      await this.assertConnectedToBusiness(userId, business.id);
      return {
        businessId: business.id,
        companyName: companyName?.trim() || business.name,
        manualContact: null,
      };
    }
    if (!companyName || !companyName.trim()) {
      throw new AppException(
        'COUNTERPARTY_REQUIRED',
        '연결 사업장(businessId) 또는 수기 회사명(companyName)이 필요합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return {
      businessId: null,
      companyName: companyName.trim(),
      manualContact: contact?.trim() || null,
    };
  }

  /**
   * 요청자(작업자)와 사업장 간 ACCEPTED 연결을 강제한다.
   * 미연결이면 400 NOT_CONNECTED — 수기 상대(companyName)로만 작성 가능하다는 안내.
   * (jobs.service.ts 의 작업지시 연결 검증과 동일 기준으로 통일)
   */
  private async assertConnectedToBusiness(
    userId: string,
    businessId: string,
  ): Promise<void> {
    const connection = await this.prisma.connection.findUnique({
      where: { profileId_businessId: { profileId: userId, businessId } },
    });
    if (!connection || connection.status !== ConnectionStatus.ACCEPTED) {
      throw new AppException(
        'NOT_CONNECTED',
        '연결(수락)된 사업장에만 확인서를 연결할 수 있습니다. 미연결 상대는 수기 회사명(companyName)으로 작성하세요.',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /** PNG data URI 검증·디코드 (최대 1MB). */
  private decodeSignPng(dataUri: string): Buffer {
    const m = /^data:image\/png;base64,([A-Za-z0-9+/=]+)$/.exec(dataUri.trim());
    if (!m) {
      throw new AppException(
        'INVALID_SIGN_IMAGE',
        '서명 이미지는 PNG data URI 형식이어야 합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const buf = Buffer.from(m[1], 'base64');
    if (buf.length === 0 || buf.length > MAX_SIGN_BYTES) {
      throw new AppException(
        'SIGN_IMAGE_TOO_LARGE',
        '서명 이미지는 1MB 이하의 PNG 여야 합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    // PNG 시그니처 확인
    if (buf[0] !== 0x89 || buf.subarray(1, 4).toString('latin1') !== 'PNG') {
      throw new AppException(
        'INVALID_SIGN_IMAGE',
        '유효한 PNG 이미지가 아닙니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return buf;
  }

  private async ownedOrThrow(
    userId: string,
    id: string,
  ): Promise<Confirmation> {
    const c = await this.prisma.confirmation.findUnique({ where: { id } });
    if (!c || c.profileId !== userId) {
      throw new AppException(
        'CONFIRMATION_NOT_FOUND',
        '확인서를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return c;
  }

  private async loadValidByToken(token: string): Promise<Confirmation> {
    const c = await this.prisma.confirmation.findUnique({
      where: { shareToken: token },
    });
    if (!c) {
      throw new AppException(
        'CONFIRMATION_NOT_FOUND',
        '확인서 링크를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (c.revokedAt) {
      throw new AppException(
        'CONFIRMATION_REVOKED',
        '무효화된 확인서 링크입니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    return c;
  }
}
