#!/bin/bash
# 작업온 로컬 테스트 스택 (이 컴퓨터에서 바로 테스트용)
# 사용법:  ./infra/local-test.sh start   |   ./infra/local-test.sh stop
# 포트: PostgreSQL 5439 / 백엔드 API 3010 / 웹 3001  (5432는 다른 프로젝트 DB라 건드리지 않음)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG_NAME=workon-local-pg
DB_URL="postgresql://jakeobon:jakeobon@localhost:5439/jakeobon?schema=public"

start() {
  echo "── 1/3 PostgreSQL(5439) 시작"
  if ! docker ps --format '{{.Names}}' | grep -q "^${PG_NAME}$"; then
    docker rm -f $PG_NAME >/dev/null 2>&1 || true
    docker run -d --name $PG_NAME -e POSTGRES_USER=jakeobon -e POSTGRES_PASSWORD=jakeobon \
      -e POSTGRES_DB=jakeobon -p 5439:5432 -v workon-local-pgdata:/var/lib/postgresql/data \
      postgres:16-alpine >/dev/null
  fi
  until docker exec $PG_NAME pg_isready -U jakeobon >/dev/null 2>&1; do sleep 0.5; done

  echo "── 2/3 백엔드 API(3010) 시작"
  cd "$ROOT/backend"
  [ -d node_modules ] || npm install
  DATABASE_URL="$DB_URL" npx prisma migrate deploy >/dev/null
  [ -f dist/main.js ] || npm run build
  pkill -f "workon-local-api" >/dev/null 2>&1 || true
  DATABASE_URL="$DB_URL" PORT=3010 JWT_SECRET=local-test-secret-please-change \
    PUBLIC_WEB_URL=http://localhost:3001 NODE_ENV=development \
    nohup node -e "process.title='workon-local-api';require('./dist/main.js')" \
    > /tmp/workon-api.log 2>&1 &
  sleep 3

  echo "── 3/3 웹(3001) 시작"
  cd "$ROOT/web"
  [ -d node_modules ] || npm install
  pkill -f "next dev.*3001" >/dev/null 2>&1 || true
  NEXT_PUBLIC_API_URL=http://localhost:3010/api API_INTERNAL_URL=http://localhost:3010/api \
    nohup npx next dev -p 3001 > /tmp/workon-web.log 2>&1 &
  sleep 5

  echo ""
  echo "✅ 준비 완료!"
  echo "   웹(사업장/외부 페이지):  http://localhost:3001"
  echo "   API 헬스체크:            http://localhost:3010/health"
  echo "   로그인: 전화번호 아무거나 입력 → 화면에 표시되는 개발용 인증코드(devCode) 입력"
  echo "   로그: /tmp/workon-api.log, /tmp/workon-web.log"
}

stop() {
  pkill -f "workon-local-api" 2>/dev/null || true
  pkill -f "next dev.*3001" 2>/dev/null || true
  docker stop $PG_NAME >/dev/null 2>&1 || true
  echo "⏹ 중지 완료 (데이터는 workon-local-pgdata 볼륨에 보존됩니다)"
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  *) echo "사용법: $0 start|stop" ;;
esac
