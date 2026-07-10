/*
  Warnings:

  - You are about to drop the `_SharedDocuments` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "_SharedDocuments" DROP CONSTRAINT "_SharedDocuments_A_fkey";

-- DropForeignKey
ALTER TABLE "_SharedDocuments" DROP CONSTRAINT "_SharedDocuments_B_fkey";

-- AlterTable
ALTER TABLE "document_shares" ADD COLUMN     "revokedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "documents" ADD COLUMN     "fileSize" INTEGER,
ADD COLUMN     "mimeType" TEXT,
ADD COLUMN     "originalFileName" TEXT,
ADD COLUMN     "originalFilePath" TEXT;

-- DropTable
DROP TABLE "_SharedDocuments";

-- CreateTable
CREATE TABLE "shared_documents" (
    "id" TEXT NOT NULL,
    "documentShareId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "useOriginal" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shared_documents_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "shared_documents_documentId_idx" ON "shared_documents"("documentId");

-- CreateIndex
CREATE UNIQUE INDEX "shared_documents_documentShareId_documentId_key" ON "shared_documents"("documentShareId", "documentId");

-- AddForeignKey
ALTER TABLE "shared_documents" ADD CONSTRAINT "shared_documents_documentShareId_fkey" FOREIGN KEY ("documentShareId") REFERENCES "document_shares"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_documents" ADD CONSTRAINT "shared_documents_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "documents"("id") ON DELETE CASCADE ON UPDATE CASCADE;
