-- CreateEnum
CREATE TYPE "TbmPresetKind" AS ENUM ('HAZARD', 'MEASURE');

-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'TBM';

-- AlterEnum
ALTER TYPE "SafetyLogType" ADD VALUE 'TBM';

-- CreateTable
CREATE TABLE "tbm_records" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "authorProfileId" TEXT,
    "site" TEXT NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL,
    "hazards" JSONB NOT NULL DEFAULT '[]',
    "measures" TEXT,
    "notes" TEXT,
    "photoPaths" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tbm_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tbm_attendees" (
    "id" TEXT NOT NULL,
    "recordId" TEXT NOT NULL,
    "profileId" TEXT,
    "name" TEXT NOT NULL,
    "ackAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbm_attendees_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tbm_presets" (
    "id" TEXT NOT NULL,
    "businessId" TEXT NOT NULL,
    "kind" "TbmPresetKind" NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tbm_presets_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "tbm_records_businessId_idx" ON "tbm_records"("businessId");

-- CreateIndex
CREATE INDEX "tbm_records_businessId_occurredAt_idx" ON "tbm_records"("businessId", "occurredAt");

-- CreateIndex
CREATE INDEX "tbm_attendees_recordId_idx" ON "tbm_attendees"("recordId");

-- CreateIndex
CREATE INDEX "tbm_attendees_profileId_idx" ON "tbm_attendees"("profileId");

-- CreateIndex
CREATE INDEX "tbm_presets_businessId_idx" ON "tbm_presets"("businessId");

-- AddForeignKey
ALTER TABLE "tbm_records" ADD CONSTRAINT "tbm_records_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbm_records" ADD CONSTRAINT "tbm_records_authorProfileId_fkey" FOREIGN KEY ("authorProfileId") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbm_attendees" ADD CONSTRAINT "tbm_attendees_recordId_fkey" FOREIGN KEY ("recordId") REFERENCES "tbm_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbm_attendees" ADD CONSTRAINT "tbm_attendees_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tbm_presets" ADD CONSTRAINT "tbm_presets_businessId_fkey" FOREIGN KEY ("businessId") REFERENCES "businesses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
