import { Team, TeamMember } from '@prisma/client';

export interface TeamMemberDto {
  id: string;
  name: string;
  profileId: string | null;
  linked: boolean; // 가입자 연결 여부
  phone: string | null;
  defaultRate: number | null;
  createdAt: Date;
}

export interface TeamDto {
  id: string;
  name: string;
  memberCount: number;
  members: TeamMemberDto[];
  createdAt: Date;
  updatedAt: Date;
}

export function toTeamMemberDto(m: TeamMember): TeamMemberDto {
  return {
    id: m.id,
    name: m.name,
    profileId: m.profileId,
    linked: m.profileId !== null,
    phone: m.phone,
    defaultRate: m.defaultRate !== null ? Number(m.defaultRate) : null,
    createdAt: m.createdAt,
  };
}

export function toTeamDto(team: Team & { members?: TeamMember[] }): TeamDto {
  const members = (team.members ?? []).map(toTeamMemberDto);
  return {
    id: team.id,
    name: team.name,
    memberCount: members.length,
    members,
    createdAt: team.createdAt,
    updatedAt: team.updatedAt,
  };
}
