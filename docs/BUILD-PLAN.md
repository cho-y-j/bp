# 작업온 빌드 플랜 (2026-07-11 착수)

> 각 스테이지: 구현 에이전트(Opus) → **별도 검수 에이전트** → 수정 → worklog 기록 후 다음 단계.
> 진행 상태는 이 파일의 체크박스가 단일 기준.

## 리포 구조 (모노레포: /Users/jojo/pro/bp)
```
backend/   NestJS + Prisma + PostgreSQL 16  (단일 모놀리식 API)
web/       Next.js  (확인서 외부 열람·서명 + 사업장 웹)
app/       Flutter  (작업자+사업장 모드)
infra/     docker-compose, nginx, 배포 스크립트
docs/      기획·설계·작업 기록 (기존)
design/    시안 (기존)
ref/       SKEP 참고 코드 (기존, 빌드 제외)
```

## 스테이지

### S1. 기반 골격 ✅ 완료 (구현+독립검수 통과)
- [x] 모노레포 스캐폴드 / [x] DB 스키마 13테이블 / [x] 통합 compose 실기동·nginx 라우팅 검증

### S2. 백엔드 핵심 API — 구현 완료 (a~d), 통합 검수 진행 중
- [x] S2a 인증(전화 mock+카카오 스텁+JWT) + 공통 봉투/가드/fail-fast
- [x] S2b 서류(PDF 정규화·마스킹·선택 묶음 공유·열람로그·만료 크론·사업자 진위확인 구조) + 장비 CRUD
- [x] S2c 확인서(자동계산·장부 자동생성·외부 서명·한글 PDF) + 장부(집계·부분입금·명세서·수금 크론)
- [x] S2d 연동(검색·초대코드·미가입 승격) + jobs(지시~완료·서류확인) + biz(수신함·서명·정산·안전리포트) + 폭염 알림 + FCM
- [x] S2 통합 검수 — 지적 결함(중요1·사소6) 수정·회귀 통과 (`worklog/2026-07-11-S2-통합검수.md`). 단위 73·e2e 55, 실서버 curl 재현 차단 확인
- 키 대기: 카카오/기상청(KMA)/FCM/공공데이터포털 — 미설정 시 비활성 스텁으로 동작

### S3. 웹 (Next.js) ✅ 완료 (구현+실브라우저 검증)
- [x] 외부 열람·서명 페이지: `/c/[token]` 종이 확인서 렌더(SSR·OG) + 캔버스 터치 서명 → SIGNED·서명 PDF·가입 유도. `/s/[token]` 서류 묶음 열람(만료·무효 안내)
- [x] 사업장 웹: `/login`(전화인증·JWT·401 리다이렉트), 레이아웃(사이드바·사업장 생성 유도), `/biz/inbox`(상세+앱내 서명), `/biz/settlements`(집계·pay·작업자 장부 대칭), `/biz/workers`(검색·연결·작업지시), `/biz/safety`(인증 blob PDF·안전 알림), `/` 랜딩(S1 지적 해소)
- [x] playwright 실검증(모바일 375·데스크톱 1280) + `npm run build` 타입에러 0. 임시 pg/서버 정리, live-db(5432) 무손상 (`worklog/2026-07-11-S3-웹.md`)
- [x] **S3 독립 검수 지적 수정·재검증 완료** — SignaturePad 리사이즈 보존, 공개 SSR 타임아웃+친화화면/404, 수신함 모달 상세(`GET /biz/confirmations/:id`), `/s` 다운로드 attachment, 모바일 topbar·파비콘·14px·코드 6자리. 단위 73·e2e 55·web build 0, playwright ①~⑤ 실측(임시 pg 5434/백엔드 3020/web 3002, live-db 무손상). 백로그: 사업장 다중 소유 전환 웹 UI

