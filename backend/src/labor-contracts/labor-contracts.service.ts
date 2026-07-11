import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { nanoid } from 'nanoid';
import {
  ConnectionStatus,
  LaborContract,
  LaborContractStatus,
  NotificationType,
  Prisma,
  WageType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { FileStorageService } from '../documents/file-storage.service';
import { PdfService } from '../documents/pdf.service';
import { NotificationsService } from '../notifications/notifications.service';
import { normalizePhone } from '../common/phone.util';
import {
  kstDate,
  toKstDateStr,
  toKstDateTimeStr,
} from '../confirmations/time.util';
import { CreateLaborContractDto } from './dto/create-labor-contract.dto';
import { UpdateLaborContractDto } from './dto/update-labor-contract.dto';
import { SignLaborContractDto } from './dto/sign-labor-contract.dto';
import {
  toLaborContractDto,
  LaborContractDto,
  LC_STATUS_LABEL,
  WAGE_TYPE_LABEL,
} from './labor-contracts.mapper';
import type { LaborContractPdfData } from '../documents/pdf.types';

const TOKEN_LENGTH = 32;
const MAX_SIGN_BYTES = 1024 * 1024; // 1MB
const VIEW_LOG_CAP = 50;

@Injectable()
export class LaborContractsService {
  private readonly logger = new Logger('LaborContractsService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: FileStorageService,
    private readonly pdf: PdfService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {}

  // ==========================================================================
  //  사업장(발행) 측
  // ==========================================================================

  /** 작성 — 사업장 소유·작업자(연결/수기) 검증 후 DRAFT 로 생성. */
  async create(
    userId: string,
    dto: CreateLaborContractDto,
  ): Promise<LaborContractDto> {
    const business = await this.ownedBusinessOrThrow(userId, dto.businessId);
    const worker = await this.resolveWorker(dto);

    const token = nanoid(TOKEN_LENGTH);
    const created = await this.prisma.laborContract.create({
      data: {
        businessId: business.id,
        title: dto.title?.trim() || '표준근로계약서',
        workerProfileId: worker.workerProfileId,
        workerName: worker.workerName,
        workerPhone: worker.workerPhone,
        startDate: kstDate(dto.startDate),
        endDate: dto.endDate ? kstDate(dto.endDate) : null,
        workplace: dto.workplace,
        jobDescription: dto.jobDescription,
        workStartTime: dto.workStartTime,
        workEndTime: dto.workEndTime,
        breakTime: dto.breakTime?.trim() || null,
        wageType: dto.wageType as WageType,
        wageAmount: new Prisma.Decimal(dto.wageAmount),
        payday: dto.payday,
        payMethod: dto.payMethod,
        weeklyHolidayAllowance: dto.weeklyHolidayAllowance ?? false,
        overtimeAllowance: dto.overtimeAllowance ?? true,
        socialInsurance: dto.socialInsurance
          ? (dto.socialInsurance as unknown as Prisma.InputJsonValue)
          : Prisma.JsonNull,
        specialTerms: dto.specialTerms?.trim() || null,
        shareToken: token,
        status: LaborContractStatus.DRAFT,
      },
      include: { business: { select: { name: true } } },
    });
    return toLaborContractDto(created);
  }

  /** 사업장 소유 계약서 목록(모든 내 사업장). */
  async listForBusiness(userId: string) {
    const businessIds = await this.myBusinessIds(userId);
    const rows = await this.prisma.laborContract.findMany({
      where: { businessId: { in: businessIds } },
      orderBy: { createdAt: 'desc' },
      include: { business: { select: { name: true } } },
    });
    return { count: rows.length, items: rows.map(toLaborContractDto) };
  }

  async getForBusiness(userId: string, id: string): Promise<LaborContractDto> {
    const c = await this.ownedContractOrThrow(userId, id);
    return toLaborContractDto(c);
  }

  /** 수정 — DRAFT + 사업장 미서명일 때만. */
  async update(userId: string, id: string, dto: UpdateLaborContractDto) {
    const c = await this.ownedContractOrThrow(userId, id);
    if (c.status !== LaborContractStatus.DRAFT || c.employerSignedAt !== null) {
      throw new AppException(
        'NOT_EDITABLE',
        '사업장 서명 전 작성됨(DRAFT) 상태의 계약서만 수정할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    const data: Prisma.LaborContractUpdateInput = {};
    if (dto.title !== undefined)
      data.title = dto.title.trim() || '표준근로계약서';
    if (dto.workerName !== undefined && c.workerProfileId === null)
      data.workerName = dto.workerName.trim();
    if (dto.workerPhone !== undefined && c.workerProfileId === null)
      data.workerPhone = dto.workerPhone.trim()
        ? normalizePhone(dto.workerPhone)
        : null;
    if (dto.startDate !== undefined) data.startDate = kstDate(dto.startDate);
    if (dto.endDate !== undefined)
      data.endDate = dto.endDate ? kstDate(dto.endDate) : null;
    if (dto.workplace !== undefined) data.workplace = dto.workplace;
    if (dto.jobDescription !== undefined)
      data.jobDescription = dto.jobDescription;
    if (dto.workStartTime !== undefined) data.workStartTime = dto.workStartTime;
    if (dto.workEndTime !== undefined) data.workEndTime = dto.workEndTime;
    if (dto.breakTime !== undefined)
      data.breakTime = dto.breakTime.trim() || null;
    if (dto.wageType !== undefined) data.wageType = dto.wageType as WageType;
    if (dto.wageAmount !== undefined)
      data.wageAmount = new Prisma.Decimal(dto.wageAmount);
    if (dto.payday !== undefined) data.payday = dto.payday;
    if (dto.payMethod !== undefined) data.payMethod = dto.payMethod;
    if (dto.weeklyHolidayAllowance !== undefined)
      data.weeklyHolidayAllowance = dto.weeklyHolidayAllowance;
    if (dto.overtimeAllowance !== undefined)
      data.overtimeAllowance = dto.overtimeAllowance;
    if (dto.socialInsurance !== undefined)
      data.socialInsurance =
        dto.socialInsurance as unknown as Prisma.InputJsonValue;
    if (dto.specialTerms !== undefined)
      data.specialTerms = dto.specialTerms.trim() || null;

    const updated = await this.prisma.laborContract.update({
      where: { id },
      data,
      include: { business: { select: { name: true } } },
    });
    return toLaborContractDto(updated);
  }

  /** 삭제 — DRAFT 만. */
  async remove(userId: string, id: string) {
    const c = await this.ownedContractOrThrow(userId, id);
    if (c.status !== LaborContractStatus.DRAFT) {
      throw new AppException(
        'NOT_DELETABLE',
        '작성됨(DRAFT) 상태의 계약서만 삭제할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    await this.prisma.laborContract.delete({ where: { id } });
    await this.storage.removeDocumentDir(c.businessId, c.id).catch(() => {});
    return { deleted: true };
  }

  /** 사업장(사용자) 서명 — 전송 전 필수 선행. DRAFT + 미서명일 때만. */
  async signEmployer(userId: string, id: string, dto: SignLaborContractDto) {
    const c = await this.ownedContractOrThrow(userId, id);
    if (c.status !== LaborContractStatus.DRAFT) {
      throw new AppException(
        'NOT_SIGNABLE',
        '작성됨(DRAFT) 상태에서만 사업장 서명이 가능합니다.',
        HttpStatus.CONFLICT,
      );
    }
    const png = this.decodeSignPng(dto.signImageBase64);
    if (c.employerSignedAt !== null) {
      throw new AppException(
        'ALREADY_SIGNED',
        '이미 사업장 서명이 완료된 계약서입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const key = this.storage.buildKey(
      c.businessId,
      c.id,
      'employer-signature.png',
    );
    await this.storage.writeFile(key, png);
    // TOCTOU 방지: DRAFT + 미서명일 때만 원자적 갱신.
    const res = await this.prisma.laborContract.updateMany({
      where: {
        id: c.id,
        status: LaborContractStatus.DRAFT,
        employerSignedAt: null,
      },
      data: {
        employerSignImagePath: key,
        employerSignerName: dto.signerName,
        employerSignedAt: new Date(),
      },
    });
    if (res.count === 0) {
      throw new AppException(
        'ALREADY_SIGNED',
        '이미 사업장 서명이 완료된 계약서입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.loadWithBusiness(c.id);
    return toLaborContractDto(updated);
  }

  /** 전송 — 사업장 서명 필수. 연결 작업자면 알림, 수기면 링크 발급(둘 다 url 반환). */
  async send(userId: string, id: string) {
    const c = await this.ownedContractOrThrow(userId, id);
    if (c.employerSignedAt === null) {
      throw new AppException(
        'EMPLOYER_SIGNATURE_REQUIRED',
        '사업장 서명을 먼저 완료해야 전송할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    if (c.status === LaborContractStatus.DRAFT) {
      await this.prisma.laborContract.update({
        where: { id },
        data: { status: LaborContractStatus.SENT, revokedAt: null },
      });
    }
    const business = await this.prisma.business.findUnique({
      where: { id: c.businessId },
      select: { name: true },
    });
    const businessName = business?.name ?? '사업장';

    const baseUrl = (
      this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:3001'
    ).replace(/\/$/, '');
    const url = `${baseUrl}/lc/${c.shareToken}`;

    let notified = false;
    let alimtalkSent = false;
    if (c.workerProfileId) {
      await this.notifications.create({
        profileId: c.workerProfileId,
        type: NotificationType.CONFIRMATION,
        title: '표준근로계약서가 도착했습니다',
        body: `${businessName}에서 표준근로계약서를 보냈습니다. 내용을 확인하고 서명해 주세요.`,
        data: {
          laborContractId: c.id,
          shareToken: c.shareToken,
          kind: 'labor_contract',
        },
      });
      notified = true;
    } else if (c.workerPhone) {
      const res = await this.notifications.sendExternalAlimtalk(
        c.workerPhone,
        'CONFIRMATION_SIGN',
        { companyName: businessName, url },
      );
      alimtalkSent = res.sent;
    }

    return {
      shareToken: c.shareToken,
      url,
      sent: true,
      linked: !!c.workerProfileId,
      notified,
      alimtalkSent,
    };
  }

  /** 사업장 측 계약서 PDF. */
  async renderPdfForBusiness(userId: string, id: string): Promise<Buffer> {
    const c = await this.ownedContractOrThrow(userId, id);
    return this.buildPdf(c);
  }

  // ==========================================================================
  //  작업자(근로자) 측
  // ==========================================================================

  /** 내가 받은/서명한 계약서 목록(가입 작업자로 연결된 계약서). */
  async listForWorker(userId: string) {
    const rows = await this.prisma.laborContract.findMany({
      where: {
        workerProfileId: userId,
        status: { in: [LaborContractStatus.SENT, LaborContractStatus.SIGNED] },
      },
      orderBy: { createdAt: 'desc' },
      include: { business: { select: { name: true } } },
    });
    return { count: rows.length, items: rows.map(toLaborContractDto) };
  }

  async getForWorker(userId: string, id: string): Promise<LaborContractDto> {
    const c = await this.workerContractOrThrow(userId, id);
    return toLaborContractDto(c);
  }

  async renderPdfForWorker(userId: string, id: string): Promise<Buffer> {
    const c = await this.workerContractOrThrow(userId, id);
    return this.buildPdf(c);
  }

  /** 작업자 앱 내 서명(연결 작업자). 전송(SENT)된 내 계약서만. */
  async signWorkerInApp(userId: string, id: string, dto: SignLaborContractDto) {
    const c = await this.workerContractOrThrow(userId, id);
    return this.applyWorkerSignature(c, dto);
  }

  // ==========================================================================
  //  공개(외부) 열람·서명 — @Public
  // ==========================================================================

  async publicView(token: string, ip: string, ua: string) {
    const c = await this.loadValidByToken(token);
    const log = {
      at: new Date().toISOString(),
      ip: ip || 'unknown',
      ua: (ua || 'unknown').slice(0, 300),
    };
    const logs = Array.isArray(c.viewLogs) ? c.viewLogs : [];
    const capped = [...logs, log].slice(-VIEW_LOG_CAP);
    await this.prisma.laborContract.update({
      where: { id: c.id },
      data: {
        viewLogs: capped as unknown as Prisma.InputJsonValue[],
        viewCount: { increment: 1 },
      },
    });
    const business = await this.prisma.business.findUnique({
      where: { id: c.businessId },
      select: { name: true, businessNumber: true, address: true },
    });
    return {
      shareToken: token,
      status: c.status,
      signed: c.status === LaborContractStatus.SIGNED,
      workerSigned: c.workerSignedAt !== null,
      title: c.title,
      businessName: business?.name ?? '사업장',
      businessNumber: business?.businessNumber ?? null,
      businessAddress: business?.address ?? null,
      workerName: c.workerName,
      startDate: toKstDateStr(c.startDate),
      endDate: c.endDate ? toKstDateStr(c.endDate) : null,
      workplace: c.workplace,
      jobDescription: c.jobDescription,
      workStartTime: c.workStartTime,
      workEndTime: c.workEndTime,
      breakTime: c.breakTime,
      wageType: c.wageType,
      wageTypeLabel: WAGE_TYPE_LABEL[c.wageType] ?? c.wageType,
      wageAmount: Number(c.wageAmount),
      payday: c.payday,
      payMethod: c.payMethod,
      weeklyHolidayAllowance: c.weeklyHolidayAllowance,
      overtimeAllowance: c.overtimeAllowance,
      socialInsurance: c.socialInsurance ?? null,
      specialTerms: c.specialTerms,
      employerSignerName: c.employerSignerName,
      employerSignedAt: c.employerSignedAt
        ? toKstDateTimeStr(c.employerSignedAt)
        : null,
      workerSignerName: c.workerSignerName,
      workerSignedAt: c.workerSignedAt
        ? toKstDateTimeStr(c.workerSignedAt)
        : null,
      pdfUrl: `/api/public/contracts/${token}/pdf`,
    };
  }

  async publicPdf(token: string): Promise<Buffer> {
    const c = await this.loadValidByToken(token);
    return this.buildPdf(c);
  }

  async publicSign(token: string, dto: SignLaborContractDto) {
    const c = await this.loadValidByToken(token);
    return this.applyWorkerSignature(c, dto);
  }

  // ==========================================================================
  //  서명 적용 공통 (작업자 서명) — 전송(SENT)만, 원자적 SIGNED 전이, 재서명 409
  // ==========================================================================
  private async applyWorkerSignature(
    c: LaborContract,
    dto: SignLaborContractDto,
  ) {
    const png = this.decodeSignPng(dto.signImageBase64);
    if (c.status === LaborContractStatus.DRAFT) {
      throw new AppException(
        'NOT_SIGNABLE',
        '전송(SENT)된 계약서만 서명할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    if (c.status === LaborContractStatus.SIGNED) {
      throw new AppException(
        'ALREADY_SIGNED',
        '이미 서명된 계약서입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const key = this.storage.buildKey(
      c.businessId,
      c.id,
      'worker-signature.png',
    );
    await this.storage.writeFile(key, png);

    const signedAt = new Date();
    // TOCTOU 방지: SENT(작업자 미서명)일 때만 원자적으로 SIGNED 전이. 경합 → 409.
    const res = await this.prisma.laborContract.updateMany({
      where: {
        id: c.id,
        status: LaborContractStatus.SENT,
        workerSignedAt: null,
      },
      data: {
        workerSignImagePath: key,
        workerSignerName: dto.signerName,
        workerSignedAt: signedAt,
        status: LaborContractStatus.SIGNED,
      },
    });
    if (res.count === 0) {
      throw new AppException(
        'ALREADY_SIGNED',
        '이미 서명된 계약서입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.loadWithBusiness(c.id);

    // 양측 알림: 사업장 소유자 + 가입 작업자(연결 시).
    await this.notifyBothOnSigned(updated, dto.signerName);

    return {
      signed: true,
      status: updated.status,
      workerSignerName: updated.workerSignerName,
      workerSignedAt: updated.workerSignedAt
        ? toKstDateTimeStr(updated.workerSignedAt)
        : null,
      pdfUrl: `/api/public/contracts/${updated.shareToken}/pdf`,
    };
  }

  private async notifyBothOnSigned(
    c: LaborContract,
    signerName: string,
  ): Promise<void> {
    try {
      const business = await this.prisma.business.findUnique({
        where: { id: c.businessId },
        select: { ownerId: true, name: true },
      });
      if (business) {
        await this.notifications.create({
          profileId: business.ownerId,
          type: NotificationType.CONFIRMATION,
          title: '표준근로계약서가 서명되었습니다',
          body: `${signerName} 님이 근로계약서에 서명했습니다. (${c.workplace})`,
          data: { laborContractId: c.id, kind: 'labor_contract' },
        });
      }
      if (c.workerProfileId) {
        await this.notifications.create({
          profileId: c.workerProfileId,
          type: NotificationType.CONFIRMATION,
          title: '근로계약서가 내 계약서에 저장되었습니다',
          body: `${business?.name ?? '사업장'} 표준근로계약서 서명이 완료되어 서류 지갑에 보관되었습니다.`,
          data: { laborContractId: c.id, kind: 'labor_contract' },
        });
      }
    } catch (err) {
      this.logger.warn(
        `[labor-contract-notify] ${c.id}: ${(err as Error).message}`,
      );
    }
  }

  // ==========================================================================
  //  PDF 빌드 (양측 서명 포함)
  // ==========================================================================
  private async buildPdf(c: LaborContract): Promise<Buffer> {
    const business = await this.prisma.business.findUnique({
      where: { id: c.businessId },
      select: { name: true, businessNumber: true, address: true },
    });
    let employerPng: Buffer | null = null;
    if (c.employerSignImagePath) {
      employerPng = await this.storage
        .readFile(c.employerSignImagePath)
        .catch(() => null);
    }
    let workerPng: Buffer | null = null;
    if (c.workerSignImagePath) {
      workerPng = await this.storage
        .readFile(c.workerSignImagePath)
        .catch(() => null);
    }
    const si =
      (c.socialInsurance as {
        employment?: boolean;
        health?: boolean;
        pension?: boolean;
        industrialAccident?: boolean;
      } | null) ?? null;

    const data: LaborContractPdfData = {
      title: c.title,
      statusLabel: LC_STATUS_LABEL[c.status] ?? c.status,
      businessName: business?.name ?? '사업장',
      businessNumber: business?.businessNumber ?? null,
      businessAddress: business?.address ?? null,
      workerName: c.workerName,
      workerPhone: c.workerPhone,
      startDate: toKstDateStr(c.startDate),
      endDate: c.endDate ? toKstDateStr(c.endDate) : null,
      workplace: c.workplace,
      jobDescription: c.jobDescription,
      timeRange: `${c.workStartTime} ~ ${c.workEndTime}`,
      breakTime: c.breakTime,
      wageTypeLabel: WAGE_TYPE_LABEL[c.wageType] ?? c.wageType,
      wageAmount: Number(c.wageAmount),
      payday: c.payday,
      payMethod: c.payMethod,
      weeklyHolidayAllowance: c.weeklyHolidayAllowance,
      overtimeAllowance: c.overtimeAllowance,
      socialInsurance: si,
      specialTerms: c.specialTerms,
      employerSignerName: c.employerSignerName,
      employerSignedAt: c.employerSignedAt
        ? toKstDateTimeStr(c.employerSignedAt)
        : null,
      employerSignPng: employerPng,
      workerSignerName: c.workerSignerName,
      workerSignedAt: c.workerSignedAt
        ? toKstDateTimeStr(c.workerSignedAt)
        : null,
      workerSignPng: workerPng,
    };
    return this.pdf.renderLaborContractPdf(data);
  }

  // ==========================================================================
  //  내부 헬퍼
  // ==========================================================================
  private async myBusinessIds(userId: string): Promise<string[]> {
    const businesses = await this.prisma.business.findMany({
      where: { ownerId: userId },
      select: { id: true },
    });
    return businesses.map((b) => b.id);
  }

  private async ownedBusinessOrThrow(userId: string, businessId: string) {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      select: { id: true, name: true, ownerId: true },
    });
    if (!business || business.ownerId !== userId) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        '계약서를 발행할 사업장을 찾을 수 없습니다(소유자만 발행 가능).',
        HttpStatus.NOT_FOUND,
      );
    }
    return business;
  }

  /**
   * 작업자 상대 해석.
   *  - 가입 연결(workerProfileId): 프로필 존재 + (전화검색 동의 OR 해당 사업장과 ACCEPTED 연결).
   *  - 수기: workerName 필수.
   */
  private async resolveWorker(dto: CreateLaborContractDto): Promise<{
    workerProfileId: string | null;
    workerName: string;
    workerPhone: string | null;
  }> {
    if (dto.workerProfileId) {
      const profile = await this.prisma.profile.findUnique({
        where: { id: dto.workerProfileId },
        select: { id: true, name: true, phone: true, phoneSearchConsent: true },
      });
      if (!profile) {
        throw new AppException(
          'WORKER_NOT_FOUND',
          '연결할 작업자를 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      let allowed = profile.phoneSearchConsent;
      if (!allowed) {
        const conn = await this.prisma.connection.findUnique({
          where: {
            profileId_businessId: {
              profileId: profile.id,
              businessId: dto.businessId,
            },
          },
          select: { status: true },
        });
        allowed = conn?.status === ConnectionStatus.ACCEPTED;
      }
      if (!allowed) {
        throw new AppException(
          'WORKER_LINK_NOT_ALLOWED',
          '전화검색에 동의했거나 연결(수락)된 작업자만 계약서에 연결할 수 있습니다.',
          HttpStatus.FORBIDDEN,
        );
      }
      const name = dto.workerName?.trim() || profile.name || '작업자';
      const phone =
        dto.workerPhone?.trim() ||
        (profile.phone.startsWith('kakao:') ? null : profile.phone);
      return {
        workerProfileId: profile.id,
        workerName: name,
        workerPhone: phone ? normalizePhone(phone) : null,
      };
    }
    // 수기
    if (!dto.workerName || !dto.workerName.trim()) {
      throw new AppException(
        'WORKER_NAME_REQUIRED',
        '수기 작업자는 이름이 필요합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return {
      workerProfileId: null,
      workerName: dto.workerName.trim(),
      workerPhone: dto.workerPhone?.trim()
        ? normalizePhone(dto.workerPhone)
        : null,
    };
  }

  private async ownedContractOrThrow(
    userId: string,
    id: string,
  ): Promise<LaborContract & { business: { name: string } | null }> {
    const c = await this.prisma.laborContract.findUnique({
      where: { id },
      include: { business: { select: { name: true, ownerId: true } } },
    });
    if (!c || !c.business || c.business.ownerId !== userId) {
      throw new AppException(
        'LABOR_CONTRACT_NOT_FOUND',
        '근로계약서를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return c as unknown as LaborContract & {
      business: { name: string } | null;
    };
  }

  private async workerContractOrThrow(
    userId: string,
    id: string,
  ): Promise<LaborContract & { business: { name: string } | null }> {
    const c = await this.prisma.laborContract.findUnique({
      where: { id },
      include: { business: { select: { name: true } } },
    });
    if (!c || c.workerProfileId !== userId) {
      throw new AppException(
        'LABOR_CONTRACT_NOT_FOUND',
        '근로계약서를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return c;
  }

  private async loadWithBusiness(id: string) {
    return this.prisma.laborContract.findUniqueOrThrow({
      where: { id },
      include: { business: { select: { name: true } } },
    });
  }

  private async loadValidByToken(token: string): Promise<LaborContract> {
    const c = await this.prisma.laborContract.findUnique({
      where: { shareToken: token },
    });
    if (!c) {
      throw new AppException(
        'LABOR_CONTRACT_NOT_FOUND',
        '근로계약서 링크를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (c.revokedAt) {
      throw new AppException(
        'LABOR_CONTRACT_REVOKED',
        '무효화된 근로계약서 링크입니다.',
        HttpStatus.FORBIDDEN,
      );
    }
    return c;
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
    if (buf[0] !== 0x89 || buf.subarray(1, 4).toString('latin1') !== 'PNG') {
      throw new AppException(
        'INVALID_SIGN_IMAGE',
        '유효한 PNG 이미지가 아닙니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return buf;
  }
}
