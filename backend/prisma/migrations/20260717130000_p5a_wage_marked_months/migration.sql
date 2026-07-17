-- P5a: 일용근로소득 지급명세서 월 마감 표시 (additive)
ALTER TABLE "businesses" ADD COLUMN "wageMarkedMonths" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
