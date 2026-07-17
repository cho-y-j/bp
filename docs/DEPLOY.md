# 작업온 배포 가이드 (리눅스 서버 · Docker)

> 이 문서는 **처음부터 따라 하면 운영 서버가 뜨는 체크리스트**입니다.
> 명령은 리눅스(Ubuntu 22.04+ 기준) 서버에서 실행합니다. 순서대로 진행하세요.
> 전체 스택 = PostgreSQL + API(NestJS) + Web(Next.js) + nginx, 모두 Docker 컨테이너.

체크박스를 채우며 진행하세요.

---

## 0. 개요 — 무엇이 뜨는가

```
                 인터넷
                   │  (443 HTTPS / 80 → 443 리다이렉트)
              ┌────▼────┐
              │  nginx  │  리버스 프록시 + TLS 종단
              └──┬───┬──┘
        /api,/health │   │ /  (그 외)
              ┌──────▼┐ ┌▼───────┐
              │  api  │ │  web   │
              │ :3000 │ │ :3001  │
              └───┬───┘ └────────┘
                  │
            ┌─────▼─────┐
            │ postgres  │  (호스트 포트 미개방, 내부 전용)
            └───────────┘
   volume: pgdata(DB), uploads(서류/사진)
```

- 외부에 열리는 포트는 **nginx(80/443) 뿐**입니다. api·web·postgres 는 내부 네트워크에만 존재합니다.
- 서류/사진은 `uploads` 볼륨에 저장되고 nginx `/uploads/` 와 api 가 함께 참조합니다.

---

## 1. 리눅스 서버 요구사항

- [ ] **사양**: vCPU 2코어 / RAM 4GB / 디스크 40GB 이상 (리소스 제한은 `infra/docker-compose.prod.yml` 기준 합계 약 CPU 3.25 / RAM 2.4GB 상한)
- [ ] **OS**: Ubuntu 22.04 LTS 이상 (또는 Docker 를 지원하는 최신 리눅스)
- [ ] **방화벽**: 80, 443 만 외부 개방. 22(SSH)는 필요 시. **5432(DB)는 절대 외부 개방 금지.**
- [ ] **도메인**: A 레코드가 서버 공인 IP 를 가리키도록 설정 (예: `jakeobon.example.com`)

### Docker / docker compose 설치

```bash
# Docker 공식 스크립트
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # 로그아웃 후 재로그인 필요
# 확인 (compose v2 는 docker 에 내장)
docker --version
docker compose version
```

### 코드 배치

```bash
sudo mkdir -p /opt/jakeobon && sudo chown "$USER" /opt/jakeobon
git clone <레포주소> /opt/jakeobon
cd /opt/jakeobon
```

- [ ] Docker / docker compose 설치 확인
- [ ] `/opt/jakeobon` 에 코드 배치 완료

---

## 2. `.env` 작성 (환경변수)

저장소 **루트**(`/opt/jakeobon`)에 `.env` 를 만듭니다. 예시는 `infra/.env.example`.

```bash
cp infra/.env.example .env
nano .env
```

각 변수 의미:

| 변수 | 설명 | 강한 값 생성 |
|------|------|------------|
| `POSTGRES_USER` | DB 사용자 | (자유) |
| `POSTGRES_PASSWORD` | DB 비밀번호 — 반드시 교체 | `openssl rand -hex 16` |
| `POSTGRES_DB` | DB 이름 | `jakeobon` |
| `JWT_SECRET` | 로그인 토큰 서명 키 — **반드시 교체(미교체 시 api 기동 실패)** | `openssl rand -hex 32` |
| `JWT_EXPIRES_IN` | 토큰 만료 | `7d` |
| `WEB_ORIGIN` | CORS 허용 오리진(운영 도메인) | `https://jakeobon.example.com` |
| `PUBLIC_WEB_URL` | 카톡 공유 링크에 박히는 공개 주소 | `https://jakeobon.example.com` |
| `GOV_DATA_SERVICE_KEY` | 사업자등록 진위확인 키 (5절) | — |
| `KMA_SERVICE_KEY` | 기상청 폭염 예보 키 (5절) | — |
| `KAKAO_ENABLED` | 카카오 로그인 활성화 | `false`(준비 전) |
| `FCM_SERVICE_ACCOUNT_PATH` | FCM 서비스계정 JSON 경로 (5절) | `/app/secrets/fcm.json` |

> **약한 시크릿 안전장치(fail-fast)**: `NODE_ENV=production` 에서 `JWT_SECRET` 이 비었거나
> `change-me` 계열/16자 미만이면 api 컨테이너가 **기동을 거부**합니다. `deploy.sh` 도 사전에 한 번 더 막습니다.

