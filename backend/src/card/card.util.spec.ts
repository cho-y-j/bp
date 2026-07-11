import { computeDocValidity, DocForValidity } from './card.util';

// KST 기준 고정 now: 2026-07-12 12:00 KST
const NOW = new Date('2026-07-12T03:00:00.000Z');

function doc(
  type: string,
  expiry: string | null,
  status = 'ACTIVE',
): DocForValidity {
  return { type, expiryDate: expiry ? new Date(expiry) : null, status };
}

describe('card.util — 서류 유효 판정', () => {
  describe('만료일 등록 0건', () => {
    it('만료일 있는 서류가 하나도 없으면 무효(배지 미노출)', () => {
      const r = computeDocValidity([doc('신분증', null)], NOW);
      expect(r.valid).toBe(false);
      expect(r.withExpiryCount).toBe(0);
      expect(r.totalCount).toBe(1);
    });
    it('서류 자체가 0건이면 무효', () => {
      const r = computeDocValidity([], NOW);
      expect(r.valid).toBe(false);
      expect(r.withExpiryCount).toBe(0);
      expect(r.totalCount).toBe(0);
      expect(r.types).toEqual([]);
    });
  });

  describe('만료 없음(전부 유효)', () => {
    it('만료일 등록 1건 + 미래 만료 → 유효', () => {
      const r = computeDocValidity(
        [doc('자격증', '2027-01-01T00:00:00.000Z')],
        NOW,
      );
      expect(r.valid).toBe(true);
      expect(r.withExpiryCount).toBe(1);
    });
    it('오늘 만료(D-0)는 아직 유효(만료 지나지 않음)', () => {
      // 만료일 = 2026-07-12 KST → computeDday=0 → 지나지 않음
      const r = computeDocValidity(
        [doc('장비검사증', '2026-07-12T00:00:00.000Z')],
        NOW,
      );
      expect(r.valid).toBe(true);
    });
    it('만료일 서류 + 만료일 없는 서류 혼재해도 유효', () => {
      const r = computeDocValidity(
        [doc('신분증', null), doc('자격증', '2027-01-01T00:00:00.000Z')],
        NOW,
      );
      expect(r.valid).toBe(true);
      expect(r.withExpiryCount).toBe(1);
      expect(r.totalCount).toBe(2);
    });
  });

  describe('일부 만료(무효)', () => {
    it('만료 지난 서류가 하나라도 있으면 무효', () => {
      const r = computeDocValidity(
        [
          doc('자격증', '2027-01-01T00:00:00.000Z'),
          doc('장비검사증', '2026-07-01T00:00:00.000Z'), // 지남
        ],
        NOW,
      );
      expect(r.valid).toBe(false);
    });
    it('만료 지난 서류가 ARCHIVED 면 판정에서 제외 → 유효', () => {
      const r = computeDocValidity(
        [
          doc('자격증', '2027-01-01T00:00:00.000Z'),
          doc('장비검사증', '2026-07-01T00:00:00.000Z', 'ARCHIVED'),
        ],
        NOW,
      );
      expect(r.valid).toBe(true);
      expect(r.totalCount).toBe(1);
    });
  });

  describe('유형명 요약', () => {
    it('중복 제거 + 정렬, ARCHIVED 제외', () => {
      const r = computeDocValidity(
        [
          doc('자격증', '2027-01-01T00:00:00.000Z'),
          doc('자격증', '2027-02-01T00:00:00.000Z'),
          doc('신분증', null),
          doc('폐기서류', null, 'ARCHIVED'),
        ],
        NOW,
      );
      expect(r.types).toEqual(['신분증', '자격증']);
    });
  });
});
