# ===== 작업온 백엔드 (NestJS + Prisma) =====
# 멀티스테이지: 빌드 → 슬림 런타임

# ---- build stage ----
FROM node:22-alpine AS builder
WORKDIR /app

# Prisma 는 alpine 에서 openssl 필요
RUN apk add --no-cache openssl

COPY package*.json ./
RUN npm ci

COPY prisma ./prisma
RUN npx prisma generate

COPY . .
RUN npm run build

# ---- runtime stage ----
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY package*.json ./
RUN npm ci --omit=dev

# 빌드 산출물 + 생성된 prisma client + 스키마/마이그레이션
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY prisma ./prisma
# 확인서/명세서 PDF 한글 폰트 (assets/fonts)
COPY --from=builder /app/assets ./assets

# 비루트 실행 (S1 검수 지적: api 컨테이너 root 회피).
#  - uploads 디렉터리를 미리 만들어 소유권을 부여 → 명명 볼륨이 이 소유권으로 초기화되어
#    비루트 사용자도 서류/사진 업로드를 쓸 수 있다.
RUN mkdir -p /app/uploads \
  && addgroup -g 1001 -S nodejs \
  && adduser -S nestjs -u 1001 \
  && chown -R nestjs:nodejs /app
USER nestjs

EXPOSE 3000

# 컨테이너 기동 시 마이그레이션 적용 후 서버 실행
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