- [ ] `.env` 작성 완료 (`JWT_SECRET`·`POSTGRES_PASSWORD` 강한 값으로 교체)
- [ ] `WEB_ORIGIN`·`PUBLIC_WEB_URL` 을 실제 도메인으로 지정

---

## 3. 도메인 · HTTPS (Let's Encrypt)

기본 `infra/nginx/nginx.conf` 는 80(HTTP)만 종단합니다. 운영은 HTTPS 필수입니다. 두 가지 방법:

### 방법 A) certbot 로 인증서 발급 후 nginx TLS 블록 추가 (권장)

```bash
sudo apt-get install -y certbot
# nginx 컨테이너를 잠시 내리고 80 포트로 발급
docker compose -f infra/docker-compose.yml -f infra/docker-compose.prod.yml stop nginx
sudo certbot certonly --standalone -d jakeobon.example.com
# 인증서: /etc/letsencrypt/live/jakeobon.example.com/{fullchain,privkey}.pem
```

그 다음 `infra/docker-compose.prod.yml` 의 nginx `ports`/`volumes` 주석(443, `/etc/letsencrypt`)을 해제하고,
`infra/nginx/nginx.conf` 에 443 서버블록(아래)을 추가한 뒤 80 은 443 으로 리다이렉트합니다.

```nginx
server {
  listen 80;
  server_name jakeobon.example.com;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl;
  server_name jakeobon.example.com;
  ssl_certificate     /etc/letsencrypt/live/jakeobon.example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/jakeobon.example.com/privkey.pem;
  client_max_body_size 20m;
  # location /api/ , /health , /uploads/ , /  블록은 기존 default.conf 내용을 그대로 복사
}
```

- [ ] 자동 갱신: `0 4 * * * certbot renew --quiet && docker compose ... restart nginx` 크론 등록

### 방법 B) 앞단에 Caddy / Cloudflare Tunnel 등 별도 TLS 프록시

- 그 경우 nginx 는 80 유지, TLS 는 상위 프록시가 담당. `WEB_ORIGIN`/`PUBLIC_WEB_URL` 은 `https://` 로 지정.

- [ ] HTTPS 로 `https://도메인/health` 가 `{"status":"ok"}` 를 반환하는지 확인

---

## 4. 기동 · 확인 · 백업

### 기동 (원스텝)

```bash
cd /opt/jakeobon
./infra/deploy.sh
```

`deploy.sh` 가 하는 일: `.env`/시크릿 점검 → `git pull` → 이미지 빌드 → postgres 기동/대기 →
`prisma migrate deploy`(마이그레이션) → 전체 기동 → `/health` 확인. **코드 갱신 후 재배포도 이 한 줄**입니다.

### 확인

```bash
docker compose -f infra/docker-compose.yml -f infra/docker-compose.prod.yml ps        # 전부 healthy
curl -fsS http://localhost/health                                                      # DB up
docker compose -f infra/docker-compose.yml -f infra/docker-compose.prod.yml logs -f api
```

### 백업 (일일 크론)

`infra/backup.sh` = PostgreSQL 덤프(`-Fc` + gzip) + `uploads` 볼륨 rsync + 보관정책(기본 14일).

```bash
# 매일 03:30 자동 백업
crontab -e
# 아래 한 줄 추가:
30 3 * * * cd /opt/jakeobon && ./infra/backup.sh >> /var/log/jakeobon-backup.log 2>&1
```

- 기본 백업 경로 `/opt/jakeobon-backups` (환경변수 `BACKUP_DIR` 로 변경).
- 오프사이트 미러: `OFFSITE_RSYNC=user@host:/backups/jakeobon ./infra/backup.sh`
- **복원**: `gunzip -c 덤프.dump.gz | docker compose ... exec -T postgres pg_restore -U jakeobon -d jakeobon --clean`

- [ ] `deploy.sh` 로 기동, `ps` 전부 healthy
- [ ] `/health` 정상, 백업 크론 등록

---

## 5. 외부 키 4종 발급 절차

무료 배포이므로 키가 없어도 앱은 **비활성 스텁**으로 동작합니다(로그인은 전화 인증만, 폭염/진위확인/푸시 비활성).
아래는 각 기능을 켜기 위한 발급 절차입니다. 발급한 값은 위 `.env` 에 넣고 `./infra/deploy.sh` 재실행.

