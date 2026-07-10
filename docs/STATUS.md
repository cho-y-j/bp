# 현재 상태 (STATUS)

> 세션 시작 시 이 파일을 가장 먼저 읽는다. 항상 최신 상태를 유지한다.

## 프로젝트
- 작업지시자–작업자 연결 + 서류 공유 + 작업확인서 + 정산/수금 장부 + 만료 관리 앱 (무료 제공 목표)
- 상세 요구사항은 `PROJECT.md` 참조

## 완료된 것
- 2026-07-10: 작업 규칙(CLAUDE.md) 및 문서 구조(docs/) 초기 설정
- 2026-07-11: 요구사항 1차 정리 → PROJECT.md 기록
- 2026-07-11: SKEP 레퍼런스 분석 완료 (`worklog/2026-07-11-skep-분석.md`) — 차용/배제 항목 확정
- 2026-07-11: 추가 요구 반영 — 폭염 안전 알림, 세금계산서 자동 발행, "복잡성보다 자동화" 철학

## 진행 중
- **S1~S5 전 단계 완료.** 백엔드+웹+앱 구현·검수 + 통합 스택 E2E 검증 + 배포 산출물 완비. **배포 준비 완료** — 실제 서버 배포는 `docs/DEPLOY.md` 절차를 따른다.
- 전권 위임 모드: 구현→검수→수정 자동 루프 (CLAUDE.md §5.5)

