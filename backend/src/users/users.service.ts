import { HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import {
  profileCountInclude,
  toProfileDto,
  ProfileDto,
} from './profile.mapper';
import { UpdateMeDto } from './dto/update-me.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string): Promise<ProfileDto> {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: profileCountInclude,
    });
    if (!profile) {
      throw new AppException(
        'PROFILE_NOT_FOUND',
        '프로필을 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return toProfileDto(profile);
  }

  async updateMe(userId: string, dto: UpdateMeDto): Promise<ProfileDto> {
    // undefined 필드는 무시 (부분 수정)
    const data: {
      name?: string;
      industryTags?: string[];
      phoneSearchConsent?: boolean;
      bizNumber?: string;
      bizName?: string;
      bizAddress?: string;
      payoutBank?: string;
      payoutAccount?: string;
      payoutHolder?: string;
    } = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.industryTags !== undefined) data.industryTags = dto.industryTags;
    if (dto.phoneSearchConsent !== undefined)
      data.phoneSearchConsent = dto.phoneSearchConsent;
    if (dto.bizNumber !== undefined) data.bizNumber = dto.bizNumber;
    if (dto.bizName !== undefined) data.bizName = dto.bizName;
    if (dto.bizAddress !== undefined) data.bizAddress = dto.bizAddress;
    if (dto.payoutBank !== undefined) data.payoutBank = dto.payoutBank;
    if (dto.payoutAccount !== undefined) data.payoutAccount = dto.payoutAccount;
    if (dto.payoutHolder !== undefined) data.payoutHolder = dto.payoutHolder;

    const profile = await this.prisma.profile.update({
      where: { id: userId },
      data,
      include: profileCountInclude,
    });
    return toProfileDto(profile);
  }
}
