# 작업온 API 계약 v1 (S2 구현 기준)

> 원칙: 화면에 연결되는 API만 만든다. 모든 응답 `{ data, error }` 봉투. 인증: `Authorization: Bearer <JWT>`.
> 외부(미가입자) 접근 경로는 `/public/*` — 토큰 기반, 로그인 불필요.

## 인증 /auth
> **토큰 정책**: 액세스 토큰(JWT) 수명 **30분**(`ACCESS_TOKEN_TTL` env, 기본 `30m`). 로그인 시 **불투명 리프레시 토큰**(랜덤 hex 64자, DB 에 sha256 해시만 저장)을 함께 발급. 만료 시 앱이 `/auth/refresh` 로 자동 연장 → 앱을 쓰는 한 재로그인 없음. **하위 호환**: 기존에 발급된 7일 액세스 토큰은 만료까지 그대로 유효(가드 변경 없음).
- `POST /auth/phone/request` — 전화번호 인증코드 발송 (개발: mock, 응답에 코드 노출은 dev 환경만)
- `POST /auth/phone/verify` — 코드 검증 → 신규면 가입, 기존이면 로그인. 응답에 `accessToken` + **`refreshToken`**(additive) + `isNew` + `profile`. body 에 선택적 `deviceId`(리프레시 토큰에 기록).
- `POST /auth/kakao` — 카카오 액세스토큰 검증 → 가입/로그인 (KAKAO_ENABLED=false 면 501 스텁). 응답에 `accessToken`+`refreshToken`. 선택적 `deviceId`.
- `POST /auth/refresh` **(@Public)** — `{ refreshToken, deviceId? }` → 유효 리프레시면 새 `{ accessToken, refreshToken }`. **회전(rotation)**: 기존 리프레시 폐기 + 새 리프레시 발급, 만료 **180일 재연장(슬라이딩)**. **재사용 감지**: 이미 회전(폐기)된 토큰 재사용 시 해당 프로필 전체 리프레시 폐기(탈취 방어) + 401 `REFRESH_REUSED`. 미존재 401 `REFRESH_INVALID`, 만료 401 `REFRESH_EXPIRED`.
- `POST /auth/logout` — `{ refreshToken }` (인증 필요) → 해당 리프레시 폐기(해당 기기 세션만 종료, 다른 기기 유지). 반환 `{ revoked }`. **프로필당 활성 리프레시 상한 5개**(기기 5대, 발급 시 초과분은 오래된 것부터 폐기). 만료·오래 폐기된 리프레시는 **정리 크론(주 1회, 일 03:00 KST)** 으로 삭제.
- `POST /auth/kakao/link` **(P1)** — 로그인 상태에서 카카오 토큰 제출 → 기존(전화 인증) 계정에 kakaoId 연결. 멱등, 충돌 시 409(KAKAO_ALREADY_LINKED), 비활성 501. 반환: ProfileDto
- `GET /me` / `PATCH /me` — 프로필 조회·수정 (전화검색 동의 토글 + **P1: bizNumber/bizName/bizAddress** 세금계산서 공급자 정보 + **P3a: payoutBank/payoutAccount/payoutHolder** 수금 안내용 입금 계좌(선택 입력) + **P3b: cardEnabled(bool)·cardIntro(<=80자)** QR 명함 노출·소개). ProfileDto 에 `bizNumber/bizName/bizAddress`·`payoutBank/payoutAccount/payoutHolder`·`cardEnabled/cardIntro` 노출