### 5-1. 카카오 로그인 → `KAKAO_ENABLED`
1. https://developers.kakao.com 로그인 → **내 애플리케이션 → 애플리케이션 추가하기** (앱 이름/회사명 입력)
2. 생성된 앱 → **앱 키** 에서 **네이티브 앱 키**(앱)와 **REST API 키**(백엔드) 확인/복사
3. **카카오 로그인** 메뉴 → 활성화 ON, **Redirect URI** 에 `https://도메인/api/auth/kakao/callback` 등록
4. **플랫폼** 에 iOS 번들ID(`kr.workon.workon`)·Android 패키지명(`kr.workon.workon`)+키해시 등록
5. **동의항목**에서 필요한 항목(닉네임 등) 설정
6. `.env`: `KAKAO_ENABLED=true` 로 변경
   > 참고: 현재 백엔드의 카카오 로그인은 스텁(501) 상태이며, REST 키 실연동은 백로그입니다.
   > 키 발급/앱 설정은 지금 해 두고, 실연동 배포 시 REST 키를 백엔드 환경변수로 주입합니다.
   > **앱(app/) 쪽 네이티브 앱 키 주입 위치는 아래 6절 "카카오 키 최종 주입 위치"** 를 보세요.
   > (네이티브 스킴/매니페스트는 이미 빌드 변수 기반으로 준비되어 있어, 키가 없으면 무해한 no-op 입니다.)

### 5-2. 기상청 단기예보(폭염 알림) → `KMA_SERVICE_KEY`
1. https://data.go.kr (공공데이터포털) 회원가입/로그인
2. **"기상청_단기예보 조회서비스"** 검색 → 상세 → **활용신청**(자동 승인, 즉시)
3. 마이페이지 → **오픈API → 인증키** 에서 **일반 인증키(Decoding)** 복사
4. `.env`: `KMA_SERVICE_KEY=발급키`
   → 매일 06:00/14:00(KST) 폭염 스캔이 켜집니다.

### 5-3. 공공데이터포털 사업자등록 진위확인 → `GOV_DATA_SERVICE_KEY`
1. https://data.go.kr 에서 **"국세청_사업자등록정보 진위확인 및 상태조회 서비스"** 검색 → **활용신청**
2. 마이페이지 → 인증키(Decoding) 복사
3. `.env`: `GOV_DATA_SERVICE_KEY=발급키`
   → 서류의 사업자등록증 **진위확인**이 켜집니다(그 외 서류는 수동확인 유지).

### 5-4. FCM 푸시 → `FCM_SERVICE_ACCOUNT_PATH` (+ 앱 설정파일)
1. https://console.firebase.google.com → **프로젝트 만들기**
2. **프로젝트 설정(⚙) → 서비스 계정 → 새 비공개 키 생성** → JSON 다운로드
3. 서버에 배치: `mkdir -p /opt/jakeobon/infra/secrets && cp 다운로드.json /opt/jakeobon/infra/secrets/fcm.json`
4. `.env`: `FCM_SERVICE_ACCOUNT_PATH=/app/secrets/fcm.json` (컨테이너 내부 경로. 볼륨은 이미 마운트됨)
5. **앱 설정파일**(아래 6절에서 사용):
   - iOS: 프로젝트에 iOS 앱 추가 → **`GoogleService-Info.plist`** 다운로드 → `app/ios/Runner/` 에 배치
   - Android: Android 앱 추가 → **`google-services.json`** 다운로드 → `app/android/app/` 에 배치
   - `flutterfire configure` 로 **`lib/firebase_options.dart`** 생성

- [ ] 필요한 키만 발급 → `.env` 반영 → `./infra/deploy.sh` 재실행

---

## 6. 앱 스토어 제출 전 체크 (Flutter)

> 서버 배포와 별개로, 모바일 앱(`app/`)을 스토어에 올리기 전 반드시 처리합니다.

- [ ] **iOS ATS 제거**: `app/ios/Runner/Info.plist` 의 `NSAppTransportSecurity` / `NSAllowsArbitraryLoads(true)`
      블록을 **삭제**(운영은 HTTPS 이므로 불필요, 심사 리스크). 현재는 로컬 개발용으로 열려 있음.
- [ ] **HTTPS BASE_URL 주입**: 앱은 `--dart-define=BASE_URL=` 로 API 주소를 주입받습니다
      (기본값 `http://localhost:3030/api` 는 개발용). 릴리스 빌드 시:
      ```bash
      flutter build ipa   --dart-define=BASE_URL=https://도메인/api
      flutter build appbundle --dart-define=BASE_URL=https://도메인/api
      ```
- [ ] **iOS 배포타깃 정합**: `ios/Podfile` 은 15.0 이지만 `Runner.xcodeproj` 의
      `IPHONEOS_DEPLOYMENT_TARGET` 이 13.0 으로 남아 있음 → Xcode 에서 **15.0 으로 통일**.
- [ ] **FCM 설정파일 배치**: 5-4 의 `GoogleService-Info.plist` / `google-services.json` / `firebase_options.dart`
      가 있어야 푸시가 동작. 없으면 앱은 푸시만 skip(그 외 정상).
