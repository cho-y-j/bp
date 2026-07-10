-- S2d: 연동·작업지시·사업장·안전·알림
-- AlterTable: businesses — 폭염 좌표/주소
ALTER TABLE "businesses" ADD COLUMN     "address" TEXT,
ADD COLUMN     "lat" DOUBLE PRECISION,
ADD COLUMN     "lng" DOUBLE PRECISION;

-- AlterTable: safety_logs — 작업자 확인(ack) 시각 (최초 1회만 UPDATE)
ALTER TABLE "safety_logs" ADD COLUMN     "ackAt" TIMESTAMP(3);
