import { IsOptional, IsString, Matches } from 'class-validator';

export class SimulateHeatwaveDto {
  @IsOptional()
  @IsString()
  @Matches(
    /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/,
    { message: 'businessId 는 UUID 형식이어야 합니다.' },
  )
  businessId?: string;
}
