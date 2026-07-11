-- CreateEnum
CREATE TYPE "LaborContractStatus" AS ENUM ('DRAFT', 'SENT', 'SIGNED');

-- CreateEnum
CREATE TYPE "WageType" AS ENUM ('DAILY', 'HOURLY');

-- CreateTable
CREATE TABLE "labor_contracts" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "title" TEXT NOT NULL DEFAULT '표준근로계약서',
    "workerProfileId" TEXT,
    "workerName" TEXT NOT NULL,
    "workerPhone" TEXT,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3),
    "workplace" TEXT NOT NULL,
    "jobDescription" TEXT NOT NULL,
    "workStartTime" TEXT NOT NULL,
    "workEndTime" TEXT NOT NULL,
    "breakTime" TEXT,
    "wageType" "WageType" NOT NULL,
    "wageAmount" DECIMAL(12,2) NOT NULL,
    "payday" TEXT NOT NULL,
    "payMethod" TEXT NOT NULL,
    "weeklyHolidayAllowance" BOOLEAN NOT NULL DEFAULT false,
    "overtimeAllowance" BOOLEAN NOT NULL DEFAULT true,
    "socialInsurance" JSONB,
    "specialTerms" TEXT,
    "employerSignImagePath" TEXT,
    "employerSignerName" TEXT,
    "employerSignedAt" TIMESTAMP(3),
    "workerSignImagePath" TEXT,
    "workerSignerName" TEXT,
    "workerSignedAt" TIMESTAMP(3),
    "shareToken" TEXT NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "viewLogs" JSONB[] DEFAULT ARRAY[]::JSONB[],
    "viewCount" INTEGER NOT NULL DEFAULT 0,
    "status" "LaborContractStatus" NOT NULL DEFAULT 'DRAFT',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "labor_contracts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "labor_contracts_shareToken_key" ON "labor_contracts"("shareToken");

-- CreateIndex
CREATE INDEX "labor_contracts_businessId_idx" ON "labor_contracts"("businessId");

-- CreateIndex
CREATE INDEX "labor_contracts_workerProfileId_idx" ON "labor_contracts"("workerProfileId");

-- CreateIndex
CREATE INDEX "labor_contracts_status_idx" ON "labor_contracts"("status");

-- AddForeignKey
ALTER TABLE "labor_contracts" ADD CONSTRAINT "labor_contracts_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "labor_contracts" ADD CONSTRAINT "labor_contracts_workerProfileId_fkey" FOREIGN KEY ("workerProfileId") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
