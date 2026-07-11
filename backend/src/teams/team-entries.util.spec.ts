import { computeTeamEntries, TeamMemberRef } from './team-entries.util';
import { AppException } from '../common/errors';

function members(...refs: TeamMemberRef[]): Map<string, TeamMemberRef> {
  return new Map(refs.map((r) => [r.id, r]));
}

describe('computeTeamEntries (팀 확인서 금액 계산)', () => {
  const m = members(
    { id: 'm1', name: '홍길동', profileId: 'p1', defaultRate: 180000 },
    { id: 'm2', name: '김수기', profileId: null, defaultRate: 150000 },
  );

  it('팀원별 공수×단가 계산 + 팀 합계', () => {
    const res = computeTeamEntries(
      [
        { memberId: 'm1', rate: 180000, quantity: 1.5 },
        { memberId: 'm2', rate: 150000, quantity: 1 },
      ],
      m,
    );
    expect(res.entries).toHaveLength(2);
    expect(res.entries[0]).toMatchObject({
      memberId: 'm1',
      name: '홍길동',
      profileId: 'p1',
      quantity: 1.5,
      rate: 180000,
      amount: 270000,
    });
    expect(res.entries[1].amount).toBe(150000);
    expect(res.total).toBe(420000);
    expect(res.totalGongsu).toBe(2.5);
  });

  it('rate 미지정이면 팀원 defaultRate 로 대체', () => {
    const res = computeTeamEntries([{ memberId: 'm1', quantity: 2 }], m);
    expect(res.entries[0].rate).toBe(180000);
    expect(res.entries[0].amount).toBe(360000);
  });

  it('defaultRate 없고 rate 미지정이면 0원', () => {
    const noRate = members({
      id: 'm3',
      name: '무단가',
      profileId: null,
      defaultRate: null,
    });
    const res = computeTeamEntries([{ memberId: 'm3', quantity: 1 }], noRate);
    expect(res.entries[0].rate).toBe(0);
    expect(res.total).toBe(0);
  });

  it('공수 0.1 단위 위반 → INVALID_GONGSU_QUANTITY', () => {
    expect(() =>
      computeTeamEntries([{ memberId: 'm1', rate: 100000, quantity: 0.55 }], m),
    ).toThrow(AppException);
    try {
      computeTeamEntries([{ memberId: 'm1', rate: 100000, quantity: 0 }], m);
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'INVALID_GONGSU_QUANTITY',
      });
    }
  });

  it('팀에 없는 멤버 → TEAM_MEMBER_NOT_IN_TEAM', () => {
    try {
      computeTeamEntries([{ memberId: 'unknown', quantity: 1 }], m);
      fail('should throw');
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'TEAM_MEMBER_NOT_IN_TEAM',
      });
    }
  });

  it('같은 팀원 중복 입력 → TEAM_MEMBER_DUPLICATED', () => {
    try {
      computeTeamEntries(
        [
          { memberId: 'm1', quantity: 1 },
          { memberId: 'm1', quantity: 1 },
        ],
        m,
      );
      fail('should throw');
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'TEAM_MEMBER_DUPLICATED',
      });
    }
  });

  it('빈 항목 → TEAM_ENTRIES_REQUIRED', () => {
    try {
      computeTeamEntries([], m);
      fail('should throw');
    } catch (e) {
      expect((e as AppException).getResponse()).toMatchObject({
        code: 'TEAM_ENTRIES_REQUIRED',
      });
    }
  });
});