## QR 명함 /me/card · /public/profiles **(P3b)**
- `GET /me/card` — 내 QR 명함(작업자 공개 프로필). 온보딩 후 **최초 조회 시 `cardToken`(nanoid 32) lazy 생성**. 반환: `{ token, url:"{PUBLIC_WEB_URL}/p/{token}", enabled, intro, viewCount, preview:{공개 프로필과 동일}, docStatus:{ valid, withExpiryCount, totalCount, types[], expiredDocs:[{type,expiryDate,dday}] } }`. **`docStatus.expiredDocs` 는 본인 전용**(만료된 내 서류 = 어떤 서류가 문제인지 소유자에게만 표시).
- `POST /me/card/rotate` — 토큰 재발급(유출 대비). 구 토큰 즉시 무효화(→ 이후 공개 조회 404). 반환 `{ token, url, enabled }`.
- `GET /public/profiles/:token` **(@Public)** — 공개 프로필. 반환: `{ name, industryTags[], intro, docValidity:{ valid, count, withExpiryCount, types[] }, equipments:[{type}], joinedAt, connect:{ message, appDeepLink, storeLinks:{ios,android} } }`. **비노출 절대 원칙**: 전화·계좌·서류 파일/경로·발급일 등 민감정보 미포함. 장비는 **종류(type)만**(차량번호·규격 제외). **서류 유효 배지**: 만료일 등록 서류 ≥1건 && 만료 지난 서류 0건 → `valid=true`(유형명·개수만 노출). **cardEnabled=false 또는 무효 토큰 → 404** PROFILE_CARD_NOT_FOUND. 조회 시 `cardViewCount`만 증가(IP/UA 로그 없음 — 로그 최소화).

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
  - **P1 단가유형 GONGSU(공수)** 추가: 1공수=하루 단가, `quantity` 소수 허용(0.5 권장·0.1 단위, 위반 시 400 INVALID_GONGSU_QUANTITY). `amountCalc.items[0].unit="공수"`, PDF·명세서에 "1.5공수 × 180,000" 라벨.
- `POST /confirmations/:id/send` 응답에 **P1 `alimtalkSent`** 추가 — 수기 상대(manualContact) 전화번호 있으면 알림톡으로 서명 링크 발송 시도(키 없으면 false, 로그만).
- `POST /confirmations/:id/duplicate` — 이전 확인서 복사
- `GET /confirmations?month=YYYY-MM` — 목록(캘린더용 일자 집계 포함)
- `POST /confirmations/:id/send` — 연결 사업장에 전송 or 외부 링크 발급 → `{ share_token?, url? }`
- `POST /confirmations/:id/revoke` — **(백로그정리)** 공유 링크 무효화(발행자). **SENT 만** 무효화 가능 → `revokedAt` 설정 후 public 열람/서명 403 CONFIRMATION_REVOKED. **SIGNED 는 증빙 보존을 위해 링크 열람 유지 → 409 ALREADY_SIGNED**, DRAFT(미전송) → 409 NOT_REVOCABLE. 반환 `{ revoked, status, revokedAt }`. (웹/앱 UI 노출은 백로그 — API 만 제공.)
- `GET /confirmations/:id/pdf` — PDF 다운로드
- `GET /public/confirmations/:token` — 외부 열람
- `POST /public/confirmations/:token/sign` — 외부 서명(서명자명 + 서명 이미지 base64) → SIGNED, 양측 알림

