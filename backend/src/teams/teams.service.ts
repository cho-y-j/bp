import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { normalizePhone } from '../common/phone.util';
import { CreateTeamDto } from './dto/create-team.dto';
import { UpdateTeamDto } from './dto/update-team.dto';
import { CreateTeamMemberDto } from './dto/create-team-member.dto';
import { UpdateTeamMemberDto } from './dto/update-team-member.dto';
import { toTeamDto, toTeamMemberDto, TeamDto } from './teams.mapper';

/**
 * 팀(반장) 서비스 — 반장 본인만 자기 팀·팀원을 관리한다.
 *  - 팀원: 가입자(profileId 연결, 전화 검색-동의자-) 또는 수기(name+phone) 둘 다 허용.
 */
@Injectable()
export class TeamsService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly memberInclude = {
    members: { orderBy: { createdAt: 'asc' as const } },
  };

  // --------------------------------------------------------------------------
  // 팀 CRUD (반장 본인만)
  // --------------------------------------------------------------------------
  async listTeams(userId: string) {
    const rows = await this.prisma.team.findMany({
      where: { ownerId: userId },
      include: this.memberInclude,
      orderBy: { createdAt: 'asc' },
    });
    return { count: rows.length, items: rows.map(toTeamDto) };
  }

  async getTeam(userId: string, id: string): Promise<TeamDto> {
    const team = await this.ownedTeamOrThrow(userId, id);
    return toTeamDto(team);
  }

  async createTeam(userId: string, dto: CreateTeamDto): Promise<TeamDto> {
    const team = await this.prisma.team.create({
      data: { ownerId: userId, name: dto.name.trim() },
      include: this.memberInclude,
    });
    return toTeamDto(team);
  }

  async updateTeam(
    userId: string,
    id: string,
    dto: UpdateTeamDto,
  ): Promise<TeamDto> {
    await this.ownedTeamOrThrow(userId, id);
    const data: Prisma.TeamUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name.trim();
    const team = await this.prisma.team.update({
      where: { id },
      data,
      include: this.memberInclude,
    });
    return toTeamDto(team);
  }

  async removeTeam(userId: string, id: string) {
    await this.ownedTeamOrThrow(userId, id);
    // 팀원은 cascade 로 함께 삭제. 발행된 확인서의 teamId 는 SetNull 로 유지(장부 보존).
    await this.prisma.team.delete({ where: { id } });
    return { deleted: true };
  }

  // --------------------------------------------------------------------------
  // 팀원 CRUD (반장 본인만)
  // --------------------------------------------------------------------------
  async addMember(userId: string, teamId: string, dto: CreateTeamMemberDto) {
    await this.ownedTeamOrThrow(userId, teamId);

    let profileId: string | null = null;
    let name = dto.name?.trim() ?? '';
    let phone: string | null = dto.phone?.trim() || null;

    if (dto.profileId) {
      // 가입자 연결: 전화검색 동의자만 연결 가능(연결 시점 재확인).
      const profile = await this.prisma.profile.findUnique({
        where: { id: dto.profileId },
        select: { id: true, name: true, phone: true, phoneSearchConsent: true },
      });
      if (!profile) {
        throw new AppException(
          'PROFILE_NOT_FOUND',
          '연결할 가입자를 찾을 수 없습니다.',
          HttpStatus.NOT_FOUND,
        );
      }
      if (!profile.phoneSearchConsent) {
        throw new AppException(
          'CONSENT_REQUIRED',
          '전화번호 검색에 동의한 가입자만 팀원으로 연결할 수 있습니다.',
          HttpStatus.FORBIDDEN,
        );
      }
      // 같은 팀에 같은 가입자 중복 연결 방지.
      const dup = await this.prisma.teamMember.findFirst({
        where: { teamId, profileId: profile.id },
        select: { id: true },
      });
      if (dup) {
        throw new AppException(
          'TEAM_MEMBER_EXISTS',
          '이미 이 팀에 연결된 가입자입니다.',
          HttpStatus.CONFLICT,
        );
      }
      profileId = profile.id;
      if (!name) name = profile.name ?? '팀원';
      if (!phone) phone = profile.phone.startsWith('kakao:') ? null : profile.phone;
    }

    if (!profileId && !name) {
      throw new AppException(
        'TEAM_MEMBER_NAME_REQUIRED',
        '수기 팀원은 이름이 필요합니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    if (phone) phone = normalizePhone(phone);

    const member = await this.prisma.teamMember.create({
      data: {
        teamId,
        profileId,
        name,
        phone,
        defaultRate:
          dto.defaultRate !== undefined
            ? new Prisma.Decimal(dto.defaultRate)
            : null,
      },
    });
    return toTeamMemberDto(member);
  }

  async updateMember(
    userId: string,
    teamId: string,
    memberId: string,
    dto: UpdateTeamMemberDto,
  ) {
    await this.ownedTeamOrThrow(userId, teamId);
    const member = await this.memberOrThrow(teamId, memberId);
    const data: Prisma.TeamMemberUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name.trim();
    if (dto.phone !== undefined)
      data.phone = dto.phone.trim() ? normalizePhone(dto.phone) : null;
    if (dto.defaultRate !== undefined)
      data.defaultRate = new Prisma.Decimal(dto.defaultRate);
    const updated = await this.prisma.teamMember.update({
      where: { id: member.id },
      data,
    });
    return toTeamMemberDto(updated);
  }

  async removeMember(userId: string, teamId: string, memberId: string) {
    await this.ownedTeamOrThrow(userId, teamId);
    const member = await this.memberOrThrow(teamId, memberId);
    await this.prisma.teamMember.delete({ where: { id: member.id } });
    return { deleted: true };
  }

  // --------------------------------------------------------------------------
  // 내부 헬퍼
  // --------------------------------------------------------------------------
  private async ownedTeamOrThrow(userId: string, id: string) {
    const team = await this.prisma.team.findUnique({
      where: { id },
      include: this.memberInclude,
    });
    if (!team || team.ownerId !== userId) {
      throw new AppException(
        'TEAM_NOT_FOUND',
        '팀을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return team;
  }

  private async memberOrThrow(teamId: string, memberId: string) {
    const member = await this.prisma.teamMember.findUnique({
      where: { id: memberId },
    });
    if (!member || member.teamId !== teamId) {
      throw new AppException(
        'TEAM_MEMBER_NOT_FOUND',
        '팀원을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return member;
  }
}