- [ ] **카카오 로그인 버튼 노출 조건**: 버튼/카카오 연결 UI 는 `--dart-define=KAKAO_APP_KEY` 가
      **주입된 경우에만** 자동 노출됩니다(미주입 시 전화 인증만 — 온보딩 완결 확인 불필요).
      dart-define 하나로 전 체인(버튼 노출 → SDK init → 로그인 호출)이 켜집니다.
- [ ] **앱 잠금(생체/PIN) 문구**: iOS `Info.plist` 의 `NSFaceIDUsageDescription`(한국어) 존재 확인.
      Android 는 `USE_BIOMETRIC` 권한 + `MainActivity : FlutterFragmentActivity`(local_auth 요건) 반영됨.
      잠금은 기본 OFF, 더보기 > 설정 > "앱 잠금" 에서 켭니다(생체 미지원 시 기기 암호 폴백).
- [ ] **권한 사용 설명 문구** 확인: 사진/위치 접근(Info.plist NSPhotoLibrary·NSLocation) 문구 적절성.

### 카카오 키 최종 주입 위치 (키 발급 후 넣는 곳)

카카오 키는 **딱 2군데** 만 넣으면 전체가 동작합니다. 네이티브 스킴/매니페스트는 이미
빌드 변수(`$(KAKAO_APP_KEY)` / `${KAKAO_APP_KEY}`) 기반으로 준비돼 있어 **키가 없으면 무해**하고,
키가 있으면 아래 값으로 자동 완성됩니다.

| # | 넣는 곳 | 값 | 무엇이 켜지나 |
|---|---------|-----|--------------|
| **1** | **앱 빌드 dart-define** — `flutter build ipa/appbundle --dart-define=KAKAO_APP_KEY=<네이티브앱키>` | 카카오 **네이티브 앱 키** | 로그인/연결 버튼 노출 + 카카오 SDK 초기화 + 로그인 호출(런타임 전 체인) |
| **2** | **백엔드 `.env`** — `KAKAO_ENABLED=true`(+ 실연동 시 REST 키 env) | `true` / REST 키 | 서버 `/auth/kakao` 검증 활성화 |

> **네이티브 스킴 자동 완성(추가 설정 불필요)**: iOS 는 빌드 설정 `KAKAO_APP_KEY`(기본 빈 값,
> `ios/Flutter/{Debug,Release}.xcconfig`)로, Android 는 Gradle 프로퍼티 `KAKAO_APP_KEY`(기본 빈 값)로
> URL 스킴 `kakao<앱키>` / redirect 를 구성합니다. **카카오톡 앱 전환(app-to-app)** 까지 쓰려면
> 릴리스 빌드 시 이 두 네이티브 빌드 변수에도 **1번과 동일한 네이티브 앱 키**를 넣으세요
> (예: iOS xcconfig 의 `KAKAO_APP_KEY=<앱키>`, Android `flutter build appbundle -PKAKAO_APP_KEY=<앱키> --dart-define=KAKAO_APP_KEY=<앱키>`).
> 넣지 않아도 카카오계정(웹) 로그인은 동작하며, 빌드는 키 없이도 깨지지 않습니다.

---

## 7. ⚠️ compose override `ports` 함정 (S1 검수 이월 경고)

docker compose 에서 `-f base.yml -f override.yml` 로 겹칠 때 **`ports` 는 기본적으로 "병합"** 됩니다.
즉 override 에서 `ports: ['18081:80']` 만 써도 base 의 `'80:80'` 이 **사라지지 않고 둘 다 열립니다**.

- 테스트/스테이징에서 포트를 **대체**하려면 반드시:
  ```yaml
  nginx:
    ports: !override
      - '18081:80'
  ```
  `!override` 를 붙여야 base 의 포트가 치환됩니다. (S5 통합검증도 이 방식으로 18081 격리 실행)
- 운영(`docker-compose.prod.yml`)은 base 의 `80:80` 을 **그대로** 쓰므로 `ports` 를 재정의하지 않습니다.
- 마찬가지로 여러 스택을 한 호스트에서 돌릴 땐 `-p 프로젝트명` 으로 네트워크/볼륨을 격리하세요.

---

## 부록 — 자주 쓰는 명령

```bash
C="docker compose -f infra/docker-compose.yml -f infra/docker-compose.prod.yml"
$C ps                 # 상태
$C logs -f api        # api 로그
$C restart nginx      # nginx 재시작(인증서 갱신 후)
$C down               # 중지(볼륨 보존)
$C down -v            # 중지 + 볼륨 삭제(데이터 소멸 주의!)
./infra/deploy.sh     # 재배포(pull→build→migrate→up)
./infra/backup.sh     # 수동 백업
```
