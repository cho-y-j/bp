import { HttpStatus, Injectable } from '@nestjs/common';
import {
  ConnectionStatus,
  Job,
  JobStatus,
  NotificationType,
  Prisma,
  RateType,
  SafetyLogType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { FileStorageService } from '../documents/file-storage.service';
import { NotificationsService } from '../notifications/notifications.service';
import { computeDday } from '../common/dday.util';
import { kstMonthRange, toKstDateTimeStr } from '../confirmations/time.util';
import { CreateJobDto } from './dto/create-job.dto';
import { StartJobDto } from './dto/start-job.dto';
import { CompleteJobDto } from './dto/complete-job.dto';

const MAX_PHOTOS = 10;
// 작업 사진 허용 MIME (documents 업로드와 동일 이미지 기준: jpg/png/heic/webp)
const ALLOWED_PHOTO_MIME = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

@Injectable()
export class JobsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: FileStorageService,
    private readonly notifications: NotificationsService,
  ) {}

  // --------------------------------------------------------------------------
  // 작업 지시/예약 (사업장 모드) — 연결(ACCEPTED) 작업자에게만
  // --------------------------------------------------------------------------
  async create(userId: string, dto: CreateJobDto) {
    const business = await this.prisma.business.findUnique({
      where: { id: dto.businessId },
      select: { id: true, ownerId: true, name: true },
    });
    if (!business || business.ownerId !== userId) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        '내 사업장을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const connection = await this.prisma.connection.findUnique({
      where: {
        profileId_businessId: {
          profileId: dto.workerProfileId,
          businessId: business.id,
        },
      },
    });
    if (!connection || connection.status !== ConnectionStatus.ACCEPTED) {
      throw new AppException(
        'NOT_CONNECTED',
        '연결(수락)된 작업자에게만 작업을 지시할 수 있습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }

    const job = await this.prisma.job.create({
      data: {
        profileId: dto.workerProfileId,
        businessId: business.id,
        site: dto.site,
        scheduledAt: new Date(dto.scheduledAt),
        rateType: dto.rateType as RateType,
        rate: new Prisma.Decimal(dto.rate),
        overtimeRate:
          dto.overtimeRate !== undefined
            ? new Prisma.Decimal(dto.overtimeRate)
            : null,
        nightRate:
          dto.nightRate !== undefined
            ? new Prisma.Decimal(dto.nightRate)
            : null,
        status: JobStatus.SCHEDULED,
      },
    });

    await this.notifications.create({
      profileId: dto.workerProfileId,
      type: NotificationType.RESERVATION,
      title: '새 작업 예약이 도착했습니다',
      body: `${business.name} · ${dto.site} (${toKstDateTimeStr(job.scheduledAt)}) 작업을 확인해 주세요.`,
      data: { jobId: job.id, businessId: business.id },
    });

    return this.toDto(job);
  }

  // --------------------------------------------------------------------------
  // 목록 (?month=) — 양측(작업자/사업장), 역할 표시
  // --------------------------------------------------------------------------
  async list(userId: string, month?: string) {
    let range: { start: Date; end: Date } | null = null;
    if (month) {
      if (!/^\d{4}-\d{2}$/.test(month)) {
        throw new AppException(
          'INVALID_MONTH',
          'month 는 YYYY-MM 형식이어야 합니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      range = kstMonthRange(month);
    }
    const where: Prisma.JobWhereInput = {
      OR: [{ profileId: userId }, { business: { ownerId: userId } }],
    };
    if (range) where.scheduledAt = { gte: range.start, lt: range.end };

    const rows = await this.prisma.job.findMany({
      where,
      include: {
        business: { select: { id: true, name: true, ownerId: true } },
        profile: { select: { id: true, name: true } },
        workLogs: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { scheduledAt: 'asc' },
    });
    return {
      month: month ?? null,
      count: rows.length,
      items: rows.map((j) => ({
        ...this.toDto(j),
        role: j.business?.ownerId === userId ? 'BUSINESS' : 'WORKER',
        businessName: j.business?.name ?? j.manualCompanyName ?? null,
        workLog: j.workLogs[0]
          ? {
              startedAt: j.workLogs[0].startedAt,
              finishedAt: j.workLogs[0].finishedAt,
              conditionCheck: j.workLogs[0].conditionCheck,
              photoCount: j.workLogs[0].photoPaths.length,
            }
          : null,
      })),
    };
  }

  // --------------------------------------------------------------------------
  // 작업자 수락 (confirm) — acceptedAt + 서류 유효성 자동 확인(safety_log)
  // --------------------------------------------------------------------------
  async confirm(userId: string, id: string) {
    const job = await this.workerJobOrThrow(userId, id);
    if (job.acceptedAt) {
      throw new AppException(
        'ALREADY_CONFIRMED',
        '이미 수락한 작업입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const updated = await this.prisma.job.update({
      where: { id },
      data: { acceptedAt: new Date() },
    });

    // 서류 유효성 자동 확인 → safety_log(DOCUMENT_VALIDITY)
    const validity = await this.checkDocumentValidity(userId);
    await this.prisma.safetyLog.create({
      data: {
        type: SafetyLogType.DOCUMENT_VALIDITY,
        targetProfileId: userId,
        businessId: job.businessId,
        payload: {
          jobId: id,
          ok: validity.expired.length === 0,
          expiredCount: validity.expired.length,
          expired: validity.expired,
        } as unknown as Prisma.InputJsonValue,
        sentAt: new Date(),
      },
    });

    // 만료 서류가 있으면 사업장(소유자)에 알림
    if (validity.expired.length > 0 && job.businessId) {
      const business = await this.prisma.business.findUnique({
        where: { id: job.businessId },
        select: { ownerId: true },
      });
      if (business) {
        await this.notifications.create({
          profileId: business.ownerId,
          type: NotificationType.DOCUMENT_EXPIRY,
          title: '작업자 서류 만료 확인 필요',
          body: `배정 작업자의 만료 서류 ${validity.expired.length}건이 확인되었습니다.`,
          data: { jobId: id, expiredCount: validity.expired.length },
        });
      }
    }

    return { ...this.toDto(updated), documentValidity: validity };
  }

  // --------------------------------------------------------------------------
  // 시작 (start) — GPS + 컨디션체크 → work_log + safety_log(CONDITION_CHECK)
  // --------------------------------------------------------------------------
  async start(userId: string, id: string, dto: StartJobDto) {
    const job = await this.workerJobOrThrow(userId, id);
    // 상태전이 강제: 수락(acceptedAt)한 예약(SCHEDULED) 상태만 시작 가능.
    if (job.status !== JobStatus.SCHEDULED || !job.acceptedAt) {
      throw new AppException(
        'JOB_NOT_STARTABLE',
        '수락한 예약(SCHEDULED) 상태의 작업만 시작할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    const now = new Date();
    const conditionCheck = {
      result: dto.condition,
      note: dto.conditionNote ?? null,
      checkedAt: now.toISOString(),
    };

    const result = await this.prisma.$transaction(async (tx) => {
      const workLog = await tx.workLog.create({
        data: {
          jobId: id,
          startedAt: now,
          gpsLat: dto.lat,
          gpsLng: dto.lng,
          conditionCheck: conditionCheck as unknown as Prisma.InputJsonValue,
        },
      });
      await tx.job.update({
        where: { id },
        data: { status: JobStatus.IN_PROGRESS },
      });
      // 컨디션 체크를 안전 로그로 기록 (증거력)
      await tx.safetyLog.create({
        data: {
          type: SafetyLogType.CONDITION_CHECK,
          targetProfileId: userId,
          businessId: job.businessId,
          payload: {
            jobId: id,
            result: dto.condition,
            note: dto.conditionNote ?? null,
            gps: { lat: dto.lat, lng: dto.lng },
          } as unknown as Prisma.InputJsonValue,
          sentAt: now,
        },
      });
      return workLog;
    });

    // 컨디션 BAD 이면 사업장에 알림
    if (dto.condition === 'BAD' && job.businessId) {
      const business = await this.prisma.business.findUnique({
        where: { id: job.businessId },
        select: { ownerId: true },
      });
      if (business) {
        await this.notifications.create({
          profileId: business.ownerId,
          type: NotificationType.HEAT_ALERT,
          title: '작업자 컨디션 이상(BAD)',
          body: `${job.site} 현장 작업자의 컨디션 체크가 BAD 로 보고되었습니다.`,
          data: { jobId: id },
        });
      }
    }

    return {
      started: true,
      status: JobStatus.IN_PROGRESS,
      workLogId: result.id,
      conditionCheck,
    };
  }

  // --------------------------------------------------------------------------
  // 완료 (complete) — GPS + 사진 경로 → work_log 갱신, status=DONE
  // --------------------------------------------------------------------------
  async complete(userId: string, id: string, dto: CompleteJobDto) {
    const job = await this.workerJobOrThrow(userId, id);
    // 상태전이 강제: 진행중(IN_PROGRESS) 작업만 완료 가능.
    if (job.status !== JobStatus.IN_PROGRESS) {
      throw new AppException(
        'JOB_NOT_COMPLETABLE',
        '진행중(IN_PROGRESS) 작업만 완료할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    const now = new Date();
    const workLog = await this.prisma.workLog.findFirst({
      where: { jobId: id },
      orderBy: { createdAt: 'desc' },
    });

    const photoPaths = dto.photoPaths ?? [];
    let finalWorkLog;
    if (workLog) {
      finalWorkLog = await this.prisma.workLog.update({
        where: { id: workLog.id },
        data: {
          finishedAt: now,
          gpsLat: dto.lat,
          gpsLng: dto.lng,
          photoPaths: photoPaths.length > 0 ? photoPaths : workLog.photoPaths,
        },
      });
    } else {
      finalWorkLog = await this.prisma.workLog.create({
        data: {
          jobId: id,
          finishedAt: now,
          gpsLat: dto.lat,
          gpsLng: dto.lng,
          photoPaths,
        },
      });
    }
    await this.prisma.job.update({
      where: { id },
      data: { status: JobStatus.DONE },
    });

    // 사업장에 완료 알림
    if (job.businessId) {
      const business = await this.prisma.business.findUnique({
        where: { id: job.businessId },
        select: { ownerId: true },
      });
      if (business) {
        await this.notifications.create({
          profileId: business.ownerId,
          type: NotificationType.RESERVATION,
          title: '작업이 완료되었습니다',
          body: `${job.site} 현장 작업이 완료 처리되었습니다.`,
          data: { jobId: id },
        });
      }
    }

    return {
      completed: true,
      status: JobStatus.DONE,
      workLogId: finalWorkLog.id,
      photoCount: finalWorkLog.photoPaths.length,
    };
  }

  // --------------------------------------------------------------------------
  // 사진 업로드 (multipart) — FileStorageService 재사용
  // --------------------------------------------------------------------------
  async uploadPhotos(userId: string, id: string, files: Express.Multer.File[]) {
    const job = await this.workerJobOrThrow(userId, id);
    if (!files || files.length === 0) {
      throw new AppException(
        'NO_FILE',
        '업로드할 사진이 없습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    if (files.length > MAX_PHOTOS) {
      throw new AppException(
        'TOO_MANY_PHOTOS',
        `사진은 최대 ${MAX_PHOTOS}장까지 업로드할 수 있습니다.`,
        HttpStatus.BAD_REQUEST,
      );
    }
    // MIME 검증: jpg/png/heic/webp 만 허용 (그 외 400)
    for (const file of files) {
      if (!ALLOWED_PHOTO_MIME.has(file.mimetype)) {
        throw new AppException(
          'UNSUPPORTED_PHOTO_TYPE',
          'jpg/png/heic/webp 이미지만 업로드할 수 있습니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
    }
    const workLog = await this.prisma.workLog.findFirst({
      where: { jobId: id },
      orderBy: { createdAt: 'desc' },
    });

    const savedPaths: string[] = [];
    let idx = Date.now();
    for (const file of files) {
      const ext = this.extFor(file.mimetype);
      const filename = `job-photo-${idx++}${ext}`;
      const key = this.storage.buildKey(userId, job.id, filename);
      await this.storage.writeFile(key, file.buffer);
      savedPaths.push(key);
    }

    const existing = workLog?.photoPaths ?? [];
    const merged = [...existing, ...savedPaths];
    if (workLog) {
      await this.prisma.workLog.update({
        where: { id: workLog.id },
        data: { photoPaths: merged },
      });
    } else {
      await this.prisma.workLog.create({
        data: { jobId: id, photoPaths: merged },
      });
    }
    return { uploaded: savedPaths.length, photoPaths: merged };
  }

  // --------------------------------------------------------------------------
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  /** 작업자(job.profileId) 본인만 접근 가능한 작업 조회. */
  private async workerJobOrThrow(userId: string, id: string): Promise<Job> {
    const job = await this.prisma.job.findUnique({ where: { id } });
    if (!job || job.profileId !== userId) {
      throw new AppException(
        'JOB_NOT_FOUND',
        '작업을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return job;
  }

  /** 작업자(+장비) 서류 중 만료 지난 것을 찾는다. */
  private async checkDocumentValidity(userId: string): Promise<{
    expired: Array<{
      id: string;
      type: string;
      expiryDate: string;
      dday: number;
    }>;
  }> {
    const now = new Date();
    const docs = await this.prisma.document.findMany({
      where: {
        expiryDate: { not: null },
        OR: [{ profileId: userId }, { equipment: { profileId: userId } }],
      },
      select: { id: true, type: true, expiryDate: true },
    });
    const expired = docs
      .filter((d) => d.expiryDate && computeDday(d.expiryDate, now) < 0)
      .map((d) => ({
        id: d.id,
        type: d.type,
        expiryDate: d.expiryDate!.toISOString(),
        dday: computeDday(d.expiryDate!, now),
      }));
    return { expired };
  }

  private extFor(mime: string): string {
    switch (mime) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/heic':
      case 'image/heif':
        return '.heic';
      default:
        return '.bin';
    }
  }

  private toDto(job: Job) {
    return {
      id: job.id,
      businessId: job.businessId,
      workerProfileId: job.profileId,
      site: job.site,
      scheduledAt: job.scheduledAt,
      rateType: job.rateType,
      rate: Number(job.rate),
      overtimeRate: job.overtimeRate !== null ? Number(job.overtimeRate) : null,
      nightRate: job.nightRate !== null ? Number(job.nightRate) : null,
      status: job.status,
      acceptedAt: job.acceptedAt,
      createdAt: job.createdAt,
    };
  }
}
