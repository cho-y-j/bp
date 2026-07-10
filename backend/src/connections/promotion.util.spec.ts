import { selectPromotable } from './promotion.util';
import { maskName, normalizePhone } from '../common/phone.util';

describe('promotion.util — 미가입 상대 승격 매칭', () => {
  it('하이픈/공백 무시하고 정규화 매칭한다', () => {
    const candidates = [
      { id: 'a', manualContact: '010-1234-5678' },
      { id: 'b', manualContact: '01099998888' },
      { id: 'c', manualContact: '010 1234 5678' },
    ];
    const matched = selectPromotable(candidates, ['01012345678']);
    expect(matched.sort()).toEqual(['a', 'c']);
  });

  it('여러 전화 집합 중 하나라도 맞으면 승격 대상', () => {
    const candidates = [
      { id: 'a', manualContact: '010-1111-2222' },
      { id: 'b', manualContact: '010-3333-4444' },
    ];
    const matched = selectPromotable(candidates, [
      '01033334444',
      '01055556666',
    ]);
    expect(matched).toEqual(['b']);
  });

  it('전화가 없거나 너무 짧은 후보/집합은 매칭하지 않는다', () => {
    const candidates = [
      { id: 'a', manualContact: null },
      { id: 'b', manualContact: '123' },
      { id: 'c', manualContact: '010-0000-0000' },
    ];
    expect(selectPromotable(candidates, [])).toEqual([]);
    expect(selectPromotable(candidates, ['123'])).toEqual([]);
    expect(selectPromotable(candidates, ['01000000000'])).toEqual(['c']);
  });

  it('매칭 없으면 빈 배열', () => {
    const matched = selectPromotable(
      [{ id: 'a', manualContact: '010-1234-5678' }],
      ['01099999999'],
    );
    expect(matched).toEqual([]);
  });
});

describe('phone.util', () => {
  it('normalizePhone 숫자만 남긴다', () => {
    expect(normalizePhone('010-1234-5678')).toBe('01012345678');
    expect(normalizePhone(' 010 1234 5678 ')).toBe('01012345678');
    expect(normalizePhone(null)).toBe('');
  });

  it('maskName 가운데를 가린다 (홍길동 → 홍*동)', () => {
    expect(maskName('홍길동')).toBe('홍*동');
    expect(maskName('김철수')).toBe('김*수');
    expect(maskName('김철')).toBe('김*');
    expect(maskName('김')).toBe('*');
    expect(maskName('남궁민수')).toBe('남**수');
    expect(maskName('')).toBe('');
  });
});
