-- AlterEnum
ALTER TYPE "RateType" ADD VALUE 'GONGSU';

-- AlterTable
ALTER TABLE "ledger_entries" ADD COLUMN     "taxInvoicedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "profiles" ADD COLUMN     "bizAddress" TEXT,
ADD COLUMN     "bizName" TEXT,
ADD COLUMN     "bizNumber" TEXT;
