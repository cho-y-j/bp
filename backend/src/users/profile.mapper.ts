import { Profile } from '@prisma/client';

/** Prisma Profile + (선택) 소유 사업장 카운트를 포함하는 조회 결과. */
export type ProfileWithCount = Profile & {
  _count?: { ownedBusinesses: number };
};

export interface ProfileDto {
  id: string;
  name: string | null;
  phone: string;
  kakaoId: string | null;
  phoneSearchConsent: boolean;
  industryTags: string[];
  hasBusiness: boolean; // 사업장 보유 여부 (소유 사업장 존재 → 사업장 모드)
  createdAt: Date;
  updatedAt: Date;
}

/** Profile → API 응답 DTO. 민감/내부 필드는 제외한다. */
export function toProfileDto(profile: ProfileWithCount): ProfileDto {
  return {
    id: profile.id,
    name: profile.name,
    phone: profile.phone,
    kakaoId: profile.kakaoId,
    phoneSearchConsent: profile.phoneSearchConsent,
    industryTags: profile.industryTags,
    hasBusiness: (profile._count?.ownedBusinesses ?? 0) > 0,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  };
}

/** hasBusiness 파생을 위한 include 절 (재사용). */
export const profileCountInclude = {
  _count: { select: { ownedBusinesses: true } },
} as const;
