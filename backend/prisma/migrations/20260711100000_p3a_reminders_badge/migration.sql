-- P3a: 수금 독촉 자동화 + 지급 평판 배지 (additive)

-- profiles: 수금 안내용 입금 계좌 (선택 입력)
ALTER TABLE "profiles" ADD COLUMN "payoutBank" TEXT;
ALTER TABLE "profiles" ADD COLUMN "payoutAccount" TEXT;
ALTER TABLE "profiles" ADD COLUMN "payoutHolder" TEXT;

-- businesses: 지급 평판 배지 캐시 컬럼
ALTER TABLE "businesses" ADD COLUMN "paymentAvgDays" DOUBLE PRECISION;
ALTER TABLE "businesses" ADD COLUMN "paymentSampleSize" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "businesses" ADD COLUMN "paymentBadgeUpdatedAt" TIMESTAMP(3);

-- ledger_entries: 수금 독촉 자동화
ALTER TABLE "ledger_entries" ADD COLUMN "autoRemind" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "ledger_entries" ADD COLUMN "reminders" JSONB[] DEFAULT ARRAY[]::JSONB[];