### S4. 앱 (Flutter — 시안 디자인 그대로) ✅ 완료 (구현+iOS 시뮬레이터 E2E 검증)
- [x] S4a 작업자 코어: 홈 / **캘린더(월간·주간 전환 뷰)** / 확인서 작성(30초) / 장부 (`worklog/2026-07-11-S4a-앱코어.md`)
- [x] S4b 서류 지갑(그리드·만료 D-day·업로드·마스킹 편집기·상세·묶음 전송·내 공유·장비)
- [x] S4b 사업장 모드: 연동·작업 지시, 수신함·**앱내 캔버스 서명(SIGNED)**, 정산 pay(작업자 장부 대칭), 안전 리포트 PDF + 작업자 받은작업(수락·시작 GPS/컨디션·완료)
- [x] S4b 알림(notifications·읽음·폭염 ack·홈 벨 뱃지·전화검색 동의 토글), FCM device-token 구조(설정 없으면 skip), 카톡 시스템 공유
- [x] 검증: flutter analyze 0 errors/warnings, 단위·위젯 27 통과, iOS 26.5 integration_test All passed + 스크린샷 14장 눈검수, 백엔드 curl 대조 (`worklog/2026-07-11-S4b-지갑사업장.md`). 임시 pg 5435/백엔드 3030 정리, live-db(5432) 무손상. 백엔드 최소 추가 `GET /documents/:id/file`

### S5. 통합 검증·배포 준비 ✅ 완료 (구현+실통합스택 E2E 검증)
- [x] 백로그 e2e 보강: `GET /documents/:id/file`·`GET /ledger/entries`(권한 격리 포함) → **단위 73·e2e 71**
- [x] **운영 구성 통합 스택**(compose 빌드·기동, `ports: !override` 18081 격리, prod override) nginx 경유 E2E 시나리오 ①~⑤ 전부 통과 (curl+playwright)
- [x] 발견·수정: 웹 API 베이스(브라우저 상대 `/api` + SSR `API_INTERNAL_URL` 분리), Next standalone `HOSTNAME=0.0.0.0` 헬스체크, 공개링크 env(PUBLIC_WEB_URL 등) 누락 → 재검증 통과
- [x] 배포 산출물: `docker-compose.prod.yml`(재시작·로그로테·리소스제한·비루트 api), `deploy.sh`·`backup.sh`, **`docs/DEPLOY.md`**(한국어 체크리스트+외부키 4종 발급), README 갱신
- [x] 테스트 자원 전부 정리(컨테이너·볼륨·이미지), **live-db(5432) 무손상 확인** (`worklog/2026-07-11-S5-통합배포.md`)

### P1. 출시 전·직후 편의 (STRATEGY.md P1) ✅ 완료
- [x] P1 백엔드 — 공수(GONGSU) 단가유형, 세금계산서 1단계, 알림톡 어댑터, 카카오 link (`worklog/2026-07-11-P1-백엔드.md`)
- [x] P1 앱 — 공수 입력, 오프라인 임시저장, 세금계산서 화면, 카카오 로그인 버튼 (`worklog/2026-07-11-P1-앱.md`)
- [x] P1 다국어 — 웹 외부 페이지 + 앱 전 화면 6언어 (`worklog/2026-07-11-P1-다국어-{웹,앱}.md`)
- [x] **P1 홈 화면 위젯 (마지막 배치)** — `home_widget` 기반 iOS(WidgetKit)+Android(AppWidget), 오늘 일정+이번 달 미수금, 소형/중형, App Group 공유·로케일 렌더, 로그아웃 클리어 (`worklog/2026-07-11-P1-위젯.md`). analyze 0·test 58·apk·ios(appex 임베드) 빌드 통과, iOS 시뮬 공유데이터 라운드트립 실측. iOS 배포타깃 15.0 통일. **남음**: 위젯 홈 배치 눈검수(GUI 통합 검수).
- [x] **P1 통합 검수 완료** — 회귀 전부 재현(87/78/58/빌드0), 결함 1건(외국어 공수 단위 소실) 수정·4개 언어 실측 (`worklog/2026-07-11-P1-통합검수.md`). 위젯 홈 배치·실기기 항목은 사용자 수동 QA로 이관

