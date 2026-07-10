import { HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppException } from '../common/errors';
import { CreateEquipmentDto } from './dto/create-equipment.dto';
import { UpdateEquipmentDto } from './dto/update-equipment.dto';

/**
 * 장비 CRUD — 본인 소유(profileId) 만 접근 가능.
 * 서류는 /documents 에서 ownerType=EQUIPMENT + equipmentId 로 연결한다.
 */
@Injectable()
export class EquipmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    return this.prisma.equipment.findMany({
      where: { profileId: userId },
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { documents: true } } },
    });
  }

  async get(userId: string, id: string) {
    return this.ownedOrThrow(userId, id);
  }

  async create(userId: string, dto: CreateEquipmentDto) {
    return this.prisma.equipment.create({
      data: {
        profileId: userId,
        type: dto.type,
        vehicleNumber: dto.vehicleNumber ?? null,
        spec: dto.spec ?? null,
      },
    });
  }

  async update(userId: string, id: string, dto: UpdateEquipmentDto) {
    await this.ownedOrThrow(userId, id);
    const data: {
      type?: string;
      vehicleNumber?: string | null;
      spec?: string | null;
    } = {};
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.vehicleNumber !== undefined) data.vehicleNumber = dto.vehicleNumber;
    if (dto.spec !== undefined) data.spec = dto.spec;
    return this.prisma.equipment.update({ where: { id }, data });
  }

  async remove(userId: string, id: string) {
    await this.ownedOrThrow(userId, id);
    // 장비 삭제 시 연결 서류는 onDelete: Cascade 로 함께 삭제된다(DB 레코드).
    await this.prisma.equipment.delete({ where: { id } });
    return { deleted: true };
  }

  /** 본인 소유 장비인지 확인하고 반환. 아니면 404(존재 은닉). */
  private async ownedOrThrow(userId: string, id: string) {
    const equipment = await this.prisma.equipment.findUnique({ where: { id } });
    if (!equipment || equipment.profileId !== userId) {
      throw new AppException(
        'EQUIPMENT_NOT_FOUND',
        '장비를 찾을 수 없습니다.',
        HttpStatus.NOT_FOUND,
      );
    }
    return equipment;
  }
}
