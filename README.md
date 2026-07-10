# 작업온 (Jakeobon)

> 일한 것을 30초에 기록하면, 확인서·장부·정산·안전증빙이 자동으로 따라오는 앱.

작업자(개인사업자·일용직·기술자·장비기사)와 소사업장(지시자)을 위한 서비스입니다.
핵심 차별점은 **상대가 미가입이어도 링크 하나로 확인서 열람·서명이 가능**하다는 점입니다.

기획·설계 문서는 [`docs/`](docs/) 를 참고하세요.

> **상태: S1~S5 전 단계 완료.** 백엔드 API + 웹 + Flutter 앱 구현·검수 완료, 통합 스택
> E2E 검증 통과, 리눅스 서버 배포 산출물 완비. 실제 서버 배포는 [`docs/DEPLOY.md`](docs/DEPLOY.md) 를 따라 하세요.

---

## 모노레포 구조

```
bp/
├── backend/   NestJS + Prisma + PostgreSQL 16  (단일 모놀리식 API)
├── web/       Next.js (App Router) — 확인서 외부 열람·서명 + 사업장 웹
├── app/       Flutter (작업자 + 사업장 모드)
├── infra/     docker-compose(.yml/.dev/.prod) + nginx + deploy.sh/backup.sh
├── docs/      기획·설계·배포·작업 기록
├── design/    디자인 시안
└── ref/       SKEP 참고 코드 (빌드 제외, 수정 금지)
```

### 문서 인덱스 (docs/)

| 문서 | 내용 |
|------|------|
| [PROJECT.md](docs/PROJECT.md) | 요구사항·기획 |
| [DESIGN.md](docs/DESIGN.md) / [DESIGN-UI.md](docs/DESIGN-UI.md) | 도메인·UI 설계 |
| [API-SPEC.md](docs/API-SPEC.md) | API 계약 |
| [BUILD-PLAN.md](docs/BUILD-PLAN.md) | 스테이지 계획·완료 체크(단일 기준) |
| [STATUS.md](docs/STATUS.md) | 현재 상태(세션 시작 시 최우선) |
| **[DEPLOY.md](docs/DEPLOY.md)** | **리눅스 서버 배포 체크리스트 + 외부 키 4종 발급 절차** |
| [worklog/](docs/worklog/) | 스테이지별 작업/검수 기록 |

---

## 기술 스택

| 레이어 | 선택 |
|---|---|
| 백엔드 API | NestJS (Node.js + TypeScript) 모놀리식 |
| ORM / DB | Prisma + PostgreSQL 16 |
| 웹 | Next.js (App Router) |
| 앱 | Flutter (iOS + Android) |
| 배포 | Docker Compose (api + postgres + web + nginx) + Let's Encrypt |

---

## 로컬 실행 방법

### 사전 준비
- Node.js 22+ (개발은 최신 LTS 권장), npm
- Docker / Docker Compose

### 1) 개발 모드 (postgres 만 컨테이너, api/web 은 로컬 실행) — 권장

```bash
# 1. Postgres 16 컨테이너 기동
docker compose -f infra/docker-compose.dev.yml up -d

# 2. 백엔드
cd backend
cp .env.example .env          # 필요 시 값 수정 (DATABASE_URL 등)
npm install
npm run prisma:migrate        # 스키마 → DB 마이그레이션 적용
npm run start:dev             # http://localhost:3000

# 헬스체크 확인
curl http://localhost:3000/health
#   → {"status":"ok","service":"jakeobon-api","checks":{"database":"up"}, ...}

# 3. 웹 (다른 터미널)
cd web
npm install
npm run dev                   # http://localhost:3001  → /health 로 리다이렉트
```

앱(Flutter)은 `app/` 에서 `flutter run` (개발 시 `--dart-define=BASE_URL=http://localhost:3030/api`).

### 2) 통합 모드 (전체 스택을 컨테이너로)

```bash
cp infra/.env.example .env    # 루트에 .env 생성 후 값 채우기
docker compose -f infra/docker-compose.yml up -d --build

# nginx 리버스 프록시를 통해 단일 진입점(:80)으로 접근
curl http://localhost/health  # API 헬스체크
open http://localhost/        # 웹
```

- `/api/...` → 백엔드(NestJS, 전역 prefix `/api`) · `/health` → 헬스체크
- `/` → 웹(Next.js) · `/uploads/...` → 업로드 파일 정적 서빙

> ⚠️ compose override 로 포트를 **대체**하려면 `ports: !override` 필수(안 쓰면 병합됨). 상세는 DEPLOY.md 7절.

---

## 서버 배포 (요약)

자체 리눅스 서버에서 Docker Compose 로 직접 운영합니다 (Supabase 미사용).
**전체 절차·외부 키 발급·HTTPS·백업은 [`docs/DEPLOY.md`](docs/DEPLOY.md) 참고.**

```bash
# 서버에서 (Docker 설치 + .env 작성 후)
./infra/deploy.sh     # pull → build → migrate → up (원스텝, 재배포도 동일)
./infra/backup.sh     # pg_dump + uploads rsync (일일 크론 권장)
```

운영 산출물:
- [`infra/docker-compose.prod.yml`](infra/docker-compose.prod.yml) — 재시작 정책·로그 로테이션·리소스 제한(base 위 오버레이)
- api 컨테이너는 **비루트(nestjs)** 로 실행, `prisma migrate deploy` 자동 적용
- nginx 앞단 **Let's Encrypt(TLS)** 종단 (DEPLOY.md 3절)

---

## 각 서비스 상세

- 백엔드: [`backend/`](backend/) — Prisma 스키마 [`backend/prisma/schema.prisma`](backend/prisma/schema.prisma) · 단위 73 · e2e 71
- 웹: [`web/`](web/) — Next.js 15 standalone
- 앱: [`app/`](app/) — Flutter (작업자 + 사업장 모드)
- 인프라: [`infra/`](infra/)