## 팀(반장) /teams **(P2a)**
- `GET /teams` — 내(반장) 팀 목록(+팀원 명단). `POST /teams { name }` — 팀 생성(여러 개 가능, 반장 본인만).
- `GET /teams/:id` / `PATCH /teams/:id { name }` / `DELETE /teams/:id` — 반장 본인만. 삭제 시 팀원은 cascade, 이미 발행된 확인서의 `teamId` 는 SetNull(장부·기록 보존).
- `POST /teams/:id/members` — 팀원 추가. **가입 연결**: `{ profileId, defaultRate? }`(전화 검색-동의자-, 미동의 시 403 CONSENT_REQUIRED, 중복 409 TEAM_MEMBER_EXISTS, 서버가 프로필명 스냅샷). **수기**: `{ name, phone?, defaultRate? }`.
- `PATCH /teams/:id/members/:memberId { name?, phone?, defaultRate? }` / `DELETE /teams/:id/members/:memberId`.
- **팀 확인서**: `POST /confirmations` 에 `teamId` + `teamEntries:[{ memberId, quantity(공수), rate? }]` 허용(있으면 `rateType/rate/quantity` 불필요). 서버가 팀원별 금액(rate×공수)·팀 합계 계산(공수 0.1 단위 검증 재사용), `rateType=GONGSU` 저장, `amountCalc.total`=팀 합계, **반장 장부에 합계 1건**. 응답·목록에 `teamId`, `teamEntries:[{name,profileId,quantity,rate,amount}]` 포함. 소유 아님 → 404 TEAM_NOT_FOUND.
- **팀원 장부 파생**: 팀 확인서가 **SIGNED** 되는 시점에, 가입+연결된 팀원(profileId 有, 반장 자신 제외)에게 각자 몫 `ledger_entry` 자동 생성(`derived=true`, `sourceConfirmationId`=원 확인서, `counterpartyName`=반장 이름) + 알림. 멱등(같은 원확인서·팀원 중복 방지). 미가입(수기) 팀원은 파생 없음.
- **공개 열람**(`GET /public/confirmations/:token`): 응답에 `teamEntries`·`isTeam` 포함(웹 PaperConfirmation P2 통합용). **PDF**: 팀 명단 표(이름/공수/단가/금액 + 합계) 렌더.

## 표준근로계약서 /biz/contracts · /contracts · /public/contracts **(P2b)**
고용노동부 일용직 표준근로계약서 필드 기반. 사업장(발행) ↔ 작업자(서명) 양자. 상태 DRAFT|SENT|SIGNED.
- **사업장 모드**(발행 사업장 소유자만):
  - `POST /biz/contracts` — 작성(DRAFT). body: `{ businessId, workerProfileId? | (workerName + workerPhone?), title?, startDate(YYYY-MM-DD), endDate?, workplace, jobDescription, workStartTime(HH:mm), workEndTime, breakTime?, wageType(DAILY|HOURLY), wageAmount, payday, payMethod, weeklyHolidayAllowance?(기본 false), overtimeAllowance?(기본 true), socialInsurance?{employment,health,pension,industrialAccident}, specialTerms? }`. 가입 연결은 전화검색 동의자 또는 사업장과 ACCEPTED 연결 작업자만(아니면 403 WORKER_LINK_NOT_ALLOWED). 남의 사업장 → 404 BUSINESS_NOT_FOUND.
  - `GET /biz/contracts` — 내 사업장 계약서 목록. **(백로그정리)** `?businessId=` 지정 시 해당 사업장만(미지정=모든 내 사업장, additive). `GET /biz/contracts/:id` — 상세. `GET /biz/contracts/:id/pdf` — 양측 서명 PDF.
  - `PATCH /biz/contracts/:id` — DRAFT + 사업장 미서명일 때만 수정(아니면 409 NOT_EDITABLE). `DELETE` — DRAFT 만(409 NOT_DELETABLE).
  - `POST /biz/contracts/:id/revoke` — **(백로그정리)** 공유 링크 무효화(사업장 소유자). **SENT 만** 무효화 가능 → `revokedAt` 설정 후 public 열람/서명 403 LABOR_CONTRACT_REVOKED. **SIGNED → 409 ALREADY_SIGNED**(증빙 보존, 링크 열람 유지), DRAFT → 409 NOT_REVOCABLE. 남의 사업장 → 404. 반환 계약서 DTO.
  - `POST /biz/contracts/:id/sign-employer` — 사업장(대표) 서명 `{ signerName, signImageBase64 }`. DRAFT 에서만, 상태는 DRAFT 유지(employerSigned=true). **전송 전 필수 선행**.
  - `POST /biz/contracts/:id/send` — 사업장 서명 완료 후에만(아니면 409 EMPLOYER_SIGNATURE_REQUIRED) → SENT. 연결 작업자면 알림, 수기면 링크 발급. 반환 `{ shareToken, url(=/lc/{token}), sent, linked, notified, alimtalkSent }`.