## P2 (2026-07-11 착수 — STRATEGY.md 기반, 설계: Fable)

### P2a. 반장(팀) 기능 ✅ 완료 (구현+실측 검증, `worklog/2026-07-11-P2a-팀기능.md`)
- [x] 팀: 반장(profile)이 팀원 명단 관리 — 가입자(연결, 전화검색 동의자) 또는 수기(이름+전화, 미가입 허용) + 기본 단가. `/teams` CRUD(반장 본인만)
- [x] **일괄 기록**: 팀원별 공수(0.1 단위 검증 재사용)·단가 입력 → **팀 확인서 1장**(teamEntries JSONB, 서버 계산, 사업장 서명 1회, PDF 팀 명단 표)
- [x] 장부: 반장 장부에 합계 1건. 가입+연결 팀원은 SIGNED 시점에 각자 몫 자동 파생(derived, 원 확인서 참조, 읽기전용—입금만)
- [x] 앱: 더보기→내 팀(명단 CRUD), 확인서 작성 "팀 확인서" 토글(공수 스텝퍼+실시간 합계), 장부 팀 배지·파생 표기, 6언어 ARB
- [x] 검증: 백엔드 단위 94·e2e 95(신규 7+17, 권한 격리), pdftotext 팀 명단 표, flutter analyze 0·test 63, iOS 시뮬 E2E+스크린샷 5장. 웹 이월: 공개 API에 teamEntries 포함 → PaperConfirmation 렌더는 P2 통합 때

### P2b. 표준근로계약서 전자서명 ✅ 완료 (구현+실측 검증, `worklog/2026-07-11-P2b-근로계약서.md`)
- [x] 백엔드: `labor_contracts` 마이그레이션 1개(additive), `/biz/contracts` CRUD+사업장 서명(전송 전 필수 선행)+send, `/contracts`(작업자 "내 계약서"+앱내 서명), `/public/contracts/:token`(열람 viewLog·서명·PDF — 원자 전이·재서명 409), 양측 서명 PDF(나눔고딕, "정본은 한국어본" 문구)
- [x] 웹: `/lc/[token]` 6언어 열람·서명(조항 라벨 번역·계약 값 원문, 기존 SignaturePad/StatusScreen/언어 스위처 재사용) + **P2a 이월: PaperConfirmation 팀 명단 표 렌더**
- [x] 앱: 사업장 계약서 작성 폼(자주 쓰는 값 저장)→내 서명→전송(연결 알림/링크 공유)·목록·상태, 작업자 지갑 "내 계약서"(목록·PDF·받은 계약서 서명), 신규 문구 6개 ARB(조항 라벨 웹 사전과 일치, 552키×6)
- [x] 검증: 백엔드 단위 97·e2e 111(신규 3+16, 권한 격리·지갑 자동 연결), pdftotext 조항·양측 서명, web build 0·playwright /lc ko+vi 열람·실서명·/c 팀 명단 스크린샷 4장, flutter analyze 0·test 70, iOS 시뮬 E2E+스크린샷 5장. 임시 pg 5436/백엔드 3040/web 3004만 사용, live-db(5432) 무손상

### P2c. 간편 TBM(안전점검회의) 기록 ✅ 완료 (구현+실측 검증, `worklog/2026-07-11-P2c-TBM.md`)
- [x] 백엔드: `tbm_records`·`tbm_attendees`·`tbm_presets` 마이그레이션 1개(additive), NotificationType/SafetyLogType +TBM, TbmPresetKind. `/biz/tbm` CRUD(당일 수정·이후 읽기전용 409)+사진 업로드(FileStorageService)+프리셋 CRUD, `/tbm` 받은목록·`POST /tbm/:attendeeId/ack`(원자적 최초 1회, 재확인 409). 생성 시 가입 참석자 알림 + safety_logs 기록·확인 각각 append. renderSafetyReportPdf 에 **월간 TBM 섹션**(일자·현장·위험요인·참석 N/확인 M)
- [x] 앱: 사업장 "TBM 기록"(위험요인 프리셋 칩 다중선택+직접입력+커스텀 프리셋 저장, 연결 참석자 칩+수기, 조치, 사진, 저장)·목록·상세(참석자 확인 현황), 작업자 "받은 TBM"+알림 확인 탭. **위험요인 프리셋 키 기반**(기본 10종 코드+6언어 번역, 커스텀은 원문). 신규 64키 × 6 ARB
- [x] 검증: 백엔드 단위 103·e2e 120(신규 6+9, 권한 격리·재ack 409·당일 후 수정 차단·safety_logs 반영), pdftotext TBM 섹션(참석/확인 2/1) 확인. flutter analyze 0·test 74, iOS 시뮬 E2E(작성→작업자 확인→상세 1/1) 스크린샷 4장. 임시 pg 5436/백엔드 3040만 사용, live-db(5432) 무손상

