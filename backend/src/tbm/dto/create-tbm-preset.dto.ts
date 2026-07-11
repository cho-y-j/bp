import { IsIn, IsString, Matches, MaxLength, MinLength } from 'class-validator';

const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export const TBM_PRESET_KINDS = ['HAZARD', 'MEASURE'] as const;

/** 사업장 커스텀 TBM 프리셋 문구 추가. */
export class CreateTbmPresetDto {
  @IsString()
  @Matches(UUID_RE, { message: 'businessId 는 UUID 형식이어야 합니다.' })
  businessId!: string;

  @IsIn(TBM_PRESET_KINDS, {
    message: 'kind 는 HAZARD | MEASURE 중 하나입니다.',
  })
  kind!: (typeof TBM_PRESET_KINDS)[number];

  @IsString()
  @MinLength(1)
  @MaxLength(200)
  text!: string;
}
