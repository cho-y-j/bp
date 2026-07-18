-- 거래처(partners): 확인서/장부 수기 상대 자동 수집 + 선택 보강 (additive)
-- 식별 키 (profileId, name). 통계는 저장하지 않고 조회 시 confirmations/ledger 에서 파생.
CREATE TABLE "partners" (
    "id" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "alias" TEXT,
    "bizNumber" TEXT,
    "email" TEXT,
    "memo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "partners_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "partners_profileId_idx" ON "partners"("profileId");
CREATE UNIQUE INDEX "partners_profileId_name_key" ON "partners"("profileId", "name");

ALTER TABLE "partners" ADD CONSTRAINT "partners_profileId_fkey"
    FOREIGN KEY ("profileId") REFERENCES "profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
