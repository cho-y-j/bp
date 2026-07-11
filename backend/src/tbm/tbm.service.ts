import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import {
  ConnectionStatus,
  NotificationType,
  Prisma,
  SafetyLogType,
  TbmPresetKind,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { FileStorageService } from '../documents/file-storage.service';
import { NotificationsService } from '../notifications/notifications.service';
import { kstDateTime, toKstDateStr } from '../confirmations/time.util';
import {
  CreateTbmRecordDto,
  TbmAttendeeDto,
  TbmHazardItemDto,
} from './dto/create-tbm-record.dto';
import { UpdateTbmRecordDto } from './dto/update-tbm-record.dto';
import { CreateTbmPresetDto } from './dto/create-tbm-preset.dto';
import { toTbmPresetDto, toTbmRecordDto, TbmRecordDto } from './tbm.mapper';

const MAX_PHOTO_BYTES = 20 * 1024 * 1024;
const ALLOWED_PHOTO_MIME = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

@Injectable()
export class TbmService {
  private readonly logger = new Logger('TbmService');

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: FileStorageService,
    private readonly notifications: NotificationsService,
  ) {}

  // ==========================================================================
  //  사업장(작성) 측
  // ==========================================================================

  /** 작성 — 사업장 소유·참석자(연결/수기) 검증 후 생성 + 참석자 알림 + safety_log. */
  async create(userId: string, dto: CreateTbmRecordDto): Promise<TbmRecordDto> {
    const business = await this.ownedBusinessOrThrow(userId, dto.businessId);
    const attendees = await this.resolveAttendees(
      dto.businessId,
      dto.attendees ?? [],
    );
    const occurredAt = kstDateTime(dto.date, dto.time ?? '09:00');

    const created = await this.prisma.tbmRecord.create({
      data: {
        businessId: business.id,
        authorProfileId: userId,
        site: dto.site.trim(),
        occurredAt,
        hazards: this.normalizeHazards(dto.hazards),
        measures: dto.measures?.trim() || null,
        notes: dto.notes?.trim() || null,
        attendees: {
          create: attendees.map((a) => ({
            profileId: a.profileId,
            name: a.name,
          })),
        },
      },
      include: {
        business: { select: { name: true } },
        attendees: { orderBy: { createdAt: 'asc' } },
      },
    });

    // safety_logs 에 "TBM 기록" append (작성자 대상, businessId 포함).
    await this.prisma.safetyLog.create({
      data: {
        type: SafetyLogType.TBM,
        targetProfileId: userId,
        businessId: business.id,
        payload: {
          kind: 'TBM_RECORD',
          tbmRecordId: created.id,
          site: created.site,
        } as unknown as Prisma.InputJsonValue,
        sentAt: new Date(),
      },
    });

    // 가입 참석자에게 알림 (자기 언어로 볼 수 있게 딥링크 데이터에 attendeeId 포함).
    await this.notifyAttendees(created.id, business.name, created.attendees);

    return toTbmRecordDto(created, { editable: true });
  }

  async listForBusiness(userId: string) {
    const businessIds = await this.myBusinessIds(userId);
    if (businessIds.length === 0) return { count: 0, items: [] };
    const rows = await this.prisma.tbmRecord.findMany({
      where: { businessId: { in: businessIds } },
      orderBy: { occurredAt: 'desc' },
      include: {
        business: { select: { name: true } },
        attendees: { orderBy: { createdAt: 'asc' } },
      },
    });
    const now = new Date();
    return {
      count: rows.length,
      items: rows.map((r) =>
        toTbmRecordDto(r, { editable: this.isSameKstDay(r.createdAt, now) }),
      ),
    };
  }

  async getForBusiness(userId: string, id: string): Promise<TbmRecordDto> {
    const r = await this.ownedRecordOrThrow(userId, id);
    return toTbmRecordDto(r, {
      editable: this.isSameKstDay(r.createdAt, new Date()),
    });
  }

  /** 수정 — 당일만. attendees 지정 시 명단 전체 대체(신규 가입자에 알림). */
  async update(
    userId: string,
    id: string,
    dto: UpdateTbmRecordDto,
  ): Promise<TbmRecordDto> {
    const r = await this.ownedRecordOrThrow(userId, id);
    this.assertEditable(r.createdAt);

    const data: Prisma.TbmRecordUpdateInput = {};
    if (dto.site !== undefined) data.site = dto.site.trim();
    if (dto.date !== undefined || dto.time !== undefined) {
      const date = dto.date ?? toKstDateStr(r.occurredAt);
      const time =
        dto.time ?? `${String(r.occurredAt.getUTCHours()).padStart(2, '0')}:00`;
      // time 미지정 시 기존 시각 유지: date 만 바뀌면 기존 시각 유지가 자연스러움.
      data.occurredAt = dto.time
        ? kstDateTime(date, time)
        : this.replaceKstDate(r.occurredAt, date);
    }
    if (dto.hazards !== undefined)
      data.hazards = this.normalizeHazards(dto.hazards);
    if (dto.measures !== undefined) data.measures = dto.measures.trim() || null;
    if (dto.notes !== undefined) data.notes = dto.notes.trim() || null;

    // 참석자 명단 전체 대체(지정 시). 기존과 비교해 신규 가입자만 알림.
    let newlyNotified: {
      id: string;
      profileId: string | null;
      name: string;
    }[] = [];
    if (dto.attendees !== undefined) {
      const resolved = await this.resolveAttendees(r.businessId, dto.attendees);
      const prevProfileIds = new Set(
        r.attendees.map((a) => a.profileId).filter((p): p is string => !!p),
      );
      await this.prisma.tbmAttendee.deleteMany({ where: { recordId: id } });
      const createdAttendees = await this.prisma.$transaction(
        resolved.map((a) =>
          this.prisma.tbmAttendee.create({
            data: { recordId: id, profileId: a.profileId, name: a.name },
          }),
        ),
      );
      newlyNotified = createdAttendees.filter(
        (a) => a.profileId && !prevProfileIds.has(a.profileId),
      );
    }

    await this.prisma.tbmRecord.update({ where: { id }, data });

    if (newlyNotified.length > 0) {
      const business = await this.prisma.business.findUnique({
        where: { id: r.businessId },
        select: { name: true },
      });
      await this.notifyAttendees(id, business?.name ?? '사업장', newlyNotified);
    }

    const updated = await this.loadOwned(id);
    return toTbmRecordDto(updated, { editable: true });
  }

  /** 삭제 — 당일만. */
  async remove(userId: string, id: string) {
    const r = await this.ownedRecordOrThrow(userId, id);
    if (!this.isSameKstDay(r.createdAt, new Date())) {
      throw new AppException(
        'NOT_DELETABLE',
        '작성 당일에만 TBM 기록을 삭제할 수 있습니다.',
        HttpStatus.CONFLICT,
      );
    }
    await this.prisma.tbmRecord.delete({ where: { id } });
    // 사진 디렉터리 정리(있으면).
    await this.storage
      .removeDocumentDir(r.businessId, r.id)
      .catch(() => undefined);
    return { deleted: true };
  }

  /** 사진 업로드(multipart) — 당일만, FileStorageService 재사용. */
  async uploadPhotos(userId: string, id: string, files: Express.Multer.File[]) {
    const r = await this.ownedRecordOrThrow(userId, id);
    this.assertEditable(r.createdAt);
    if (!files || files.length === 0) {
      throw new AppException(
        'NO_FILES',
        '업로드할 사진이 없습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    const existing = r.photoPaths ?? [];
    const savedPaths: string[] = [];
    let idx = existing.length;
    for (const file of files) {
      if (file.size > MAX_PHOTO_BYTES) {
        throw new AppException(
          'PHOTO_TOO_LARGE',
          '사진은 20MB 이하만 업로드할 수 있습니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      if (!ALLOWED_PHOTO_MIME.has(file.mimetype)) {
        throw new AppException(
          'UNSUPPORTED_FILE_TYPE',
          '지원하지 않는 사진 형식입니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      const ext = this.extFor(file.mimetype);
      const filename = `tbm-photo-${idx++}${ext}`;
      const key = this.storage.buildKey(r.businessId, r.id, filename);
      await this.storage.writeFile(key, file.buffer);
      savedPaths.push(key);
    }
    const merged = [...existing, ...savedPaths];
    await this.prisma.tbmRecord.update({
      where: { id },
      data: { photoPaths: merged },
    });
    return { uploaded: savedPaths.length, photoCount: merged.length };
  }

  /** 사진 바이트 (사업장 소유자). */
  async getPhotoForBusiness(
    userId: string,
    id: string,
    index: number,
  ): Promise<{ buffer: Buffer; mime: string }> {
    const r = await this.ownedRecordOrThrow(userId, id);
    return this.readPhoto(r.photoPaths ?? [], index);
  }

  /** 사진 바이트 (참석 작업자). */
  async getPhotoForWorker(
    userId: string,
    id: string,
    index: number,
  ): Promise<{ buffer: Buffer; mime: string }> {
    const r = await this.attendedRecordOrThrow(userId, id);
    return this.readPhoto(r.photoPaths ?? [], index);
  }

  // ==========================================================================
  //  작업자(참석자) 측
  // ==========================================================================

  /** 내가 참석자로 포함된 TBM 목록("내 안전 기록"). */
  async listForWorker(userId: string) {
    const attendees = await this.prisma.tbmAttendee.findMany({
      where: { profileId: userId },
      orderBy: { record: { occurredAt: 'desc' } },
      include: {
        record: {
          include: {
            business: { select: { name: true } },
            attendees: { orderBy: { createdAt: 'asc' } },
          },
        },
      },
    });
    return {
      count: attendees.length,
      items: attendees.map((a) => ({
        attendeeId: a.id,
        acked: a.ackAt !== null,
        record: toTbmRecordDto(a.record, { photoBase: 'worker' }),
      })),
    };
  }

  /**
   * 참석자 "확인"(ack) — tbm_attendees.ackAt 최초 1회 UPDATE.
   *  - 본인(profileId) 참석자만. 이미 ackAt 있으면 409 (재확인 차단).
   *  - safety_logs 에 "TBM 확인" append + 작성 사업장에 알림.
   */
  async ack(userId: string, attendeeId: string) {
    const attendee = await this.prisma.tbmAttendee.findUnique({
      where: { id: attendeeId },
      include: {
        record: { select: { id: true, businessId: true, site: true } },
      },
    });
    if (!attendee || attendee.profileId !== userId) {
      throw new AppException(
        'TBM_ATTENDEE_NOT_FOUND',
        'TBM 참석 기록을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    if (attendee.ackAt) {
      throw new AppException(
        'ALREADY_ACKED',
        '이미 확인한 TBM 입니다.',
        HttpStatus.CONFLICT,
      );
    }
    const ackAt = new Date();
    // TOCTOU 방지: ackAt 미설정일 때만 원자적으로 갱신. 경합 → 409.
    const res = await this.prisma.tbmAttendee.updateMany({
      where: { id: attendeeId, ackAt: null },
      data: { ackAt },
    });
    if (res.count === 0) {
      throw new AppException(
        'ALREADY_ACKED',
        '이미 확인한 TBM 입니다.',
        HttpStatus.CONFLICT,
      );
    }

    // safety_logs 에 "TBM 확인" append (참석자 대상, businessId 포함).
    await this.prisma.safetyLog.create({
      data: {
        type: SafetyLogType.TBM,
        targetProfileId: userId,
        businessId: attendee.record.businessId,
        payload: {
          kind: 'TBM_ACK',
          tbmRecordId: attendee.record.id,
          attendeeId: attendee.id,
        } as unknown as Prisma.InputJsonValue,
        sentAt: attendee.createdAt,
        receivedAt: ackAt,
        confirmedAt: ackAt,
        ackAt,
      },
    });

    // 작성 사업장 소유자에게 확인 알림.
    await this.notifyOwnerOnAck(attendee.record.businessId, attendee.name);

    return { acked: true, ackAt };
  }

  // ==========================================================================
  //  프리셋 (사업장 커스텀 문구)
  // ==========================================================================

  async listPresets(userId: string, businessId: string) {
    await this.ownedBusinessOrThrow(userId, businessId);
    const rows = await this.prisma.tbmPreset.findMany({
      where: { businessId },
      orderBy: { createdAt: 'asc' },
    });
    return { count: rows.length, items: rows.map(toTbmPresetDto) };
  }

  async createPreset(userId: string, dto: CreateTbmPresetDto) {
    await this.ownedBusinessOrThrow(userId, dto.businessId);
    const created = await this.prisma.tbmPreset.create({
      data: {
        businessId: dto.businessId,
        kind: dto.kind as TbmPresetKind,
        text: dto.text.trim(),
      },
    });
    return toTbmPresetDto(created);
  }

  async removePreset(userId: string, id: string) {
    const preset = await this.prisma.tbmPreset.findUnique({
      where: { id },
      include: { business: { select: { ownerId: true } } },
    });
    if (!preset || preset.business.ownerId !== userId) {
      throw new AppException(
        'TBM_PRESET_NOT_FOUND',
        'TBM 프리셋을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    await this.prisma.tbmPreset.delete({ where: { id } });
    return { deleted: true };
  }

  // ==========================================================================
  //  내부 헬퍼
  // ==========================================================================

  private normalizeHazards(items: TbmHazardItemDto[]): Prisma.InputJsonValue {
    const out = items
      .map((h) => {
        const code = h.code?.trim();
        const text = h.text?.trim();
        if (code) return { code };
        if (text) return { text };
        return null;
      })
      .filter((x): x is { code: string } | { text: string } => x !== null);
    return out as unknown as Prisma.InputJsonValue;
  }

  private async resolveAttendees(
    businessId: string,
    attendees: TbmAttendeeDto[],
  ): Promise<{ profileId: string | null; name: string }[]> {
    const out: { profileId: string | null; name: string }[] = [];
    for (const a of attendees) {
      if (a.profileId) {
        const profile = await this.prisma.profile.findUnique({
          where: { id: a.profileId },
          select: { id: true, name: true, phoneSearchConsent: true },
        });
        if (!profile) {
          throw new AppException(
            'ATTENDEE_NOT_FOUND',
            '참석자로 연결할 작업자를 찾을 수 없습니다.',
            HttpStatus.NOT_FOUND,
          );
        }
        // 전화검색 동의자 또는 해당 사업장과 ACCEPTED 연결된 작업자만 연결 허용.
        let allowed = profile.phoneSearchConsent;
        if (!allowed) {
          const conn = await this.prisma.connection.findUnique({
            where: {
              profileId_businessId: { profileId: profile.id, businessId },
            },
            select: { status: true },
          });
          allowed = conn?.status === ConnectionStatus.ACCEPTED;
        }
        if (!allowed) {
          throw new AppException(
            'ATTENDEE_LINK_NOT_ALLOWED',
            '전화검색에 동의했거나 연결(수락)된 작업자만 참석자로 연결할 수 있습니다.',
            HttpStatus.FORBIDDEN,
          );
        }
        out.push({
          profileId: profile.id,
          name: a.name?.trim() || profile.name || '작업자',
        });
      } else {
        if (!a.name || !a.name.trim()) {
          throw new AppException(
            'ATTENDEE_NAME_REQUIRED',
            '수기 참석자는 이름이 필요합니다.',
            HttpStatus.BAD_REQUEST,
          );
        }
        out.push({ profileId: null, name: a.name.trim() });
      }
    }
    return out;
  }

  private async notifyAttendees(
    recordId: string,
    businessName: string,
    attendees: { id: string; profileId: string | null; name: string }[],
  ): Promise<void> {
    for (const a of attendees) {
      if (!a.profileId) continue;
      try {
        await this.notifications.create({
          profileId: a.profileId,
          type: NotificationType.TBM,
          title: 'TBM(안전점검회의) 확인 요청',
          body: `${businessName} 현장 TBM 기록이 도착했습니다. 위험요인·안전조치를 확인해 주세요.`,
          data: {
            kind: 'TBM',
            tbmRecordId: recordId,
            tbmAttendeeId: a.id,
          },
        });
      } catch (err) {
        this.logger.warn(
          `[tbm-notify] ${recordId}/${a.id}: ${(err as Error).message}`,
        );
      }
    }
  }

  private async notifyOwnerOnAck(
    businessId: string,
    attendeeName: string,
  ): Promise<void> {
    try {
      const business = await this.prisma.business.findUnique({
        where: { id: businessId },
        select: { ownerId: true, name: true },
      });
      if (!business) return;
      await this.notifications.create({
        profileId: business.ownerId,
        type: NotificationType.TBM,
        title: 'TBM 참석 확인',
        body: `${attendeeName} 님이 TBM 을 확인했습니다.`,
        data: { kind: 'TBM_ACK', businessId },
      });
    } catch (err) {
      this.logger.warn(
        `[tbm-ack-notify] ${businessId}: ${(err as Error).message}`,
      );
    }
  }

  private readPhoto(
    photoPaths: string[],
    index: number,
  ): Promise<{ buffer: Buffer; mime: string }> {
    if (index < 0 || index >= photoPaths.length) {
      throw new AppException(
        'TBM_PHOTO_NOT_FOUND',
        'TBM 사진을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    const rel = photoPaths[index];
    const mime = this.mimeFor(rel);
    return this.storage.readFile(rel).then((buffer) => ({ buffer, mime }));
  }

  private extFor(mime: string): string {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/heic':
      case 'image/heif':
        return '.heic';
      default:
        return '.jpg';
    }
  }

  private mimeFor(path: string): string {
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  private assertEditable(createdAt: Date): void {
    if (!this.isSameKstDay(createdAt, new Date())) {
      throw new AppException(
        'NOT_EDITABLE',
        '작성 당일에만 TBM 기록을 수정할 수 있습니다(증빙 무결성).',
        HttpStatus.CONFLICT,
      );
    }
  }

  private isSameKstDay(a: Date, b: Date): boolean {
    return toKstDateStr(a) === toKstDateStr(b);
  }

  /** occurredAt 의 KST 시각(HH:mm)은 유지하고 날짜만 교체. */
  private replaceKstDate(occurredAt: Date, dateStr: string): Date {
    const KST = 9 * 60 * 60 * 1000;
    const shifted = new Date(occurredAt.getTime() + KST);
    const hh = String(shifted.getUTCHours()).padStart(2, '0');
    const mm = String(shifted.getUTCMinutes()).padStart(2, '0');
    return kstDateTime(dateStr, `${hh}:${mm}`);
  }

  private async myBusinessIds(userId: string): Promise<string[]> {
    const rows = await this.prisma.business.findMany({
      where: { ownerId: userId },
      select: { id: true },
    });
    return rows.map((r) => r.id);
  }

  private async ownedBusinessOrThrow(userId: string, businessId: string) {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      select: { id: true, name: true, ownerId: true },
    });
    if (!business || business.ownerId !== userId) {
      throw new AppException(
        'BUSINESS_NOT_FOUND',
        'TBM 을 기록할 사업장을 찾을 수 없습니다(소유자만 가능).',
        HttpStatus.NOT_FOUND,
      );
    }
    return business;
  }

  private async ownedRecordOrThrow(userId: string, id: string) {
    const r = await this.prisma.tbmRecord.findUnique({
      where: { id },
      include: {
        business: { select: { name: true, ownerId: true } },
        attendees: { orderBy: { createdAt: 'asc' } },
      },
    });
    if (!r || r.business.ownerId !== userId) {
      throw new AppException(
        'TBM_RECORD_NOT_FOUND',
        'TBM 기록을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return r;
  }

  private async attendedRecordOrThrow(userId: string, id: string) {
    const r = await this.prisma.tbmRecord.findUnique({
      where: { id },
      include: { attendees: true },
    });
    const mine = r?.attendees.some((a) => a.profileId === userId);
    if (!r || !mine) {
      throw new AppException(
        'TBM_RECORD_NOT_FOUND',
        'TBM 기록을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return r;
  }

  private async loadOwned(id: string) {
    return this.prisma.tbmRecord.findUniqueOrThrow({
      where: { id },
      include: {
        business: { select: { name: true } },
        attendees: { orderBy: { createdAt: 'asc' } },
      },
    });
  }
}