## 완료 (개발)
- ✅ S1 기반 골격 — 구현+독립 검수 통과 (`worklog/2026-07-11-S1-기반골격.md`). 통합 Docker 스택 실기동 검증 완료
- ✅ SKEP 진위확인 분석 (`worklog/2026-07-11-진위확인-분석.md`) — 사업자등록 API 우선, 면허는 수동확인 fallback
- ✅ S2a 인증·공통 인프라 (`worklog/2026-07-11-S2a-인증.md`) — 봉투/가드/OTP/JWT, 단위 9·e2e 3
- ✅ S2b 서류·장비 (`worklog/2026-07-11-S2b-서류장비.md`) — 장비 CRUD, 서류 업로드(PDF 정규화)·마스킹·진위확인·묶음 공유(public)·만료 크론. 단위 37·e2e 13, 실서버 curl 검증 완료. 마이그레이션 `20260711020000_s2b_documents_equipment`
- ✅ S2c 확인서·장부 (`worklog/2026-07-11-S2c-확인서장부.md`) — 작업확인서(amountCalc 서버계산+ledger 자동생성, DRAFT 수정/삭제·ledger 동기화, duplicate, month 캘린더 집계, send, public 열람/서명 409, 확인서 PDF+한글폰트 임베드+서명이미지), 장부(summary/by-company 상태·D-day, 부분입금, 명세서 PDF, 수금 D-day 크론). 단위 55·e2e 16(+회귀 documents13·auth3), 실서버 curl+pdftotext/pdffonts 검증 완료. 마이그레이션 `20260711030000_s2c_confirmations_ledger`. 의존성 `@pdf-lib/fontkit` + `assets/fonts` 한글 폰트
- ✅ S2d 연동·작업지시·사업장·안전·알림 (`worklog/2026-07-11-S2d-연동사업장안전.md`) — 사업장/초대코드/작업자검색(마스킹)/연결·미가입 승격, 작업지시(confirm 서류확인·start 컨디션·complete·사진 multipart), biz(inbox/앱내서명/정산 pay 양측일치/안전리포트 PDF), 폭염 자동알림(WeatherService·HeatwaveScheduler 06:00/14:00 KST·ack 1회 409), FCM 실발송(firebase-admin, 키없으면 로그만)·알림 조회/읽음/device-token. 크론 전체 Asia/Seoul. **폰트 라이선스 교체**(AppleGothic→정품 OFL NanumGothic). 단위 71·e2e 19(전체 48/48), 실서버 curl+PDF 검증 완료. 마이그레이션 `20260711040000_s2d_connections_safety`. 의존성 `firebase-admin`. infra compose healthcheck+TZ 이월 처리
- ✅ S2 통합 검수 수정 (`worklog/2026-07-11-S2-통합검수.md`) — [중요] 확인서 상대 businessId ACCEPTED 연결 검증(create/duplicate/PATCH, bizSign SENT 강제) + [사소6] viewLogs cap50·viewCount, 서명 TOCTOU 원자화, 정산 pay 트랜잭션, job 상태전이 강제, manualContact 인덱스, 사진 MIME 검증. 단위 73·e2e 55 통과, 실서버 curl 재현 차단 확인. 마이그레이션 `20260711050000_s2_review_hardening`. 백로그: 승격 전역 스캔 DB측 필터 최적화
- ✅ S3 웹 (Next.js 15) (`worklog/2026-07-11-S3-웹.md`) — 외부 공개(`/c/[token]` 종이 확인서 SSR·OG·캔버스 서명→SIGNED·가입유도, `/s/[token]` 서류 묶음) + 사업장 웹(`/login` 전화인증·JWT·401 리다이렉트, 사이드바·사업장 생성 유도, inbox 앱내서명, settlements pay 작업자장부 대칭, workers 검색·연결·작업지시, safety 인증 blob PDF) + `/` 랜딩(S1 지적 해소). 디자인 토큰 CSS 변수(오렌지/네이비/종이톤·다크모드)·PaperConfirmation·SignaturePad(캔버스 직접구현) 재사용. axios 인터셉터 봉투 언래핑. **playwright 실검증**(모바일 375·데스크톱 1280, 서명·정산 대칭·인증 PDF·리다이렉트·다크모드) + `npm run build` 타입에러 0. 임시 pg(5433)·서버 정리, live-db(5432) 무손상. 의존성 `axios`
- ✅ S3 독립 검수 지적 수정 (`worklog/2026-07-11-S3-웹.md` 하단 추가) — [중요] SignaturePad 리사이즈 서명 보존(벡터 리드로우), 공개 SSR 8초 타임아웃+친화 화면/`notFound()` 404+`error.tsx`, 수신함 모달 상세 엔드포인트(`GET /biz/confirmations/:id`)로 시간·금액 완전 렌더, `/s` 다운로드 `?download=1`→attachment. [사소] 모바일 topbar 사업장명+로그아웃, 파비콘(오렌지+흰 온 SVG), 13→14px, 로그인 코드 6자리 고정. 재검증: 단위 73·e2e 55·web build 0, playwright ①~⑤ 실측 통과. 임시 pg 5434·백엔드 3020·web 3002 정리, live-db(5432) 무손상. 백로그: **사업장 다중 소유 전환 웹 UI**(백엔드는 대응됨)
- ✅ 루트 .gitignore 생성 (보안 지적 즉시 조치)
- ✅ S4a Flutter 앱 코어 (`worklog/2026-07-11-S4a-앱코어.md`) — 작업자 관점 전 화면: 로그인/온보딩(전화인증·devCode 자동), 홈(오늘 일정 종이카드·이번 달 요약 미수/입금), 캘린더(월 그리드 도트+금액 ↔ 주간 리스트 토글), 확인서 작성(이전복사·연결/수기 상대·단가유형·연장야간·장비토글·실시간 금액계산·저장→share_plus 공유시트), 장부(회사별 D-day 4상태·회사상세 항목별 부분입금·명세서 PDF 인증blob), 더보기(프로필·S4b 자리). 디자인 토큰 ThemeExtension(라이트/다크)·종이 확인서 PaperCard·tabular figures·시스템폰트. dio 봉투언래핑+JWT secure storage+401. **flutter analyze 0 errors, 단위/위젯 16 통과, iOS 26.5 시뮬레이터 E2E(flutter drive) All passed + 스크린샷 8장 눈검수, 장부 반영 curl 대조**. 임시 pg(5435)·백엔드(3030) 정리, live-db(5432) 무손상. **백엔드 추가**: `GET /ledger/entries?month=`(앱 부분입금용 항목 id, 최소·비파괴, ledger 단위 12/12 통과). 의존성 riverpod/go_router/dio/flutter_secure_storage/share_plus/path_provider/open_filex/intl
- ✅ S4b Flutter 서류 지갑·사업장 모드·알림 (`worklog/2026-07-11-S4b-지갑사업장.md`) — 서류 지갑(그리드·만료 D-day·업로드 image_picker/file_picker·마스킹 편집기 드래그→정규화좌표·상세 인증blob 미리보기·묶음 공유 7/14/30일→시스템 공유시트·내 공유 열람/무효화·장비 CRUD), 사업장 모드(hasBusiness 분기 생성/홈·수신함 PaperCard 상세·**앱내 캔버스 SignaturePad 서명 SIGNED**·정산 pay 작업자장부 대칭·작업자 검색/연결/작업지시·안전 리포트 PDF), 작업자 받은작업(수락·시작 GPS+컨디션·완료), 알림(목록·읽음·폭염 ack·홈 벨 뱃지·FCM 구조 설정없으면 skip·전화검색 동의 토글). **flutter analyze 0 errors/0 warnings, 단위/위젯 27 통과, iOS 26.5 시뮬레이터 integration_test All passed + 스크린샷 14장 눈검수, 백엔드 curl 대조(DONE/SIGNED/paid 대칭)**. 임시 pg(5435)·백엔드(3030) 정리, live-db(5432) 무손상. **백엔드 추가**: `GET /documents/:id/file`(인증 미리보기, 최소·비파괴). 의존성 image_picker/file_picker/geolocator/firebase_core/firebase_messaging. iOS 배포타깃 15.0 상향
- ✅ S4 독립 검수 지적 수정 (`worklog/2026-07-11-S4-검수수정.md`) — [중요] 공통 `ErrorRetry` 위젯(친화 메시지 "연결에 문제가 있어요"+"다시 시도" provider invalidate) 홈/캘린더/장부/회사상세/지갑/알림/사업장/작업자/장비/수신함 에러 표시부 일괄 적용, 장부 빈 상태 CTA(PaperCard 안내 "확인서를 작성하면 장부가 자동으로 채워져요"+확인서 작성 버튼, 홈 스타일 통일). [사소] dispose 누락(biz 수신함 상세 `_sig`/`_nameCtl`, 사업장 생성, 작업자/작업지시 폼)+바텀시트 임시 컨트롤러 해제(whenComplete/try-finally), 확인서 수량>0 검증(0이면 저장 비활성+안내), use_build_context_synchronously 2건·pop-후-SnackBar 2건 정리(메신저/네비게이터 사전 캡처), 서명 1MB 검사를 디코드 PNG 바이트 기준으로 백엔드(`decodeSignPng`)와 일치. **flutter analyze 0 issues(기존 info 10→0), 단위/위젯 30 통과(신규 3)**, iOS 26.5 시뮬레이터 E2E(임시 pg 5435/api 3030): 빈 상태 CTA·백엔드 다운→친화 에러+재시도→재기동 복구 스크린샷 검증. 임시 자원 정리, live-db(5432) 무손상
- ✅ S5 통합 검증·배포 준비 (`worklog/2026-07-11-S5-통합배포.md`) — 백로그 e2e 보강(documents/:id/file·ledger/entries, 권한격리 → **e2e 55→71**, 단위 73). **운영 구성 통합 스택**(compose 빌드·기동, `ports: !override` 18081 격리, NODE_ENV=production) nginx 경유 시나리오 ①~⑤ 전부 통과(curl+playwright): 가입→서류(이미지→PDF)→마스킹→공유→외부 웹열람, 확인서→웹 서명 SIGNED→장부 자동, 같은전화 사업장 자동승격→정산→작업자 PAID 대칭, 작업지시~완료, prod 안전장치(devCode 미노출·dev엔드포인트 403·약한 JWT fail-fast). **발견·수정 3건**: 웹 API베이스(브라우저 상대`/api`+SSR `API_INTERNAL_URL` 분리), Next standalone `HOSTNAME=0.0.0.0` 헬스체크, 공개링크 env(PUBLIC_WEB_URL 등) 누락 → 재빌드 재검증 통과. **배포 산출물**: `docker-compose.prod.yml`(재시작·로그로테·리소스제한·비루트 api uid1001), `deploy.sh`·`backup.sh`, **`docs/DEPLOY.md`**(한국어 체크리스트+외부키 4종 발급 절차), `.env.example`·README 갱신. 테스트 자원 전부 정리(컨테이너·볼륨·이미지), live-db(5432) 무손상(임시 pg 5436·nginx 18081만 사용).
- 디자인 v1 피드백 반영 확정: 서류 선택 전송+주민번호 마스킹, 캘린더 월/주 뷰, 사업주 앱 연동(지시·정산·안전알림)

