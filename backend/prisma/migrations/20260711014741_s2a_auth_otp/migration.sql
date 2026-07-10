-- AlterTable
ALTER TABLE "document_shares" ADD COLUMN     "useMasked" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "jobs" ADD COLUMN     "acceptedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "profiles" ADD COLUMN     "kakaoId" TEXT,
ALTER COLUMN "name" DROP NOT NULL;

-- AlterTable
ALTER TABLE "safety_logs" ADD COLUMN     "businessId" TEXT;

-- CreateTable
CREATE TABLE "otp_codes" (
    "id" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "otp_codes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "otp_codes_phone_idx" ON "otp_codes"("phone");

-- CreateIndex
CREATE INDEX "otp_codes_expiresAt_idx" ON "otp_codes"("expiresAt");

-- CreateIndex
CREATE INDEX "confirmations_profileId_date_idx" ON "confirmations"("profileId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "profiles_kakaoId_key" ON "profiles"("kakaoId");

-- CreateIndex
CREATE INDEX "safety_logs_businessId_idx" ON "safety_logs"("businessId");

-- AddForeignKey
ALTER TABLE "safety_logs" ADD CONSTRAINT "safety_logs_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "businesses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

