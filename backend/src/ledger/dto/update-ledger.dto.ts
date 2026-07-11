import {
  IsBoolean,
  IsOptional,
  IsString,
  Matches,
  ValidateIf,
} from 'class-validator';

/** 장부 수정 — 수금예정일(dueDate) + 자동 수금 안내 토글(autoRemind). */
export class UpdateLedgerDto {
  // "YYYY-MM-DD" 또는 null
  @ValidateIf((o: UpdateLedgerDto) => o.dueDate !== null)
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '수금 예정일은 YYYY-MM-DD 형식이거나 null 이어야 합니다.',
  })
  dueDate?: string | null;

  // 자동 수금 안내 ON/OFF (P3a). 파생 항목은 토글 불가.
  @IsOptional()
  @IsBoolean()
  autoRemind?: boolean;
}
