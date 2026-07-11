-- P3b: QR 명함 (작업자 공개 프로필). additive.
ALTER TABLE "profiles" ADD COLUMN "cardToken" TEXT;
ALTER TABLE "profiles" ADD COLUMN "cardEnabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "profiles" ADD COLUMN "cardIntro" TEXT;
ALTER TABLE "profiles" ADD COLUMN "cardViewCount" INTEGER NOT NULL DEFAULT 0;

-- 공개 프로필 토큰은 유일해야 한다 (충돌 방지).
CREATE UNIQUE INDEX "profiles_cardToken_key" ON "profiles"("cardToken");