## 확정된 결정
- 업종 포괄 (장비 기사 + 일반 노동자), 장비 사용자는 서류 관리 강화
- 스택: Flutter + Next.js + NestJS + PostgreSQL, **자체 리눅스 서버 Docker 운영 (Supabase 사용 안 함)**
- 플랫폼: 안드로이드 + iOS + 웹 / 로그인: 카카오 + 전화번호 인증
- 진행 순서: 화면 디자인 시안 먼저 → 확정 후 구현

## 다음 할 일 (개발 완료 — 배포 및 백로그)
- **실제 서버 배포**: `docs/DEPLOY.md` 체크리스트 그대로 진행(사용자 직접). 외부 키 4종 발급이 사용자 몫:
  카카오 REST 키(developers.kakao.com), 기상청 KMA_SERVICE_KEY(data.go.kr 활용신청), 공공데이터 GOV_DATA_SERVICE_KEY(사업자진위), FCM 서비스계정 JSON + 앱 설정파일(GoogleService-Info.plist·google-services.json·firebase_options.dart). 미발급 시 해당 기능만 비활성 스텁.
- **앱 스토어 제출 전**(DEPLOY.md 6절): iOS `NSAllowsArbitraryLoads` 제거, `--dart-define=BASE_URL=https://도메인/api`, iOS 배포타깃 Podfile 15.0↔pbxproj 13.0 통일, 카카오 로그인 버튼 노출 조건.
- **미구현 백로그(코드)**: 카카오 로그인 실연동(현재 스텁 501), 사업장 다중 소유 전환 웹 UI, 승격 전역스캔 DB측 필터 최적화, safety_logs DB 트리거(증거력 강화 시).