- **작업자 측**(가입 연결 작업자만): `GET /contracts`(내가 받은/서명한 계약서 = "내 계약서", SENT·SIGNED), `GET /contracts/:id`, `GET /contracts/:id/pdf`, `POST /contracts/:id/sign`(앱 내 서명, SENT 만 → SIGNED, 재서명 409 ALREADY_SIGNED). 가입 작업자면 서명 여부와 무관하게 SENT 시점부터 "내 계약서"에 자동 연결(workerProfileId).
- **공개(외부) 열람·서명**(`@Public`): `GET /public/contracts/:token`(열람+viewLog, 조항 데이터 전체·정본 안내용 필드), `GET /public/contracts/:token/pdf`, `POST /public/contracts/:token/sign`(외부 작업자 서명 `{ signerName, signImageBase64 }`, SENT 만 → SIGNED, 원자적 전이·재서명 409). 서명 시 양측(사업장 소유자 + 가입 작업자) 알림. **PDF·웹 열람 정본 안내**: "본 계약서의 정본은 한국어본입니다" 문구 포함, 열람 페이지 `/lc/{token}` 6개 언어(조항 라벨 번역, 계약 값 원문).

## 장부 /ledger
- `GET /ledger/summary?month=` — 월 합계(미수/입금/일한 날 + **P1 `totalGongsu`** 공수 합계)
- `GET /ledger/tax-invoice-data?month=&businessId?=` **(P1)** — 홈택스 세금계산서 작성 데이터. SIGNED·미발행 확인서만 상대별 집계: 공급자(내 프로필 bizNumber 등), 공급받는자(사업장 상호·사업자번호), 작성일자, 공급가액 합계, 세액(10%), 품목(일자·내용·금액). `{ supplier, supplierReady, groups[{ buyerName, buyerBizNumber, supplyTotal, taxTotal, grandTotal, items[], ledgerIds[] }], text }` — JSON + **복사용 텍스트**.
- `POST /ledger/tax-invoice-data/mark` **(P1)** — `{ ledgerIds:[] }` 발행 완료 표시(taxInvoicedAt). 이후 tax-invoice-data 에서 제외. 반환 `{ marked, alreadyMarked, taxInvoicedAt }`
- `GET /ledger/by-company?month=` — 회사별 미수 집계 + 수금 D-day. **P2a**: 팀 파생 항목은 반장 이름 그룹으로 집계, 월 기준일은 원 확인서(팀 확인서) 작업일.
- `POST /ledger/:id/payments` — 입금 기록(부분입금 허용). **P2a**: 팀 파생 항목(`derived=true`)도 입금 기록 가능. `PATCH /ledger/:id` — 수금예정일 수정 + **P3a `autoRemind`(bool) 토글**(additive, 파생 항목은 409 LEDGER_DERIVED_READONLY). 장부 DTO 에 **P3a `autoRemind`·`reminders[{at,channel,stage}]`** 노출(`GET /ledger/entries` 포함).
- `POST /ledger/:id/remind` **(P3a)** — 수동 즉시 수금 안내. 작업자 대신 상대(연결 사업장 소유자=푸시+인앱 알림 / 수기 미가입 상대=알림톡, 명세서·확인서 공개 링크+금액+계좌 포함)에게 점잖은 대금 안내 발송 + 발송 이력 append. **쿨다운 3일**(최근 발송 후 3일 내 재요청 409 REMIND_COOLDOWN). 이미 완납 409 LEDGER_ALREADY_PAID, 대상 정보 없음 409 REMIND_NO_TARGET, 파생 409 LEDGER_DERIVED_READONLY, 타인 404 LEDGER_NOT_FOUND. 반환 `{ sent, channel, lastAt }`.
- **P3a 자동 독촉 크론**: 매일 10:00 KST(기존 수금 스케줄러 확장). `autoRemind=true`·미수·파생 아님·수금예정일 **D+7/D+30 도달** 항목 → 상대에게 발송, `reminders` 에 append, **같은 단계(D7/D30) 중복 발송 방지**.
  - 장부 항목 응답에 **P2a** `derived`(팀 파생 여부)·`sourceConfirmationId` 포함.
