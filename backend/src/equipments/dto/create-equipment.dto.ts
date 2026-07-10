import { IsOptional, IsString, Length } from 'class-validator';

export class CreateEquipmentDto {
  // 장비 종류 (예: 굴삭기, 지게차) — 필수
  @IsString()
  @Length(1, 40, { message: '장비 종류는 1~40자입니다.' })
  type!: string;

  // 차량번호 (선택)
  @IsOptional()
  @IsString()
  @Length(1, 30)
  vehicleNumber?: string;

  // 규격 (예: 06W, 3.5톤) (선택)
  @IsOptional()
  @IsString()
  @Length(1, 60)
  spec?: string;
}
