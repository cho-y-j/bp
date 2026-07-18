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

  /// No description provided for @appLockTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금'**
  String get appLockTitle;

  /// No description provided for @appLockSub.
  ///
  /// In ko, this message translates to:
  /// **'생체 인증·기기 암호로 앱을 보호해요'**
  String get appLockSub;

  /// No description provided for @appLockLockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'잠겨 있어요'**
  String get appLockLockedTitle;

  /// No description provided for @appLockUnlock.
  ///
  /// In ko, this message translates to:
  /// **'인증하고 계속하기'**
  String get appLockUnlock;

  /// No description provided for @appLockReason.
  ///
  /// In ko, this message translates to:
  /// **'작업온 잠금을 해제합니다'**
  String get appLockReason;

  /// No description provided for @appLockUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 생체 인증·기기 암호를 지원하지 않아요'**
  String get appLockUnavailable;

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
  /// **'서명이 완료되었습니다.'**
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
  /// **'{type} {status}'**
  String homeDocExpiry(String type, String status);

  /// No description provided for @homeDocExpiryDue.
  ///
  /// In ko, this message translates to:
  /// **'만료 {dday}'**
  String homeDocExpiryDue(String dday);

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

  /// No description provided for @homeHeroReceivable.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 받을 돈'**
  String get homeHeroReceivable;

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

  /// No description provided for @calMonthReceivable.
  ///
  /// In ko, this message translates to:
  /// **'받을 돈'**
  String get calMonthReceivable;

  /// No description provided for @calTapDayHint.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 눌러 그날 확인서를 펼쳐 보세요'**
  String get calTapDayHint;

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
  /// **'서명 완료·미발행 확인서만 여기 모여요.'**
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

  /// No description provided for @walletSelectSend.
  ///
  /// In ko, this message translates to:
  /// **'선택해서 보내기'**
  String get walletSelectSend;

  /// No description provided for @ddayOverdue.
  ///
  /// In ko, this message translates to:
  /// **'+{n}일'**
  String ddayOverdue(int n);

  /// No description provided for @ledgerEntryActions.
  ///
  /// In ko, this message translates to:
  /// **'이 건 관리'**
  String get ledgerEntryActions;

  /// No description provided for @homeWriteConfirmation.
  ///
  /// In ko, this message translates to:
  /// **'확인서 쓰기'**
  String get homeWriteConfirmation;

  /// No description provided for @settleMonthTotal.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 지급할 돈'**
  String get settleMonthTotal;

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

  /// No description provided for @teamMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 팀'**
  String get teamMenuTitle;

  /// No description provided for @teamMenuSub.
  ///
  /// In ko, this message translates to:
  /// **'반장으로 팀원 명단·단가 관리'**
  String get teamMenuSub;

  /// No description provided for @teamListTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 팀'**
  String get teamListTitle;

  /// No description provided for @teamEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 만든 팀이 없어요'**
  String get teamEmptyTitle;

  /// No description provided for @teamEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'팀을 만들고 팀원을 추가하면 팀 확인서를 한 장으로 정리할 수 있어요'**
  String get teamEmptySub;

  /// No description provided for @teamCreate.
  ///
  /// In ko, this message translates to:
  /// **'팀 만들기'**
  String get teamCreate;

  /// No description provided for @teamNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'팀 이름'**
  String get teamNameLabel;

  /// No description provided for @teamNameHint.
  ///
  /// In ko, this message translates to:
  /// **'팀 이름 (예: 박반장 A팀)'**
  String get teamNameHint;

  /// No description provided for @teamAddMember.
  ///
  /// In ko, this message translates to:
  /// **'팀원 추가'**
  String get teamAddMember;

  /// No description provided for @teamMembersTitle.
  ///
  /// In ko, this message translates to:
  /// **'팀원'**
  String get teamMembersTitle;

  /// No description provided for @teamNoMembers.
  ///
  /// In ko, this message translates to:
  /// **'팀원을 추가해 주세요'**
  String get teamNoMembers;

  /// No description provided for @teamMemberCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'팀원 {count}명'**
  String teamMemberCountLabel(int count);

  /// No description provided for @teamMemberLinked.
  ///
  /// In ko, this message translates to:
  /// **'가입 연결'**
  String get teamMemberLinked;

  /// No description provided for @teamMemberManual.
  ///
  /// In ko, this message translates to:
  /// **'수기'**
  String get teamMemberManual;

  /// No description provided for @teamDefaultRate.
  ///
  /// In ko, this message translates to:
  /// **'기본 단가'**
  String get teamDefaultRate;

  /// No description provided for @teamDefaultRateHint.
  ///
  /// In ko, this message translates to:
  /// **'기본 단가 (공수 1일)'**
  String get teamDefaultRateHint;

  /// No description provided for @teamAddByPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호로 찾기'**
  String get teamAddByPhone;

  /// No description provided for @teamAddManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get teamAddManual;

  /// No description provided for @teamMemberNameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get teamMemberNameHint;

  /// No description provided for @teamMemberPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 (선택)'**
  String get teamMemberPhoneHint;

  /// No description provided for @teamSearchPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'팀원 전화번호'**
  String get teamSearchPhoneHint;

  /// No description provided for @teamSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 검색에 동의한 가입자만 찾을 수 있어요'**
  String get teamSearchHint;

  /// No description provided for @teamSearchNoResult.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get teamSearchNoResult;

  /// No description provided for @teamMemberAdded.
  ///
  /// In ko, this message translates to:
  /// **'팀원을 추가했어요'**
  String get teamMemberAdded;

  /// No description provided for @teamMemberExists.
  ///
  /// In ko, this message translates to:
  /// **'이미 팀에 있는 팀원이에요'**
  String get teamMemberExists;

  /// No description provided for @teamConsentRequired.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 검색에 동의한 가입자만 연결할 수 있어요'**
  String get teamConsentRequired;

  /// No description provided for @teamDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 팀을 삭제할까요? 이미 발행된 확인서는 그대로 유지돼요.'**
  String get teamDeleteConfirm;

  /// No description provided for @teamDeleteMemberConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 팀원을 삭제할까요?'**
  String get teamDeleteMemberConfirm;

  /// No description provided for @confTeamMode.
  ///
  /// In ko, this message translates to:
  /// **'팀 확인서'**
  String get confTeamMode;

  /// No description provided for @confTeamModeSub.
  ///
  /// In ko, this message translates to:
  /// **'팀원별 공수로 한 장에 정리'**
  String get confTeamModeSub;

  /// No description provided for @confTeamSelect.
  ///
  /// In ko, this message translates to:
  /// **'팀 선택'**
  String get confTeamSelect;

  /// No description provided for @confTeamPickTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀을 선택하세요'**
  String get confTeamPickTeam;

  /// No description provided for @confTeamNoTeam.
  ///
  /// In ko, this message translates to:
  /// **'먼저 \'내 팀\'에서 팀을 만들어 주세요'**
  String get confTeamNoTeam;

  /// No description provided for @confTeamTotal.
  ///
  /// In ko, this message translates to:
  /// **'팀 합계'**
  String get confTeamTotal;

  /// No description provided for @confTeamEmptyEntries.
  ///
  /// In ko, this message translates to:
  /// **'공수를 입력한 팀원이 없어요'**
  String get confTeamEmptyEntries;

  /// No description provided for @ledgerTeamBadge.
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get ledgerTeamBadge;

  /// No description provided for @ledgerTeamDerived.
  ///
  /// In ko, this message translates to:
  /// **'{boss} 반장 팀 작업'**
  String ledgerTeamDerived(String boss);

  /// No description provided for @ledgerDerivedReadonly.
  ///
  /// In ko, this message translates to:
  /// **'반장이 작성한 팀 작업이에요 (입금만 기록할 수 있어요)'**
  String get ledgerDerivedReadonly;

  /// No description provided for @lcKicker.
  ///
  /// In ko, this message translates to:
  /// **'표준근로계약서'**
  String get lcKicker;

  /// No description provided for @lcStamp.
  ///
  /// In ko, this message translates to:
  /// **'표 준 근 로 계 약 서'**
  String get lcStamp;

  /// No description provided for @lcParties.
  ///
  /// In ko, this message translates to:
  /// **'계약 당사자'**
  String get lcParties;

  /// No description provided for @lcEmployer.
  ///
  /// In ko, this message translates to:
  /// **'사업주(갑)'**
  String get lcEmployer;

  /// No description provided for @lcWorkerParty.
  ///
  /// In ko, this message translates to:
  /// **'근로자(을)'**
  String get lcWorkerParty;

  /// No description provided for @lcBizNumber.
  ///
  /// In ko, this message translates to:
  /// **'사업자번호'**
  String get lcBizNumber;

  /// No description provided for @lcPeriod.
  ///
  /// In ko, this message translates to:
  /// **'근로계약기간'**
  String get lcPeriod;

  /// No description provided for @lcPeriodOpen.
  ///
  /// In ko, this message translates to:
  /// **'기간의 정함 없음 · 일 단위'**
  String get lcPeriodOpen;

  /// No description provided for @lcWorkplace.
  ///
  /// In ko, this message translates to:
  /// **'근무장소'**
  String get lcWorkplace;

  /// No description provided for @lcJob.
  ///
  /// In ko, this message translates to:
  /// **'업무내용'**
  String get lcJob;

  /// No description provided for @lcWorkTime.
  ///
  /// In ko, this message translates to:
  /// **'근로시간'**
  String get lcWorkTime;

  /// No description provided for @lcBreak.
  ///
  /// In ko, this message translates to:
  /// **'휴게'**
  String get lcBreak;

  /// No description provided for @lcWage.
  ///
  /// In ko, this message translates to:
  /// **'임금'**
  String get lcWage;

  /// No description provided for @lcWageDaily.
  ///
  /// In ko, this message translates to:
  /// **'일급'**
  String get lcWageDaily;

  /// No description provided for @lcWageHourly.
  ///
  /// In ko, this message translates to:
  /// **'시급'**
  String get lcWageHourly;

  /// No description provided for @lcPayday.
  ///
  /// In ko, this message translates to:
  /// **'임금 지급일'**
  String get lcPayday;

  /// No description provided for @lcPayMethod.
  ///
  /// In ko, this message translates to:
  /// **'지급 방법'**
  String get lcPayMethod;

  /// No description provided for @lcAllowance.
  ///
  /// In ko, this message translates to:
  /// **'수당'**
  String get lcAllowance;

  /// No description provided for @lcWeeklyHoliday.
  ///
  /// In ko, this message translates to:
  /// **'주휴수당: 1주 소정근로일을 개근하면 주휴수당을 지급합니다.'**
  String get lcWeeklyHoliday;

  /// No description provided for @lcWeeklyHolidayNone.
  ///
  /// In ko, this message translates to:
  /// **'주휴수당: 해당 없음(일용·단시간 등).'**
  String get lcWeeklyHolidayNone;

  /// No description provided for @lcOvertime.
  ///
  /// In ko, this message translates to:
  /// **'연장·야간·휴일근로 시 근로기준법에 따라 통상임금의 50%를 가산 지급합니다.'**
  String get lcOvertime;

  /// No description provided for @lcOvertimeNone.
  ///
  /// In ko, this message translates to:
  /// **'연장·야간·휴일 가산수당: 별도로 정하지 않음.'**
  String get lcOvertimeNone;

  /// No description provided for @lcInsurance.
  ///
  /// In ko, this message translates to:
  /// **'사회보험 적용'**
  String get lcInsurance;

  /// No description provided for @lcInsEmployment.
  ///
  /// In ko, this message translates to:
  /// **'고용보험'**
  String get lcInsEmployment;

  /// No description provided for @lcInsHealth.
  ///
  /// In ko, this message translates to:
  /// **'건강보험'**
  String get lcInsHealth;

  /// No description provided for @lcInsPension.
  ///
  /// In ko, this message translates to:
  /// **'국민연금'**
  String get lcInsPension;

  /// No description provided for @lcInsAccident.
  ///
  /// In ko, this message translates to:
  /// **'산재보험'**
  String get lcInsAccident;

  /// No description provided for @lcApplied.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get lcApplied;

  /// No description provided for @lcNotApplied.
  ///
  /// In ko, this message translates to:
  /// **'미적용'**
  String get lcNotApplied;

  /// No description provided for @lcSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특약사항'**
  String get lcSpecial;

  /// No description provided for @lcMasterNote.
  ///
  /// In ko, this message translates to:
  /// **'본 계약서의 정본은 한국어본입니다. 번역본은 이해를 돕기 위한 참고용이며, 해석상 차이가 있을 경우 한국어본이 우선합니다.'**
  String get lcMasterNote;

  /// No description provided for @lcEmployerSigned.
  ///
  /// In ko, this message translates to:
  /// **'사업주 서명 완료'**
  String get lcEmployerSigned;

  /// No description provided for @lcMenuDesc.
  ///
  /// In ko, this message translates to:
  /// **'작업자와 전자서명으로 계약'**
  String get lcMenuDesc;

  /// No description provided for @lcListEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 계약서가 없어요'**
  String get lcListEmptyTitle;

  /// No description provided for @lcListEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'작업자와 맺을 근로계약서를 작성해 보세요'**
  String get lcListEmptySub;

  /// No description provided for @lcNewContract.
  ///
  /// In ko, this message translates to:
  /// **'계약서 작성'**
  String get lcNewContract;

  /// No description provided for @lcStatusDraft.
  ///
  /// In ko, this message translates to:
  /// **'작성됨'**
  String get lcStatusDraft;

  /// No description provided for @lcStatusSent.
  ///
  /// In ko, this message translates to:
  /// **'전송됨'**
  String get lcStatusSent;

  /// No description provided for @lcStatusSigned.
  ///
  /// In ko, this message translates to:
  /// **'서명됨'**
  String get lcStatusSigned;

  /// No description provided for @lcWorkerSection.
  ///
  /// In ko, this message translates to:
  /// **'작업자'**
  String get lcWorkerSection;

  /// No description provided for @lcWorkerByPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화로 찾기'**
  String get lcWorkerByPhone;

  /// No description provided for @lcWorkerManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get lcWorkerManual;

  /// No description provided for @lcWorkerNameHint.
  ///
  /// In ko, this message translates to:
  /// **'작업자 이름'**
  String get lcWorkerNameHint;

  /// No description provided for @lcWorkerPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'작업자 전화번호 (선택)'**
  String get lcWorkerPhoneHint;

  /// No description provided for @lcSearchPhoneHint.
  ///
  /// In ko, this message translates to:
  /// **'작업자 전화번호'**
  String get lcSearchPhoneHint;

  /// No description provided for @lcSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 검색에 동의한 가입자만 찾을 수 있어요'**
  String get lcSearchHint;

  /// No description provided for @lcSearchNoResult.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get lcSearchNoResult;

  /// No description provided for @lcWorkerLinkedBadge.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get lcWorkerLinkedBadge;

  /// No description provided for @lcStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get lcStartDate;

  /// No description provided for @lcEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일 (선택)'**
  String get lcEndDate;

  /// No description provided for @lcEndDateNotSet.
  ///
  /// In ko, this message translates to:
  /// **'정함 없음'**
  String get lcEndDateNotSet;

  /// No description provided for @lcWorkplaceHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 강남 A현장'**
  String get lcWorkplaceHint;

  /// No description provided for @lcJobHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 철근 조립'**
  String get lcJobHint;

  /// No description provided for @lcBreakHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 12:00~13:00'**
  String get lcBreakHint;

  /// No description provided for @lcWageAmountHint.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get lcWageAmountHint;

  /// No description provided for @lcPaydayHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 매월 25일'**
  String get lcPaydayHint;

  /// No description provided for @lcPayMethodHint.
  ///
  /// In ko, this message translates to:
  /// **'예) 계좌이체'**
  String get lcPayMethodHint;

  /// No description provided for @lcWeeklyHolidaySwitch.
  ///
  /// In ko, this message translates to:
  /// **'주휴수당 지급'**
  String get lcWeeklyHolidaySwitch;

  /// No description provided for @lcOvertimeSwitch.
  ///
  /// In ko, this message translates to:
  /// **'연장·야간·휴일 가산수당'**
  String get lcOvertimeSwitch;

  /// No description provided for @lcSpecialHint.
  ///
  /// In ko, this message translates to:
  /// **'특약사항 (선택)'**
  String get lcSpecialHint;

  /// No description provided for @lcSaveCommon.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 값 저장'**
  String get lcSaveCommon;

  /// No description provided for @lcSaveCommonSub.
  ///
  /// In ko, this message translates to:
  /// **'다음 작성 시 자동으로 채워요'**
  String get lcSaveCommonSub;

  /// No description provided for @lcSubmit.
  ///
  /// In ko, this message translates to:
  /// **'계약서 만들기'**
  String get lcSubmit;

  /// No description provided for @lcCreated.
  ///
  /// In ko, this message translates to:
  /// **'계약서를 만들었어요'**
  String get lcCreated;

  /// No description provided for @lcDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'계약서'**
  String get lcDetailTitle;

  /// No description provided for @lcSignEmployerTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 서명 (사업주)'**
  String get lcSignEmployerTitle;

  /// No description provided for @lcSignEmployerDesc.
  ///
  /// In ko, this message translates to:
  /// **'서명하면 작업자에게 보낼 수 있어요'**
  String get lcSignEmployerDesc;

  /// No description provided for @lcSignerNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'서명자 이름'**
  String get lcSignerNameLabel;

  /// No description provided for @lcSignRedraw.
  ///
  /// In ko, this message translates to:
  /// **'다시 그리기'**
  String get lcSignRedraw;

  /// No description provided for @lcSignSubmit.
  ///
  /// In ko, this message translates to:
  /// **'서명하기'**
  String get lcSignSubmit;

  /// No description provided for @lcSigned.
  ///
  /// In ko, this message translates to:
  /// **'서명을 완료했어요'**
  String get lcSigned;

  /// No description provided for @lcSignErrPad.
  ///
  /// In ko, this message translates to:
  /// **'서명을 입력해 주세요'**
  String get lcSignErrPad;

  /// No description provided for @lcSignErrName.
  ///
  /// In ko, this message translates to:
  /// **'서명자 이름을 입력해 주세요'**
  String get lcSignErrName;

  /// No description provided for @lcSend.
  ///
  /// In ko, this message translates to:
  /// **'작업자에게 전송'**
  String get lcSend;

  /// No description provided for @lcSentLinked.
  ///
  /// In ko, this message translates to:
  /// **'작업자에게 전송했어요'**
  String get lcSentLinked;

  /// No description provided for @lcSentShare.
  ///
  /// In ko, this message translates to:
  /// **'링크를 공유해 전달하세요'**
  String get lcSentShare;

  /// No description provided for @lcShareBody.
  ///
  /// In ko, this message translates to:
  /// **'아래 링크에서 계약서를 확인하고 서명해 주세요'**
  String get lcShareBody;

  /// No description provided for @lcViewPdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF 열람'**
  String get lcViewPdf;

  /// No description provided for @lcDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 계약서를 삭제할까요?'**
  String get lcDeleteConfirm;

  /// No description provided for @lcDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제했어요'**
  String get lcDeleted;

  /// No description provided for @lcWaitingWorker.
  ///
  /// In ko, this message translates to:
  /// **'작업자 서명 대기 중'**
  String get lcWaitingWorker;

  /// No description provided for @lcMyContractsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 계약서'**
  String get lcMyContractsTitle;

  /// No description provided for @lcMyContractsSub.
  ///
  /// In ko, this message translates to:
  /// **'받은 근로계약서 확인·서명'**
  String get lcMyContractsSub;

  /// No description provided for @lcMyEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'받은 계약서가 없어요'**
  String get lcMyEmptyTitle;

  /// No description provided for @lcMyEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'사업주가 보낸 계약서가 여기에 표시돼요'**
  String get lcMyEmptySub;

  /// No description provided for @lcWorkerSignTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 서명 (근로자)'**
  String get lcWorkerSignTitle;

  /// No description provided for @lcWorkerSignDesc.
  ///
  /// In ko, this message translates to:
  /// **'내용을 확인하고 서명해 주세요'**
  String get lcWorkerSignDesc;

  /// No description provided for @lcAlreadySigned.
  ///
  /// In ko, this message translates to:
  /// **'이미 서명한 계약서예요'**
  String get lcAlreadySigned;

  /// No description provided for @lcCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'계약서를 저장하지 못했어요: {msg}'**
  String lcCreateFailed(String msg);

  /// No description provided for @lcSignFailed.
  ///
  /// In ko, this message translates to:
  /// **'서명하지 못했어요: {msg}'**
  String lcSignFailed(String msg);

  /// No description provided for @lcSendFailed.
  ///
  /// In ko, this message translates to:
  /// **'전송하지 못했어요: {msg}'**
  String lcSendFailed(String msg);

  /// No description provided for @lcPdfFailed.
  ///
  /// In ko, this message translates to:
  /// **'PDF를 열지 못했어요: {msg}'**
  String lcPdfFailed(String msg);

  /// No description provided for @tbmMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'TBM 기록'**
  String get tbmMenuTitle;

  /// No description provided for @tbmMenuDesc.
  ///
  /// In ko, this message translates to:
  /// **'안전점검회의 · 위험요인·참석자 확인'**
  String get tbmMenuDesc;

  /// No description provided for @tbmMyTitle.
  ///
  /// In ko, this message translates to:
  /// **'받은 TBM'**
  String get tbmMyTitle;

  /// No description provided for @tbmMySub.
  ///
  /// In ko, this message translates to:
  /// **'내 안전 기록 · 확인'**
  String get tbmMySub;

  /// No description provided for @tbmTitle.
  ///
  /// In ko, this message translates to:
  /// **'TBM(안전점검회의)'**
  String get tbmTitle;

  /// No description provided for @tbmStamp.
  ///
  /// In ko, this message translates to:
  /// **'T B M'**
  String get tbmStamp;

  /// No description provided for @tbmListEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 TBM 기록이 없어요'**
  String get tbmListEmptyTitle;

  /// No description provided for @tbmListEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'현장 안전점검회의를 기록하세요.'**
  String get tbmListEmptySub;

  /// No description provided for @tbmNew.
  ///
  /// In ko, this message translates to:
  /// **'오늘 TBM 작성'**
  String get tbmNew;

  /// No description provided for @tbmFormTitle.
  ///
  /// In ko, this message translates to:
  /// **'TBM 작성'**
  String get tbmFormTitle;

  /// No description provided for @tbmSite.
  ///
  /// In ko, this message translates to:
  /// **'현장명'**
  String get tbmSite;

  /// No description provided for @tbmSiteHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 강동 현장 3층'**
  String get tbmSiteHint;

  /// No description provided for @tbmDate.
  ///
  /// In ko, this message translates to:
  /// **'일시'**
  String get tbmDate;

  /// No description provided for @tbmHazards.
  ///
  /// In ko, this message translates to:
  /// **'위험요인'**
  String get tbmHazards;

  /// No description provided for @tbmHazardsHint.
  ///
  /// In ko, this message translates to:
  /// **'칩을 눌러 선택하거나 직접 입력하세요'**
  String get tbmHazardsHint;

  /// No description provided for @tbmAddCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get tbmAddCustom;

  /// No description provided for @tbmCustomHint.
  ///
  /// In ko, this message translates to:
  /// **'위험요인 직접 입력'**
  String get tbmCustomHint;

  /// No description provided for @tbmMeasures.
  ///
  /// In ko, this message translates to:
  /// **'안전 조치'**
  String get tbmMeasures;

  /// No description provided for @tbmMeasuresHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 안전벨트 착용, 유도원 배치'**
  String get tbmMeasuresHint;

  /// No description provided for @tbmNotes.
  ///
  /// In ko, this message translates to:
  /// **'특이사항'**
  String get tbmNotes;

  /// No description provided for @tbmNotesHint.
  ///
  /// In ko, this message translates to:
  /// **'특이사항(선택)'**
  String get tbmNotesHint;

  /// No description provided for @tbmAttendees.
  ///
  /// In ko, this message translates to:
  /// **'참석자'**
  String get tbmAttendees;

  /// No description provided for @tbmSelectWorkers.
  ///
  /// In ko, this message translates to:
  /// **'연결 작업자 선택'**
  String get tbmSelectWorkers;

  /// No description provided for @tbmNoConnections.
  ///
  /// In ko, this message translates to:
  /// **'연결된 작업자가 없어요'**
  String get tbmNoConnections;

  /// No description provided for @tbmAddAttendeeManual.
  ///
  /// In ko, this message translates to:
  /// **'수기 참석자 추가'**
  String get tbmAddAttendeeManual;

  /// No description provided for @tbmAttendeeNameHint.
  ///
  /// In ko, this message translates to:
  /// **'참석자 이름'**
  String get tbmAttendeeNameHint;

  /// No description provided for @tbmPhotos.
  ///
  /// In ko, this message translates to:
  /// **'현장 사진'**
  String get tbmPhotos;

  /// No description provided for @tbmAddPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get tbmAddPhoto;

  /// No description provided for @tbmSave.
  ///
  /// In ko, this message translates to:
  /// **'TBM 저장'**
  String get tbmSave;

  /// No description provided for @tbmSaved.
  ///
  /// In ko, this message translates to:
  /// **'TBM을 기록했어요'**
  String get tbmSaved;

  /// No description provided for @tbmSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요: {msg}'**
  String tbmSaveFailed(String msg);

  /// No description provided for @tbmNeedHazard.
  ///
  /// In ko, this message translates to:
  /// **'위험요인을 1개 이상 선택하세요'**
  String get tbmNeedHazard;

  /// No description provided for @tbmNeedSite.
  ///
  /// In ko, this message translates to:
  /// **'현장명을 입력하세요'**
  String get tbmNeedSite;

  /// No description provided for @tbmPresetMine.
  ///
  /// In ko, this message translates to:
  /// **'내 프리셋'**
  String get tbmPresetMine;

  /// No description provided for @tbmPresetAddChip.
  ///
  /// In ko, this message translates to:
  /// **'＋ 프리셋 저장'**
  String get tbmPresetAddChip;

  /// No description provided for @tbmPresetAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 문구 저장'**
  String get tbmPresetAddTitle;

  /// No description provided for @tbmPresetDeleted.
  ///
  /// In ko, this message translates to:
  /// **'프리셋을 삭제했어요'**
  String get tbmPresetDeleted;

  /// No description provided for @tbmDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'TBM 상세'**
  String get tbmDetailTitle;

  /// No description provided for @tbmAttendeesStatus.
  ///
  /// In ko, this message translates to:
  /// **'참석자 확인 현황'**
  String get tbmAttendeesStatus;

  /// No description provided for @tbmAcked.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get tbmAcked;

  /// No description provided for @tbmNotAcked.
  ///
  /// In ko, this message translates to:
  /// **'미확인'**
  String get tbmNotAcked;

  /// No description provided for @tbmAckSummary.
  ///
  /// In ko, this message translates to:
  /// **'참석 {att}명 · 확인 {ack}명'**
  String tbmAckSummary(int att, int ack);

  /// No description provided for @tbmReadonly.
  ///
  /// In ko, this message translates to:
  /// **'작성 당일이 지나 읽기 전용입니다'**
  String get tbmReadonly;

  /// No description provided for @tbmEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get tbmEdit;

  /// No description provided for @tbmDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 TBM 기록을 삭제할까요?'**
  String get tbmDeleteConfirm;

  /// No description provided for @tbmDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제했어요'**
  String get tbmDeleted;

  /// No description provided for @tbmSaveUpdated.
  ///
  /// In ko, this message translates to:
  /// **'수정했어요'**
  String get tbmSaveUpdated;

  /// No description provided for @tbmPhotoFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진 처리 실패: {msg}'**
  String tbmPhotoFailed(String msg);

  /// No description provided for @tbmReceivedEmpty.
  ///
  /// In ko, this message translates to:
  /// **'받은 TBM이 없어요'**
  String get tbmReceivedEmpty;

  /// No description provided for @tbmAckButton.
  ///
  /// In ko, this message translates to:
  /// **'TBM 확인'**
  String get tbmAckButton;

  /// No description provided for @tbmAckDone.
  ///
  /// In ko, this message translates to:
  /// **'확인했어요'**
  String get tbmAckDone;

  /// No description provided for @tbmAckFailed.
  ///
  /// In ko, this message translates to:
  /// **'확인하지 못했어요: {msg}'**
  String tbmAckFailed(String msg);

  /// No description provided for @tbmAlreadyAcked.
  ///
  /// In ko, this message translates to:
  /// **'이미 확인함'**
  String get tbmAlreadyAcked;

  /// No description provided for @tbmPhotoCount.
  ///
  /// In ko, this message translates to:
  /// **'사진 {n}장'**
  String tbmPhotoCount(int n);

  /// No description provided for @tbmHzHeavyEquip.
  ///
  /// In ko, this message translates to:
  /// **'중장비 협착·충돌'**
  String get tbmHzHeavyEquip;

  /// No description provided for @tbmHzFallHeight.
  ///
  /// In ko, this message translates to:
  /// **'고소작업 추락'**
  String get tbmHzFallHeight;

  /// No description provided for @tbmHzHeatIllness.
  ///
  /// In ko, this message translates to:
  /// **'폭염 온열질환'**
  String get tbmHzHeatIllness;

  /// No description provided for @tbmHzElectric.
  ///
  /// In ko, this message translates to:
  /// **'감전'**
  String get tbmHzElectric;

  /// No description provided for @tbmHzFallingObject.
  ///
  /// In ko, this message translates to:
  /// **'낙하물'**
  String get tbmHzFallingObject;

  /// No description provided for @tbmHzCollapse.
  ///
  /// In ko, this message translates to:
  /// **'붕괴·매몰'**
  String get tbmHzCollapse;

  /// No description provided for @tbmHzFire.
  ///
  /// In ko, this message translates to:
  /// **'화재·폭발'**
  String get tbmHzFire;

  /// No description provided for @tbmHzDustNoise.
  ///
  /// In ko, this message translates to:
  /// **'분진·소음'**
  String get tbmHzDustNoise;

  /// No description provided for @tbmHzSlipTrip.
  ///
  /// In ko, this message translates to:
  /// **'전도·미끄러짐'**
  String get tbmHzSlipTrip;

  /// No description provided for @tbmHzConfined.
  ///
  /// In ko, this message translates to:
  /// **'밀폐공간 질식'**
  String get tbmHzConfined;

  /// No description provided for @incomeReportMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'소득 리포트'**
  String get incomeReportMenuTitle;

  /// No description provided for @incomeReportMenuSub.
  ///
  /// In ko, this message translates to:
  /// **'연간 수입·미수·공수 한눈에'**
  String get incomeReportMenuSub;

  /// No description provided for @incomeReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'소득 리포트'**
  String get incomeReportTitle;

  /// No description provided for @incomeReportYear.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String incomeReportYear(String year);

  /// No description provided for @incomeReportTotalBilled.
  ///
  /// In ko, this message translates to:
  /// **'총 청구액'**
  String get incomeReportTotalBilled;

  /// No description provided for @incomeReportTotalPaid.
  ///
  /// In ko, this message translates to:
  /// **'총 입금'**
  String get incomeReportTotalPaid;

  /// No description provided for @incomeReportTotalOutstanding.
  ///
  /// In ko, this message translates to:
  /// **'총 미수'**
  String get incomeReportTotalOutstanding;

  /// No description provided for @incomeReportTotalDays.
  ///
  /// In ko, this message translates to:
  /// **'일한 날'**
  String get incomeReportTotalDays;

  /// No description provided for @incomeReportTotalGongsu.
  ///
  /// In ko, this message translates to:
  /// **'총 공수'**
  String get incomeReportTotalGongsu;

  /// No description provided for @incomeReportTeamPayout.
  ///
  /// In ko, this message translates to:
  /// **'팀 지급분'**
  String get incomeReportTeamPayout;

  /// No description provided for @incomeReportNetBilled.
  ///
  /// In ko, this message translates to:
  /// **'순소득 참고'**
  String get incomeReportNetBilled;

  /// No description provided for @incomeReportNetHint.
  ///
  /// In ko, this message translates to:
  /// **'청구액 − 팀원 지급분 (반장 본인 몫)'**
  String get incomeReportNetHint;

  /// No description provided for @incomeReportMonthlyTrend.
  ///
  /// In ko, this message translates to:
  /// **'월별 추이'**
  String get incomeReportMonthlyTrend;

  /// No description provided for @incomeReportPeakLabel.
  ///
  /// In ko, this message translates to:
  /// **'최고 {amount}'**
  String incomeReportPeakLabel(String amount);

  /// No description provided for @incomeReportByCompany.
  ///
  /// In ko, this message translates to:
  /// **'상대별 합계'**
  String get incomeReportByCompany;

  /// No description provided for @incomeReportEntryCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}건'**
  String incomeReportEntryCount(int n);

  /// No description provided for @incomeReportOutstandingShort.
  ///
  /// In ko, this message translates to:
  /// **'미수 {amount}'**
  String incomeReportOutstandingShort(String amount);

  /// No description provided for @incomeReportTaxTitle.
  ///
  /// In ko, this message translates to:
  /// **'종합소득세 안내'**
  String get incomeReportTaxTitle;

  /// No description provided for @incomeReportTaxL1.
  ///
  /// In ko, this message translates to:
  /// **'종합소득세는 매년 5월에 전년도 소득을 신고·납부합니다.'**
  String get incomeReportTaxL1;

  /// No description provided for @incomeReportTaxL2.
  ///
  /// In ko, this message translates to:
  /// **'인적용역 사업소득은 대금 지급 시 3.3%가 원천징수되는 경우가 많습니다.'**
  String get incomeReportTaxL2;

  /// No description provided for @incomeReportTaxL3.
  ///
  /// In ko, this message translates to:
  /// **'원천징수된 세액은 5월 신고 때 정산(환급 또는 추가납부)됩니다.'**
  String get incomeReportTaxL3;

  /// No description provided for @incomeReportTaxL4.
  ///
  /// In ko, this message translates to:
  /// **'지출 경비와 확인서·명세서를 보관하면 신고에 도움이 됩니다.'**
  String get incomeReportTaxL4;

  /// No description provided for @incomeReportTaxL5.
  ///
  /// In ko, this message translates to:
  /// **'일반 안내이며 세무 상담이 아닙니다. 정확한 신고는 세무 전문가·홈택스를 확인하세요.'**
  String get incomeReportTaxL5;

  /// No description provided for @incomeReportSavePdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF 저장·공유'**
  String get incomeReportSavePdf;

  /// No description provided for @incomeReportPdfFail.
  ///
  /// In ko, this message translates to:
  /// **'리포트를 열지 못했어요: {msg}'**
  String incomeReportPdfFail(String msg);

  /// No description provided for @incomeReportEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 소득 기록이 없어요'**
  String get incomeReportEmptyTitle;

  /// No description provided for @incomeReportEmptySub.
  ///
  /// In ko, this message translates to:
  /// **'확인서를 작성하면 이 리포트에 수입이 쌓여요.'**
  String get incomeReportEmptySub;

  /// No description provided for @ledgerAutoRemind.
  ///
  /// In ko, this message translates to:
  /// **'자동 수금 안내'**
  String get ledgerAutoRemind;

  /// No description provided for @ledgerAutoRemindHint.
  ///
  /// In ko, this message translates to:
  /// **'수금일 이후 자동으로 대금 안내를 보냅니다'**
  String get ledgerAutoRemindHint;

  /// No description provided for @ledgerRemindNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 안내 보내기'**
  String get ledgerRemindNow;

  /// No description provided for @ledgerRemindSent.
  ///
  /// In ko, this message translates to:
  /// **'수금 안내를 보냈어요'**
  String get ledgerRemindSent;

  /// No description provided for @ledgerRemindHistory.
  ///
  /// In ko, this message translates to:
  /// **'안내 발송 이력'**
  String get ledgerRemindHistory;

  /// No description provided for @ledgerRemindHistoryItem.
  ///
  /// In ko, this message translates to:
  /// **'{date} · {stage}'**
  String ledgerRemindHistoryItem(String date, String stage);

  /// No description provided for @reminderStageD7.
  ///
  /// In ko, this message translates to:
  /// **'7일 안내'**
  String get reminderStageD7;

  /// No description provided for @reminderStageD30.
  ///
  /// In ko, this message translates to:
  /// **'30일 안내'**
  String get reminderStageD30;

  /// No description provided for @reminderStageManual.
  ///
  /// In ko, this message translates to:
  /// **'수동 안내'**
  String get reminderStageManual;

  /// No description provided for @profilePayoutSection.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌 (수금 안내용)'**
  String get profilePayoutSection;

  /// No description provided for @profilePayoutBank.
  ///
  /// In ko, this message translates to:
  /// **'은행명'**
  String get profilePayoutBank;

  /// No description provided for @profilePayoutAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호'**
  String get profilePayoutAccount;

  /// No description provided for @profilePayoutHolder.
  ///
  /// In ko, this message translates to:
  /// **'예금주'**
  String get profilePayoutHolder;

  /// No description provided for @profilePayoutHint.
  ///
  /// In ko, this message translates to:
  /// **'수금 안내를 보낼 때 이 계좌가 함께 전달됩니다 (선택 입력)'**
  String get profilePayoutHint;

  /// No description provided for @profilePayoutSaved.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌를 저장했어요'**
  String get profilePayoutSaved;

  /// No description provided for @badgeExcellent.
  ///
  /// In ko, this message translates to:
  /// **'우수 지급처'**
  String get badgeExcellent;

  /// No description provided for @badgeGood.
  ///
  /// In ko, this message translates to:
  /// **'양호 지급처'**
  String get badgeGood;

  /// No description provided for @badgeAvgDays.
  ///
  /// In ko, this message translates to:
  /// **'평균 {days}일'**
  String badgeAvgDays(int days);

  /// No description provided for @badgeSelfImproveGood.
  ///
  /// In ko, this message translates to:
  /// **'15일 내 지급 시 우수 지급처 배지를 받을 수 있어요'**
  String get badgeSelfImproveGood;

  /// No description provided for @badgeSelfImproveNone.
  ///
  /// In ko, this message translates to:
  /// **'대금을 제때 지급하면 우수 지급처 배지를 받을 수 있어요'**
  String get badgeSelfImproveNone;

  /// No description provided for @badgeInsufficient.
  ///
  /// In ko, this message translates to:
  /// **'지급 기록 {count}건 — 배지 산정에는 더 많은 기록이 필요해요'**
  String badgeInsufficient(int count);

  /// No description provided for @badgeSampleCount.
  ///
  /// In ko, this message translates to:
  /// **'최근 {count}건 기준'**
  String badgeSampleCount(int count);

  /// No description provided for @badgeSelfTitle.
  ///
  /// In ko, this message translates to:
  /// **'지급 신뢰도'**
  String get badgeSelfTitle;

  /// No description provided for @qrCardMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 QR 명함'**
  String get qrCardMenuTitle;

  /// No description provided for @qrCardMenuSub.
  ///
  /// In ko, this message translates to:
  /// **'QR·링크로 나를 소개해요'**
  String get qrCardMenuSub;

  /// No description provided for @qrCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 QR 명함'**
  String get qrCardTitle;

  /// No description provided for @qrCardScanHint.
  ///
  /// In ko, this message translates to:
  /// **'QR을 찍으면 내 공개 프로필이 열려요'**
  String get qrCardScanHint;

  /// No description provided for @qrCardViewCount.
  ///
  /// In ko, this message translates to:
  /// **'조회 {count}회'**
  String qrCardViewCount(int count);

  /// No description provided for @qrCardIntroLabel.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개'**
  String get qrCardIntroLabel;

  /// No description provided for @qrCardIntroPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 20년 경력 철근 반장'**
  String get qrCardIntroPlaceholder;

  /// No description provided for @qrCardIntroSaved.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 소개를 저장했어요'**
  String get qrCardIntroSaved;

  /// No description provided for @qrCardExposeTitle.
  ///
  /// In ko, this message translates to:
  /// **'명함 공개'**
  String get qrCardExposeTitle;

  /// No description provided for @qrCardExposeSub.
  ///
  /// In ko, this message translates to:
  /// **'켜면 QR·링크로 프로필을 볼 수 있어요'**
  String get qrCardExposeSub;

  /// No description provided for @qrCardHiddenHint.
  ///
  /// In ko, this message translates to:
  /// **'지금은 비공개예요 — 링크를 열어도 명함이 보이지 않아요'**
  String get qrCardHiddenHint;

  /// No description provided for @qrCardRotate.
  ///
  /// In ko, this message translates to:
  /// **'링크 재발급'**
  String get qrCardRotate;

  /// No description provided for @qrCardRotateConfirm.
  ///
  /// In ko, this message translates to:
  /// **'새 링크를 만들면 이전 QR·링크는 더 이상 열리지 않아요. 계속할까요?'**
  String get qrCardRotateConfirm;

  /// No description provided for @qrCardRotateConfirmBtn.
  ///
  /// In ko, this message translates to:
  /// **'재발급'**
  String get qrCardRotateConfirmBtn;

  /// No description provided for @qrCardRotated.
  ///
  /// In ko, this message translates to:
  /// **'새 명함 링크를 발급했어요'**
  String get qrCardRotated;

  /// No description provided for @qrCardDocValid.
  ///
  /// In ko, this message translates to:
  /// **'서류 유효'**
  String get qrCardDocValid;

  /// No description provided for @qrCardDocProblem.
  ///
  /// In ko, this message translates to:
  /// **'확인이 필요한 서류'**
  String get qrCardDocProblem;

  /// No description provided for @qrCardDocExpiryLabel.
  ///
  /// In ko, this message translates to:
  /// **'만료 {date}'**
  String qrCardDocExpiryLabel(String date);

  /// No description provided for @smsSendSms.
  ///
  /// In ko, this message translates to:
  /// **'문자로 보내기'**
  String get smsSendSms;

  /// No description provided for @smsSharedInstead.
  ///
  /// In ko, this message translates to:
  /// **'문자를 지원하지 않아 공유로 열었어요'**
  String get smsSharedInstead;

  /// No description provided for @smsFailed.
  ///
  /// In ko, this message translates to:
  /// **'문자 앱을 열지 못했어요'**
  String get smsFailed;

  /// No description provided for @callButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'전화 걸기'**
  String get callButtonLabel;

  /// No description provided for @callFailed.
  ///
  /// In ko, this message translates to:
  /// **'전화를 걸지 못했어요'**
  String get callFailed;

  /// No description provided for @smsConfBodyNamed.
  ///
  /// In ko, this message translates to:
  /// **'{name}님, {site} 작업확인서 서명 부탁드립니다: {link}'**
  String smsConfBodyNamed(String name, String site, String link);

  /// No description provided for @smsConfBodyPlain.
  ///
  /// In ko, this message translates to:
  /// **'{site} 작업확인서 서명 부탁드립니다: {link}'**
  String smsConfBodyPlain(String site, String link);

  /// No description provided for @smsCardShareBody.
  ///
  /// In ko, this message translates to:
  /// **'명함을 보내드려요: {link}'**
  String smsCardShareBody(String link);

  /// No description provided for @smsDocBundleBody.
  ///
  /// In ko, this message translates to:
  /// **'서류를 보내드려요: {link}'**
  String smsDocBundleBody(String link);

  /// No description provided for @smsRecipientTitle.
  ///
  /// In ko, this message translates to:
  /// **'받는 사람'**
  String get smsRecipientTitle;

  /// No description provided for @smsRecipientHint.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 입력'**
  String get smsRecipientHint;

  /// No description provided for @smsPickConnection.
  ///
  /// In ko, this message translates to:
  /// **'연결 상대에서 선택'**
  String get smsPickConnection;

  /// No description provided for @smsOpenCompose.
  ///
  /// In ko, this message translates to:
  /// **'문자 작성창 열기'**
  String get smsOpenCompose;

  /// No description provided for @quickSendMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'빠른 보내기'**
  String get quickSendMenuTitle;

  /// No description provided for @quickSendMenuSub.
  ///
  /// In ko, this message translates to:
  /// **'명함·서류를 문자로 바로 전송'**
  String get quickSendMenuSub;

  /// No description provided for @quickSendTitle.
  ///
  /// In ko, this message translates to:
  /// **'빠른 보내기'**
  String get quickSendTitle;

  /// No description provided for @quickSendAddTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 추가'**
  String get quickSendAddTemplate;

  /// No description provided for @quickSendPickTemplate.
  ///
  /// In ko, this message translates to:
  /// **'보낼 템플릿을 선택하세요'**
  String get quickSendPickTemplate;

  /// No description provided for @quickSendBuiltinSection.
  ///
  /// In ko, this message translates to:
  /// **'기본 템플릿'**
  String get quickSendBuiltinSection;

  /// No description provided for @quickSendCustomSection.
  ///
  /// In ko, this message translates to:
  /// **'내 템플릿'**
  String get quickSendCustomSection;

  /// No description provided for @quickSendNoDoc.
  ///
  /// In ko, this message translates to:
  /// **'‘{type}’ 서류가 없어요. 서류 지갑에 먼저 등록하세요'**
  String quickSendNoDoc(String type);

  /// No description provided for @quickSendAttachImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지로 첨부'**
  String get quickSendAttachImage;

  /// No description provided for @quickSendAttachImageSub.
  ///
  /// In ko, this message translates to:
  /// **'링크 대신 서류 이미지를 직접 첨부해요'**
  String get quickSendAttachImageSub;

  /// No description provided for @tplCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'명함'**
  String get tplCardTitle;

  /// No description provided for @tplCardBody.
  ///
  /// In ko, this message translates to:
  /// **'{name}님, 안녕하세요. {me} 명함을 보내드려요: {link}'**
  String tplCardBody(String name, String me, String link);

  /// No description provided for @tplBizTitle.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록증'**
  String get tplBizTitle;

  /// No description provided for @tplBizBody.
  ///
  /// In ko, this message translates to:
  /// **'{name}님, {me} 사업자등록증을 보내드려요: {link}'**
  String tplBizBody(String name, String me, String link);

  /// No description provided for @tplBankTitle.
  ///
  /// In ko, this message translates to:
  /// **'통장사본'**
  String get tplBankTitle;

  /// No description provided for @tplBankBody.
  ///
  /// In ko, this message translates to:
  /// **'{name}님, {me} 통장사본을 보내드려요: {link}'**
  String tplBankBody(String name, String me, String link);

  /// No description provided for @tplEditorTitle.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 추가'**
  String get tplEditorTitle;

  /// No description provided for @tplFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get tplFieldTitle;

  /// No description provided for @tplFieldBody.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get tplFieldBody;

  /// No description provided for @tplFieldBodyHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 안녕하세요, 자료 보내드립니다'**
  String get tplFieldBodyHint;

  /// No description provided for @tplVarsHelp.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 변수'**
  String get tplVarsHelp;

  /// No description provided for @tplFieldLink.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get tplFieldLink;

  /// No description provided for @tplLinkNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get tplLinkNone;

  /// No description provided for @tplLinkCard.
  ///
  /// In ko, this message translates to:
  /// **'명함 링크'**
  String get tplLinkCard;

  /// No description provided for @tplLinkDoc.
  ///
  /// In ko, this message translates to:
  /// **'서류 링크'**
  String get tplLinkDoc;

  /// No description provided for @tplFieldDocType.
  ///
  /// In ko, this message translates to:
  /// **'서류 유형'**
  String get tplFieldDocType;

  /// No description provided for @tplDocTypeHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 사업자등록증, 통장사본'**
  String get tplDocTypeHint;

  /// No description provided for @tplSaveTemplate.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 저장'**
  String get tplSaveTemplate;

  /// No description provided for @tplNeedTitleBody.
  ///
  /// In ko, this message translates to:
  /// **'제목과 본문을 입력하세요'**
  String get tplNeedTitleBody;

  /// No description provided for @postCallTitle.
  ///
  /// In ko, this message translates to:
  /// **'방금 {name}님과 통화하셨나요?'**
  String postCallTitle(String name);

  /// No description provided for @postCallSendCard.
  ///
  /// In ko, this message translates to:
  /// **'명함 보내기'**
  String get postCallSendCard;

  /// No description provided for @postCallQuickSend.
  ///
  /// In ko, this message translates to:
  /// **'빠른 보내기'**
  String get postCallQuickSend;

  /// No description provided for @postCallSettingTitle.
  ///
  /// In ko, this message translates to:
  /// **'통화 후 보내기 제안'**
  String get postCallSettingTitle;

  /// No description provided for @postCallSettingSub.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 전화한 뒤 돌아오면 명함·빠른 보내기를 제안해요'**
  String get postCallSettingSub;

  /// No description provided for @attendBoardTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 출역 현황'**
  String get attendBoardTitle;

  /// No description provided for @attendBoardEmpty.
  ///
  /// In ko, this message translates to:
  /// **'오늘 예정된 작업이 없어요'**
  String get attendBoardEmpty;

  /// No description provided for @attendBoardViewDetail.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 상세 보기'**
  String get attendBoardViewDetail;

  /// No description provided for @attendSummaryTotal.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get attendSummaryTotal;

  /// No description provided for @attendSummaryAttended.
  ///
  /// In ko, this message translates to:
  /// **'출근'**
  String get attendSummaryAttended;

  /// No description provided for @attendSummaryCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get attendSummaryCompleted;

  /// No description provided for @attendSummaryAbsent.
  ///
  /// In ko, this message translates to:
  /// **'미출근'**
  String get attendSummaryAbsent;

  /// No description provided for @attendPeopleCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String attendPeopleCount(int count);

  /// No description provided for @attendStatusScheduled.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get attendStatusScheduled;

  /// No description provided for @attendStatusAccepted.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get attendStatusAccepted;

  /// No description provided for @attendStatusStarted.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get attendStatusStarted;

  /// No description provided for @attendStatusDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get attendStatusDone;

  /// No description provided for @attendStatusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get attendStatusCancelled;

  /// No description provided for @attendStartedAt.
  ///
  /// In ko, this message translates to:
  /// **'{time} 시작'**
  String attendStartedAt(String time);

  /// No description provided for @attendScheduledAt.
  ///
  /// In ko, this message translates to:
  /// **'{time} 예정'**
  String attendScheduledAt(String time);

  /// No description provided for @attendCondOk.
  ///
  /// In ko, this message translates to:
  /// **'컨디션 좋음'**
  String get attendCondOk;

  /// No description provided for @attendCondBad.
  ///
  /// In ko, this message translates to:
  /// **'컨디션 이상'**
  String get attendCondBad;

  /// No description provided for @siteCostsTitle.
  ///
  /// In ko, this message translates to:
  /// **'현장별 인건비'**
  String get siteCostsTitle;

  /// No description provided for @bizMenuSiteCostsDesc.
  ///
  /// In ko, this message translates to:
  /// **'현장별 인건비 집계·발주처 제출 PDF'**
  String get bizMenuSiteCostsDesc;

  /// No description provided for @siteCostsThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get siteCostsThisMonth;

  /// No description provided for @siteCostsLast3.
  ///
  /// In ko, this message translates to:
  /// **'최근 3개월'**
  String get siteCostsLast3;

  /// No description provided for @siteCostsLast6.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월'**
  String get siteCostsLast6;

  /// No description provided for @siteCostsLast12.
  ///
  /// In ko, this message translates to:
  /// **'최근 12개월'**
  String get siteCostsLast12;

  /// No description provided for @siteCostsRangeLabel.
  ///
  /// In ko, this message translates to:
  /// **'{from} ~ {to}'**
  String siteCostsRangeLabel(String from, String to);

  /// No description provided for @siteCostsSubtotal.
  ///
  /// In ko, this message translates to:
  /// **'소계'**
  String get siteCostsSubtotal;

  /// No description provided for @siteCostsTotalHeader.
  ///
  /// In ko, this message translates to:
  /// **'전체 총계'**
  String get siteCostsTotalHeader;

  /// No description provided for @siteCostsWorkerCount.
  ///
  /// In ko, this message translates to:
  /// **'작업자 {count}명'**
  String siteCostsWorkerCount(int count);

  /// No description provided for @siteCostsTeamMembers.
  ///
  /// In ko, this message translates to:
  /// **'팀원 {count}명'**
  String siteCostsTeamMembers(int count);

  /// No description provided for @siteCostsEntryCount.
  ///
  /// In ko, this message translates to:
  /// **'확인서 {count}건'**
  String siteCostsEntryCount(int count);

  /// No description provided for @siteCostsSavePdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF 저장·공유'**
  String get siteCostsSavePdf;

  /// No description provided for @siteCostsPdfFail.
  ///
  /// In ko, this message translates to:
  /// **'PDF 를 만들지 못했어요 ({error})'**
  String siteCostsPdfFail(String error);

  /// No description provided for @siteCostsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 집계할 확인서가 없어요'**
  String get siteCostsEmpty;

  /// No description provided for @wageStmtTitle.
  ///
  /// In ko, this message translates to:
  /// **'지급명세서(월 마감)'**
  String get wageStmtTitle;

  /// No description provided for @bizMenuWageStmtDesc.
  ///
  /// In ko, this message translates to:
  /// **'일용근로소득 지급명세서·월 마감'**
  String get bizMenuWageStmtDesc;

  /// No description provided for @wageStmtEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 달에 지급한 내역이 없어요'**
  String get wageStmtEmpty;

  /// No description provided for @wageStmtType33.
  ///
  /// In ko, this message translates to:
  /// **'사업소득 3.3%'**
  String get wageStmtType33;

  /// No description provided for @wageStmtTypeDaily.
  ///
  /// In ko, this message translates to:
  /// **'일용근로'**
  String get wageStmtTypeDaily;

  /// No description provided for @wageStmtPaidTotal.
  ///
  /// In ko, this message translates to:
  /// **'지급액'**
  String get wageStmtPaidTotal;

  /// No description provided for @wageStmtIncomeTax.
  ///
  /// In ko, this message translates to:
  /// **'소득세'**
  String get wageStmtIncomeTax;

  /// No description provided for @wageStmtLocalTax.
  ///
  /// In ko, this message translates to:
  /// **'지방소득세'**
  String get wageStmtLocalTax;

  /// No description provided for @wageStmtTotalTax.
  ///
  /// In ko, this message translates to:
  /// **'원천징수 합계'**
  String get wageStmtTotalTax;

  /// No description provided for @wageStmtNetPay.
  ///
  /// In ko, this message translates to:
  /// **'차인지급액'**
  String get wageStmtNetPay;

  /// No description provided for @wageStmtPaymentCount.
  ///
  /// In ko, this message translates to:
  /// **'지급 {count}건'**
  String wageStmtPaymentCount(int count);

  /// No description provided for @wageStmtCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get wageStmtCopy;

  /// No description provided for @wageStmtCopied.
  ///
  /// In ko, this message translates to:
  /// **'지급명세서 내용을 복사했어요'**
  String get wageStmtCopied;

  /// No description provided for @wageStmtMark.
  ///
  /// In ko, this message translates to:
  /// **'이 달 마감'**
  String get wageStmtMark;

  /// No description provided for @wageStmtMarked.
  ///
  /// In ko, this message translates to:
  /// **'마감됨'**
  String get wageStmtMarked;

  /// No description provided for @wageStmtMarkedSnack.
  ///
  /// In ko, this message translates to:
  /// **'{month} 지급명세서를 마감했어요'**
  String wageStmtMarkedSnack(String month);

  /// No description provided for @wageStmtAlreadyMarked.
  ///
  /// In ko, this message translates to:
  /// **'이미 마감한 달이에요'**
  String get wageStmtAlreadyMarked;

  /// No description provided for @wageStmtMarkFail.
  ///
  /// In ko, this message translates to:
  /// **'마감하지 못했어요 ({error})'**
  String wageStmtMarkFail(String error);

  /// No description provided for @wageStmtTotalHeader.
  ///
  /// In ko, this message translates to:
  /// **'전체 지급 총계'**
  String get wageStmtTotalHeader;

  /// No description provided for @wageStmtNoticeTitle.
  ///
  /// In ko, this message translates to:
  /// **'안내'**
  String get wageStmtNoticeTitle;

  /// No description provided for @wageStmtWorkerTax.
  ///
  /// In ko, this message translates to:
  /// **'소득 유형별 원천징수'**
  String get wageStmtWorkerTax;

  /// No description provided for @siteCostsManDays.
  ///
  /// In ko, this message translates to:
  /// **'연인원 {n}'**
  String siteCostsManDays(String n);

  /// No description provided for @partnersMenuTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get partnersMenuTitle;

  /// No description provided for @partnersMenuSub.
  ///
  /// In ko, this message translates to:
  /// **'확인서 상대가 자동으로 모여요'**
  String get partnersMenuSub;

  /// No description provided for @partnersTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get partnersTitle;

  /// No description provided for @partnersSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'이름·전화 검색'**
  String get partnersSearchHint;

  /// No description provided for @partnersEmpty.
  ///
  /// In ko, this message translates to:
  /// **'확인서를 작성하면 거래처가 자동으로 모여요'**
  String get partnersEmpty;

  /// No description provided for @partnerLinkedBadge.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get partnerLinkedBadge;

  /// No description provided for @partnerSettledLabel.
  ///
  /// In ko, this message translates to:
  /// **'정산 완료'**
  String get partnerSettledLabel;

  /// No description provided for @partnerConfCount.
  ///
  /// In ko, this message translates to:
  /// **'확인서 {count}건'**
  String partnerConfCount(int count);

  /// No description provided for @partnerOutstandingLabel.
  ///
  /// In ko, this message translates to:
  /// **'미수 잔액'**
  String get partnerOutstandingLabel;

  /// No description provided for @partnerPaidLabel.
  ///
  /// In ko, this message translates to:
  /// **'입금 합계'**
  String get partnerPaidLabel;

  /// No description provided for @partnerConfLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인서'**
  String get partnerConfLabel;

  /// No description provided for @partnerLastWorked.
  ///
  /// In ko, this message translates to:
  /// **'최근 작업일'**
  String get partnerLastWorked;

  /// No description provided for @partnerActionSms.
  ///
  /// In ko, this message translates to:
  /// **'문자 보내기'**
  String get partnerActionSms;

  /// No description provided for @partnerActionCall.
  ///
  /// In ko, this message translates to:
  /// **'전화 걸기'**
  String get partnerActionCall;

  /// No description provided for @partnerActionWriteConf.
  ///
  /// In ko, this message translates to:
  /// **'확인서 쓰기'**
  String get partnerActionWriteConf;

  /// No description provided for @partnerNoPhone.
  ///
  /// In ko, this message translates to:
  /// **'연락처 없음'**
  String get partnerNoPhone;

  /// No description provided for @partnerEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래처 정보'**
  String get partnerEditTitle;

  /// No description provided for @partnerAlias.
  ///
  /// In ko, this message translates to:
  /// **'별칭'**
  String get partnerAlias;

  /// No description provided for @partnerBizNumber.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록번호'**
  String get partnerBizNumber;

  /// No description provided for @partnerEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get partnerEmail;

  /// No description provided for @partnerMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get partnerMemo;

  /// No description provided for @partnerSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get partnerSave;

  /// No description provided for @partnerSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get partnerSaved;

  /// No description provided for @partnerLinkedNote.
  ///
  /// In ko, this message translates to:
  /// **'연결된 거래처는 사업장 정보를 따릅니다'**
  String get partnerLinkedNote;

  /// No description provided for @quickSendPickPartner.
  ///
  /// In ko, this message translates to:
  /// **'거래처에서 선택'**
  String get quickSendPickPartner;

  /// No description provided for @quickSendPickContact.
  ///
  /// In ko, this message translates to:
  /// **'연락처에서 선택'**
  String get quickSendPickContact;

  /// No description provided for @partnersAdd.
  ///
  /// In ko, this message translates to:
  /// **'거래처 추가'**
  String get partnersAdd;

  /// No description provided for @partnerNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get partnerNameLabel;

  /// No description provided for @partnerPhoneLabel.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get partnerPhoneLabel;

  /// No description provided for @partnerNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해 주세요'**
  String get partnerNameRequired;

  /// No description provided for @partnerAdded.
  ///
  /// In ko, this message translates to:
  /// **'거래처를 추가했어요'**
  String get partnerAdded;

  /// No description provided for @partnerDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 거래처예요'**
  String get partnerDuplicate;

  /// No description provided for @partnerNoRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get partnerNoRecord;

  /// No description provided for @partnerSavePromptTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 번호를 거래처로 저장할까요?'**
  String get partnerSavePromptTitle;

  /// No description provided for @partnerSavePromptLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get partnerSavePromptLater;

  /// No description provided for @confPickPartner.
  ///
  /// In ko, this message translates to:
  /// **'거래처에서 선택'**
  String get confPickPartner;
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
