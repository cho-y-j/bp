import { LaborContract } from '@prisma/client';
import { toLaborContractDto } from './labor-contracts.mapper';

/** 순수 매퍼 단위 테스트 — Decimal/날짜/서명 상태 변환·경로 비노출. */
describe('toLaborContractDto', () => {
  const base = (over: Partial<LaborContract> = {}): LaborContract =>
    ({
      id: 'c1',
      businessId: 'b1',
      title: '표준근로계약서',
      workerProfileId: null,
      workerName: '김근로',
      workerPhone: '01011112222',
      startDate: new Date('2026-07-10T00:00:00+09:00'),
      endDate: null,
      workplace: '반포 현장',
      jobDescription: '철근 배근',
      workStartTime: '08:00',
      workEndTime: '17:00',
      breakTime: '12:00~13:00',
      wageType: 'DAILY',
      wageAmount: { toString: () => '180000' } as unknown as never,
      payday: '매월 말일',
      payMethod: '계좌 입금',
      weeklyHolidayAllowance: false,
      overtimeAllowance: true,
      socialInsurance: { employment: true } as never,
      specialTerms: null,
      employerSignImagePath: 'b1/c1/employer-signature.png',
      employerSignerName: '대표',
      employerSignedAt: new Date('2026-07-10T09:00:00+09:00'),
      workerSignImagePath: null,
      workerSignerName: null,
      workerSignedAt: null,
      shareToken: 'tok',
      revokedAt: null,
      viewLogs: [],
      viewCount: 3,
      status: 'SENT',
      createdAt: new Date('2026-07-10T00:00:00Z'),
      updatedAt: new Date('2026-07-10T00:00:00Z'),
      ...over,
    }) as unknown as LaborContract;

  it('일급 계약(수기, 사업장만 서명) 변환', () => {
    const dto = toLaborContractDto(base());
    expect(dto.wageAmount).toBe(180000);
    expect(dto.wageTypeLabel).toBe('일급');
    expect(dto.workerLinked).toBe(false);
    expect(dto.employerSigned).toBe(true);
    expect(dto.workerSigned).toBe(false);
    expect(dto.statusLabel).toBe('전송됨');
    expect(dto.startDate).toBe('2026-07-10');
    expect(dto.endDate).toBeNull();
    // 내부 파일 경로는 노출하지 않는다.
    expect(JSON.stringify(dto)).not.toContain('employer-signature.png');
  });

  it('가입 연결 + 양측 서명 완료', () => {
    const dto = toLaborContractDto(
      base({
        workerProfileId: 'p9',
        wageType: 'HOURLY',
        wageAmount: { toString: () => '11000' } as unknown as never,
        status: 'SIGNED',
        workerSignerName: '김근로',
        workerSignedAt: new Date('2026-07-11T10:00:00+09:00'),
        endDate: new Date('2026-07-31T00:00:00+09:00'),
      }),
    );
    expect(dto.workerLinked).toBe(true);
    expect(dto.wageTypeLabel).toBe('시급');
    expect(dto.wageAmount).toBe(11000);
    expect(dto.workerSigned).toBe(true);
    expect(dto.statusLabel).toBe('서명됨');
    expect(dto.endDate).toBe('2026-07-31');
  });

  it('사업장명 include 시 businessName 채움', () => {
    const dto = toLaborContractDto(
      Object.assign(base(), { business: { name: '대성건설' } }),
    );
    expect(dto.businessName).toBe('대성건설');
  });
});
