import { TbmAttendee, TbmRecord } from '@prisma/client';
import { hazardLabelsKo, parseHazards, toTbmRecordDto } from './tbm.mapper';
import { tbmHazardsSummaryKo } from '../common/tbm-presets';

describe('tbm.mapper', () => {
  describe('parseHazards', () => {
    it('code/text 항목만 남기고 빈 항목은 제거한다', () => {
      const out = parseHazards([
        { code: 'FALL_HEIGHT' },
        { text: '개구부 덮개 미설치' },
        { text: '   ' }, // 공백 → 제거
        { foo: 'bar' }, // 무관 → 제거
        'nope', // 문자열 → 제거
      ]);
      expect(out).toEqual([
        { code: 'FALL_HEIGHT', text: undefined },
        { code: undefined, text: '개구부 덮개 미설치' },
      ]);
    });
    it('배열이 아니면 빈 배열', () => {
      expect(parseHazards(null)).toEqual([]);
      expect(parseHazards({})).toEqual([]);
    });
  });

  describe('hazardLabelsKo / summary', () => {
    it('기본 코드는 한국어 라벨로, 커스텀은 원문으로 치환', () => {
      const hazards = [
        { code: 'HEAVY_EQUIP' },
        { code: 'HEAT_ILLNESS' },
        { text: '자재 정리정돈 불량' },
      ];
      expect(hazardLabelsKo(hazards)).toEqual([
        '중장비 협착·충돌(굴착기·지게차)',
        '폭염 온열질환',
        '자재 정리정돈 불량',
      ]);
      expect(tbmHazardsSummaryKo(hazards)).toBe(
        '중장비 협착·충돌(굴착기·지게차), 폭염 온열질환, 자재 정리정돈 불량',
      );
    });
    it('알 수 없는 코드는 text 로 폴백', () => {
      expect(hazardLabelsKo([{ code: 'UNKNOWN', text: '폴백' }])).toEqual([
        '폴백',
      ]);
    });
  });

  describe('toTbmRecordDto', () => {
    const base: TbmRecord = {
      id: '11111111-1111-1111-1111-111111111111',
      businessId: '22222222-2222-2222-2222-222222222222',
      authorProfileId: '33333333-3333-3333-3333-333333333333',
      site: 'A현장',
      occurredAt: new Date('2026-07-11T00:00:00+09:00'),
      hazards: [{ code: 'FALL_HEIGHT' }, { text: '직접입력' }] as never,
      measures: '안전벨트 착용',
      notes: null,
      photoPaths: ['a/b/tbm-photo-0.jpg', 'a/b/tbm-photo-1.jpg'],
      createdAt: new Date('2026-07-11T01:00:00Z'),
      updatedAt: new Date('2026-07-11T01:00:00Z'),
    } as unknown as TbmRecord;

    const attendees: TbmAttendee[] = [
      {
        id: 'a1',
        recordId: base.id,
        profileId: 'p1',
        name: '홍길동',
        ackAt: new Date('2026-07-11T02:00:00Z'),
        createdAt: new Date(),
      },
      {
        id: 'a2',
        recordId: base.id,
        profileId: null,
        name: '수기참석',
        ackAt: null,
        createdAt: new Date(),
      },
    ];

    it('참석/확인 카운트·사진 URL·라벨을 계산한다(biz)', () => {
      const dto = toTbmRecordDto(
        { ...base, business: { name: '대성건설' }, attendees },
        { editable: true },
      );
      expect(dto.businessName).toBe('대성건설');
      expect(dto.date).toBe('2026-07-11');
      expect(dto.attendeeCount).toBe(2);
      expect(dto.ackCount).toBe(1);
      expect(dto.hazardLabelsKo).toEqual(['고소작업 추락', '직접입력']);
      expect(dto.photoCount).toBe(2);
      expect(dto.photoUrls[0]).toBe(
        '/api/biz/tbm/11111111-1111-1111-1111-111111111111/photos/0',
      );
      expect(dto.editable).toBe(true);
      expect(dto.attendees[0]).toMatchObject({ linked: true, acked: true });
      expect(dto.attendees[1]).toMatchObject({ linked: false, acked: false });
    });

    it('worker photoBase 는 /api/tbm 경로', () => {
      const dto = toTbmRecordDto(
        { ...base, attendees: [] },
        { photoBase: 'worker' },
      );
      expect(dto.photoUrls[0]).toBe(
        '/api/tbm/11111111-1111-1111-1111-111111111111/photos/0',
      );
    });
  });
});
