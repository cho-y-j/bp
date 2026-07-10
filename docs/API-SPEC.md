# 작업온 API 계약 v1 (S2 구현 기준)

> 원칙: 화면에 연결되는 API만 만든다. 모든 응답 `{ data, error }` 봉투. 인증: `Authorization: Bearer <JWT>`.
> 외부(미가입자) 접근 경로는 `/public/*` — 토큰 기반, 로그인 불필요.

## 인증 /auth
- `POST /auth/phone/request` — 전화번호 인증코드 발송 (개발: mock, 응답에 코드 노출은 dev 환경만)
- `POST /auth/phone/verify` — 코드 검증 → 신규면 가입 + JWT, 기존이면 로그인 + JWT
- `POST /auth/kakao` — 카카오 액세스토큰 검증 → 가입/로그인 (키 없으면 501 스텁)
- `GET /me` / `PATCH /me` — 프로필 조회·수정 (전화검색 동의 토글 포함)

## 서류 /documents
- `POST /documents` — 업로드(multipart, 이미지/PDF) → PDF 정규화 저장. body: 유형, 소유자(profile|equipment), 발급일?, 만료일?
- `GET /documents` — 내 서류 목록 (만료 D-day 포함)
- `PATCH /documents/:id` — 만료일 등 수정 / `DELETE /documents/:id`
- `POST /documents/:id/mask` — 마스킹 영역(사각형 좌표들) 지정 → 마스킹본 생성(masked_file_path)
- `POST /documents/:id/verify` — 진위확인 (v1: 사업자등록만 실연동, 나머지 UNSUPPORTED → 수동확인 상태)
- `GET /documents/expiring?days=30` — 만료 임박
- `POST /document-shares` — **선택한 서류 id 배열**로 묶음 링크 생성 (유효기간, 마스킹본 사용 여부) → `{ share_token, url }`
- `GET /public/shares/:token` — 외부 열람(로그인 불필요, 열람 로그 기록)

## 장비 /equipments
- CRUD. 장비별 서류는 /documents에서 owner=equipment로 연결

## 확인서 /confirmations
- `POST /confirmations` — 작성(코어+장비섹션?, 단가유형/수량 → 금액 자동계산) → 저장 시 ledger_entry 자동 생성
- `POST /confirmations/:id/duplicate` — 이전 확인서 복사
- `GET /confirmations?month=YYYY-MM` — 목록(캘린더용 일자 집계 포함)
- `POST /confirmations/:id/send` — 연결 사업장에 전송 or 외부 링크 발급 → `{ share_token?, url? }`
- `GET /confirmations/:id/pdf` — PDF 다운로드
- `GET /public/confirmations/:token` — 외부 열람
- `POST /public/confirmations/:token/sign` — 외부 서명(서명자명 + 서명 이미지 base64) → SIGNED, 양측 알림

## 장부 /ledger
- `GET /ledger/summary?month=` — 월 합계(미수/입금/일한 날)
- `GET /ledger/by-company?month=` — 회사별 미수 집계 + 수금 D-day
- `POST /ledger/:id/payments` — 입금 기록(부분입금 허용) / `PATCH /ledger/:id` — 수금예정일 수정
- `GET /ledger/statement?month=` — 월간 명세서 PDF

## 연동 /connections, /businesses
- `POST /businesses` — 사업장 생성(초대코드 자동 발급) / `GET /businesses/search?q=` — 상호·코드 검색
- `GET /workers/search?phone=` — 전화번호로 작업자 검색(동의자만)
- `POST /connections` — 연결 요청 / `POST /connections/:id/accept`
- `GET /connections` — 내 연결 목록

## 작업 지시 /jobs (사업장 모드)
- `POST /jobs` — 작업 지시/예약 (연결 작업자 대상) → 작업자에게 푸시, 확인 요청
- `POST /jobs/:id/confirm` — 작업자의 예약 확인 / `GET /jobs?month=` — 양측 조회
- `POST /jobs/:id/start` `POST /jobs/:id/complete` — 시작/완료 (GPS, 사진?, 컨디션체크는 start에 포함)

## 사업장 정산·안전 (사업장 모드)
- `GET /biz/inbox` — 수신 확인서 목록 / `POST /biz/confirmations/:id/sign` — 앱 내 서명
- `GET /biz/settlements?month=` — 작업자별 미지급 집계 / `POST /biz/settlements/pay` — 지급 처리(해당 ledger 반영)
- `GET /biz/safety-report?month=` — 안전관리 이행 리포트 PDF (safety_logs 집계)

## 안전 /safety
- 스케줄러: 기상청 API 폴링 → 폭염특보/체감온도 기준 대상자에게 푸시+기록(safety_logs, append-only)
- `POST /safety/:id/ack` — 작업자 "확인" 탭 → 확인 시각 기록
- 서류 유효성 확인 기록: jobs 배정 시 자동 safety_log 생성

## 알림 /notifications
- `GET /notifications` / `POST /device-tokens` (FCM 토큰 등록)
- 스케줄러: 수금 D-day, 서류 만료 D-30/7/0, 작업 예약 리마인드

## 구현 순서 (S2 내부)
1. auth → 2. documents(+shares/mask) → 3. confirmations(+public sign) → 4. ledger → 5. connections/jobs → 6. biz → 7. safety/notifications(스케줄러)
