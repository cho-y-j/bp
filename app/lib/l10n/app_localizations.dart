import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ne'),
    Locale('ru'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @widgetToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 일정'**
  String get widgetToday;

  /// No description provided for @widgetNoSchedule.
  ///
  /// In ko, this message translates to:
  /// **'오늘 일정 없음'**
  String get widgetNoSchedule;

  /// No description provided for @widgetOutstanding.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 미수금'**
  String get widgetOutstanding;

  /// No description provided for @widgetLoginPlease.
  ///
  /// In ko, this message translates to:
  /// **'로그인해 주세요'**
  String get widgetLoginPlease;

  /// No description provided for @widgetSyncedAt.
  ///
  /// In ko, this message translates to:
  /// **'{time} 기준'**
  String widgetSyncedAt(String time);

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get share;

  /// No description provided for @download.
  ///
  /// In ko, this message translates to:
  /// **'다운로드'**
  String get download;

  /// No description provided for @view.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get view;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get loading;

  /// No description provided for @errorConnTitle.
  ///
  /// In ko, this message translates to:
  /// **'연결에 문제가 있어요'**
  String get errorConnTitle;

  /// No description provided for @errorConnSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인하고 다시 시도해 주세요.'**
  String get errorConnSubtitle;

  /// No description provided for @statusDeposited.
  ///
  /// In ko, this message translates to:
  /// **'입금완료'**
  String get statusDeposited;

  /// No description provided for @statusOverdue.
  ///
  /// In ko, this message translates to:
  /// **'기한 지남'**
  String get statusOverdue;

  /// No description provided for @collectDday.
  ///
  /// In ko, this message translates to:
  /// **'수금 {dday}'**
  String collectDday(String dday);

  /// No description provided for @amtBase.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get amtBase;

  /// No description provided for @amtOvertime.
  ///
  /// In ko, this message translates to:
  /// **'연장'**
  String get amtOvertime;

  /// No description provided for @amtEarly.
  ///
  /// In ko, this message translates to:
  /// **'조출'**
  String get amtEarly;

  /// No description provided for @amtNight.
  ///
  /// In ko, this message translates to:
  /// **'야간'**
  String get amtNight;

  /// No description provided for @amtAllnight.
  ///
  /// In ko, this message translates to:
  /// **'철야'**
  String get amtAllnight;

  /// No description provided for @itemOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get itemOther;

  /// No description provided for @baseDaily.
  ///
  /// In ko, this message translates to:
  /// **'기본(일당)'**
  String get baseDaily;

  /// No description provided for @baseHourly.
  ///
  /// In ko, this message translates to:
  /// **'기본(시급)'**
  String get baseHourly;

  /// No description provided for @basePerCase.
  ///
  /// In ko, this message translates to:
  /// **'기본(건당)'**
  String get basePerCase;

  /// No description provided for @baseGongsu.
  ///
  /// In ko, this message translates to:
  /// **'기본(공수)'**
  String get baseGongsu;

  /// No description provided for @unitGongsu.
  ///
  /// In ko, this message translates to:
  /// **'공수'**
  String get unitGongsu;

  /// No description provided for @qtyGongsu.
  ///
  /// In ko, this message translates to:
  /// **'{qty}공수'**
  String qtyGongsu(String qty);

  /// No description provided for @vatLabel.
  ///
  /// In ko, this message translates to:
  /// **'부가세 ({rate}%)'**
  String vatLabel(String rate);

  /// No description provided for @daysCount.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String daysCount(int days);

  /// No description provided for @daysWithGongsu.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 · {gongsu}공수'**
  String daysWithGongsu(int days, String gongsu);

  /// No description provided for @moreTitle.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get moreTitle;

  /// No description provided for @sectionManage.
  ///
  /// In ko, this message translates to:
  /// **'관리'**
  String get sectionManage;

  /// No description provided for @sectionSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get sectionSettings;

  /// No description provided for @menuWallet.
  ///
  /// In ko, this message translates to:
  /// **'서류 지갑'**
  String get menuWallet;

  /// No description provided for @menuWalletSub.
  ///
  /// In ko, this message translates to:
  /// **'자격증·보험·검사증 만료 관리 · 묶음 전송'**
  String get menuWalletSub;

  /// No description provided for @menuBizHome.
  ///
  /// In ko, this message translates to:
  /// **'사업장 홈'**
  String get menuBizHome;

  /// No description provided for @menuBizMode.
  ///
  /// In ko, this message translates to:
  /// **'사업장 모드'**
  String get menuBizMode;

  /// No description provided for @menuBizSub.
  ///
  /// In ko, this message translates to:
  /// **'작업 지시·수신 확인서·정산·안전 리포트'**
  String get menuBizSub;

  /// No description provided for @menuJobs.
  ///
  /// In ko, this message translates to:
  /// **'받은 작업'**
  String get menuJobs;

  /// No description provided for @menuJobsSub.
  ///
  /// In ko, this message translates to:
  /// **'작업 지시 수락·시작·완료'**
  String get menuJobsSub;

  /// No description provided for @menuTax.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 준비'**
  String get menuTax;

  /// No description provided for @menuTaxSub.
  ///
  /// In ko, this message translates to:
  /// **'서명 완료 확인서 → 홈택스 입력용 데이터 정리'**
  String get menuTaxSub;

  /// No description provided for @menuNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get menuNotifications;

  /// No description provided for @menuNotificationsSub.
  ///
  /// In ko, this message translates to:
  /// **'수금·서류 만료·작업 예약·폭염 안전'**
  String get menuNotificationsSub;

  /// No description provided for @consentTitle.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 검색 허용'**
  String get consentTitle;

  /// No description provided for @consentSub.
  ///
  /// In ko, this message translates to:
  /// **'사업장이 내 번호로 나를 찾아 연결할 수 있어요'**
  String get consentSub;

  /// No description provided for @kakaoLinkTitle.
  ///
  /// In ko, this message translates to:
  /// **'카카오 계정 연결'**
  String get kakaoLinkTitle;

  /// No description provided for @kakaoLinkedSub.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get kakaoLinkedSub;

  /// No description provided for @kakaoLinkSub.
  ///
  /// In ko, this message translates to:
  /// **'카카오로도 로그인할 수 있게 연결해요'**
  String get kakaoLinkSub;

  /// No description provided for @kakaoLinked.
  ///
  /// In ko, this message translates to:
  /// **'카카오 계정을 연결했어요.'**
  String get kakaoLinked;

  /// No description provided for @kakaoNotReady.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인 준비 중이에요.'**
  String get kakaoNotReady;

  /// No description provided for @kakaoAlreadyLinked.
  ///
  /// In ko, this message translates to:
  /// **'이미 다른 계정에 연결된 카카오예요.'**
  String get kakaoAlreadyLinked;

  /// No description provided for @kakaoLinkFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결 실패: {message}'**
  String kakaoLinkFailed(String message);

  /// No description provided for @kakaoLinkCanceled.
  ///
  /// In ko, this message translates to:
  /// **'카카오 연결이 취소되었어요.'**
  String get kakaoLinkCanceled;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 하시겠어요?'**
  String get logoutConfirm;

  /// No description provided for @noName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get noName;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 따름'**
  String get languageSystem;

  /// No description provided for @paperStamp.
  ///
  /// In ko, this message translates to:
  /// **'작 업 확 인 서'**
  String get paperStamp;

  /// No description provided for @paperDate.
  ///
  /// In ko, this message translates to:
  /// **'작업일'**
  String get paperDate;

  /// No description provided for @paperTime.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get paperTime;

  /// No description provided for @paperSite.
  ///
  /// In ko, this message translates to:
  /// **'현장'**
  String get paperSite;

  /// No description provided for @paperWorker.
  ///
  /// In ko, this message translates to:
  /// **'작업자'**
  String get paperWorker;

  /// No description provided for @paperOrderer.
  ///
  /// In ko, this message translates to:
  /// **'지시자'**
  String get paperOrderer;

  /// No description provided for @paperWork.
  ///
  /// In ko, this message translates to:
  /// **'작업내용'**
  String get paperWork;

  /// No description provided for @paperEquipment.
  ///
  /// In ko, this message translates to:
  /// **'장비'**
  String get paperEquipment;

  /// No description provided for @paperGuide.
  ///
  /// In ko, this message translates to:
  /// **'유도원'**
  String get paperGuide;

  /// No description provided for @paperTotal.
  ///
  /// In ko, this message translates to:
  /// **'받을 금액'**
  String get paperTotal;

  /// No description provided for @paperMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get paperMemo;

  /// No description provided for @paperSignHead.
  ///
  /// In ko, this message translates to:
  /// **'지시자 서명'**
  String get paperSignHead;

  /// No description provided for @paperSignedBy.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님 서명 완료'**
  String paperSignedBy(String name);

  /// No description provided for @shareCount.
  ///
  /// In ko, this message translates to:
  /// **'공유된 서류 {n}건'**
  String shareCount(int n);

  /// No description provided for @shareValidUntil.
  ///
  /// In ko, this message translates to:
  /// **'유효기간 {date}까지 열람 가능'**
  String shareValidUntil(String date);

  /// No description provided for @shareExpiry.
  ///
  /// In ko, this message translates to:
  /// **'만료 {date}'**
  String shareExpiry(String date);

  /// No description provided for @shareNoExpiry.
  ///
  /// In ko, this message translates to:
  /// **'만료일 없음'**
  String get shareNoExpiry;

  /// No description provided for @shareMasked.
  ///
  /// In ko, this message translates to:
  /// **'마스킹본'**
  String get shareMasked;

  /// No description provided for @statusTransientTitle.
  ///
  /// In ko, this message translates to:
  /// **'일시적인 오류입니다'**
  String get statusTransientTitle;

  /// No description provided for @statusTransientMsg.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 시도해 주세요.'**
  String get statusTransientMsg;

  /// No description provided for @statusNotFoundTitle.
  ///
  /// In ko, this message translates to:
  /// **'찾을 수 없는 링크입니다'**
  String get statusNotFoundTitle;

  /// No description provided for @statusNotFoundMsg.
  ///
  /// In ko, this message translates to:
  /// **'링크가 만료되었거나 무효화되었을 수 있습니다. 보낸 분에게 새 링크를 요청하세요.'**
  String get statusNotFoundMsg;

  /// No description provided for @authStartWithPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호로 시작하기'**
  String get authStartWithPhone;

  /// No description provided for @authTagline.
  ///
  /// In ko, this message translates to:
  /// **'일한 것을 30초에 기록하고 확인서·장부·정산을 자동으로 관리하세요.'**
  String get authTagline;

  /// No description provided for @authPhoneLabel.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get authPhoneLabel;

  /// No description provided for @authCodeLabel.
  ///
  /// In ko, this message translates to:
  /// **'인증번호'**
  String get authCodeLabel;

  /// No description provided for @authCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'6자리 인증번호'**
  String get authCodeHint;

  /// No description provided for @authDevAutofill.
  ///
  /// In ko, this message translates to:
  /// **'개발 환경: 인증번호가 자동으로 채워집니다.'**
  String get authDevAutofill;

  /// No description provided for @authRequestCode.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 받기'**
  String get authRequestCode;

  /// No description provided for @authVerifyStart.
  ///
  /// In ko, this message translates to:
  /// **'인증하고 시작하기'**
  String get authVerifyStart;

  /// No description provided for @authReenterPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 다시 입력'**
  String get authReenterPhone;

  /// No description provided for @authOr.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get authOr;

  /// No description provided for @authKakaoStart.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 시작하기'**
  String get authKakaoStart;

  /// No description provided for @authKakaoPreparing.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인 준비 중이에요. 전화번호로 시작해 주세요.'**
  String get authKakaoPreparing;

  /// No description provided for @onbWelcome.
  ///
  /// In ko, this message translates to:
  /// **'반가워요!'**
  String get onbWelcome;

  /// No description provided for @onbNamePrompt.
  ///
  /// In ko, this message translates to:
  /// **'확인서에 표시될 이름을 알려주세요.'**
  String get onbNamePrompt;

  /// No description provided for @onbNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get onbNameLabel;

  /// No description provided for @onbNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 김기사'**
  String get onbNameHint;

  /// No description provided for @onbStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onbStart;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get navCalendar;

  /// No description provided for @navLedger.
  ///
  /// In ko, this message translates to:
  /// **'장부'**
  String get navLedger;

  /// No description provided for @navMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get navMore;

  /// No description provided for @navWrite.
  ///
  /// In ko, this message translates to:
  /// **'작성'**
  String get navWrite;

  /// No description provided for @navDraftsSent.
  ///
  /// In ko, this message translates to:
  /// **'임시저장 {n}건이 자동 전송되었어요.'**
  String navDraftsSent(int n);

  /// No description provided for @navDraftsFailed.
  ///
  /// In ko, this message translates to:
  /// **'임시저장 초안 {n}건 전송에 실패했어요. 홈에서 확인해 주세요.'**
  String navDraftsFailed(int n);

  /// No description provided for @notiTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notiTitle;

  /// No description provided for @notiEmpty.
  ///
  /// In ko, this message translates to:
  /// **'알림이 없어요'**
  String get notiEmpty;

  /// No description provided for @notiAckDone.
  ///
  /// In ko, this message translates to:
  /// **'확인 처리되었습니다.'**
  String get notiAckDone;

  /// No description provided for @notiAckFailed.
  ///
  /// In ko, this message translates to:
  /// **'확인 실패: {error}'**
  String notiAckFailed(String error);

  /// No description provided for @bizModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'사업장 모드'**
  String get bizModeTitle;

  /// No description provided for @bizCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'생성 실패: {error}'**
  String bizCreateFailed(String error);

  /// No description provided for @bizCreateHeading.
  ///
  /// In ko, this message translates to:
  /// **'사업장을 만들어 시작하세요'**
  String get bizCreateHeading;

  /// No description provided for @bizCreateDesc.
  ///
  /// In ko, this message translates to:
  /// **'작업자 연결·작업 지시·수신 확인서 서명·정산·안전 리포트를 한 곳에서.'**
  String get bizCreateDesc;

  /// No description provided for @bizNameHint.
  ///
  /// In ko, this message translates to:
  /// **'상호 (예: 대성건설)'**
  String get bizNameHint;

  /// No description provided for @bizBnoHint.
  ///
  /// In ko, this message translates to:
  /// **'사업자번호 (선택)'**
  String get bizBnoHint;

  /// No description provided for @bizCreateButton.
  ///
  /// In ko, this message translates to:
  /// **'사업장 만들기'**
  String get bizCreateButton;

  /// No description provided for @bizInviteCode.
  ///
  /// In ko, this message translates to:
  /// **'초대코드 {code}'**
  String bizInviteCode(String code);

  /// No description provided for @inboxTitle.
  ///
  /// In ko, this message translates to:
  /// **'수신함'**
  String get inboxTitle;

  /// No description provided for @bizMenuInboxDesc.
  ///
  /// In ko, this message translates to:
  /// **'받은 작업확인서 확인·앱내 서명'**
  String get bizMenuInboxDesc;

  /// No description provided for @settleTitle.
  ///
  /// In ko, this message translates to:
  /// **'정산'**
  String get settleTitle;

  /// No description provided for @bizMenuSettleDesc.
  ///
  /// In ko, this message translates to:
  /// **'작업자별 미지급 집계·지급 처리'**
  String get bizMenuSettleDesc;

  /// No description provided for @workerTitle.
  ///
  /// In ko, this message translates to:
  /// **'작업자·지시'**
  String get workerTitle;

  /// No description provided for @bizMenuWorkerDesc.
  ///
  /// In ko, this message translates to:
  /// **'작업자 검색·연결·작업 지시 생성'**
  String get bizMenuWorkerDesc;

  /// No description provided for @jobTitle.
  ///
  /// In ko, this message translates to:
  /// **'작업 지시 목록'**
  String get jobTitle;

  /// No description provided for @bizMenuJobDesc.
  ///
  /// In ko, this message translates to:
  /// **'예약·진행·완료 상태 조회'**
  String get bizMenuJobDesc;

  /// No description provided for @safetyTitle.
  ///
  /// In ko, this message translates to:
  /// **'안전'**
  String get safetyTitle;

  /// No description provided for @bizMenuSafetyDesc.
  ///
  /// In ko, this message translates to:
  /// **'안전관리 리포트 PDF·최근 안전 기록'**
  String get bizMenuSafetyDesc;

  /// No description provided for @bizLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했습니다: {error}'**
  String bizLoadFailed(String error);

  /// No description provided for @inboxEmpty.
  ///
  /// In ko, this message translates to:
  /// **'받은 확인서가 없어요'**
  String get inboxEmpty;

  /// No description provided for @inboxStatusSigned.
  ///
  /// In ko, this message translates to:
  /// **'서명완료'**
  String get inboxStatusSigned;

  /// No description provided for @inboxStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'서명대기'**
  String get inboxStatusPending;

  /// No description provided for @jobStatusScheduled.
  ///
  /// In ko, this message translates to:
  /// **'예약'**
  String get jobStatusScheduled;

  /// No description provided for @jobStatusInProgress.
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get jobStatusInProgress;

  /// No description provided for @jobStatusDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get jobStatusDone;

  /// No description provided for @jobEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 작업 지시가 없어요'**
  String get jobEmpty;

  /// No description provided for @jobAccepted.
  ///
  /// In ko, this message translates to:
  /// **'수락됨'**
  String get jobAccepted;

  /// No description provided for @jobAcceptPending.
  ///
  /// In ko, this message translates to:
  /// **'수락 대기'**
  String get jobAcceptPending;

  /// No description provided for @safetyReportOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'리포트 열기 실패: {error}'**
  String safetyReportOpenFailed(String error);

  /// No description provided for @safetyReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'안전관리 이행 리포트'**
  String get safetyReportTitle;

  /// No description provided for @safetyReportDesc.
  ///
  /// In ko, this message translates to:
  /// **'컨디션 체크·서류 유효성·폭염 알림 기록을 월별 PDF로 확인하세요.'**
  String get safetyReportDesc;

  /// No description provided for @safetyOpenReport.
  ///
  /// In ko, this message translates to:
  /// **'{month} 리포트 열기'**
  String safetyOpenReport(String month);

  /// No description provided for @safetyHeatNotice.
  ///
  /// In ko, this message translates to:
  /// **'폭염특보 시 연결된 작업자에게 자동으로 안전 알림이 발송되고 확인 기록이 남습니다.'**
  String get safetyHeatNotice;

  /// No description provided for @settlePaidSnack.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 {amount} 지급 처리'**
  String settlePaidSnack(String name, String amount);

  /// No description provided for @settlePayFailed.
  ///
  /// In ko, this message translates to:
  /// **'지급 실패: {error}'**
  String settlePayFailed(String error);

  /// No description provided for @settleEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 미지급 내역이 없어요'**
  String get settleEmpty;

  /// No description provided for @settleEntryCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String settleEntryCount(int count);

  /// No description provided for @settlePaidDone.
  ///
  /// In ko, this message translates to:
  /// **'지급 완료'**
  String get settlePaidDone;

  /// No description provided for @settlePayAmount.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 지급'**
  String settlePayAmount(String amount);

  /// No description provided for @workerSearchFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색 실패: {error}'**
  String workerSearchFailed(String error);

  /// No description provided for @workerConnectRequested.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 연결을 요청했어요.'**
  String workerConnectRequested(String name);

  /// No description provided for @workerRequestFailed.
  ///
  /// In ko, this message translates to:
  /// **'요청 실패: {error}'**
  String workerRequestFailed(String error);

  /// No description provided for @workerSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'작업자 전화번호로 검색'**
  String get workerSearchHint;

  /// No description provided for @workerSearchButton.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get workerSearchButton;

  /// No description provided for @workerConnectButton.
  ///
  /// In ko, this message translates to:
  /// **'연결 요청'**
  String get workerConnectButton;

  /// No description provided for @workerConnectedHeading.
  ///
  /// In ko, this message translates to:
  /// **'연결된 작업자'**
  String get workerConnectedHeading;

  /// No description provided for @workerNoneConnected.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 작업자가 없어요'**
  String get workerNoneConnected;

  /// No description provided for @workerStatusConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get workerStatusConnected;

  /// No description provided for @workerStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'요청 대기중'**
  String get workerStatusPending;

  /// No description provided for @workerJobButton.
  ///
  /// In ko, this message translates to:
  /// **'작업 지시'**
  String get workerJobButton;

  /// No description provided for @workerAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get workerAccept;

  /// No description provided for @workerJobSent.
  ///
  /// In ko, this message translates to:
  /// **'작업 지시를 보냈어요. 작업자에게 알림이 전송됩니다.'**
  String get workerJobSent;

  /// No description provided for @jobFormTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 작업 지시'**
  String jobFormTitle(String name);

  /// No description provided for @jobFormSiteHint.
  ///
  /// In ko, this message translates to:
  /// **'현장 (예: 반포자이 리모델링)'**
  String get jobFormSiteHint;

  /// No description provided for @jobRateDaily.
  ///
  /// In ko, this message translates to:
  /// **'일당'**
  String get jobRateDaily;

  /// No description provided for @jobRateHourly.
  ///
  /// In ko, this message translates to:
  /// **'시급'**
  String get jobRateHourly;

  /// No description provided for @jobRatePerCase.
  ///
  /// In ko, this message translates to:
  /// **'건당'**
  String get jobRatePerCase;

  /// No description provided for @jobFormRateHint.
  ///
  /// In ko, this message translates to:
  /// **'단가 (원)'**
  String get jobFormRateHint;

  /// No description provided for @jobFormSubmit.
  ///
  /// In ko, this message translates to:
  /// **'작업 지시 보내기'**
  String get jobFormSubmit;

  /// No description provided for @jobCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'지시 실패: {error}'**
  String jobCreateFailed(String error);

  /// No description provided for @bizConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'작업확인서'**
  String get bizConfirmTitle;

  /// No description provided for @bizSignErrSign.
  ///
  /// In ko, this message translates to:
  /// **'서명을 입력해 주세요.'**
  String get bizSignErrSign;

  /// No description provided for @bizSignErrName.
  ///
  /// In ko, this message translates to:
  /// **'서명자 이름을 입력해 주세요.'**
  String get bizSignErrName;

  /// No description provided for @bizSignDone.
  ///
  /// In ko, this message translates to:
  /// **'서명이 완료되었습니다. (SIGNED)'**
  String get bizSignDone;

  /// No description provided for @bizSignFailed.
  ///
  /// In ko, this message translates to:
  /// **'서명 실패: {error}'**
  String bizSignFailed(String error);

  /// No description provided for @bizStampDefault.
  ///
  /// In ko, this message translates to:
  /// **'작업확인서 · WORKON'**
  String get bizStampDefault;

  /// No description provided for @bizStampSigned.
  ///
  /// In ko, this message translates to:
  /// **'서 명 완 료 · WORKON'**
  String get bizStampSigned;

  /// No description provided for @bizLineCounterpart.
  ///
  /// In ko, this message translates to:
  /// **'상대'**
  String get bizLineCounterpart;

  /// No description provided for @bizLineRateType.
  ///
  /// In ko, this message translates to:
  /// **'단가유형'**
  String get bizLineRateType;

  /// No description provided for @bizSignedBadge.
  ///
  /// In ko, this message translates to:
  /// **'{name} 서명 · {at}'**
  String bizSignedBadge(String name, String at);

  /// No description provided for @bizSignInAppTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 바로 서명'**
  String get bizSignInAppTitle;

  /// No description provided for @bizSignInAppDesc.
  ///
  /// In ko, this message translates to:
  /// **'아래에 서명하면 작업자에게 즉시 전달되고 확인서가 확정됩니다.'**
  String get bizSignInAppDesc;

  /// No description provided for @bizSignerNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'서명자 이름'**
  String get bizSignerNameLabel;

  /// No description provided for @bizSignRedraw.
  ///
  /// In ko, this message translates to:
  /// **'다시 서명'**
  String get bizSignRedraw;

  /// No description provided for @bizSignSubmit.
  ///
  /// In ko, this message translates to:
  /// **'서명하고 확정'**
  String get bizSignSubmit;

  /// No description provided for @confNoCopySource.
  ///
  /// In ko, this message translates to:
  /// **'복사할 이전 확인서가 없어요.'**
  String get confNoCopySource;

  /// No description provided for @confCopyPrevious.
  ///
  /// In ko, this message translates to:
  /// **'이전 확인서 복사'**
  String get confCopyPrevious;

  /// No description provided for @confFormTitle.
  ///
  /// In ko, this message translates to:
  /// **'작업확인서 작성'**
  String get confFormTitle;

  /// No description provided for @confSiteHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 래미안 원펜타스 3공구'**
  String get confSiteHint;

  /// No description provided for @confWorkHint.
  ///
  /// In ko, this message translates to:
  /// **'작업한 내용을 적어주세요'**
  String get confWorkHint;

  /// No description provided for @confRateType.
  ///
  /// In ko, this message translates to:
  /// **'단가 유형'**
  String get confRateType;

  /// No description provided for @confRateDaily.
  ///
  /// In ko, this message translates to:
  /// **'일당'**
  String get confRateDaily;

  /// No description provided for @confRateHourly.
  ///
  /// In ko, this message translates to:
  /// **'시급'**
  String get confRateHourly;

  /// No description provided for @confRatePerCase.
  ///
  /// In ko, this message translates to:
  /// **'건당'**
  String get confRatePerCase;

  /// No description provided for @confPricePerCase.
  ///
  /// In ko, this message translates to:
  /// **'건당 단가'**
  String get confPricePerCase;

  /// No description provided for @confPriceGongsu.
  ///
  /// In ko, this message translates to:
  /// **'공수 단가 (1공수=하루)'**
  String get confPriceGongsu;

  /// No description provided for @confQtyHours.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get confQtyHours;

  /// No description provided for @confQtyCases.
  ///
  /// In ko, this message translates to:
  /// **'건수'**
  String get confQtyCases;

  /// No description provided for @confQtyDays.
  ///
  /// In ko, this message translates to:
  /// **'일수'**
  String get confQtyDays;

  /// No description provided for @confErrGongsu.
  ///
  /// In ko, this message translates to:
  /// **'공수는 0.1 단위로 입력해 주세요 (예: 0.5 · 1.5).'**
  String get confErrGongsu;

  /// No description provided for @confErrHours.
  ///
  /// In ko, this message translates to:
  /// **'시간을 1 이상 입력해 주세요.'**
  String get confErrHours;

  /// No description provided for @confErrCases.
  ///
  /// In ko, this message translates to:
  /// **'건수를 1 이상 입력해 주세요.'**
  String get confErrCases;

  /// No description provided for @confErrDays.
  ///
  /// In ko, this message translates to:
  /// **'일수를 1 이상 입력해 주세요.'**
  String get confErrDays;

  /// No description provided for @confDueDate.
  ///
  /// In ko, this message translates to:
  /// **'수금 예정일 (선택)'**
  String get confDueDate;

  /// No description provided for @confNotSet.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get confNotSet;

  /// No description provided for @confSaveSend.
  ///
  /// In ko, this message translates to:
  /// **'저장하고 보내기'**
  String get confSaveSend;

  /// No description provided for @confSaveHint.
  ///
  /// In ko, this message translates to:
  /// **'저장 즉시 장부에 반영됩니다 · 링크로 전송'**
  String get confSaveHint;

  /// No description provided for @confStartTime.
  ///
  /// In ko, this message translates to:
  /// **'시작 시각'**
  String get confStartTime;

  /// No description provided for @confEndTime.
  ///
  /// In ko, this message translates to:
  /// **'종료 시각'**
  String get confEndTime;

  /// No description provided for @confOrdererCompany.
  ///
  /// In ko, this message translates to:
  /// **'지시자 (회사)'**
  String get confOrdererCompany;

  /// No description provided for @confLinkedBiz.
  ///
  /// In ko, this message translates to:
  /// **'연결 사업장'**
  String get confLinkedBiz;

  /// No description provided for @confManualEntry.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get confManualEntry;

  /// No description provided for @confSelectBiz.
  ///
  /// In ko, this message translates to:
  /// **'연결 사업장 선택'**
  String get confSelectBiz;

  /// No description provided for @confCompanyHint.
  ///
  /// In ko, this message translates to:
  /// **'회사/현장 담당 상호'**
  String get confCompanyHint;

  /// No description provided for @confContactHint.
  ///
  /// In ko, this message translates to:
  /// **'담당자/연락처 (선택)'**
  String get confContactHint;

  /// No description provided for @confEquipSection.
  ///
  /// In ko, this message translates to:
  /// **'장비 섹션'**
  String get confEquipSection;

  /// No description provided for @confEquipAutoInclude.
  ///
  /// In ko, this message translates to:
  /// **'확인서에 자동 포함'**
  String get confEquipAutoInclude;

  /// No description provided for @confEquipName.
  ///
  /// In ko, this message translates to:
  /// **'장비명'**
  String get confEquipName;

  /// No description provided for @confVehicleNo.
  ///
  /// In ko, this message translates to:
  /// **'차량번호'**
  String get confVehicleNo;

  /// No description provided for @confUnitPrice.
  ///
  /// In ko, this message translates to:
  /// **'단가'**
  String get confUnitPrice;

  /// No description provided for @confQuantity.
  ///
  /// In ko, this message translates to:
  /// **'수량'**
  String get confQuantity;

  /// No description provided for @confAddExtra.
  ///
  /// In ko, this message translates to:
  /// **'연장·야간 항목 추가'**
  String get confAddExtra;

  /// No description provided for @confSavedLinked.
  ///
  /// In ko, this message translates to:
  /// **'저장 완료 · 연결된 사업장에 전송했어요.'**
  String get confSavedLinked;

  /// No description provided for @confSavedBook.
  ///
  /// In ko, this message translates to:
  /// **'저장 완료 · 장부에 반영되었어요.'**
  String get confSavedBook;

  /// No description provided for @confDraftQueued.
  ///
  /// In ko, this message translates to:
  /// **'임시저장됨 — 연결되면 자동 전송돼요.'**
  String get confDraftQueued;

  /// No description provided for @confSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {message}'**
  String confSaveFailed(String message);

  /// No description provided for @confRestoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'작성 중이던 내용이 있어요.'**
  String get confRestoreTitle;

  /// No description provided for @confRestore.
  ///
  /// In ko, this message translates to:
  /// **'불러오기'**
  String get confRestore;

  /// No description provided for @confDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'작업확인서'**
  String get confDetailTitle;

  /// No description provided for @confSentLinked.
  ///
  /// In ko, this message translates to:
  /// **'연결된 사업장에 전송했어요.'**
  String get confSentLinked;

  /// No description provided for @confSendFailed.
  ///
  /// In ko, this message translates to:
  /// **'전송 실패: {message}'**
  String confSendFailed(String message);

  /// No description provided for @confReshare.
  ///
  /// In ko, this message translates to:
  /// **'다시 공유하기'**
  String get confReshare;

  /// No description provided for @confSendToLinked.
  ///
  /// In ko, this message translates to:
  /// **'연결된 사업장으로 전송됩니다'**
  String get confSendToLinked;

  /// No description provided for @confSendViaShare.
  ///
  /// In ko, this message translates to:
  /// **'공유 시트(카카오톡 등)로 링크를 보낼 수 있어요'**
  String get confSendViaShare;

  /// No description provided for @confCounterparty.
  ///
  /// In ko, this message translates to:
  /// **'상대'**
  String get confCounterparty;

  /// No description provided for @confSentWaitingSign.
  ///
  /// In ko, this message translates to:
  /// **'전송됨 · 상대 서명 대기 중'**
  String get confSentWaitingSign;

  /// No description provided for @confDraftBeforeSend.
  ///
  /// In ko, this message translates to:
  /// **'작성됨 · 전송 전'**
  String get confDraftBeforeSend;

  /// No description provided for @confShareHeader.
  ///
  /// In ko, this message translates to:
  /// **'[작업확인서] {site}'**
  String confShareHeader(String site);

  /// No description provided for @confShareBody.
  ///
  /// In ko, this message translates to:
  /// **'아래 링크에서 내용을 확인하고 서명해 주세요.'**
  String get confShareBody;

  /// No description provided for @confShareSubject.
  ///
  /// In ko, this message translates to:
  /// **'작업확인서 · {site}'**
  String confShareSubject(String site);

  /// No description provided for @draftFlushNone.
  ///
  /// In ko, this message translates to:
  /// **'아직 전송하지 못했어요. 연결을 확인해 주세요.'**
  String get draftFlushNone;

  /// No description provided for @draftFlushSent.
  ///
  /// In ko, this message translates to:
  /// **'{n}건 전송 완료 · 장부에 반영되었어요.'**
  String draftFlushSent(int n);

  /// No description provided for @draftFlushFailed.
  ///
  /// In ko, this message translates to:
  /// **'전송에 실패한 초안이 있어요. 내용을 확인해 주세요.'**
  String get draftFlushFailed;

  /// No description provided for @draftTitle.
  ///
  /// In ko, this message translates to:
  /// **'임시저장 초안'**
  String get draftTitle;

  /// No description provided for @draftEmpty.
  ///
  /// In ko, this message translates to:
  /// **'전송 대기 중인 초안이 없어요.'**
  String get draftEmpty;

  /// No description provided for @draftHint.
  ///
  /// In ko, this message translates to:
  /// **'연결이 복구되면 자동으로 전송돼요. 지금 바로 보내려면 아래에서 다시 시도하세요.'**
  String get draftHint;

  /// No description provided for @draftSendAll.
  ///
  /// In ko, this message translates to:
  /// **'지금 모두 전송'**
  String get draftSendAll;

  /// No description provided for @draftNoSite.
  ///
  /// In ko, this message translates to:
  /// **'(현장 미입력)'**
  String get draftNoSite;

  /// No description provided for @draftCheckNeeded.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요: {error}'**
  String draftCheckNeeded(String error);

  /// No description provided for @homeGreeting.
  ///
  /// In ko, this message translates to:
  /// **'반갑습니다, {name}님'**
  String homeGreeting(String name);

  /// No description provided for @homeToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 일정'**
  String get homeToday;

  /// No description provided for @homeMonthSummary.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 요약'**
  String get homeMonthSummary;

  /// No description provided for @homeCheckNeeded.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get homeCheckNeeded;

  /// No description provided for @homeDocExpiry.
  ///
  /// In ko, this message translates to:
  /// **'{type} 만료 {dday}'**
  String homeDocExpiry(String type, String dday);

  /// No description provided for @homeDocExpirySub.
  ///
  /// In ko, this message translates to:
  /// **'서류 지갑에서 갱신하고 다시 등록하세요'**
  String get homeDocExpirySub;

  /// No description provided for @homeDraftsPending.
  ///
  /// In ko, this message translates to:
  /// **'임시저장 {n}건 전송 대기'**
  String homeDraftsPending(int n);

  /// No description provided for @homeDraftsError.
  ///
  /// In ko, this message translates to:
  /// **'일부 초안은 확인이 필요해요 · 탭하여 보기'**
  String get homeDraftsError;

  /// No description provided for @homeDraftsAuto.
  ///
  /// In ko, this message translates to:
  /// **'연결되면 자동으로 전송돼요 · 탭하여 보기'**
  String get homeDraftsAuto;

  /// No description provided for @homeStampDraft.
  ///
  /// In ko, this message translates to:
  /// **'작 성 됨 · WORKON'**
  String get homeStampDraft;

  /// No description provided for @homeStampScheduled.
  ///
  /// In ko, this message translates to:
  /// **'작업 예정 · WORKON'**
  String get homeStampScheduled;

  /// No description provided for @homeTodayBadge.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get homeTodayBadge;

  /// No description provided for @homeStampToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 · WORKON'**
  String get homeStampToday;

  /// No description provided for @homeEmptyToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 예정된 일정이 없어요'**
  String get homeEmptyToday;

  /// No description provided for @homeEmptyTodaySub.
  ///
  /// In ko, this message translates to:
  /// **'하단 + 버튼으로 오늘 작업을 30초에 기록하세요.'**
  String get homeEmptyTodaySub;

  /// No description provided for @homeDaysWorked.
  ///
  /// In ko, this message translates to:
  /// **'일한 날'**
  String get homeDaysWorked;

  /// No description provided for @homeReceivable.
  ///
  /// In ko, this message translates to:
  /// **'받을 돈 (미수)'**
  String get homeReceivable;

  /// No description provided for @homeReceived.
  ///
  /// In ko, this message translates to:
  /// **'받은 돈 (입금)'**
  String get homeReceived;

  /// No description provided for @calViewMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get calViewMonth;

  /// No description provided for @calViewWeek.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get calViewWeek;

  /// No description provided for @calWorkCount.
  ///
  /// In ko, this message translates to:
  /// **'작업 {n}건'**
  String calWorkCount(int n);

  /// No description provided for @calManUnit.
  ///
  /// In ko, this message translates to:
  /// **'만'**
  String get calManUnit;

  /// No description provided for @calEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'이 달에 기록된 작업이 없어요.'**
  String get calEmptyMonth;

  /// No description provided for @calEmptyDay.
  ///
  /// In ko, this message translates to:
  /// **'이 날 기록된 작업이 없어요.'**
  String get calEmptyDay;

  /// No description provided for @calRecordThisDay.
  ///
  /// In ko, this message translates to:
  /// **'이 날 작업 기록하기'**
  String get calRecordThisDay;

  /// No description provided for @ledgerTitle.
  ///
  /// In ko, this message translates to:
  /// **'장부'**
  String get ledgerTitle;

  /// No description provided for @ledgerOutstandingTotal.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 미수 합계'**
  String get ledgerOutstandingTotal;

  /// No description provided for @ledgerWorkedThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {summary} 일함'**
  String ledgerWorkedThisMonth(String summary);

  /// No description provided for @ledgerByCompany.
  ///
  /// In ko, this message translates to:
  /// **'회사별'**
  String get ledgerByCompany;

  /// No description provided for @ledgerCompanyCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}곳'**
  String ledgerCompanyCount(int n);

  /// No description provided for @ledgerStamp.
  ///
  /// In ko, this message translates to:
  /// **'장부 · WORKON'**
  String get ledgerStamp;

  /// No description provided for @ledgerEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 달의 장부 기록이 없어요'**
  String get ledgerEmptyTitle;

  /// No description provided for @ledgerEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'확인서를 작성하면 장부가 자동으로 채워져요.'**
  String get ledgerEmptySub;

  /// No description provided for @ledgerWriteConfirmation.
  ///
  /// In ko, this message translates to:
  /// **'확인서 작성하기'**
  String get ledgerWriteConfirmation;

  /// No description provided for @ledgerDaysWorked.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 작업'**
  String ledgerDaysWorked(int days);

  /// No description provided for @ledgerPaidAmount.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 입금'**
  String ledgerPaidAmount(String amount);

  /// No description provided for @ledgerStatementFail.
  ///
  /// In ko, this message translates to:
  /// **'명세서 열기 실패: {error}'**
  String ledgerStatementFail(String error);

  /// No description provided for @ledgerMonthlyStatement.
  ///
  /// In ko, this message translates to:
  /// **'월간 명세서 PDF'**
  String get ledgerMonthlyStatement;

  /// No description provided for @ledgerRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 미수'**
  String get ledgerRemaining;

  /// No description provided for @ledgerWorkHistory.
  ///
  /// In ko, this message translates to:
  /// **'작업 내역'**
  String get ledgerWorkHistory;

  /// No description provided for @ledgerBilled.
  ///
  /// In ko, this message translates to:
  /// **'청구 {amount}'**
  String ledgerBilled(String amount);

  /// No description provided for @ledgerDeposited.
  ///
  /// In ko, this message translates to:
  /// **'입금 {amount}'**
  String ledgerDeposited(String amount);

  /// No description provided for @ledgerPaymentSaved.
  ///
  /// In ko, this message translates to:
  /// **'입금이 기록되었어요.'**
  String get ledgerPaymentSaved;

  /// No description provided for @ledgerPaymentFail.
  ///
  /// In ko, this message translates to:
  /// **'실패: {message}'**
  String ledgerPaymentFail(String message);

  /// No description provided for @ledgerRecordPayment.
  ///
  /// In ko, this message translates to:
  /// **'입금 기록'**
  String get ledgerRecordPayment;

  /// No description provided for @ledgerRemainingAmount.
  ///
  /// In ko, this message translates to:
  /// **'남은 미수 {amount}'**
  String ledgerRemainingAmount(String amount);

  /// No description provided for @ledgerPaymentAmount.
  ///
  /// In ko, this message translates to:
  /// **'입금액'**
  String get ledgerPaymentAmount;

  /// No description provided for @ledgerWonSuffix.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get ledgerWonSuffix;

  /// No description provided for @ledgerFull.
  ///
  /// In ko, this message translates to:
  /// **'전액'**
  String get ledgerFull;

  /// No description provided for @ledgerHalf.
  ///
  /// In ko, this message translates to:
  /// **'절반'**
  String get ledgerHalf;

  /// No description provided for @ledgerRecordPaymentBtn.
  ///
  /// In ko, this message translates to:
  /// **'입금 기록하기'**
  String get ledgerRecordPaymentBtn;

  /// No description provided for @taxTitle.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 준비'**
  String get taxTitle;

  /// No description provided for @taxSupplierPrefix.
  ///
  /// In ko, this message translates to:
  /// **'공급자 · {name}'**
  String taxSupplierPrefix(String name);

  /// No description provided for @taxNoBizName.
  ///
  /// In ko, this message translates to:
  /// **'(상호 미등록)'**
  String get taxNoBizName;

  /// No description provided for @taxBizNumberLine.
  ///
  /// In ko, this message translates to:
  /// **'사업자번호 {number}'**
  String taxBizNumberLine(String number);

  /// No description provided for @taxHometaxGuide.
  ///
  /// In ko, this message translates to:
  /// **'복사한 내용을 홈택스(hometax.go.kr) 세금계산서 발행에 붙여넣으세요. 발행 후 \"발행 완료 표시\"를 누르면 목록에서 빠져요.'**
  String get taxHometaxGuide;

  /// No description provided for @taxEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'발행 대상 확인서가 없어요.'**
  String get taxEmptyTitle;

  /// No description provided for @taxEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'서명 완료(SIGNED)·미발행 확인서만 여기 모여요.'**
  String get taxEmptySubtitle;

  /// No description provided for @taxStamp.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 · WORKON'**
  String get taxStamp;

  /// No description provided for @taxSupplierPromptTitle.
  ///
  /// In ko, this message translates to:
  /// **'먼저 사업자 정보를 입력하세요'**
  String get taxSupplierPromptTitle;

  /// No description provided for @taxSupplierPromptDesc.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 공급자(나)의 사업자등록번호·상호가 필요해요.'**
  String get taxSupplierPromptDesc;

  /// No description provided for @taxEnterBizInfo.
  ///
  /// In ko, this message translates to:
  /// **'사업자 정보 입력'**
  String get taxEnterBizInfo;

  /// No description provided for @taxCopiedSnack.
  ///
  /// In ko, this message translates to:
  /// **'복사됐어요 · 홈택스에 붙여넣으세요.'**
  String get taxCopiedSnack;

  /// No description provided for @taxMarkedSnack.
  ///
  /// In ko, this message translates to:
  /// **'발행 완료로 표시했어요 · 목록에서 제외돼요.'**
  String get taxMarkedSnack;

  /// No description provided for @taxAlreadyMarkedSnack.
  ///
  /// In ko, this message translates to:
  /// **'이미 발행 표시된 항목이에요.'**
  String get taxAlreadyMarkedSnack;

  /// No description provided for @taxMarkFailed.
  ///
  /// In ko, this message translates to:
  /// **'표시 실패: {msg}'**
  String taxMarkFailed(String msg);

  /// No description provided for @taxBuyerBizLine.
  ///
  /// In ko, this message translates to:
  /// **'사업자번호 {number} · 품목 {count}건'**
  String taxBuyerBizLine(String number, int count);

  /// No description provided for @taxNotRegistered.
  ///
  /// In ko, this message translates to:
  /// **'(미등록)'**
  String get taxNotRegistered;

  /// No description provided for @taxSupplyAmount.
  ///
  /// In ko, this message translates to:
  /// **'공급가액'**
  String get taxSupplyAmount;

  /// No description provided for @taxGrandTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계금액'**
  String get taxGrandTotal;

  /// No description provided for @taxCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get taxCopy;

  /// No description provided for @taxMarkIssued.
  ///
  /// In ko, this message translates to:
  /// **'발행 완료 표시'**
  String get taxMarkIssued;

  /// No description provided for @taxRegisteredBadge.
  ///
  /// In ko, this message translates to:
  /// **'등록 상대'**
  String get taxRegisteredBadge;

  /// No description provided for @taxCheckNeeded.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get taxCheckNeeded;

  /// No description provided for @bizinfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'사업자 정보'**
  String get bizinfoTitle;

  /// No description provided for @bizinfoDesc.
  ///
  /// In ko, this message translates to:
  /// **'세금계산서 발행에 쓰이는 공급자(나) 정보예요.'**
  String get bizinfoDesc;

  /// No description provided for @bizinfoBizNumberLabel.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록번호'**
  String get bizinfoBizNumberLabel;

  /// No description provided for @bizinfoBizNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'상호'**
  String get bizinfoBizNameLabel;

  /// No description provided for @bizinfoBizNameHint.
  ///
  /// In ko, this message translates to:
  /// **'상호(회사명)'**
  String get bizinfoBizNameHint;

  /// No description provided for @bizinfoAddressLabel.
  ///
  /// In ko, this message translates to:
  /// **'사업장 주소 (선택)'**
  String get bizinfoAddressLabel;

  /// No description provided for @bizinfoAddressHint.
  ///
  /// In ko, this message translates to:
  /// **'사업장 주소'**
  String get bizinfoAddressHint;

  /// No description provided for @bizinfoSavedSnack.
  ///
  /// In ko, this message translates to:
  /// **'사업자 정보를 저장했어요.'**
  String get bizinfoSavedSnack;

  /// No description provided for @bizinfoSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {msg}'**
  String bizinfoSaveFailed(String msg);

  /// No description provided for @walletTitle.
  ///
  /// In ko, this message translates to:
  /// **'서류 지갑'**
  String get walletTitle;

  /// No description provided for @walletSelectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 선택'**
  String walletSelectedCount(int n);

  /// No description provided for @walletAddDoc.
  ///
  /// In ko, this message translates to:
  /// **'서류 추가'**
  String get walletAddDoc;

  /// No description provided for @walletMaskPromptTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보를 가릴까요?'**
  String get walletMaskPromptTitle;

  /// No description provided for @walletMaskPromptBody.
  ///
  /// In ko, this message translates to:
  /// **'주민번호·주소 등 민감정보를 마스킹하면 안전하게 공유할 수 있어요.'**
  String get walletMaskPromptBody;

  /// No description provided for @walletLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get walletLater;

  /// No description provided for @walletMaskEdit.
  ///
  /// In ko, this message translates to:
  /// **'마스킹 편집'**
  String get walletMaskEdit;

  /// No description provided for @walletExpiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'{type} 만료됨'**
  String walletExpiredTitle(String type);

  /// No description provided for @walletExpiringTitle.
  ///
  /// In ko, this message translates to:
  /// **'{type} 만료 {dday}'**
  String walletExpiringTitle(String type, String dday);

  /// No description provided for @walletExpiringMultiSub.
  ///
  /// In ko, this message translates to:
  /// **'만료 임박 서류 {n}건 — 갱신 후 다시 등록하세요'**
  String walletExpiringMultiSub(int n);

  /// No description provided for @walletRenewHint.
  ///
  /// In ko, this message translates to:
  /// **'갱신 후 다시 등록하세요'**
  String get walletRenewHint;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록한 서류가 없어요'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'자격증·보험·검사증을 등록하고 만료를 관리하세요'**
  String get walletEmptySub;

  /// No description provided for @walletShareMessage.
  ///
  /// In ko, this message translates to:
  /// **'[작업온] 서류 {count}건을 보냅니다.\n아래 링크에서 확인하세요 (유효 {days}일).\n{url}'**
  String walletShareMessage(int count, int days, String url);

  /// No description provided for @walletShareSubject.
  ///
  /// In ko, this message translates to:
  /// **'작업온 서류 공유'**
  String get walletShareSubject;

  /// No description provided for @walletShareFailed.
  ///
  /// In ko, this message translates to:
  /// **'공유 실패: {error}'**
  String walletShareFailed(String error);

  /// No description provided for @walletSendBundle.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 묶어 보내기'**
  String walletSendBundle(int count);

  /// No description provided for @walletBundleSend.
  ///
  /// In ko, this message translates to:
  /// **'묶음 보내기'**
  String get walletBundleSend;

  /// No description provided for @walletValidPeriod.
  ///
  /// In ko, this message translates to:
  /// **'유효기간'**
  String get walletValidPeriod;

  /// No description provided for @walletMaskedInfo.
  ///
  /// In ko, this message translates to:
  /// **'마스킹본이 있는 서류는 개인정보가 가려진 상태로 전송됩니다.'**
  String get walletMaskedInfo;

  /// No description provided for @walletUnmaskedInfo.
  ///
  /// In ko, this message translates to:
  /// **'마스킹본이 없으면 원본이 그대로 전송됩니다. 상세에서 마스킹할 수 있어요.'**
  String get walletUnmaskedInfo;

  /// No description provided for @walletMakeLinkShare.
  ///
  /// In ko, this message translates to:
  /// **'링크 만들고 공유'**
  String get walletMakeLinkShare;

  /// No description provided for @docOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'열기 실패: {error}'**
  String docOpenFailed(String error);

  /// No description provided for @docUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패: {error}'**
  String docUpdateFailed(String error);

  /// No description provided for @docDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'서류를 삭제할까요?'**
  String get docDeleteConfirmTitle;

  /// No description provided for @docDeleteConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'이 서류와 공유 링크가 함께 삭제됩니다.'**
  String get docDeleteConfirmBody;

  /// No description provided for @docDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String docDeleteFailed(String error);

  /// No description provided for @docOpenPdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF 열기'**
  String get docOpenPdf;

  /// No description provided for @docHasMask.
  ///
  /// In ko, this message translates to:
  /// **'마스킹본 있음'**
  String get docHasMask;

  /// No description provided for @docExpiryDate.
  ///
  /// In ko, this message translates to:
  /// **'만료일'**
  String get docExpiryDate;

  /// No description provided for @docNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get docNone;

  /// No description provided for @docIssuedDate.
  ///
  /// In ko, this message translates to:
  /// **'발급일'**
  String get docIssuedDate;

  /// No description provided for @docReMask.
  ///
  /// In ko, this message translates to:
  /// **'마스킹 다시 편집'**
  String get docReMask;

  /// No description provided for @docMaskEdit.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 마스킹 편집'**
  String get docMaskEdit;

  /// No description provided for @docModify.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get docModify;

  /// No description provided for @docExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료됨'**
  String get docExpired;

  /// No description provided for @docUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패: {error}'**
  String docUploadFailed(String error);

  /// No description provided for @docSourceCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get docSourceCamera;

  /// No description provided for @docSourceGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get docSourceGallery;

  /// No description provided for @docSourcePdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF 파일 선택'**
  String get docSourcePdf;

  /// No description provided for @docInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'서류 정보'**
  String get docInfoTitle;

  /// No description provided for @docFilePdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF · {name}'**
  String docFilePdf(String name);

  /// No description provided for @docFileImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 · {kb}KB'**
  String docFileImage(int kb);

  /// No description provided for @docTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get docTypeLabel;

  /// No description provided for @docLinkEquip.
  ///
  /// In ko, this message translates to:
  /// **'장비 연결 (선택)'**
  String get docLinkEquip;

  /// No description provided for @docPersonal.
  ///
  /// In ko, this message translates to:
  /// **'개인'**
  String get docPersonal;

  /// No description provided for @docPickExpiry.
  ///
  /// In ko, this message translates to:
  /// **'만료일 선택 (선택)'**
  String get docPickExpiry;

  /// No description provided for @docUpload.
  ///
  /// In ko, this message translates to:
  /// **'업로드'**
  String get docUpload;

  /// No description provided for @equipTitle.
  ///
  /// In ko, this message translates to:
  /// **'장비 관리'**
  String get equipTitle;

  /// No description provided for @equipAdd.
  ///
  /// In ko, this message translates to:
  /// **'장비 추가'**
  String get equipAdd;

  /// No description provided for @equipEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'등록된 장비가 없어요'**
  String get equipEmptyTitle;

  /// No description provided for @equipEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'굴삭기·지게차 등 장비를 등록하고 서류를 묶으세요'**
  String get equipEmptySub;

  /// No description provided for @equipDocCount.
  ///
  /// In ko, this message translates to:
  /// **'서류 {n}건'**
  String equipDocCount(int n);

  /// No description provided for @equipDocs.
  ///
  /// In ko, this message translates to:
  /// **'서류'**
  String get equipDocs;

  /// No description provided for @equipTypeHint.
  ///
  /// In ko, this message translates to:
  /// **'장비 종류 (예: 굴삭기)'**
  String get equipTypeHint;

  /// No description provided for @equipVehicleHint.
  ///
  /// In ko, this message translates to:
  /// **'차량번호 (선택)'**
  String get equipVehicleHint;

  /// No description provided for @equipSpecHint.
  ///
  /// In ko, this message translates to:
  /// **'규격 (예: 06W) (선택)'**
  String get equipSpecHint;

  /// No description provided for @equipSubmit.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get equipSubmit;

  /// No description provided for @maskDoneToast.
  ///
  /// In ko, this message translates to:
  /// **'마스킹본을 만들었어요. 공유 시 개인정보가 가려집니다.'**
  String get maskDoneToast;

  /// No description provided for @maskFailed.
  ///
  /// In ko, this message translates to:
  /// **'마스킹 실패: {error}'**
  String maskFailed(String error);

  /// No description provided for @maskTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 마스킹'**
  String get maskTitle;

  /// No description provided for @maskReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get maskReset;

  /// No description provided for @maskGuide.
  ///
  /// In ko, this message translates to:
  /// **'가릴 영역을 손가락으로 드래그해 사각형으로 지정하세요. (예: 주민번호·주소)'**
  String get maskGuide;

  /// No description provided for @maskRegionCount.
  ///
  /// In ko, this message translates to:
  /// **'지정한 영역 {n}개'**
  String maskRegionCount(int n);

  /// No description provided for @maskSave.
  ///
  /// In ko, this message translates to:
  /// **'마스킹본 저장'**
  String get maskSave;

  /// No description provided for @wshareTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 공유'**
  String get wshareTitle;

  /// No description provided for @wshareLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했습니다: {error}'**
  String wshareLoadFailed(String error);

  /// No description provided for @wshareEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 공유한 서류 묶음이 없어요'**
  String get wshareEmpty;

  /// No description provided for @wshareActive.
  ///
  /// In ko, this message translates to:
  /// **'활성'**
  String get wshareActive;

  /// No description provided for @wshareInactive.
  ///
  /// In ko, this message translates to:
  /// **'만료/무효'**
  String get wshareInactive;

  /// No description provided for @wshareViewCount.
  ///
  /// In ko, this message translates to:
  /// **'열람 {n}회'**
  String wshareViewCount(int n);

  /// No description provided for @wshareReshare.
  ///
  /// In ko, this message translates to:
  /// **'다시 공유'**
  String get wshareReshare;

  /// No description provided for @wshareRevoke.
  ///
  /// In ko, this message translates to:
  /// **'무효화'**
  String get wshareRevoke;

  /// No description provided for @myjobFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패: {error}'**
  String myjobFailed(String error);

  /// No description provided for @myjobConditionTitle.
  ///
  /// In ko, this message translates to:
  /// **'컨디션 체크'**
  String get myjobConditionTitle;

  /// No description provided for @myjobConditionBody.
  ///
  /// In ko, this message translates to:
  /// **'오늘 몸 상태는 어떤가요? 안전한 작업을 위해 확인합니다.'**
  String get myjobConditionBody;

  /// No description provided for @myjobConditionBad.
  ///
  /// In ko, this message translates to:
  /// **'안 좋아요'**
  String get myjobConditionBad;

  /// No description provided for @myjobConditionGood.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get myjobConditionGood;

  /// No description provided for @myjobConditionReported.
  ///
  /// In ko, this message translates to:
  /// **'사업장에 컨디션 이상이 전달되었습니다. 무리하지 마세요.'**
  String get myjobConditionReported;

  /// No description provided for @myjobLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했습니다: {error}'**
  String myjobLoadFailed(String error);

  /// No description provided for @myjobEmpty.
  ///
  /// In ko, this message translates to:
  /// **'받은 작업 지시가 없어요'**
  String get myjobEmpty;

  /// No description provided for @myjobAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get myjobAccept;

  /// No description provided for @myjobStart.
  ///
  /// In ko, this message translates to:
  /// **'작업 시작'**
  String get myjobStart;

  /// No description provided for @myjobComplete.
  ///
  /// In ko, this message translates to:
  /// **'작업 완료'**
  String get myjobComplete;

  /// No description provided for @signPadHint.
  ///
  /// In ko, this message translates to:
  /// **'여기에 손가락으로 서명하세요'**
  String get signPadHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'ko',
    'ne',
    'ru',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ne':
      return AppLocalizationsNe();
    case 'ru':
      return AppLocalizationsRu();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
