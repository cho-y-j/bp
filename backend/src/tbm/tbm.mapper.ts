import { TbmAttendee, TbmPreset, TbmRecord } from '@prisma/client';
import { toKstDateStr, toKstDateTimeStr } from '../confirmations/time.util';
import { TbmHazardItem, TBM_HAZARD_LABEL_KO } from '../common/tbm-presets';

export interface TbmAttendeeDtoOut {
  id: string;
  profileId: string | null;
  linked: boolean;
  name: string;
  acked: boolean;
  ackAt: string | null;
}

export interface TbmRecordDto {
  id: string;
  businessId: string;
  businessName?: string | null;
  site: string;
  occurredAt: string; // YYYY-MM-DD HH:mm (KST)
  date: string; // YYYY-MM-DD
  hazards: TbmHazardItem[]; // 키 기반 [{ code?, text? }]
  hazardLabelsKo: string[]; // 한국어 라벨(참고/작성자 표시용)
  measures: string | null;
  notes: string | null;
  photoCount: number;
  photoUrls: string[]; // GET /biz/tbm/:id/photos/:idx
  attendeeCount: number;
  ackCount: number;
  attendees: TbmAttendeeDtoOut[];
  editable: boolean; // 당일 여부(사업장 응답에서만 유효)
  createdAt: Date;
  updatedAt: Date;
}

/** 위험요인 JSON → 안전한 TbmHazardItem[] 로 정규화. */
export function parseHazards(raw: unknown): TbmHazardItem[] {
  if (!Array.isArray(raw)) return [];
  const out: TbmHazardItem[] = [];
  for (const it of raw) {
    if (it && typeof it === 'object') {
      const o = it as { code?: unknown; text?: unknown };
      const code = typeof o.code === 'string' ? o.code : undefined;
      const text = typeof o.text === 'string' ? o.text : undefined;
      if (code || (text && text.trim())) out.push({ code, text });
    }
  }
  return out;
}

export function hazardLabelsKo(hazards: TbmHazardItem[]): string[] {
  return hazards
    .map((h) =>
      h.code && TBM_HAZARD_LABEL_KO[h.code]
        ? TBM_HAZARD_LABEL_KO[h.code]
        : (h.text ?? '').trim(),
    )
    .filter((s) => s.length > 0);
}

export function toTbmAttendeeDto(a: TbmAttendee): TbmAttendeeDtoOut {
  return {
    id: a.id,
    profileId: a.profileId,
    linked: a.profileId !== null,
    name: a.name,
    acked: a.ackAt !== null,
    ackAt: a.ackAt ? toKstDateTimeStr(a.ackAt) : null,
  };
}

type RecordWithRelations = TbmRecord & {
  business?: { name: string } | null;
  attendees?: TbmAttendee[];
};

export function toTbmRecordDto(
  r: RecordWithRelations,
  opts: { editable?: boolean; photoBase?: 'biz' | 'worker' } = {},
): TbmRecordDto {
  const hazards = parseHazards(r.hazards);
  const attendees = (r.attendees ?? []).map(toTbmAttendeeDto);
  const photoPaths = r.photoPaths ?? [];
  const base = opts.photoBase === 'worker' ? 'tbm' : 'biz/tbm';
  return {
    id: r.id,
    businessId: r.businessId,
    businessName: r.business?.name ?? null,
    site: r.site,
    occurredAt: toKstDateTimeStr(r.occurredAt),
    date: toKstDateStr(r.occurredAt),
    hazards,
    hazardLabelsKo: hazardLabelsKo(hazards),
    measures: r.measures,
    notes: r.notes,
    photoCount: photoPaths.length,
    photoUrls: photoPaths.map((_, idx) => `/api/${base}/${r.id}/photos/${idx}`),
    attendeeCount: attendees.length,
    ackCount: attendees.filter((a) => a.acked).length,
    attendees,
    editable: opts.editable ?? false,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  };
}

export function toTbmPresetDto(p: TbmPreset) {
  return {
    id: p.id,
    businessId: p.businessId,
    kind: p.kind,
    text: p.text,
    createdAt: p.createdAt,
  };
}
