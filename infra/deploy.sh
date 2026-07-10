#!/usr/bin/env bash
# ============================================================================
#  작업온 — 서버 원스텝 배포 (pull → build → migrate → up)
#
#  사용:  cd /opt/jakeobon && ./infra/deploy.sh
#  전제:  저장소 루트에 .env 가 채워져 있어야 한다(infra/.env.example 참고).
#         Docker + docker compose v2 설치 필요.
# ============================================================================
set -euo pipefail

# 저장소 루트(이 스크립트의 상위/상위)로 이동
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

COMPOSE=(docker compose \
  -f infra/docker-compose.yml \
  -f infra/docker-compose.prod.yml)

log(){ printf '\n\033[1;36m[deploy] %s\033[0m\n' "$*"; }
die(){ printf '\n\033[1;31m[deploy][ERROR] %s\033[0m\n' "$*" >&2; exit 1; }

# --- 0) 사전 점검 -----------------------------------------------------------
[ -f .env ] || die ".env 파일이 없습니다. infra/.env.example 를 복사해 값을 채우세요."

# 약한 JWT_SECRET 가드 (api 는 production 에서 fail-fast 하지만, 여기서 먼저 걸러 준다)
JWT_SECRET_VAL="$(grep -E '^JWT_SECRET=' .env | head -1 | cut -d= -f2- | tr -d '"'"'"' ')"
case "${JWT_SECRET_VAL}" in
  ''|*change-me*|*changeme*|*your-secret*)
    die "JWT_SECRET 이 비어있거나 약한 기본값입니다. 강한 값으로 교체하세요: openssl rand -hex 32" ;;
esac
[ "${#JWT_SECRET_VAL}" -ge 16 ] || die "JWT_SECRET 은 16자 이상이어야 합니다."

# --- 1) 최신 코드 -----------------------------------------------------------
if [ -d .git ]; then
  log "git pull"
  git pull --ff-only
else
  log "git 저장소가 아니므로 pull 을 건너뜁니다(수동 배포)."
fi

# --- 2) 이미지 빌드 ---------------------------------------------------------
log "이미지 빌드 (backend/web)"
"${COMPOSE[@]}" build

# --- 3) DB 기동 + 마이그레이션 ---------------------------------------------
log "postgres 기동 대기"
"${COMPOSE[@]}" up -d postgres
# postgres healthy 대기 (최대 60초)
for i in $(seq 1 30); do
  cid="$("${COMPOSE[@]}" ps -q postgres)"
  st="$(docker inspect -f '{{.State.Health.Status}}' "$cid" 2>/dev/null || echo starting)"
  [ "$st" = "healthy" ] && break
  sleep 2
done
[ "${st:-}" = "healthy" ] || die "postgres 가 정상(healthy) 상태가 되지 못했습니다."

log "prisma 마이그레이션 적용 (migrate deploy)"
# api 컨테이너 CMD 도 migrate 하지만, 명확한 실패 지점을 위해 선행 실행
"${COMPOSE[@]}" run --rm --no-deps api npx prisma migrate deploy

# --- 4) 전체 기동 -----------------------------------------------------------
log "전체 스택 기동 (api / web / nginx)"
"${COMPOSE[@]}" up -d --remove-orphans

# --- 5) 확인 ---------------------------------------------------------------
log "기동 상태"
"${COMPOSE[@]}" ps
log "헬스체크 (nginx 경유 /health)"
sleep 3
if curl -fsS http://localhost/health >/dev/null 2>&1; then
  printf '\033[1;32m[deploy] 배포 완료 — /health OK\033[0m\n'
else
  printf '\033[1;33m[deploy] /health 응답 대기 중일 수 있습니다. `%s logs -f api` 로 확인하세요.\033[0m\n' "${COMPOSE[*]}"
fi
