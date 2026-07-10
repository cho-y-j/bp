import { IsOptional, IsString, Matches, ValidateIf } from 'class-validator';

/** 장부 수정 — 현재는 수금예정일(dueDate)만. null 로 보내면 예정일 해제. */
export class UpdateLedgerDto {
  // "YYYY-MM-DD" 또는 null
  @ValidateIf((o: UpdateLedgerDto) => o.dueDate !== null)
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: '수금 예정일은 YYYY-MM-DD 형식이거나 null 이어야 합니다.',
  })
  dueDate?: string | null;
}
