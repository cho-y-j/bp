-- S2 통합 검수 보강: 열람 카운터 컬럼 + 승격 스캔 인덱스
-- 1) viewLogs 는 최근 50개만 유지(애플리케이션 cap) → 누적 총계는 viewCount 정수 카운터로 유지
ALTER TABLE "confirmations" ADD COLUMN     "viewCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "document_shares" ADD COLUMN     "viewCount" INTEGER NOT NULL DEFAULT 0;

-- 2) 미가입 상대 승격 전역 스캔(manualContact 매칭) 성능 인덱스
CREATE INDEX "confirmations_manualContact_idx" ON "confirmations"("manualContact");
CREATE INDEX "jobs_manualContact_idx" ON "jobs"("manualContact");
