#!/usr/bin/env bash
# ============================================================================
#  작업온 — 일일 백업 (PostgreSQL 덤프 + 업로드 파일 rsync)
#
#  수동 실행:  ./infra/backup.sh
#  크론(매일 03:30):
#    30 3 * * *  cd /opt/jakeobon && ./infra/backup.sh >> /var/log/jakeobon-backup.log 2>&1
#
#  환경변수(선택):
#    BACKUP_DIR   백업 저장 경로 (기본 /opt/jakeobon-backups)
#    RETENTION_DAYS  DB 덤프 보관 일수 (기본 14)
#    OFFSITE_RSYNC   설정 시 백업본을 원격으로 미러링 (예: user@host:/backups/jakeobon)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

BACKUP_DIR="${BACKUP_DIR:-/opt/jakeobon-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TS="$(date +%Y%m%d-%H%M%S)"

COMPOSE=(docker compose -f infra/docker-compose.yml -f infra/docker-compose.prod.yml)

log(){ printf '[backup %s] %s\n' "$(date +%H:%M:%S)" "$*"; }

# .env 에서 DB 접속 정보 로드
[ -f .env ] || { echo "[backup][ERROR] .env 없음"; exit 1; }
# shellcheck disable=SC1091
set -a; . ./.env; set +a
PGUSER="${POSTGRES_USER:-jakeobon}"
PGDB="${POSTGRES_DB:-jakeobon}"

mkdir -p "$BACKUP_DIR/db" "$BACKUP_DIR/uploads"

# --- 1) PostgreSQL 덤프 (custom 포맷 + gzip) --------------------------------
DUMP="$BACKUP_DIR/db/jakeobon-$TS.dump.gz"
log "pg_dump → $DUMP"
"${COMPOSE[@]}" exec -T postgres pg_dump -U "$PGUSER" -d "$PGDB" -Fc | gzip > "$DUMP"
log "덤프 크기: $(du -h "$DUMP" | cut -f1)"
# 복원 예시:  gunzip -c FILE.dump.gz | docker compose ... exec -T postgres pg_restore -U jakeobon -d jakeobon --clean

# --- 2) 업로드 파일 rsync (명명 볼륨 → 백업 디렉터리 미러) -------------------
# uploads 는 docker 명명 볼륨이므로, 임시 alpine 컨테이너에 볼륨을 붙여 rsync 한다.
PROJECT="$(basename "$ROOT_DIR" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
VOL="$("${COMPOSE[@]}" ps -q api >/dev/null 2>&1 && docker inspect -f '{{ range .Mounts }}{{ if eq .Destination "/app/uploads" }}{{ .Name }}{{ end }}{{ end }}' "$("${COMPOSE[@]}" ps -q api)" 2>/dev/null || true)"
VOL="${VOL:-${PROJECT}_uploads}"
log "업로드 볼륨 rsync ($VOL → $BACKUP_DIR/uploads)"
docker run --rm \
  -v "${VOL}:/uploads:ro" \
  -v "${BACKUP_DIR}/uploads:/backup" \
  alpine:3.20 sh -c "apk add --no-cache rsync >/dev/null && rsync -a --delete /uploads/ /backup/"

# --- 3) 보관 정책 (DB 덤프 N일 초과분 삭제) --------------------------------
log "보관 정책: ${RETENTION_DAYS}일 초과 덤프 삭제"
find "$BACKUP_DIR/db" -name 'jakeobon-*.dump.gz' -type f -mtime "+${RETENTION_DAYS}" -delete || true

# --- 4) (선택) 오프사이트 미러 --------------------------------------------
if [ -n "${OFFSITE_RSYNC:-}" ]; then
  log "오프사이트 미러 → $OFFSITE_RSYNC"
  rsync -az --delete "$BACKUP_DIR/" "$OFFSITE_RSYNC/"
fi

log "백업 완료"
