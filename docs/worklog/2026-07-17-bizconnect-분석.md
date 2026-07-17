# bizconnect-v2 문자 구현 분석 → 작업온 P4 이식 방침 (2026-07-17)

## bizconnect-v2 정체
- 네이티브 Kotlin 앱, **스스로 "기본 문자앱"으로 등록**되는 구조 — 그래서 자동 발송(SEND_SMS)·통화 감지+통화기록(READ_CALL_LOG)·통화 후 자동 콜백 문자가 전부 가능했던 것
- Play Store 등록 실체 있음(제출 가이드·Data Safety 양식·릴리스 키)
- 발송 2경로: ①기기 직접(SmsManager+원시 MMS PDU 조립→통신사 MMSC HTTP 전송, LMS 90바이트 자동 승격, 이미지 압축 300KB) ②서버 API(Wideshot/세종 — SMS 8원/LMS 25원/MMS 50원/알림톡 7원, 단 서버 MMS는 미구현)

## 작업온 이식 판단
- **직접 발송(b)은 이식 불가**: 기본 문자앱 + 위험 권한 전제 — 작업온은 기본 문자앱이 될 수 없고 iOS는 원천 불가
- **채택: (a) 기기 문자앱 호출 + 프리필** —
  - Android: ACTION_SEND + image/* + FileProvider URI + EXTRA_TEXT + 기본문자앱 지정 (MethodChannel 네이티브 브릿지)
  - iOS: MFMessageComposeViewController (recipients+body+이미지 첨부) — MethodChannel
  - 텍스트만이면 url_launcher sms:번호?body= 로 충분
- **재사용 가치**: 템플릿 엔진({고객명}{날짜} 변수 치환 — Dart 포팅 용이), 이미지 압축 로직(EXIF 보정+반복 JPEG 압축), 이미지 포함 템플릿 모델(isMms/imageUri), Wideshot LMS 규격(추후 서버 대량 발송 시)
- 통화 후 액션: bizconnect 방식(READ_CALL_LOG)은 정책 부담 → **작업온 방식 = 앱 내 전화 걸기 + 앱 복귀 시 제안 카드**(무권한, iOS 포함)

## P4 최종 설계
1. 문자로 보내기(확인서·서류 링크): 작성창 프리필(번호+본문)
2. 빠른 전송 템플릿: 명함/사업자/통장 + 변수 치환({상대명} 등), **이미지 첨부 문자**(마스킹본 이미지 등) MethodChannel로
3. 앱 내 전화 → 통화 후 복귀 시 "명함/서류 보내기" 제안 카드 (+Android 한정 옵션: 통화종료 알림, 기본 OFF)
