import { IsOptional, IsString, Length } from 'class-validator';

// 모든 필드 선택적 (부분 수정)
export class UpdateEquipmentDto {
  @IsOptional()
  @IsString()
  @Length(1, 40, { message: '장비 종류는 1~40자입니다.' })
  type?: string;

  @IsOptional()
  @IsString()
  @Length(1, 30)
  vehicleNumber?: string;

  @IsOptional()
  @IsString()
  @Length(1, 60)
  spec?: string;
}