- `GET /ledger/statement?month=` — 월간 명세서 PDF
- `GET /ledger/income-report?year=YYYY | from=YYYY-MM&to=YYYY-MM` **(P2d)** — 연간(기간별) 소득 리포트. `{ range{from,to,year}, monthly[{month,billed,paid,outstanding,daysWorked,gongsu}](데이터 없는 월도 0으로 채움), companies[{companyName,businessId,count,total,paid,outstanding}](총액 내림차순), totals{totalBilled,totalPaid,totalOutstanding,totalDays,totalGongsu,entryCount,teamPayout,netBilled}, taxNote{period,lines[]} }`. **팀 파생 처리**: 팀원 파생 항목은 본인 소득으로 집계(teamPayout 0), 반장은 팀 확인서 전체가 매출이며 팀원 지급분(본인 몫 제외)을 `teamPayout` 으로 표기해 `netBilled(=총청구−지급분)` 순소득 참고 제공(차감 아님). 범위 최대 24개월, year/from-to 누락 400, year 형식 400. 종소세 안내는 일반 정보(5월 신고·3.3% 원천징수, 세무 상담 아님 명시).
- `GET /ledger/income-report/pdf?year=|from=&to=` **(P2d)** — 위 리포트를 인증 blob PDF(월별 표+상대별 표+총계+종소세 안내, 나눔고딕·페이지 브레이크).

## 연동 /connections, /businesses
- `POST /businesses` — 사업장 생성(초대코드 자동 발급) / `GET /businesses/search?q=` — 상호·코드 검색. **P3a**: 각 item 에 `paymentBadge: {grade:"EXCELLENT"|"GOOD", avgDays, sampleSize} | null` 추가(우수/양호만 노출, 없으면 null — 부정 낙인 금지).
- `GET /businesses/:id` **(P3a)** — 사업장 단건(공개 정보 + `paymentBadge`). 인증 필요.
- `GET /workers/search?phone=` — 전화번호로 작업자 검색(동의자만)
- `POST /connections` — 연결 요청 / `POST /connections/:id/accept`
- `GET /connections` — 내 연결 목록

## 작업 지시 /jobs (사업장 모드)
- `POST /jobs` — 작업 지시/예약 (연결 작업자 대상) → 작업자에게 푸시, 확인 요청
- `POST /jobs/:id/confirm` — 작업자의 예약 확인 / `GET /jobs?month=` — 양측 조회
- `POST /jobs/:id/start` `POST /jobs/:id/complete` — 시작/완료 (GPS, 사진?, 컨디션체크는 start에 포함)

