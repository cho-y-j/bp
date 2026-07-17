// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get widgetToday => '오늘 일정';

  @override
  String get widgetNoSchedule => '오늘 일정 없음';

  @override
  String get widgetOutstanding => '이번 달 미수금';

  @override
  String get widgetLoginPlease => '로그인해 주세요';

  @override
  String widgetSyncedAt(String time) {
    return '$time 기준';
  }

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get retry => '다시 시도';

  @override
  String get close => '닫기';

  @override
  String get edit => '편집';

  @override
  String get share => '공유';

  @override
  String get download => '다운로드';

  @override
  String get view => '보기';

  @override
  String get loading => '불러오는 중…';

  @override
  String get errorConnTitle => '연결에 문제가 있어요';

  @override
  String get errorConnSubtitle => '인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get statusDeposited => '입금완료';

  @override
  String get statusOverdue => '기한 지남';

  @override
  String collectDday(String dday) {
    return '수금 $dday';
  }

  @override
  String get amtBase => '기본';

  @override
  String get amtOvertime => '연장';

  @override
  String get amtEarly => '조출';

  @override
  String get amtNight => '야간';

  @override
  String get amtAllnight => '철야';

  @override
  String get itemOther => '기타';

  @override
  String get baseDaily => '기본(일당)';

  @override
  String get baseHourly => '기본(시급)';

  @override
  String get basePerCase => '기본(건당)';

  @override
  String get baseGongsu => '기본(공수)';

  @override
  String get unitGongsu => '공수';

  @override
  String qtyGongsu(String qty) {
    return '$qty공수';
  }

  @override
  String vatLabel(String rate) {
    return '부가세 ($rate%)';
  }

  @override
  String daysCount(int days) {
    return '$days일';
  }

  @override
  String daysWithGongsu(int days, String gongsu) {
    return '$days일 · $gongsu공수';
  }

  @override
  String get moreTitle => '더보기';

  @override
  String get sectionManage => '관리';

  @override
  String get sectionSettings => '설정';

  @override
  String get menuWallet => '서류 지갑';

  @override
  String get menuWalletSub => '자격증·보험·검사증 만료 관리 · 묶음 전송';

  @override
  String get menuBizHome => '사업장 홈';

  @override
  String get menuBizMode => '사업장 모드';

  @override
  String get menuBizSub => '작업 지시·수신 확인서·정산·안전 리포트';

  @override
  String get menuJobs => '받은 작업';

  @override
  String get menuJobsSub => '작업 지시 수락·시작·완료';

  @override
  String get menuTax => '세금계산서 준비';

  @override
  String get menuTaxSub => '서명 완료 확인서 → 홈택스 입력용 데이터 정리';

  @override
  String get menuNotifications => '알림';

  @override
  String get menuNotificationsSub => '수금·서류 만료·작업 예약·폭염 안전';

  @override
  String get consentTitle => '전화번호 검색 허용';

  @override
  String get consentSub => '사업장이 내 번호로 나를 찾아 연결할 수 있어요';

  @override
  String get kakaoLinkTitle => '카카오 계정 연결';

  @override
  String get kakaoLinkedSub => '연결됨';

  @override
  String get kakaoLinkSub => '카카오로도 로그인할 수 있게 연결해요';

  @override
  String get kakaoLinked => '카카오 계정을 연결했어요.';

  @override
  String get kakaoNotReady => '카카오 로그인 준비 중이에요.';

  @override
  String get kakaoAlreadyLinked => '이미 다른 계정에 연결된 카카오예요.';

  @override
  String kakaoLinkFailed(String message) {
    return '연결 실패: $message';
  }

  @override
  String get kakaoLinkCanceled => '카카오 연결이 취소되었어요.';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '로그아웃 하시겠어요?';

  @override
  String get appLockTitle => '앱 잠금';

  @override
  String get appLockSub => '생체 인증·기기 암호로 앱을 보호해요';

  @override
  String get appLockLockedTitle => '잠겨 있어요';

  @override
  String get appLockUnlock => '인증하고 계속하기';

  @override
  String get appLockReason => '작업온 잠금을 해제합니다';

  @override
  String get appLockUnavailable => '이 기기는 생체 인증·기기 암호를 지원하지 않아요';

  @override
  String get noName => '이름 없음';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 따름';

  @override
  String get paperStamp => '작 업 확 인 서';

  @override
  String get paperDate => '작업일';

  @override
  String get paperTime => '시간';

  @override
  String get paperSite => '현장';

  @override
  String get paperWorker => '작업자';

  @override
  String get paperOrderer => '지시자';

  @override
  String get paperWork => '작업내용';

  @override
  String get paperEquipment => '장비';

  @override
  String get paperGuide => '유도원';

  @override
  String get paperTotal => '받을 금액';

  @override
  String get paperMemo => '메모';

  @override
  String get paperSignHead => '지시자 서명';

  @override
  String paperSignedBy(String name) {
    return '$name 님 서명 완료';
  }

  @override
  String shareCount(int n) {
    return '공유된 서류 $n건';
  }

  @override
  String shareValidUntil(String date) {
    return '유효기간 $date까지 열람 가능';
  }

  @override
  String shareExpiry(String date) {
    return '만료 $date';
  }

  @override
  String get shareNoExpiry => '만료일 없음';

  @override
  String get shareMasked => '마스킹본';

  @override
  String get statusTransientTitle => '일시적인 오류입니다';

  @override
  String get statusTransientMsg => '잠시 후 다시 시도해 주세요.';

  @override
  String get statusNotFoundTitle => '찾을 수 없는 링크입니다';

  @override
  String get statusNotFoundMsg =>
      '링크가 만료되었거나 무효화되었을 수 있습니다. 보낸 분에게 새 링크를 요청하세요.';

  @override
  String get authStartWithPhone => '전화번호로 시작하기';

  @override
  String get authTagline => '일한 것을 30초에 기록하고 확인서·장부·정산을 자동으로 관리하세요.';

  @override
  String get authPhoneLabel => '전화번호';

  @override
  String get authCodeLabel => '인증번호';

  @override
  String get authCodeHint => '6자리 인증번호';

  @override
  String get authDevAutofill => '개발 환경: 인증번호가 자동으로 채워집니다.';

  @override
  String get authRequestCode => '인증번호 받기';

  @override
  String get authVerifyStart => '인증하고 시작하기';

  @override
  String get authReenterPhone => '전화번호 다시 입력';

  @override
  String get authOr => '또는';

  @override
  String get authKakaoStart => '카카오로 시작하기';

  @override
  String get authKakaoPreparing => '카카오 로그인 준비 중이에요. 전화번호로 시작해 주세요.';

  @override
  String get onbWelcome => '반가워요!';

  @override
  String get onbNamePrompt => '확인서에 표시될 이름을 알려주세요.';

  @override
  String get onbNameLabel => '이름';

  @override
  String get onbNameHint => '예) 김기사';

  @override
  String get onbStart => '시작하기';

  @override
  String get navHome => '홈';

  @override
  String get navCalendar => '캘린더';

  @override
  String get navLedger => '장부';

  @override
  String get navMore => '더보기';

  @override
  String get navWrite => '작성';

  @override
  String navDraftsSent(int n) {
    return '임시저장 $n건이 자동 전송되었어요.';
  }

  @override
  String navDraftsFailed(int n) {
    return '임시저장 초안 $n건 전송에 실패했어요. 홈에서 확인해 주세요.';
  }

  @override
  String get notiTitle => '알림';

  @override
  String get notiEmpty => '알림이 없어요';

  @override
  String get notiAckDone => '확인 처리되었습니다.';

  @override
  String notiAckFailed(String error) {
    return '확인 실패: $error';
  }

  @override
  String get bizModeTitle => '사업장 모드';

  @override
  String bizCreateFailed(String error) {
    return '생성 실패: $error';
  }

  @override
  String get bizCreateHeading => '사업장을 만들어 시작하세요';

  @override
  String get bizCreateDesc => '작업자 연결·작업 지시·수신 확인서 서명·정산·안전 리포트를 한 곳에서.';

  @override
  String get bizNameHint => '상호 (예: 대성건설)';

  @override
  String get bizBnoHint => '사업자번호 (선택)';

  @override
  String get bizCreateButton => '사업장 만들기';

  @override
  String bizInviteCode(String code) {
    return '초대코드 $code';
  }

  @override
  String get inboxTitle => '수신함';

  @override
  String get bizMenuInboxDesc => '받은 작업확인서 확인·앱내 서명';

  @override
  String get settleTitle => '정산';

  @override
  String get bizMenuSettleDesc => '작업자별 미지급 집계·지급 처리';

  @override
  String get workerTitle => '작업자·지시';

  @override
  String get bizMenuWorkerDesc => '작업자 검색·연결·작업 지시 생성';

  @override
  String get jobTitle => '작업 지시 목록';

  @override
  String get bizMenuJobDesc => '예약·진행·완료 상태 조회';

  @override
  String get safetyTitle => '안전';

  @override
  String get bizMenuSafetyDesc => '안전관리 리포트 PDF·최근 안전 기록';

  @override
  String bizLoadFailed(String error) {
    return '불러오지 못했습니다: $error';
  }

  @override
  String get inboxEmpty => '받은 확인서가 없어요';

  @override
  String get inboxStatusSigned => '서명완료';

  @override
  String get inboxStatusPending => '서명대기';

  @override
  String get jobStatusScheduled => '예약';

  @override
  String get jobStatusInProgress => '진행중';

  @override
  String get jobStatusDone => '완료';

  @override
  String get jobEmpty => '이번 달 작업 지시가 없어요';

  @override
  String get jobAccepted => '수락됨';

  @override
  String get jobAcceptPending => '수락 대기';

  @override
  String safetyReportOpenFailed(String error) {
    return '리포트 열기 실패: $error';
  }

  @override
  String get safetyReportTitle => '안전관리 이행 리포트';

  @override
  String get safetyReportDesc => '컨디션 체크·서류 유효성·폭염 알림 기록을 월별 PDF로 확인하세요.';

  @override
  String safetyOpenReport(String month) {
    return '$month 리포트 열기';
  }

  @override
  String get safetyHeatNotice =>
      '폭염특보 시 연결된 작업자에게 자동으로 안전 알림이 발송되고 확인 기록이 남습니다.';

  @override
  String settlePaidSnack(String name, String amount) {
    return '$name님에게 $amount 지급 처리';
  }

  @override
  String settlePayFailed(String error) {
    return '지급 실패: $error';
  }

  @override
  String get settleEmpty => '이번 달 미지급 내역이 없어요';

  @override
  String settleEntryCount(int count) {
    return '$count건';
  }

  @override
  String get settlePaidDone => '지급 완료';

  @override
  String settlePayAmount(String amount) {
    return '$amount 지급';
  }

  @override
  String workerSearchFailed(String error) {
    return '검색 실패: $error';
  }

  @override
  String workerConnectRequested(String name) {
    return '$name님에게 연결을 요청했어요.';
  }

  @override
  String workerRequestFailed(String error) {
    return '요청 실패: $error';
  }

  @override
  String get workerSearchHint => '작업자 전화번호로 검색';

  @override
  String get workerSearchButton => '검색';

  @override
  String get workerConnectButton => '연결 요청';

  @override
  String get workerConnectedHeading => '연결된 작업자';

  @override
  String get workerNoneConnected => '아직 연결된 작업자가 없어요';

  @override
  String get workerStatusConnected => '연결됨';

  @override
  String get workerStatusPending => '요청 대기중';

  @override
  String get workerJobButton => '작업 지시';

  @override
  String get workerAccept => '수락';

  @override
  String get workerJobSent => '작업 지시를 보냈어요. 작업자에게 알림이 전송됩니다.';

  @override
  String jobFormTitle(String name) {
    return '$name님에게 작업 지시';
  }

  @override
  String get jobFormSiteHint => '현장 (예: 반포자이 리모델링)';

  @override
  String get jobRateDaily => '일당';

  @override
  String get jobRateHourly => '시급';

  @override
  String get jobRatePerCase => '건당';

  @override
  String get jobFormRateHint => '단가 (원)';

  @override
  String get jobFormSubmit => '작업 지시 보내기';

  @override
  String jobCreateFailed(String error) {
    return '지시 실패: $error';
  }

  @override
  String get bizConfirmTitle => '작업확인서';

  @override
  String get bizSignErrSign => '서명을 입력해 주세요.';

  @override
  String get bizSignErrName => '서명자 이름을 입력해 주세요.';

  @override
  String get bizSignDone => '서명이 완료되었습니다. (SIGNED)';

  @override
  String bizSignFailed(String error) {
    return '서명 실패: $error';
  }

  @override
  String get bizStampDefault => '작업확인서 · WORKON';

  @override
  String get bizStampSigned => '서 명 완 료 · WORKON';

  @override
  String get bizLineCounterpart => '상대';

  @override
  String get bizLineRateType => '단가유형';

  @override
  String bizSignedBadge(String name, String at) {
    return '$name 서명 · $at';
  }

  @override
  String get bizSignInAppTitle => '앱에서 바로 서명';

  @override
  String get bizSignInAppDesc => '아래에 서명하면 작업자에게 즉시 전달되고 확인서가 확정됩니다.';

  @override
  String get bizSignerNameLabel => '서명자 이름';

  @override
  String get bizSignRedraw => '다시 서명';

  @override
  String get bizSignSubmit => '서명하고 확정';

  @override
  String get confNoCopySource => '복사할 이전 확인서가 없어요.';

  @override
  String get confCopyPrevious => '이전 확인서 복사';

  @override
  String get confFormTitle => '작업확인서 작성';

  @override
  String get confSiteHint => '예) 래미안 원펜타스 3공구';

  @override
  String get confWorkHint => '작업한 내용을 적어주세요';

  @override
  String get confRateType => '단가 유형';

  @override
  String get confRateDaily => '일당';

  @override
  String get confRateHourly => '시급';

  @override
  String get confRatePerCase => '건당';

  @override
  String get confPricePerCase => '건당 단가';

  @override
  String get confPriceGongsu => '공수 단가 (1공수=하루)';

  @override
  String get confQtyHours => '시간';

  @override
  String get confQtyCases => '건수';

  @override
  String get confQtyDays => '일수';

  @override
  String get confErrGongsu => '공수는 0.1 단위로 입력해 주세요 (예: 0.5 · 1.5).';

  @override
  String get confErrHours => '시간을 1 이상 입력해 주세요.';

  @override
  String get confErrCases => '건수를 1 이상 입력해 주세요.';

  @override
  String get confErrDays => '일수를 1 이상 입력해 주세요.';

  @override
  String get confDueDate => '수금 예정일 (선택)';

  @override
  String get confNotSet => '미설정';

  @override
  String get confSaveSend => '저장하고 보내기';

  @override
  String get confSaveHint => '저장 즉시 장부에 반영됩니다 · 링크로 전송';

  @override
  String get confStartTime => '시작 시각';

  @override
  String get confEndTime => '종료 시각';

  @override
  String get confOrdererCompany => '지시자 (회사)';

  @override
  String get confLinkedBiz => '연결 사업장';

  @override
  String get confManualEntry => '직접 입력';

  @override
  String get confSelectBiz => '연결 사업장 선택';

  @override
  String get confCompanyHint => '회사/현장 담당 상호';

  @override
  String get confContactHint => '담당자/연락처 (선택)';

  @override
  String get confEquipSection => '장비 섹션';

  @override
  String get confEquipAutoInclude => '확인서에 자동 포함';

  @override
  String get confEquipName => '장비명';

  @override
  String get confVehicleNo => '차량번호';

  @override
  String get confUnitPrice => '단가';

  @override
  String get confQuantity => '수량';

  @override
  String get confAddExtra => '연장·야간 항목 추가';

  @override
  String get confSavedLinked => '저장 완료 · 연결된 사업장에 전송했어요.';

  @override
  String get confSavedBook => '저장 완료 · 장부에 반영되었어요.';

  @override
  String get confDraftQueued => '임시저장됨 — 연결되면 자동 전송돼요.';

  @override
  String confSaveFailed(String message) {
    return '저장 실패: $message';
  }

  @override
  String get confRestoreTitle => '작성 중이던 내용이 있어요.';

  @override
  String get confRestore => '불러오기';

  @override
  String get confDetailTitle => '작업확인서';

  @override
  String get confSentLinked => '연결된 사업장에 전송했어요.';

  @override
  String confSendFailed(String message) {
    return '전송 실패: $message';
  }

  @override
  String get confReshare => '다시 공유하기';

  @override
  String get confSendToLinked => '연결된 사업장으로 전송됩니다';

  @override
  String get confSendViaShare => '공유 시트(카카오톡 등)로 링크를 보낼 수 있어요';

  @override
  String get confCounterparty => '상대';

  @override
  String get confSentWaitingSign => '전송됨 · 상대 서명 대기 중';

  @override
  String get confDraftBeforeSend => '작성됨 · 전송 전';

  @override
  String confShareHeader(String site) {
    return '[작업확인서] $site';
  }

  @override
  String get confShareBody => '아래 링크에서 내용을 확인하고 서명해 주세요.';

  @override
  String confShareSubject(String site) {
    return '작업확인서 · $site';
  }

  @override
  String get draftFlushNone => '아직 전송하지 못했어요. 연결을 확인해 주세요.';

  @override
  String draftFlushSent(int n) {
    return '$n건 전송 완료 · 장부에 반영되었어요.';
  }

  @override
  String get draftFlushFailed => '전송에 실패한 초안이 있어요. 내용을 확인해 주세요.';

  @override
  String get draftTitle => '임시저장 초안';

  @override
  String get draftEmpty => '전송 대기 중인 초안이 없어요.';

  @override
  String get draftHint => '연결이 복구되면 자동으로 전송돼요. 지금 바로 보내려면 아래에서 다시 시도하세요.';

  @override
  String get draftSendAll => '지금 모두 전송';

  @override
  String get draftNoSite => '(현장 미입력)';

  @override
  String draftCheckNeeded(String error) {
    return '확인 필요: $error';
  }

  @override
  String homeGreeting(String name) {
    return '반갑습니다, $name님';
  }

  @override
  String get homeToday => '오늘 일정';

  @override
  String get homeMonthSummary => '이번 달 요약';

  @override
  String get homeCheckNeeded => '확인 필요';

  @override
  String homeDocExpiry(String type, String dday) {
    return '$type 만료 $dday';
  }

  @override
  String get homeDocExpirySub => '서류 지갑에서 갱신하고 다시 등록하세요';

  @override
  String homeDraftsPending(int n) {
    return '임시저장 $n건 전송 대기';
  }

  @override
  String get homeDraftsError => '일부 초안은 확인이 필요해요 · 탭하여 보기';

  @override
  String get homeDraftsAuto => '연결되면 자동으로 전송돼요 · 탭하여 보기';

  @override
  String get homeStampDraft => '작 성 됨 · WORKON';

  @override
  String get homeStampScheduled => '작업 예정 · WORKON';

  @override
  String get homeTodayBadge => '오늘';

  @override
  String get homeStampToday => '오늘 · WORKON';

  @override
  String get homeEmptyToday => '오늘 예정된 일정이 없어요';

  @override
  String get homeEmptyTodaySub => '하단 + 버튼으로 오늘 작업을 30초에 기록하세요.';

  @override
  String get homeDaysWorked => '일한 날';

  @override
  String get homeReceivable => '받을 돈 (미수)';

  @override
  String get homeReceived => '받은 돈 (입금)';

  @override
  String get calViewMonth => '월';

  @override
  String get calViewWeek => '주';

  @override
  String calWorkCount(int n) {
    return '작업 $n건';
  }

  @override
  String get calManUnit => '만';

  @override
  String get calEmptyMonth => '이 달에 기록된 작업이 없어요.';

  @override
  String get calEmptyDay => '이 날 기록된 작업이 없어요.';

  @override
  String get calRecordThisDay => '이 날 작업 기록하기';

  @override
  String get ledgerTitle => '장부';

  @override
  String get ledgerOutstandingTotal => '이번 달 미수 합계';

  @override
  String ledgerWorkedThisMonth(String summary) {
    return '이번 달 $summary 일함';
  }

  @override
  String get ledgerByCompany => '회사별';

  @override
  String ledgerCompanyCount(int n) {
    return '$n곳';
  }

  @override
  String get ledgerStamp => '장부 · WORKON';

  @override
  String get ledgerEmptyTitle => '이 달의 장부 기록이 없어요';

  @override
  String get ledgerEmptySub => '확인서를 작성하면 장부가 자동으로 채워져요.';

  @override
  String get ledgerWriteConfirmation => '확인서 작성하기';

  @override
  String ledgerDaysWorked(int days) {
    return '$days일 작업';
  }

  @override
  String ledgerPaidAmount(String amount) {
    return '$amount 입금';
  }

  @override
  String ledgerStatementFail(String error) {
    return '명세서 열기 실패: $error';
  }

  @override
  String get ledgerMonthlyStatement => '월간 명세서 PDF';

  @override
  String get ledgerRemaining => '남은 미수';

  @override
  String get ledgerWorkHistory => '작업 내역';

  @override
  String ledgerBilled(String amount) {
    return '청구 $amount';
  }

  @override
  String ledgerDeposited(String amount) {
    return '입금 $amount';
  }

  @override
  String get ledgerPaymentSaved => '입금이 기록되었어요.';

  @override
  String ledgerPaymentFail(String message) {
    return '실패: $message';
  }

  @override
  String get ledgerRecordPayment => '입금 기록';

  @override
  String ledgerRemainingAmount(String amount) {
    return '남은 미수 $amount';
  }

  @override
  String get ledgerPaymentAmount => '입금액';

  @override
  String get ledgerWonSuffix => '원';

  @override
  String get ledgerFull => '전액';

  @override
  String get ledgerHalf => '절반';

  @override
  String get ledgerRecordPaymentBtn => '입금 기록하기';

  @override
  String get taxTitle => '세금계산서 준비';

  @override
  String taxSupplierPrefix(String name) {
    return '공급자 · $name';
  }

  @override
  String get taxNoBizName => '(상호 미등록)';

  @override
  String taxBizNumberLine(String number) {
    return '사업자번호 $number';
  }

  @override
  String get taxHometaxGuide =>
      '복사한 내용을 홈택스(hometax.go.kr) 세금계산서 발행에 붙여넣으세요. 발행 후 \"발행 완료 표시\"를 누르면 목록에서 빠져요.';

  @override
  String get taxEmptyTitle => '발행 대상 확인서가 없어요.';

  @override
  String get taxEmptySubtitle => '서명 완료(SIGNED)·미발행 확인서만 여기 모여요.';

  @override
  String get taxStamp => '세금계산서 · WORKON';

  @override
  String get taxSupplierPromptTitle => '먼저 사업자 정보를 입력하세요';

  @override
  String get taxSupplierPromptDesc => '세금계산서 공급자(나)의 사업자등록번호·상호가 필요해요.';

  @override
  String get taxEnterBizInfo => '사업자 정보 입력';

  @override
  String get taxCopiedSnack => '복사됐어요 · 홈택스에 붙여넣으세요.';

  @override
  String get taxMarkedSnack => '발행 완료로 표시했어요 · 목록에서 제외돼요.';

  @override
  String get taxAlreadyMarkedSnack => '이미 발행 표시된 항목이에요.';

  @override
  String taxMarkFailed(String msg) {
    return '표시 실패: $msg';
  }

  @override
  String taxBuyerBizLine(String number, int count) {
    return '사업자번호 $number · 품목 $count건';
  }

  @override
  String get taxNotRegistered => '(미등록)';

  @override
  String get taxSupplyAmount => '공급가액';

  @override
  String get taxGrandTotal => '합계금액';

  @override
  String get taxCopy => '복사';

  @override
  String get taxMarkIssued => '발행 완료 표시';

  @override
  String get taxRegisteredBadge => '등록 상대';

  @override
  String get taxCheckNeeded => '확인 필요';

  @override
  String get bizinfoTitle => '사업자 정보';

  @override
  String get bizinfoDesc => '세금계산서 발행에 쓰이는 공급자(나) 정보예요.';

  @override
  String get bizinfoBizNumberLabel => '사업자등록번호';

  @override
  String get bizinfoBizNameLabel => '상호';

  @override
  String get bizinfoBizNameHint => '상호(회사명)';

  @override
  String get bizinfoAddressLabel => '사업장 주소 (선택)';

  @override
  String get bizinfoAddressHint => '사업장 주소';

  @override
  String get bizinfoSavedSnack => '사업자 정보를 저장했어요.';

  @override
  String bizinfoSaveFailed(String msg) {
    return '저장 실패: $msg';
  }

  @override
  String get walletTitle => '서류 지갑';

  @override
  String walletSelectedCount(int n) {
    return '$n개 선택';
  }

  @override
  String get walletAddDoc => '서류 추가';

  @override
  String get walletMaskPromptTitle => '개인정보를 가릴까요?';

  @override
  String get walletMaskPromptBody => '주민번호·주소 등 민감정보를 마스킹하면 안전하게 공유할 수 있어요.';

  @override
  String get walletLater => '나중에';

  @override
  String get walletMaskEdit => '마스킹 편집';

  @override
  String walletExpiredTitle(String type) {
    return '$type 만료됨';
  }

  @override
  String walletExpiringTitle(String type, String dday) {
    return '$type 만료 $dday';
  }

  @override
  String walletExpiringMultiSub(int n) {
    return '만료 임박 서류 $n건 — 갱신 후 다시 등록하세요';
  }

  @override
  String get walletRenewHint => '갱신 후 다시 등록하세요';

  @override
  String get walletEmptyTitle => '아직 등록한 서류가 없어요';

  @override
  String get walletEmptySub => '자격증·보험·검사증을 등록하고 만료를 관리하세요';

  @override
  String walletShareMessage(int count, int days, String url) {
    return '[작업온] 서류 $count건을 보냅니다.\n아래 링크에서 확인하세요 (유효 $days일).\n$url';
  }

  @override
  String get walletShareSubject => '작업온 서류 공유';

  @override
  String walletShareFailed(String error) {
    return '공유 실패: $error';
  }

  @override
  String walletSendBundle(int count) {
    return '$count건 묶어 보내기';
  }

  @override
  String get walletBundleSend => '묶음 보내기';

  @override
  String get walletValidPeriod => '유효기간';

  @override
  String get walletMaskedInfo => '마스킹본이 있는 서류는 개인정보가 가려진 상태로 전송됩니다.';

  @override
  String get walletUnmaskedInfo => '마스킹본이 없으면 원본이 그대로 전송됩니다. 상세에서 마스킹할 수 있어요.';

  @override
  String get walletMakeLinkShare => '링크 만들고 공유';

  @override
  String docOpenFailed(String error) {
    return '열기 실패: $error';
  }

  @override
  String docUpdateFailed(String error) {
    return '수정 실패: $error';
  }

  @override
  String get docDeleteConfirmTitle => '서류를 삭제할까요?';

  @override
  String get docDeleteConfirmBody => '이 서류와 공유 링크가 함께 삭제됩니다.';

  @override
  String docDeleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get docOpenPdf => 'PDF 열기';

  @override
  String get docHasMask => '마스킹본 있음';

  @override
  String get docExpiryDate => '만료일';

  @override
  String get docNone => '없음';

  @override
  String get docIssuedDate => '발급일';

  @override
  String get docReMask => '마스킹 다시 편집';

  @override
  String get docMaskEdit => '개인정보 마스킹 편집';

  @override
  String get docModify => '수정';

  @override
  String get docExpired => '만료됨';

  @override
  String docUploadFailed(String error) {
    return '업로드 실패: $error';
  }

  @override
  String get docSourceCamera => '카메라로 촬영';

  @override
  String get docSourceGallery => '갤러리에서 선택';

  @override
  String get docSourcePdf => 'PDF 파일 선택';

  @override
  String get docInfoTitle => '서류 정보';

  @override
  String docFilePdf(String name) {
    return 'PDF · $name';
  }

  @override
  String docFileImage(int kb) {
    return '이미지 · ${kb}KB';
  }

  @override
  String get docTypeLabel => '유형';

  @override
  String get docLinkEquip => '장비 연결 (선택)';

  @override
  String get docPersonal => '개인';

  @override
  String get docPickExpiry => '만료일 선택 (선택)';

  @override
  String get docUpload => '업로드';

  @override
  String get equipTitle => '장비 관리';

  @override
  String get equipAdd => '장비 추가';

  @override
  String get equipEmptyTitle => '등록된 장비가 없어요';

  @override
  String get equipEmptySub => '굴삭기·지게차 등 장비를 등록하고 서류를 묶으세요';

  @override
  String equipDocCount(int n) {
    return '서류 $n건';
  }

  @override
  String get equipDocs => '서류';

  @override
  String get equipTypeHint => '장비 종류 (예: 굴삭기)';

  @override
  String get equipVehicleHint => '차량번호 (선택)';

  @override
  String get equipSpecHint => '규격 (예: 06W) (선택)';

  @override
  String get equipSubmit => '추가';

  @override
  String get maskDoneToast => '마스킹본을 만들었어요. 공유 시 개인정보가 가려집니다.';

  @override
  String maskFailed(String error) {
    return '마스킹 실패: $error';
  }

  @override
  String get maskTitle => '개인정보 마스킹';

  @override
  String get maskReset => '초기화';

  @override
  String get maskGuide => '가릴 영역을 손가락으로 드래그해 사각형으로 지정하세요. (예: 주민번호·주소)';

  @override
  String maskRegionCount(int n) {
    return '지정한 영역 $n개';
  }

  @override
  String get maskSave => '마스킹본 저장';

  @override
  String get wshareTitle => '내 공유';

  @override
  String wshareLoadFailed(String error) {
    return '불러오지 못했습니다: $error';
  }

  @override
  String get wshareEmpty => '아직 공유한 서류 묶음이 없어요';

  @override
  String get wshareActive => '활성';

  @override
  String get wshareInactive => '만료/무효';

  @override
  String wshareViewCount(int n) {
    return '열람 $n회';
  }

  @override
  String get wshareReshare => '다시 공유';

  @override
  String get wshareRevoke => '무효화';

  @override
  String myjobFailed(String error) {
    return '실패: $error';
  }

  @override
  String get myjobConditionTitle => '컨디션 체크';

  @override
  String get myjobConditionBody => '오늘 몸 상태는 어떤가요? 안전한 작업을 위해 확인합니다.';

  @override
  String get myjobConditionBad => '안 좋아요';

  @override
  String get myjobConditionGood => '좋아요';

  @override
  String get myjobConditionReported => '사업장에 컨디션 이상이 전달되었습니다. 무리하지 마세요.';

  @override
  String myjobLoadFailed(String error) {
    return '불러오지 못했습니다: $error';
  }

  @override
  String get myjobEmpty => '받은 작업 지시가 없어요';

  @override
  String get myjobAccept => '수락';

  @override
  String get myjobStart => '작업 시작';

  @override
  String get myjobComplete => '작업 완료';

  @override
  String get signPadHint => '여기에 손가락으로 서명하세요';

  @override
  String get teamMenuTitle => '내 팀';

  @override
  String get teamMenuSub => '반장으로 팀원 명단·단가 관리';

  @override
  String get teamListTitle => '내 팀';

  @override
  String get teamEmptyTitle => '아직 만든 팀이 없어요';

  @override
  String get teamEmptySub => '팀을 만들고 팀원을 추가하면 팀 확인서를 한 장으로 정리할 수 있어요';

  @override
  String get teamCreate => '팀 만들기';

  @override
  String get teamNameLabel => '팀 이름';

  @override
  String get teamNameHint => '팀 이름 (예: 박반장 A팀)';

  @override
  String get teamAddMember => '팀원 추가';

  @override
  String get teamMembersTitle => '팀원';

  @override
  String get teamNoMembers => '팀원을 추가해 주세요';

  @override
  String teamMemberCountLabel(int count) {
    return '팀원 $count명';
  }

  @override
  String get teamMemberLinked => '가입 연결';

  @override
  String get teamMemberManual => '수기';

  @override
  String get teamDefaultRate => '기본 단가';

  @override
  String get teamDefaultRateHint => '기본 단가 (공수 1일)';

  @override
  String get teamAddByPhone => '전화번호로 찾기';

  @override
  String get teamAddManual => '직접 입력';

  @override
  String get teamMemberNameHint => '이름';

  @override
  String get teamMemberPhoneHint => '전화번호 (선택)';

  @override
  String get teamSearchPhoneHint => '팀원 전화번호';

  @override
  String get teamSearchHint => '전화번호 검색에 동의한 가입자만 찾을 수 있어요';

  @override
  String get teamSearchNoResult => '검색 결과가 없어요';

  @override
  String get teamMemberAdded => '팀원을 추가했어요';

  @override
  String get teamMemberExists => '이미 팀에 있는 팀원이에요';

  @override
  String get teamConsentRequired => '전화번호 검색에 동의한 가입자만 연결할 수 있어요';

  @override
  String get teamDeleteConfirm => '이 팀을 삭제할까요? 이미 발행된 확인서는 그대로 유지돼요.';

  @override
  String get teamDeleteMemberConfirm => '이 팀원을 삭제할까요?';

  @override
  String get confTeamMode => '팀 확인서';

  @override
  String get confTeamModeSub => '팀원별 공수로 한 장에 정리';

  @override
  String get confTeamSelect => '팀 선택';

  @override
  String get confTeamPickTeam => '팀을 선택하세요';

  @override
  String get confTeamNoTeam => '먼저 \'내 팀\'에서 팀을 만들어 주세요';

  @override
  String get confTeamTotal => '팀 합계';

  @override
  String get confTeamEmptyEntries => '공수를 입력한 팀원이 없어요';

  @override
  String get ledgerTeamBadge => '팀';

  @override
  String ledgerTeamDerived(String boss) {
    return '$boss 반장 팀 작업';
  }

  @override
  String get ledgerDerivedReadonly => '반장이 작성한 팀 작업이에요 (입금만 기록할 수 있어요)';

  @override
  String get lcKicker => '표준근로계약서';

  @override
  String get lcStamp => '표 준 근 로 계 약 서';

  @override
  String get lcParties => '계약 당사자';

  @override
  String get lcEmployer => '사업주(갑)';

  @override
  String get lcWorkerParty => '근로자(을)';

  @override
  String get lcBizNumber => '사업자번호';

  @override
  String get lcPeriod => '근로계약기간';

  @override
  String get lcPeriodOpen => '기간의 정함 없음 · 일 단위';

  @override
  String get lcWorkplace => '근무장소';

  @override
  String get lcJob => '업무내용';

  @override
  String get lcWorkTime => '근로시간';

  @override
  String get lcBreak => '휴게';

  @override
  String get lcWage => '임금';

  @override
  String get lcWageDaily => '일급';

  @override
  String get lcWageHourly => '시급';

  @override
  String get lcPayday => '임금 지급일';

  @override
  String get lcPayMethod => '지급 방법';

  @override
  String get lcAllowance => '수당';

  @override
  String get lcWeeklyHoliday => '주휴수당: 1주 소정근로일을 개근하면 주휴수당을 지급합니다.';

  @override
  String get lcWeeklyHolidayNone => '주휴수당: 해당 없음(일용·단시간 등).';

  @override
  String get lcOvertime => '연장·야간·휴일근로 시 근로기준법에 따라 통상임금의 50%를 가산 지급합니다.';

  @override
  String get lcOvertimeNone => '연장·야간·휴일 가산수당: 별도로 정하지 않음.';

  @override
  String get lcInsurance => '사회보험 적용';

  @override
  String get lcInsEmployment => '고용보험';

  @override
  String get lcInsHealth => '건강보험';

  @override
  String get lcInsPension => '국민연금';

  @override
  String get lcInsAccident => '산재보험';

  @override
  String get lcApplied => '적용';

  @override
  String get lcNotApplied => '미적용';

  @override
  String get lcSpecial => '특약사항';

  @override
  String get lcMasterNote =>
      '본 계약서의 정본은 한국어본입니다. 번역본은 이해를 돕기 위한 참고용이며, 해석상 차이가 있을 경우 한국어본이 우선합니다.';

  @override
  String get lcEmployerSigned => '사업주 서명 완료';

  @override
  String get lcMenuDesc => '작업자와 전자서명으로 계약';

  @override
  String get lcListEmptyTitle => '아직 계약서가 없어요';

  @override
  String get lcListEmptySub => '작업자와 맺을 근로계약서를 작성해 보세요';

  @override
  String get lcNewContract => '계약서 작성';

  @override
  String get lcStatusDraft => '작성됨';

  @override
  String get lcStatusSent => '전송됨';

  @override
  String get lcStatusSigned => '서명됨';

  @override
  String get lcWorkerSection => '작업자';

  @override
  String get lcWorkerByPhone => '전화로 찾기';

  @override
  String get lcWorkerManual => '직접 입력';

  @override
  String get lcWorkerNameHint => '작업자 이름';

  @override
  String get lcWorkerPhoneHint => '작업자 전화번호 (선택)';

  @override
  String get lcSearchPhoneHint => '작업자 전화번호';

  @override
  String get lcSearchHint => '전화번호 검색에 동의한 가입자만 찾을 수 있어요';

  @override
  String get lcSearchNoResult => '검색 결과가 없어요';

  @override
  String get lcWorkerLinkedBadge => '연결';

  @override
  String get lcStartDate => '시작일';

  @override
  String get lcEndDate => '종료일 (선택)';

  @override
  String get lcEndDateNotSet => '정함 없음';

  @override
  String get lcWorkplaceHint => '예) 강남 A현장';

  @override
  String get lcJobHint => '예) 철근 조립';

  @override
  String get lcBreakHint => '예) 12:00~13:00';

  @override
  String get lcWageAmountHint => '금액';

  @override
  String get lcPaydayHint => '예) 매월 25일';

  @override
  String get lcPayMethodHint => '예) 계좌이체';

  @override
  String get lcWeeklyHolidaySwitch => '주휴수당 지급';

  @override
  String get lcOvertimeSwitch => '연장·야간·휴일 가산수당';

  @override
  String get lcSpecialHint => '특약사항 (선택)';

  @override
  String get lcSaveCommon => '자주 쓰는 값 저장';

  @override
  String get lcSaveCommonSub => '다음 작성 시 자동으로 채워요';

  @override
  String get lcSubmit => '계약서 만들기';

  @override
  String get lcCreated => '계약서를 만들었어요';

  @override
  String get lcDetailTitle => '계약서';

  @override
  String get lcSignEmployerTitle => '내 서명 (사업주)';

  @override
  String get lcSignEmployerDesc => '서명하면 작업자에게 보낼 수 있어요';

  @override
  String get lcSignerNameLabel => '서명자 이름';

  @override
  String get lcSignRedraw => '다시 그리기';

  @override
  String get lcSignSubmit => '서명하기';

  @override
  String get lcSigned => '서명을 완료했어요';

  @override
  String get lcSignErrPad => '서명을 입력해 주세요';

  @override
  String get lcSignErrName => '서명자 이름을 입력해 주세요';

  @override
  String get lcSend => '작업자에게 전송';

  @override
  String get lcSentLinked => '작업자에게 전송했어요';

  @override
  String get lcSentShare => '링크를 공유해 전달하세요';

  @override
  String get lcShareBody => '아래 링크에서 계약서를 확인하고 서명해 주세요';

  @override
  String get lcViewPdf => 'PDF 열람';

  @override
  String get lcDeleteConfirm => '이 계약서를 삭제할까요?';

  @override
  String get lcDeleted => '삭제했어요';

  @override
  String get lcWaitingWorker => '작업자 서명 대기 중';

  @override
  String get lcMyContractsTitle => '내 계약서';

  @override
  String get lcMyContractsSub => '받은 근로계약서 확인·서명';

  @override
  String get lcMyEmptyTitle => '받은 계약서가 없어요';

  @override
  String get lcMyEmptySub => '사업주가 보낸 계약서가 여기에 표시돼요';

  @override
  String get lcWorkerSignTitle => '내 서명 (근로자)';

  @override
  String get lcWorkerSignDesc => '내용을 확인하고 서명해 주세요';

  @override
  String get lcAlreadySigned => '이미 서명한 계약서예요';

  @override
  String lcCreateFailed(String msg) {
    return '계약서를 저장하지 못했어요: $msg';
  }

  @override
  String lcSignFailed(String msg) {
    return '서명하지 못했어요: $msg';
  }

  @override
  String lcSendFailed(String msg) {
    return '전송하지 못했어요: $msg';
  }

  @override
  String lcPdfFailed(String msg) {
    return 'PDF를 열지 못했어요: $msg';
  }

  @override
  String get tbmMenuTitle => 'TBM 기록';

  @override
  String get tbmMenuDesc => '안전점검회의 · 위험요인·참석자 확인';

  @override
  String get tbmMyTitle => '받은 TBM';

  @override
  String get tbmMySub => '내 안전 기록 · 확인';

  @override
  String get tbmTitle => 'TBM(안전점검회의)';

  @override
  String get tbmStamp => 'T B M';

  @override
  String get tbmListEmptyTitle => '오늘 TBM 기록이 없어요';

  @override
  String get tbmListEmptySub => '현장 안전점검회의를 기록하세요.';

  @override
  String get tbmNew => '오늘 TBM 작성';

  @override
  String get tbmFormTitle => 'TBM 작성';

  @override
  String get tbmSite => '현장명';

  @override
  String get tbmSiteHint => '예: 강동 현장 3층';

  @override
  String get tbmDate => '일시';

  @override
  String get tbmHazards => '위험요인';

  @override
  String get tbmHazardsHint => '칩을 눌러 선택하거나 직접 입력하세요';

  @override
  String get tbmAddCustom => '직접 입력';

  @override
  String get tbmCustomHint => '위험요인 직접 입력';

  @override
  String get tbmMeasures => '안전 조치';

  @override
  String get tbmMeasuresHint => '예: 안전벨트 착용, 유도원 배치';

  @override
  String get tbmNotes => '특이사항';

  @override
  String get tbmNotesHint => '특이사항(선택)';

  @override
  String get tbmAttendees => '참석자';

  @override
  String get tbmSelectWorkers => '연결 작업자 선택';

  @override
  String get tbmNoConnections => '연결된 작업자가 없어요';

  @override
  String get tbmAddAttendeeManual => '수기 참석자 추가';

  @override
  String get tbmAttendeeNameHint => '참석자 이름';

  @override
  String get tbmPhotos => '현장 사진';

  @override
  String get tbmAddPhoto => '사진 추가';

  @override
  String get tbmSave => 'TBM 저장';

  @override
  String get tbmSaved => 'TBM을 기록했어요';

  @override
  String tbmSaveFailed(String msg) {
    return '저장하지 못했어요: $msg';
  }

  @override
  String get tbmNeedHazard => '위험요인을 1개 이상 선택하세요';

  @override
  String get tbmNeedSite => '현장명을 입력하세요';

  @override
  String get tbmPresetMine => '내 프리셋';

  @override
  String get tbmPresetAddChip => '＋ 프리셋 저장';

  @override
  String get tbmPresetAddTitle => '자주 쓰는 문구 저장';

  @override
  String get tbmPresetDeleted => '프리셋을 삭제했어요';

  @override
  String get tbmDetailTitle => 'TBM 상세';

  @override
  String get tbmAttendeesStatus => '참석자 확인 현황';

  @override
  String get tbmAcked => '확인';

  @override
  String get tbmNotAcked => '미확인';

  @override
  String tbmAckSummary(int att, int ack) {
    return '참석 $att명 · 확인 $ack명';
  }

  @override
  String get tbmReadonly => '작성 당일이 지나 읽기 전용입니다';

  @override
  String get tbmEdit => '수정';

  @override
  String get tbmDeleteConfirm => '이 TBM 기록을 삭제할까요?';

  @override
  String get tbmDeleted => '삭제했어요';

  @override
  String get tbmSaveUpdated => '수정했어요';

  @override
  String tbmPhotoFailed(String msg) {
    return '사진 처리 실패: $msg';
  }

  @override
  String get tbmReceivedEmpty => '받은 TBM이 없어요';

  @override
  String get tbmAckButton => 'TBM 확인';

  @override
  String get tbmAckDone => '확인했어요';

  @override
  String tbmAckFailed(String msg) {
    return '확인하지 못했어요: $msg';
  }

  @override
  String get tbmAlreadyAcked => '이미 확인함';

  @override
  String tbmPhotoCount(int n) {
    return '사진 $n장';
  }

  @override
  String get tbmHzHeavyEquip => '중장비 협착·충돌';

  @override
  String get tbmHzFallHeight => '고소작업 추락';

  @override
  String get tbmHzHeatIllness => '폭염 온열질환';

  @override
  String get tbmHzElectric => '감전';

  @override
  String get tbmHzFallingObject => '낙하물';

  @override
  String get tbmHzCollapse => '붕괴·매몰';

  @override
  String get tbmHzFire => '화재·폭발';

  @override
  String get tbmHzDustNoise => '분진·소음';

  @override
  String get tbmHzSlipTrip => '전도·미끄러짐';

  @override
  String get tbmHzConfined => '밀폐공간 질식';

  @override
  String get incomeReportMenuTitle => '소득 리포트';

  @override
  String get incomeReportMenuSub => '연간 수입·미수·공수 한눈에';

  @override
  String get incomeReportTitle => '소득 리포트';

  @override
  String incomeReportYear(String year) {
    return '$year년';
  }

  @override
  String get incomeReportTotalBilled => '총 청구액';

  @override
  String get incomeReportTotalPaid => '총 입금';

  @override
  String get incomeReportTotalOutstanding => '총 미수';

  @override
  String get incomeReportTotalDays => '일한 날';

  @override
  String get incomeReportTotalGongsu => '총 공수';

  @override
  String get incomeReportTeamPayout => '팀 지급분';

  @override
  String get incomeReportNetBilled => '순소득 참고';

  @override
  String get incomeReportNetHint => '청구액 − 팀원 지급분 (반장 본인 몫)';

  @override
  String get incomeReportMonthlyTrend => '월별 추이';

  @override
  String incomeReportPeakLabel(String amount) {
    return '최고 $amount';
  }

  @override
  String get incomeReportByCompany => '상대별 합계';

  @override
  String incomeReportEntryCount(int n) {
    return '$n건';
  }

  @override
  String incomeReportOutstandingShort(String amount) {
    return '미수 $amount';
  }

  @override
  String get incomeReportTaxTitle => '종합소득세 안내';

  @override
  String get incomeReportTaxL1 => '종합소득세는 매년 5월에 전년도 소득을 신고·납부합니다.';

  @override
  String get incomeReportTaxL2 => '인적용역 사업소득은 대금 지급 시 3.3%가 원천징수되는 경우가 많습니다.';

  @override
  String get incomeReportTaxL3 => '원천징수된 세액은 5월 신고 때 정산(환급 또는 추가납부)됩니다.';

  @override
  String get incomeReportTaxL4 => '지출 경비와 확인서·명세서를 보관하면 신고에 도움이 됩니다.';

  @override
  String get incomeReportTaxL5 =>
      '일반 안내이며 세무 상담이 아닙니다. 정확한 신고는 세무 전문가·홈택스를 확인하세요.';

  @override
  String get incomeReportSavePdf => 'PDF 저장·공유';

  @override
  String incomeReportPdfFail(String msg) {
    return '리포트를 열지 못했어요: $msg';
  }

  @override
  String get incomeReportEmptyTitle => '아직 소득 기록이 없어요';

  @override
  String get incomeReportEmptySub => '확인서를 작성하면 이 리포트에 수입이 쌓여요.';

  @override
  String get ledgerAutoRemind => '자동 수금 안내';

  @override
  String get ledgerAutoRemindHint => '수금일 이후 자동으로 대금 안내를 보냅니다';

  @override
  String get ledgerRemindNow => '지금 안내 보내기';

  @override
  String get ledgerRemindSent => '수금 안내를 보냈어요';

  @override
  String get ledgerRemindHistory => '안내 발송 이력';

  @override
  String ledgerRemindHistoryItem(String date, String stage) {
    return '$date · $stage';
  }

  @override
  String get reminderStageD7 => '7일 안내';

  @override
  String get reminderStageD30 => '30일 안내';

  @override
  String get reminderStageManual => '수동 안내';

  @override
  String get profilePayoutSection => '입금 계좌 (수금 안내용)';

  @override
  String get profilePayoutBank => '은행명';

  @override
  String get profilePayoutAccount => '계좌번호';

  @override
  String get profilePayoutHolder => '예금주';

  @override
  String get profilePayoutHint => '수금 안내를 보낼 때 이 계좌가 함께 전달됩니다 (선택 입력)';

  @override
  String get profilePayoutSaved => '입금 계좌를 저장했어요';

  @override
  String get badgeExcellent => '우수 지급처';

  @override
  String get badgeGood => '양호 지급처';

  @override
  String badgeAvgDays(int days) {
    return '평균 $days일';
  }

  @override
  String get badgeSelfImproveGood => '15일 내 지급 시 우수 지급처 배지를 받을 수 있어요';

  @override
  String get badgeSelfImproveNone => '대금을 제때 지급하면 우수 지급처 배지를 받을 수 있어요';

  @override
  String badgeInsufficient(int count) {
    return '지급 기록 $count건 — 배지 산정에는 더 많은 기록이 필요해요';
  }

  @override
  String badgeSampleCount(int count) {
    return '최근 $count건 기준';
  }

  @override
  String get badgeSelfTitle => '지급 신뢰도';

  @override
  String get qrCardMenuTitle => '내 QR 명함';

  @override
  String get qrCardMenuSub => 'QR·링크로 나를 소개해요';

  @override
  String get qrCardTitle => '내 QR 명함';

  @override
  String get qrCardScanHint => 'QR을 찍으면 내 공개 프로필이 열려요';

  @override
  String qrCardViewCount(int count) {
    return '조회 $count회';
  }

  @override
  String get qrCardIntroLabel => '한 줄 소개';

  @override
  String get qrCardIntroPlaceholder => '예: 20년 경력 철근 반장';

  @override
  String get qrCardIntroSaved => '한 줄 소개를 저장했어요';

  @override
  String get qrCardExposeTitle => '명함 공개';

  @override
  String get qrCardExposeSub => '켜면 QR·링크로 프로필을 볼 수 있어요';

  @override
  String get qrCardHiddenHint => '지금은 비공개예요 — 링크를 열어도 명함이 보이지 않아요';

  @override
  String get qrCardRotate => '링크 재발급';

  @override
  String get qrCardRotateConfirm => '새 링크를 만들면 이전 QR·링크는 더 이상 열리지 않아요. 계속할까요?';

  @override
  String get qrCardRotateConfirmBtn => '재발급';

  @override
  String get qrCardRotated => '새 명함 링크를 발급했어요';

  @override
  String get qrCardDocValid => '서류 유효';

  @override
  String get qrCardDocProblem => '확인이 필요한 서류';

  @override
  String qrCardDocExpiryLabel(String date) {
    return '만료 $date';
  }

  @override
  String get smsSendSms => '문자로 보내기';

  @override
  String get smsSharedInstead => '문자를 지원하지 않아 공유로 열었어요';

  @override
  String get smsFailed => '문자 앱을 열지 못했어요';

  @override
  String get callButtonLabel => '전화 걸기';

  @override
  String get callFailed => '전화를 걸지 못했어요';

  @override
  String smsConfBodyNamed(String name, String site, String link) {
    return '$name님, $site 작업확인서 서명 부탁드립니다: $link';
  }

  @override
  String smsConfBodyPlain(String site, String link) {
    return '$site 작업확인서 서명 부탁드립니다: $link';
  }

  @override
  String smsCardShareBody(String link) {
    return '명함을 보내드려요: $link';
  }

  @override
  String smsDocBundleBody(String link) {
    return '서류를 보내드려요: $link';
  }

  @override
  String get smsRecipientTitle => '받는 사람';

  @override
  String get smsRecipientHint => '전화번호 입력';

  @override
  String get smsPickConnection => '연결 상대에서 선택';

  @override
  String get smsOpenCompose => '문자 작성창 열기';

  @override
  String get quickSendMenuTitle => '빠른 보내기';

  @override
  String get quickSendMenuSub => '명함·서류를 문자로 바로 전송';

  @override
  String get quickSendTitle => '빠른 보내기';

  @override
  String get quickSendAddTemplate => '템플릿 추가';

  @override
  String get quickSendPickTemplate => '보낼 템플릿을 선택하세요';

  @override
  String get quickSendBuiltinSection => '기본 템플릿';

  @override
  String get quickSendCustomSection => '내 템플릿';

  @override
  String quickSendNoDoc(String type) {
    return '‘$type’ 서류가 없어요. 서류 지갑에 먼저 등록하세요';
  }

  @override
  String get quickSendAttachImage => '이미지로 첨부';

  @override
  String get quickSendAttachImageSub => '링크 대신 서류 이미지를 직접 첨부해요';

  @override
  String get tplCardTitle => '명함';

  @override
  String tplCardBody(String name, String me, String link) {
    return '$name님, 안녕하세요. $me 명함을 보내드려요: $link';
  }

  @override
  String get tplBizTitle => '사업자등록증';

  @override
  String tplBizBody(String name, String me, String link) {
    return '$name님, $me 사업자등록증을 보내드려요: $link';
  }

  @override
  String get tplBankTitle => '통장사본';

  @override
  String tplBankBody(String name, String me, String link) {
    return '$name님, $me 통장사본을 보내드려요: $link';
  }

  @override
  String get tplEditorTitle => '템플릿 추가';

  @override
  String get tplFieldTitle => '제목';

  @override
  String get tplFieldBody => '본문';

  @override
  String get tplFieldBodyHint => '예: 안녕하세요, 자료 보내드립니다';

  @override
  String get tplVarsHelp => '사용 가능한 변수';

  @override
  String get tplFieldLink => '연결';

  @override
  String get tplLinkNone => '없음';

  @override
  String get tplLinkCard => '명함 링크';

  @override
  String get tplLinkDoc => '서류 링크';

  @override
  String get tplFieldDocType => '서류 유형';

  @override
  String get tplDocTypeHint => '예: 사업자등록증, 통장사본';

  @override
  String get tplSaveTemplate => '템플릿 저장';

  @override
  String get tplNeedTitleBody => '제목과 본문을 입력하세요';

  @override
  String postCallTitle(String name) {
    return '방금 $name님과 통화하셨나요?';
  }

  @override
  String get postCallSendCard => '명함 보내기';

  @override
  String get postCallQuickSend => '빠른 보내기';

  @override
  String get postCallSettingTitle => '통화 후 보내기 제안';

  @override
  String get postCallSettingSub => '앱에서 전화한 뒤 돌아오면 명함·빠른 보내기를 제안해요';
}
