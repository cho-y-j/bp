import { buildPartnerList } from './partners.util';

/**
 * 거래처 목록 파생 계산 단위 테스트.
 *  - 수기 상대 그룹핑(name)·연결 상대 그룹핑(businessId)
 *  - 미수 집계(computeOutstanding 재사용)·보강행 병합·최근순 정렬
 */
describe('buildPartnerList', () => {
  const now = new Date('2026-07-18T00:00:00+09:00');
  const d = (s: string) => new Date(`${s}T00:00:00+09:00`);

  it('수기 상대: 확인서 건수·미수·최근 작업일 파생 + 보강행 병합', () => {
    const items = buildPartnerList({
      confirmations: [
        {
          businessId: null,
          companyName: '대성건설',
          manualContact: '010-1111-2222',
          date: d('2026-07-05'),
        },
        {
          businessId: null,
          companyName: '대성건설',
          manualContact: '010-1111-3333', // 더 최근 → 대표 전화
          date: d('2026-07-10'),
        },
      ],
      ledgerEntries: [
        {
          businessId: null,
          counterpartyName: '대성건설',
          amount: 300000,
          payments: [{ amount: 100000, paidAt: '2026-07-11' }],
          dueDate: null,
        },
      ],
      partnerRows: [
        {
          id: 'P1',
          name: '대성건설',
          phone: '010-1111-2222',
          alias: '대성',
          bizNumber: '123-45-67890',
          email: null,
          memo: '판교 현장',
        },
      ],
      businesses: [],
      now,
    });
    expect(items).toHaveLength(1);
    const p = items[0];
    expect(p.id).toBe('P1');
    expect(p.linked).toBe(false);
    expect(p.confirmationCount).toBe(2);
    expect(p.outstanding).toBe(200000); // 300000 - 100000
    expect(p.paid).toBe(100000);
    expect(p.lastWorkedDate).toBe('2026-07-10');
    expect(p.phone).toBe('010-1111-3333'); // 최근 확인서 연락처 우선
    expect(p.alias).toBe('대성');
    expect(p.bizNumber).toBe('123-45-67890');
  });

  it('연결(승격) 상대: businessId 그룹 + 사업장명·소유자 전화, id null·linked true', () => {
    const items = buildPartnerList({
      confirmations: [
        {
          businessId: 'B1',
          companyName: '무시됨',
          manualContact: null,
          date: d('2026-07-15'),
        },
      ],
      ledgerEntries: [
        {
          businessId: 'B1',
          counterpartyName: null,
          amount: 500000,
          payments: [],
          dueDate: null,
        },
      ],
      partnerRows: [],
      businesses: [{ id: 'B1', name: '한빛종합건설', ownerPhone: '01099998888' }],
      now,
    });
    expect(items).toHaveLength(1);
    const p = items[0];
    expect(p.id).toBeNull();
    expect(p.businessId).toBe('B1');
    expect(p.linked).toBe(true);
    expect(p.name).toBe('한빛종합건설');
    expect(p.phone).toBe('01099998888');
    expect(p.outstanding).toBe(500000);
    expect(p.confirmationCount).toBe(1);
  });

  it('정렬: 최근 작업일 desc, 확인서 없는 보강행은 뒤로', () => {
    const items = buildPartnerList({
      confirmations: [
        {
          businessId: null,
          companyName: '가건설',
          manualContact: null,
          date: d('2026-07-01'),
        },
        {
          businessId: null,
          companyName: '나건설',
          manualContact: null,
          date: d('2026-07-12'),
        },
      ],
      ledgerEntries: [],
      // 확인서가 없는 보강행(삭제된 상대 등) — 목록엔 남지만 최근일 null 이라 뒤로.
      partnerRows: [
        { id: 'P3', name: '다건설', phone: null, alias: null, bizNumber: null, email: null, memo: null },
      ],
      businesses: [],
      now,
    });
    expect(items.map((i) => i.name)).toEqual(['나건설', '가건설', '다건설']);
    expect(items[2].lastWorkedDate).toBeNull();
  });

  it('대표 전화: 최신 확인서에 연락처가 없어도, 연락처 있는 확인서 중 최신값을 유지(순서 독립)', () => {
    const base = {
      confirmations: [
        // 최신 작업일이지만 연락처 없음
        { businessId: null, companyName: '동방', manualContact: null, date: d('2026-07-20') },
        // 그 전 작업일이지만 연락처 있음 → 대표 전화가 되어야 함
        { businessId: null, companyName: '동방', manualContact: '010-7000-8000', date: d('2026-07-10') },
      ],
      ledgerEntries: [],
      partnerRows: [
        { id: 'P5', name: '동방', phone: null, alias: null, bizNumber: null, email: null, memo: null },
      ],
      businesses: [],
      now,
    };
    expect(buildPartnerList(base)[0].phone).toBe('010-7000-8000');
    // 역순으로 넣어도 동일해야 함
    const rev = { ...base, confirmations: [...base.confirmations].reverse() };
    expect(buildPartnerList(rev)[0].phone).toBe('010-7000-8000');
  });

  it('미수 없음(전액 입금)·연락처 없음도 안전', () => {
    const items = buildPartnerList({
      confirmations: [
        { businessId: null, companyName: '무입금상대', manualContact: null, date: d('2026-07-08') },
      ],
      ledgerEntries: [
        { businessId: null, counterpartyName: '무입금상대', amount: 100000, payments: [{ amount: 100000, paidAt: '2026-07-09' }], dueDate: null },
      ],
      partnerRows: [
        { id: 'P4', name: '무입금상대', phone: null, alias: null, bizNumber: null, email: null, memo: null },
      ],
      businesses: [],
      now,
    });
    expect(items[0].outstanding).toBe(0);
    expect(items[0].paid).toBe(100000);
    expect(items[0].phone).toBeNull();
  });
});