## 사업장 정산·안전 (사업장 모드)
- `GET /biz/inbox` — 수신 확인서 목록 / `POST /biz/confirmations/:id/sign` — 앱 내 서명
- `GET /biz/settlements?month=` — 작업자별 미지급 집계 / `POST /biz/settlements/pay` — 지급 처리(해당 ledger 반영). **P3a**: pay 후 지급 평판 배지 캐시 비동기 갱신(fire-and-forget).
- `GET /biz/payment-badge?businessId?=` **(P3a)** — 내 사업장 지급 평판 배지(본인용). `{ businessId, businessName, status:"EXCELLENT"|"GOOD"|"NONE"|"INSUFFICIENT", avgDays, sampleSize, updatedAt }`. 우수/양호는 배지, NONE(>30일)·INSUFFICIENT(표본<3)는 개선 안내만(부정 낙인 없음). 미소유 404 BUSINESS_NOT_FOUND.
- **P3a 지급 평판 배지 집계**: 사업장별 **평균 지급 소요일** = SIGNED(확인서)→전액 PAID 까지 일수 평균(최근 12개월, 표본 3건 이상일 때만 산출). 등급 ⚡우수(≤15일)/양호(≤30일). **캐시 컬럼**(`businesses.paymentAvgDays/paymentSampleSize/paymentBadgeUpdatedAt`)에 저장 — 검색마다 실시간 집계 금지. **일일 크론**(04:00 KST) 전 사업장 갱신 + pay 시점 비동기 갱신.
- `GET /biz/safety-report?month=` — 안전관리 이행 리포트 PDF (safety_logs 집계)
- **(백로그정리 — 다중 사업장 스코프)** `GET /biz/inbox`·`/biz/settlements`·`/biz/safety-report` 모두 선택적 `?businessId=` 지원(additive). 미지정 시 소유 전체 집계(기존 동작), 지정 시 해당 사업장만. 미소유 businessId 는 빈 결과(타 사업장 데이터 유출 차단). `pay` 는 항상 소유 전체 ledger 대상(스코프 무관).

## 안전 /safety
- 스케줄러: 기상청 API 폴링 → 폭염특보/체감온도 기준 대상자에게 푸시+기록(safety_logs, append-only)
- `POST /safety/:id/ack` — 작업자 "확인" 탭 → 확인 시각 기록
- 서류 유효성 확인 기록: jobs 배정 시 자동 safety_log 생성

## 간편 TBM /biz/tbm, /tbm (P2c)
- **사업장(소유자)** — `POST /biz/tbm`(현장·일시·위험요인[{code|text}]·조치·특이사항·참석자[{profileId|name}]) → 가입 참석자 알림(TBM) + safety_log(TBM_RECORD) append. `GET /biz/tbm`·`GET /biz/tbm/:id`(참석자 확인 현황), `PATCH`/`DELETE /biz/tbm/:id`(**작성 당일만**, 이후 409 NOT_EDITABLE/NOT_DELETABLE — 증빙 무결성)
- `POST /biz/tbm/:id/photos`(multipart, 당일만, FileStorageService) / `GET /biz/tbm/:id/photos/:idx` — 사진
- **프리셋(커스텀 문구)** — `GET /biz/tbm/presets?businessId=`·`POST /biz/tbm/presets`(kind=HAZARD|MEASURE)·`DELETE /biz/tbm/presets/:id`. 기본 위험요인 프리셋 10종은 **코드 기반**(앱이 6언어 번역), 커스텀은 원문 저장
- **작업자(참석자)** — `GET /tbm`(받은 TBM, 위험요인 코드 기반 → 자기 언어 렌더), `POST /tbm/:attendeeId/ack`(본인만·**최초 1회 원자적**·재확인 409 ALREADY_ACKED → safety_log(TBM_ACK) append + 사업장 알림), `GET /tbm/:id/photos/:idx`
- **안전 리포트 연동**: `GET /biz/safety-report` PDF 에 **월간 TBM 섹션**(일자·현장·위험요인·참석 N/확인 M) 추가. NotificationType/SafetyLogType 에 `TBM`(additive)

## 알림 /notifications
- `GET /notifications` / `POST /device-tokens` (FCM 토큰 등록)
- 스케줄러: 수금 D-day, 서류 만료 D-30/7/0, 작업 예약 리마인드
- **P1 알림톡 채널**: 수금 D-day·폭염 알림은 푸시 미도달(미가입/미설치) 시 알림톡 fallback. Solapi 어댑터(`SOLAPI_*`/`ALIMTALK_*` env)·카카오 비즈메시지 템플릿 승인 필요(미설정이면 로그만, API 계약 변화 없음).

## 구현 순서 (S2 내부)
1. auth → 2. documents(+shares/mask) → 3. confirmations(+public sign) → 4. ledger → 5. connections/jobs → 6. biz → 7. safety/notifications(스케줄러)
