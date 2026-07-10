-- AlterTable
ALTER TABLE "confirmations" ADD COLUMN     "manualContact" TEXT,
ADD COLUMN     "revokedAt" TIMESTAMP(3),
ADD COLUMN     "viewLogs" JSONB[] DEFAULT ARRAY[]::JSONB[];