### P2d. 연간 소득 리포트 ✅ 완료 (구현+실측 검증, `worklog/2026-07-11-P2d-소득리포트.md`)
- [x] 백엔드: `GET /ledger/income-report?year=|from=&to=`(월별 추이·상대별·총계·공수·입금/미수 + **팀 지급분(teamPayout)·순소득 참고(netBilled)**), `GET /ledger/income-report/pdf`(인증 blob, 나눔고딕·페이지 브레이크). 집계 순수 함수(`income-report.util.ts`, 파생 중복 합산 방지 검증 내장), 종소세 일반 안내(5월 신고·3.3% 원천징수·세무상담 아님). 스키마 변경 없음(기존 ledger 재사용).
- [x] 앱: 더보기→"소득 리포트"(연도 선택·총계 카드·**월별 막대 커스텀 페인트**·상대별 리스트·종소세 안내·PDF 저장·공유). 신규 27키 × 6 ARB.
- [x] 검증: 백엔드 단위 110·e2e 129(신규 7+9, 일반+공수+팀 반장/팀원·권한 격리·기간·PDF), pdftotext 표 확인, 집계 수동 대조. flutter analyze 0·test 77, iOS 시뮬 E2E + 스크린샷 3장 눈검수. 임시 pg 5436/백엔드 3040만 사용, live-db(5432) 무손상.

### 순서: P2a → P2b → P2c → P2d → P2 통합 검수 (각 배치 구현→검증→커밋)

## P5 사업장 강화 (2026-07-17 착수, 설계: Fable)

### P5-1. 현장별 인건비 집계
- 사업장 대상 SIGNED 확인서를 현장명(siteName)별·기간별 집계: 작업자별 내역(일수·공수·금액), 팀 확인서 포함, 현장 합계·총계 + PDF. 발주처 재청구 근거 서류 겸용

### P5-2. 일용근로소득 지급명세서 도우미
- 월 마감: 지급(paid) 기준 작업자별 지급총액·일수 집계 → 소득 유형 선택 산출:
  ①사업소득(3.3% 원천징수) ②일용근로소득(일 15만 공제·6%×45% 감면=실효 2.7%·세액 1,000원 미만 소액부징수)
- 홈택스 입력용 정리(JSON+복사 텍스트) + 발행 표시. **주민번호는 수집·저장하지 않음** — 홈택스에서 직접 입력 안내
- 세율·공제 기준을 상수+주석으로 명시, "세무 상담 아님·세무사 확인 권장" 문구 필수

### P5-3. 오늘의 출역 현황판
- 사업장 홈 상단: 오늘 jobs+work_logs 현장별 그룹 — 출근(시작 시각·컨디션)/미출근/완료, 인원 요약

### 진행: P5a 백엔드(3종 API+PDF) → P5b 앱 + P5c 웹(병렬) → P5 통합 검수

## 검수 규칙 (매 스테이지)
- 구현 에이전트와 다른 에이전트가: 실행 검증(빌드·마이그레이션·API 호출/화면 렌더), 코드 리뷰
- 통과 기준 미달 시 수정 후 재검수. 결과는 worklog에 기록.
