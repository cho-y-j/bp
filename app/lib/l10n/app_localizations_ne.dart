// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get widgetToday => 'आजको तालिका';

  @override
  String get widgetNoSchedule => 'आज कुनै तालिका छैन';

  @override
  String get widgetOutstanding => 'यस महिनाको बाँकी';

  @override
  String get widgetLoginPlease => 'कृपया लग इन गर्नुहोस्';

  @override
  String widgetSyncedAt(String time) {
    return '$time अद्यावधिक';
  }

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get confirm => 'ठिक छ';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get delete => 'मेटाउनुहोस्';

  @override
  String get retry => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get edit => 'सम्पादन';

  @override
  String get share => 'साझा गर्नुहोस्';

  @override
  String get download => 'डाउनलोड';

  @override
  String get view => 'हेर्नुहोस्';

  @override
  String get loading => 'लोड हुँदै…';

  @override
  String get errorConnTitle => 'जडानमा समस्या छ';

  @override
  String get errorConnSubtitle =>
      'इन्टरनेट जडान जाँच गरी फेरि प्रयास गर्नुहोस्।';

  @override
  String get statusDeposited => 'भुक्तानी भयो';

  @override
  String get statusOverdue => 'म्याद नाघ्यो';

  @override
  String collectDday(String dday) {
    return 'असुली $dday';
  }

  @override
  String get amtBase => 'आधार';

  @override
  String get amtOvertime => 'ओभरटाइम';

  @override
  String get amtEarly => 'बिहान जल्दी';

  @override
  String get amtNight => 'रात';

  @override
  String get amtAllnight => 'रातभर';

  @override
  String get itemOther => 'अन्य';

  @override
  String get baseDaily => 'आधार (दैनिक)';

  @override
  String get baseHourly => 'आधार (घण्टा)';

  @override
  String get basePerCase => 'आधार (प्रति काम)';

  @override
  String get baseGongsu => 'आधार (gongsu)';

  @override
  String get unitGongsu => 'gongsu';

  @override
  String qtyGongsu(String qty) {
    return '$qty gongsu';
  }

  @override
  String vatLabel(String rate) {
    return 'भ्याट ($rate%)';
  }

  @override
  String daysCount(int days) {
    return '$days दिन';
  }

  @override
  String daysWithGongsu(int days, String gongsu) {
    return '$days दिन · $gongsu gongsu';
  }

  @override
  String get moreTitle => 'थप';

  @override
  String get sectionManage => 'व्यवस्थापन';

  @override
  String get sectionSettings => 'सेटिङ';

  @override
  String get menuWallet => 'कागजात वालेट';

  @override
  String get menuWalletSub =>
      'प्रमाणपत्र·बीमा·जाँच म्याद व्यवस्थापन · सेटमा पठाउने';

  @override
  String get menuBizHome => 'ठेकेदार गृह';

  @override
  String get menuBizMode => 'ठेकेदार मोड';

  @override
  String get menuBizSub => 'काम आदेश·प्राप्त पुष्टि·भुक्तानी·सुरक्षा रिपोर्ट';

  @override
  String get menuJobs => 'प्राप्त कामहरू';

  @override
  String get menuJobsSub => 'काम आदेश स्वीकार·सुरु·पूरा';

  @override
  String get menuTax => 'कर बिजक तयारी';

  @override
  String get menuTaxSub => 'हस्ताक्षर भएको पुष्टि → Hometax मा हाल्ने डाटा';

  @override
  String get menuNotifications => 'सूचना';

  @override
  String get menuNotificationsSub =>
      'असुली·कागजात म्याद·काम तालिका·गर्मी सुरक्षा';

  @override
  String get consentTitle => 'फोन नम्बरबाट खोज्न दिने';

  @override
  String get consentSub =>
      'ठेकेदारले मेरो नम्बरबाट मलाई खोजी सम्पर्क गर्न सक्छ';

  @override
  String get kakaoLinkTitle => 'Kakao खाता जोड्ने';

  @override
  String get kakaoLinkedSub => 'जोडिएको';

  @override
  String get kakaoLinkSub => 'Kakao बाट पनि लगइन गर्न जोड्नुहोस्';

  @override
  String get kakaoLinked => 'Kakao खाता जोडियो।';

  @override
  String get kakaoNotReady => 'Kakao लगइन तयारीमा छ।';

  @override
  String get kakaoAlreadyLinked => 'यो Kakao अर्को खातामा पहिले नै जोडिएको छ।';

  @override
  String kakaoLinkFailed(String message) {
    return 'जोड्न सकिएन: $message';
  }

  @override
  String get kakaoLinkCanceled => 'Kakao जडान रद्द भयो।';

  @override
  String get logout => 'लगआउट';

  @override
  String get logoutConfirm => 'लगआउट गर्ने?';

  @override
  String get noName => 'नाम छैन';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'प्रणाली अनुसार';

  @override
  String get paperStamp => 'कामको पुष्टि पत्र';

  @override
  String get paperDate => 'काम गरेको मिति';

  @override
  String get paperTime => 'समय';

  @override
  String get paperSite => 'साइट';

  @override
  String get paperWorker => 'कामदार';

  @override
  String get paperOrderer => 'काम दिने';

  @override
  String get paperWork => 'कामको विवरण';

  @override
  String get paperEquipment => 'उपकरण';

  @override
  String get paperGuide => 'निर्देशक';

  @override
  String get paperTotal => 'पाउने रकम';

  @override
  String get paperMemo => 'टिप्पणी';

  @override
  String get paperSignHead => 'काम दिनेको हस्ताक्षर';

  @override
  String paperSignedBy(String name) {
    return '$name ले हस्ताक्षर गर्नुभयो';
  }

  @override
  String shareCount(int n) {
    return 'साझा गरिएका कागजात $n वटा';
  }

  @override
  String shareValidUntil(String date) {
    return '$date सम्म हेर्न मिल्ने';
  }

  @override
  String shareExpiry(String date) {
    return 'म्याद $date';
  }

  @override
  String get shareNoExpiry => 'म्याद छैन';

  @override
  String get shareMasked => 'ढाकिएको प्रति';

  @override
  String get statusTransientTitle => 'अस्थायी त्रुटि';

  @override
  String get statusTransientMsg => 'केही बेरमा फेरि प्रयास गर्नुहोस्।';

  @override
  String get statusNotFoundTitle => 'लिंक भेटिएन';

  @override
  String get statusNotFoundMsg =>
      'लिंकको म्याद सकिएको वा रद्द भएको हुन सक्छ। पठाउनेसँग नयाँ लिंक माग्नुहोस्।';

  @override
  String get authStartWithPhone => 'फोन नम्बरबाट सुरु गर्नुहोस्';

  @override
  String get authTagline =>
      '३० सेकेन्डमा आफ्नो काम रेकर्ड गर्नुहोस्, पुष्टि पत्र, खाता र भुक्तानी स्वतः व्यवस्थापन हुन्छ।';

  @override
  String get authPhoneLabel => 'फोन नम्बर';

  @override
  String get authCodeLabel => 'प्रमाणीकरण कोड';

  @override
  String get authCodeHint => '६ अङ्कको कोड';

  @override
  String get authDevAutofill => 'विकास मोड: कोड स्वतः भरिन्छ।';

  @override
  String get authRequestCode => 'प्रमाणीकरण कोड पाउनुहोस्';

  @override
  String get authVerifyStart => 'प्रमाणित गरी सुरु गर्नुहोस्';

  @override
  String get authReenterPhone => 'फोन नम्बर फेरि लेख्नुहोस्';

  @override
  String get authOr => 'वा';

  @override
  String get authKakaoStart => 'Kakao बाट सुरु गर्नुहोस्';

  @override
  String get authKakaoPreparing =>
      'Kakao लगइन तयारी हुँदैछ। कृपया फोन नम्बरबाट सुरु गर्नुहोस्।';

  @override
  String get onbWelcome => 'स्वागत छ!';

  @override
  String get onbNamePrompt => 'पुष्टि पत्रमा देखिने नाम बताउनुहोस्।';

  @override
  String get onbNameLabel => 'नाम';

  @override
  String get onbNameHint => 'जस्तै) राम बहादुर';

  @override
  String get onbStart => 'सुरु गर्नुहोस्';

  @override
  String get navHome => 'गृह';

  @override
  String get navCalendar => 'क्यालेन्डर';

  @override
  String get navLedger => 'खाता';

  @override
  String get navMore => 'थप';

  @override
  String get navWrite => 'नयाँ';

  @override
  String navDraftsSent(int n) {
    return '$n मस्यौदा स्वतः पठाइयो।';
  }

  @override
  String navDraftsFailed(int n) {
    return '$n मस्यौदा पठाउन सकिएन। गृहमा जाँच गर्नुहोस्।';
  }

  @override
  String get notiTitle => 'सूचनाहरू';

  @override
  String get notiEmpty => 'कुनै सूचना छैन';

  @override
  String get notiAckDone => 'पुष्टि गरियो।';

  @override
  String notiAckFailed(String error) {
    return 'पुष्टि असफल: $error';
  }

  @override
  String get bizModeTitle => 'व्यवसाय मोड';

  @override
  String bizCreateFailed(String error) {
    return 'सिर्जना असफल: $error';
  }

  @override
  String get bizCreateHeading => 'सुरु गर्न व्यवसाय बनाउनुहोस्';

  @override
  String get bizCreateDesc =>
      'कामदार जोड्ने, काम दिने, पुष्टि पत्र हस्ताक्षर, भुक्तानी र सुरक्षा रिपोर्ट — एकै ठाउँमा।';

  @override
  String get bizNameHint => 'व्यवसायको नाम (जस्तै: Daesung Construction)';

  @override
  String get bizBnoHint => 'व्यवसाय नम्बर (वैकल्पिक)';

  @override
  String get bizCreateButton => 'व्यवसाय बनाउनुहोस्';

  @override
  String bizInviteCode(String code) {
    return 'निमन्त्रणा कोड $code';
  }

  @override
  String get inboxTitle => 'प्राप्ति बाकस';

  @override
  String get bizMenuInboxDesc => 'प्राप्त पुष्टि पत्र हेर्ने·एपमै हस्ताक्षर';

  @override
  String get settleTitle => 'भुक्तानी';

  @override
  String get bizMenuSettleDesc => 'कामदारअनुसार बाँकी·भुक्तानी गर्ने';

  @override
  String get workerTitle => 'कामदार·काम दिने';

  @override
  String get bizMenuWorkerDesc => 'कामदार खोज्ने·जोड्ने·काम दिने';

  @override
  String get jobTitle => 'काम आदेश सूची';

  @override
  String get bizMenuJobDesc => 'तालिका·चलिरहेको·सकिएको स्थिति हेर्ने';

  @override
  String get safetyTitle => 'सुरक्षा';

  @override
  String get bizMenuSafetyDesc => 'सुरक्षा रिपोर्ट PDF·भर्खरका सुरक्षा रेकर्ड';

  @override
  String bizLoadFailed(String error) {
    return 'लोड गर्न सकिएन: $error';
  }

  @override
  String get inboxEmpty => 'कुनै पुष्टि पत्र आएको छैन';

  @override
  String get inboxStatusSigned => 'हस्ताक्षर भयो';

  @override
  String get inboxStatusPending => 'हस्ताक्षर बाँकी';

  @override
  String get jobStatusScheduled => 'तालिका';

  @override
  String get jobStatusInProgress => 'चलिरहेको';

  @override
  String get jobStatusDone => 'सकियो';

  @override
  String get jobEmpty => 'यस महिना कुनै काम आदेश छैन';

  @override
  String get jobAccepted => 'स्वीकृत';

  @override
  String get jobAcceptPending => 'स्वीकृति बाँकी';

  @override
  String safetyReportOpenFailed(String error) {
    return 'रिपोर्ट खोल्न सकिएन: $error';
  }

  @override
  String get safetyReportTitle => 'सुरक्षा व्यवस्थापन पालना रिपोर्ट';

  @override
  String get safetyReportDesc =>
      'अवस्था जाँच·कागजात मान्यता·गर्मी सूचना रेकर्ड मासिक PDF मा हेर्नुहोस्।';

  @override
  String safetyOpenReport(String month) {
    return '$month को रिपोर्ट खोल्नुहोस्';
  }

  @override
  String get safetyHeatNotice =>
      'गर्मी चेतावनी हुँदा जोडिएका कामदारलाई स्वतः सुरक्षा सूचना पठाइन्छ र रेकर्ड रहन्छ।';

  @override
  String settlePaidSnack(String name, String amount) {
    return '$name लाई $amount भुक्तानी भयो';
  }

  @override
  String settlePayFailed(String error) {
    return 'भुक्तानी असफल: $error';
  }

  @override
  String get settleEmpty => 'यस महिना बाँकी भुक्तानी छैन';

  @override
  String settleEntryCount(int count) {
    return '$count वटा';
  }

  @override
  String get settlePaidDone => 'भुक्तानी भयो';

  @override
  String settlePayAmount(String amount) {
    return '$amount भुक्तानी';
  }

  @override
  String workerSearchFailed(String error) {
    return 'खोज असफल: $error';
  }

  @override
  String workerConnectRequested(String name) {
    return '$name लाई जडान अनुरोध पठाइयो।';
  }

  @override
  String workerRequestFailed(String error) {
    return 'अनुरोध असफल: $error';
  }

  @override
  String get workerSearchHint => 'कामदारको फोन नम्बरले खोज्नुहोस्';

  @override
  String get workerSearchButton => 'खोज्नुहोस्';

  @override
  String get workerConnectButton => 'जडान अनुरोध';

  @override
  String get workerConnectedHeading => 'जोडिएका कामदार';

  @override
  String get workerNoneConnected => 'अहिलेसम्म जोडिएको कामदार छैन';

  @override
  String get workerStatusConnected => 'जोडियो';

  @override
  String get workerStatusPending => 'अनुरोध पर्खाइमा';

  @override
  String get workerJobButton => 'काम दिने';

  @override
  String get workerAccept => 'स्वीकार';

  @override
  String get workerJobSent => 'काम आदेश पठाइयो। कामदारलाई सूचना जान्छ।';

  @override
  String jobFormTitle(String name) {
    return '$name लाई काम दिने';
  }

  @override
  String get jobFormSiteHint => 'साइट (जस्तै: Banpo Xi रिमोडेलिङ)';

  @override
  String get jobRateDaily => 'दैनिक';

  @override
  String get jobRateHourly => 'घण्टा';

  @override
  String get jobRatePerCase => 'प्रतिकाम';

  @override
  String get jobFormRateHint => 'दर (KRW)';

  @override
  String get jobFormSubmit => 'काम आदेश पठाउनुहोस्';

  @override
  String jobCreateFailed(String error) {
    return 'आदेश पठाउन सकिएन: $error';
  }

  @override
  String get bizConfirmTitle => 'कामको पुष्टि पत्र';

  @override
  String get bizSignErrSign => 'कृपया हस्ताक्षर गर्नुहोस्।';

  @override
  String get bizSignErrName => 'हस्ताक्षर गर्नेको नाम लेख्नुहोस्।';

  @override
  String get bizSignDone => 'हस्ताक्षर पूरा भयो। (SIGNED)';

  @override
  String bizSignFailed(String error) {
    return 'हस्ताक्षर असफल: $error';
  }

  @override
  String get bizStampDefault => 'कामको पुष्टि पत्र · WORKON';

  @override
  String get bizStampSigned => 'हस्ताक्षर भयो · WORKON';

  @override
  String get bizLineCounterpart => 'अर्को पक्ष';

  @override
  String get bizLineRateType => 'दर प्रकार';

  @override
  String bizSignedBadge(String name, String at) {
    return '$name ले हस्ताक्षर · $at';
  }

  @override
  String get bizSignInAppTitle => 'एपमै हस्ताक्षर गर्नुहोस्';

  @override
  String get bizSignInAppDesc =>
      'तल हस्ताक्षर गर्नुभयो भने कामदारलाई तुरुन्तै पठाइन्छ र पुष्टि पत्र अन्तिम हुन्छ।';

  @override
  String get bizSignerNameLabel => 'हस्ताक्षर गर्नेको नाम';

  @override
  String get bizSignRedraw => 'फेरि हस्ताक्षर गर्नुहोस्';

  @override
  String get bizSignSubmit => 'हस्ताक्षर गरी पुष्टि गर्नुहोस्';

  @override
  String get confNoCopySource => 'सार्नका लागि पुरानो पुष्टि पत्र छैन।';

  @override
  String get confCopyPrevious => 'पुरानो पुष्टि पत्र सार्नुहोस्';

  @override
  String get confFormTitle => 'कामको पुष्टि पत्र लेख्नुहोस्';

  @override
  String get confSiteHint => 'जस्तै) रिभरसाइड टावर, खण्ड ३';

  @override
  String get confWorkHint => 'तपाईंले गरेको कामको विवरण लेख्नुहोस्';

  @override
  String get confRateType => 'दर प्रकार';

  @override
  String get confRateDaily => 'दैनिक';

  @override
  String get confRateHourly => 'घण्टामा';

  @override
  String get confRatePerCase => 'प्रति काम';

  @override
  String get confPricePerCase => 'प्रति काम दर';

  @override
  String get confPriceGongsu => 'gongsu दर (१ gongsu = १ दिन)';

  @override
  String get confQtyHours => 'घण्टा';

  @override
  String get confQtyCases => 'संख्या';

  @override
  String get confQtyDays => 'दिन';

  @override
  String get confErrGongsu =>
      'gongsu ०.१ को दरमा हाल्नुहोस् (जस्तै: ०.५, १.५)।';

  @override
  String get confErrHours => '१ वा बढी घण्टा हाल्नुहोस्।';

  @override
  String get confErrCases => '१ वा बढी संख्या हाल्नुहोस्।';

  @override
  String get confErrDays => '१ वा बढी दिन हाल्नुहोस्।';

  @override
  String get confDueDate => 'भुक्तानी पाउने अनुमानित मिति (वैकल्पिक)';

  @override
  String get confNotSet => 'सेट गरिएको छैन';

  @override
  String get confSaveSend => 'सेभ गरी पठाउनुहोस्';

  @override
  String get confSaveHint => 'सेभ गर्नेबित्तिकै खातामा जान्छ · लिंकबाट पठाइन्छ';

  @override
  String get confStartTime => 'सुरु समय';

  @override
  String get confEndTime => 'अन्त्य समय';

  @override
  String get confOrdererCompany => 'काम दिने (कम्पनी)';

  @override
  String get confLinkedBiz => 'जोडिएको व्यवसाय';

  @override
  String get confManualEntry => 'आफैं लेख्नुहोस्';

  @override
  String get confSelectBiz => 'जोडिएको व्यवसाय छान्नुहोस्';

  @override
  String get confCompanyHint => 'कम्पनी / साइट सम्पर्कको नाम';

  @override
  String get confContactHint => 'सम्पर्क व्यक्ति / फोन (वैकल्पिक)';

  @override
  String get confEquipSection => 'उपकरण खण्ड';

  @override
  String get confEquipAutoInclude => 'पुष्टि पत्रमा स्वतः थपिन्छ';

  @override
  String get confEquipName => 'उपकरणको नाम';

  @override
  String get confVehicleNo => 'गाडी नम्बर';

  @override
  String get confUnitPrice => 'दर';

  @override
  String get confQuantity => 'परिमाण';

  @override
  String get confAddExtra => 'ओभरटाइम · रात थप्नुहोस्';

  @override
  String get confSavedLinked => 'सेभ भयो · जोडिएको व्यवसायमा पठाइयो।';

  @override
  String get confSavedBook => 'सेभ भयो · खातामा दर्ता भयो।';

  @override
  String get confDraftQueued =>
      'ड्राफ्टमा सेभ भयो — इन्टरनेट आएपछि स्वतः पठाइन्छ।';

  @override
  String confSaveFailed(String message) {
    return 'सेभ हुन सकेन: $message';
  }

  @override
  String get confRestoreTitle => 'नसकिएको लेखाइ छ।';

  @override
  String get confRestore => 'फिर्ता ल्याउनुहोस्';

  @override
  String get confDetailTitle => 'कामको पुष्टि पत्र';

  @override
  String get confSentLinked => 'जोडिएको व्यवसायमा पठाइयो।';

  @override
  String confSendFailed(String message) {
    return 'पठाउन सकिएन: $message';
  }

  @override
  String get confReshare => 'फेरि सेयर गर्नुहोस्';

  @override
  String get confSendToLinked => 'जोडिएको व्यवसायमा पठाइन्छ';

  @override
  String get confSendViaShare =>
      'सेयर सिट (KakaoTalk आदि) बाट लिंक पठाउन सकिन्छ';

  @override
  String get confCounterparty => 'अर्को पक्ष';

  @override
  String get confSentWaitingSign => 'पठाइयो · अर्को पक्षको हस्ताक्षर पर्खँदै';

  @override
  String get confDraftBeforeSend => 'लेखियो · अझै पठाइएको छैन';

  @override
  String confShareHeader(String site) {
    return '[कामको पुष्टि पत्र] $site';
  }

  @override
  String get confShareBody => 'तलको लिंकमा विवरण हेरेर हस्ताक्षर गर्नुहोस्।';

  @override
  String confShareSubject(String site) {
    return 'कामको पुष्टि पत्र · $site';
  }

  @override
  String get draftFlushNone => 'अझै पठाउन सकिएन। इन्टरनेट जाँच्नुहोस्।';

  @override
  String draftFlushSent(int n) {
    return '$n वटा पठाइयो · खातामा दर्ता भयो।';
  }

  @override
  String get draftFlushFailed => 'केही ड्राफ्ट पठाउन सकिएन। जाँच्नुहोस्।';

  @override
  String get draftTitle => 'सेभ गरिएका ड्राफ्ट';

  @override
  String get draftEmpty => 'पठाउन बाँकी ड्राफ्ट छैन।';

  @override
  String get draftHint =>
      'इन्टरनेट आएपछि स्वतः पठाइन्छ। अहिले नै पठाउन तल फेरि प्रयास गर्नुहोस्।';

  @override
  String get draftSendAll => 'अहिले सबै पठाउनुहोस्';

  @override
  String get draftNoSite => '(साइट लेखिएको छैन)';

  @override
  String draftCheckNeeded(String error) {
    return 'जाँच्नु पर्ने: $error';
  }

  @override
  String homeGreeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get homeToday => 'आजको तालिका';

  @override
  String get homeMonthSummary => 'यस महिना';

  @override
  String get homeCheckNeeded => 'जाँच आवश्यक';

  @override
  String homeDocExpiry(String type, String dday) {
    return '$type म्याद $dday';
  }

  @override
  String get homeDocExpirySub =>
      'कागजात वालेटमा नवीकरण गरी फेरि दर्ता गर्नुहोस्';

  @override
  String homeDraftsPending(int n) {
    return 'पठाउन बाँकी $n ड्राफ्ट';
  }

  @override
  String get homeDraftsError =>
      'केही ड्राफ्ट जाँच्न बाँकी · हेर्न ट्याप गर्नुहोस्';

  @override
  String get homeDraftsAuto =>
      'इन्टरनेट आएपछि स्वतः पठाइन्छ · हेर्न ट्याप गर्नुहोस्';

  @override
  String get homeStampDraft => 'मस्यौदा · WORKON';

  @override
  String get homeStampScheduled => 'तालिकाबद्ध · WORKON';

  @override
  String get homeTodayBadge => 'आज';

  @override
  String get homeStampToday => 'आज · WORKON';

  @override
  String get homeEmptyToday => 'आज कुनै काम तालिकामा छैन';

  @override
  String get homeEmptyTodaySub =>
      'तलको + बटनले आजको काम ३० सेकेन्डमा टिप्नुहोस्।';

  @override
  String get homeDaysWorked => 'काम गरेको दिन';

  @override
  String get homeReceivable => 'पाउनुपर्ने (बाँकी)';

  @override
  String get homeReceived => 'प्राप्त (भुक्तानी)';

  @override
  String get calViewMonth => 'महिना';

  @override
  String get calViewWeek => 'हप्ता';

  @override
  String calWorkCount(int n) {
    return '$n काम';
  }

  @override
  String get calManUnit => 'हजार';

  @override
  String get calEmptyMonth => 'यस महिना कुनै काम टिपिएको छैन।';

  @override
  String get calEmptyDay => 'यस दिन कुनै काम टिपिएको छैन।';

  @override
  String get calRecordThisDay => 'यस दिनको काम टिप्नुहोस्';

  @override
  String get ledgerTitle => 'खाता';

  @override
  String get ledgerOutstandingTotal => 'यस महिना बाँकी जम्मा';

  @override
  String ledgerWorkedThisMonth(String summary) {
    return 'यस महिना $summary काम गरियो';
  }

  @override
  String get ledgerByCompany => 'कम्पनी अनुसार';

  @override
  String ledgerCompanyCount(int n) {
    return '$n कम्पनी';
  }

  @override
  String get ledgerStamp => 'खाता · WORKON';

  @override
  String get ledgerEmptyTitle => 'यस महिनाको खाता रेकर्ड छैन';

  @override
  String get ledgerEmptySub => 'पुष्टि पत्र लेखेपछि खाता स्वतः भरिन्छ।';

  @override
  String get ledgerWriteConfirmation => 'पुष्टि पत्र लेख्नुहोस्';

  @override
  String ledgerDaysWorked(int days) {
    return '$days दिन काम';
  }

  @override
  String ledgerPaidAmount(String amount) {
    return '$amount भुक्तानी';
  }

  @override
  String ledgerStatementFail(String error) {
    return 'विवरण खोल्न सकिएन: $error';
  }

  @override
  String get ledgerMonthlyStatement => 'मासिक विवरण PDF';

  @override
  String get ledgerRemaining => 'बाँकी रकम';

  @override
  String get ledgerWorkHistory => 'कामको विवरण';

  @override
  String ledgerBilled(String amount) {
    return 'बिल $amount';
  }

  @override
  String ledgerDeposited(String amount) {
    return 'भुक्तानी $amount';
  }

  @override
  String get ledgerPaymentSaved => 'भुक्तानी टिपियो।';

  @override
  String ledgerPaymentFail(String message) {
    return 'असफल: $message';
  }

  @override
  String get ledgerRecordPayment => 'भुक्तानी टिप्नुहोस्';

  @override
  String ledgerRemainingAmount(String amount) {
    return 'बाँकी $amount';
  }

  @override
  String get ledgerPaymentAmount => 'भुक्तानी रकम';

  @override
  String get ledgerWonSuffix => '₩';

  @override
  String get ledgerFull => 'पूरै';

  @override
  String get ledgerHalf => 'आधा';

  @override
  String get ledgerRecordPaymentBtn => 'भुक्तानी टिप्नुहोस्';

  @override
  String get taxTitle => 'कर बिजक तयारी';

  @override
  String taxSupplierPrefix(String name) {
    return 'आपूर्तिकर्ता · $name';
  }

  @override
  String get taxNoBizName => '(व्यवसायको नाम छैन)';

  @override
  String taxBizNumberLine(String number) {
    return 'व्यवसाय नं. $number';
  }

  @override
  String get taxHometaxGuide =>
      'कपी गरेको सामग्री कर बिजक जारी गर्दा Hometax (hometax.go.kr) मा टाँस्नुहोस्। जारी गरेपछि \"जारी भयो भनी चिन्ह लगाउनुहोस्\" थिच्नुहोस्, अनि सूचीबाट हट्छ।';

  @override
  String get taxEmptyTitle => 'जारी गर्नुपर्ने पुष्टि पत्र छैन।';

  @override
  String get taxEmptySubtitle =>
      'यहाँ हस्ताक्षर भइसकेका (SIGNED) र जारी नभएका पुष्टि पत्र मात्र देखिन्छन्।';

  @override
  String get taxStamp => 'कर बिजक · WORKON';

  @override
  String get taxSupplierPromptTitle => 'पहिले व्यवसायको जानकारी भर्नुहोस्';

  @override
  String get taxSupplierPromptDesc =>
      'कर बिजकका लागि आपूर्तिकर्ता (तपाईं) को व्यवसाय नम्बर र नाम चाहिन्छ।';

  @override
  String get taxEnterBizInfo => 'व्यवसाय जानकारी भर्नुहोस्';

  @override
  String get taxCopiedSnack => 'कपी भयो · Hometax मा टाँस्नुहोस्।';

  @override
  String get taxMarkedSnack => 'जारी भयो भनी चिन्ह लगाइयो · सूचीबाट हटाइयो।';

  @override
  String get taxAlreadyMarkedSnack =>
      'यो वस्तु पहिले नै जारी भनी चिन्ह लगाइएको छ।';

  @override
  String taxMarkFailed(String msg) {
    return 'चिन्ह लगाउन सकिएन: $msg';
  }

  @override
  String taxBuyerBizLine(String number, int count) {
    return 'व्यवसाय नं. $number · $count वस्तु';
  }

  @override
  String get taxNotRegistered => '(दर्ता छैन)';

  @override
  String get taxSupplyAmount => 'आपूर्ति रकम';

  @override
  String get taxGrandTotal => 'जम्मा रकम';

  @override
  String get taxCopy => 'कपी';

  @override
  String get taxMarkIssued => 'जारी भयो भनी चिन्ह';

  @override
  String get taxRegisteredBadge => 'दर्ता भएको';

  @override
  String get taxCheckNeeded => 'जाँच चाहिन्छ';

  @override
  String get bizinfoTitle => 'व्यवसाय जानकारी';

  @override
  String get bizinfoDesc =>
      'यो कर बिजक जारी गर्न प्रयोग हुने आपूर्तिकर्ता (तपाईं) को जानकारी हो।';

  @override
  String get bizinfoBizNumberLabel => 'व्यवसाय दर्ता नम्बर';

  @override
  String get bizinfoBizNameLabel => 'व्यवसायको नाम';

  @override
  String get bizinfoBizNameHint => 'व्यवसायको नाम (कम्पनी)';

  @override
  String get bizinfoAddressLabel => 'व्यवसाय ठेगाना (वैकल्पिक)';

  @override
  String get bizinfoAddressHint => 'व्यवसाय ठेगाना';

  @override
  String get bizinfoSavedSnack => 'व्यवसाय जानकारी सुरक्षित भयो।';

  @override
  String bizinfoSaveFailed(String msg) {
    return 'सुरक्षित गर्न सकिएन: $msg';
  }

  @override
  String get walletTitle => 'कागजात वालेट';

  @override
  String walletSelectedCount(int n) {
    return '$n छानियो';
  }

  @override
  String get walletAddDoc => 'कागजात थप्नुहोस्';

  @override
  String get walletMaskPromptTitle => 'व्यक्तिगत जानकारी ढाक्ने?';

  @override
  String get walletMaskPromptBody =>
      'नागरिकता नम्बर, ठेगाना जस्ता संवेदनशील जानकारी ढाके सुरक्षित रूपमा साझा गर्न सकिन्छ।';

  @override
  String get walletLater => 'पछि';

  @override
  String get walletMaskEdit => 'मास्किङ सम्पादन';

  @override
  String walletExpiredTitle(String type) {
    return '$type म्याद सकियो';
  }

  @override
  String walletExpiringTitle(String type, String dday) {
    return '$type म्याद $dday';
  }

  @override
  String walletExpiringMultiSub(int n) {
    return '$n कागजात म्याद सकिन लाग्यो — नवीकरण गरी फेरि दर्ता गर्नुहोस्';
  }

  @override
  String get walletRenewHint => 'नवीकरण गरी फेरि दर्ता गर्नुहोस्';

  @override
  String get walletEmptyTitle => 'अहिलेसम्म कुनै कागजात छैन';

  @override
  String get walletEmptySub =>
      'प्रमाणपत्र, बीमा, जाँच प्रमाणपत्र दर्ता गरी म्याद व्यवस्थापन गर्नुहोस्';

  @override
  String walletShareMessage(int count, int days, String url) {
    return '[작업온] $count कागजात पठाउँदै छु।\nतलको लिंकमा हेर्नुहोस् ($days दिनसम्म मान्य)।\n$url';
  }

  @override
  String get walletShareSubject => '작업온 कागजात साझेदारी';

  @override
  String walletShareFailed(String error) {
    return 'साझा गर्न सकिएन: $error';
  }

  @override
  String walletSendBundle(int count) {
    return '$count वटा सँगै पठाउनुहोस्';
  }

  @override
  String get walletBundleSend => 'सेट पठाउनुहोस्';

  @override
  String get walletValidPeriod => 'म्याद';

  @override
  String get walletMaskedInfo =>
      'ढाकिएको प्रति भएका कागजात व्यक्तिगत जानकारी लुकाएर पठाइन्छ।';

  @override
  String get walletUnmaskedInfo =>
      'ढाकिएको प्रति नभए मूल कागजात जस्ताको तस्तै पठाइन्छ। विवरणमा गएर ढाक्न सकिन्छ।';

  @override
  String get walletMakeLinkShare => 'लिंक बनाएर साझा गर्नुहोस्';

  @override
  String docOpenFailed(String error) {
    return 'खोल्न सकिएन: $error';
  }

  @override
  String docUpdateFailed(String error) {
    return 'अद्यावधिक गर्न सकिएन: $error';
  }

  @override
  String get docDeleteConfirmTitle => 'यो कागजात मेट्ने?';

  @override
  String get docDeleteConfirmBody => 'यो कागजात र यसको साझा लिंक सँगै मेटिन्छ।';

  @override
  String docDeleteFailed(String error) {
    return 'मेट्न सकिएन: $error';
  }

  @override
  String get docOpenPdf => 'PDF खोल्नुहोस्';

  @override
  String get docHasMask => 'ढाकिएको प्रति छ';

  @override
  String get docExpiryDate => 'म्याद मिति';

  @override
  String get docNone => 'छैन';

  @override
  String get docIssuedDate => 'जारी मिति';

  @override
  String get docReMask => 'मास्किङ फेरि सम्पादन';

  @override
  String get docMaskEdit => 'व्यक्तिगत जानकारी ढाक्नुहोस्';

  @override
  String get docModify => 'सम्पादन';

  @override
  String get docExpired => 'म्याद सकियो';

  @override
  String docUploadFailed(String error) {
    return 'अपलोड गर्न सकिएन: $error';
  }

  @override
  String get docSourceCamera => 'क्यामेराले खिच्नुहोस्';

  @override
  String get docSourceGallery => 'ग्यालरीबाट छान्नुहोस्';

  @override
  String get docSourcePdf => 'PDF फाइल छान्नुहोस्';

  @override
  String get docInfoTitle => 'कागजात जानकारी';

  @override
  String docFilePdf(String name) {
    return 'PDF · $name';
  }

  @override
  String docFileImage(int kb) {
    return 'तस्बिर · ${kb}KB';
  }

  @override
  String get docTypeLabel => 'प्रकार';

  @override
  String get docLinkEquip => 'उपकरण जोड्नुहोस् (वैकल्पिक)';

  @override
  String get docPersonal => 'व्यक्तिगत';

  @override
  String get docPickExpiry => 'म्याद मिति छान्नुहोस् (वैकल्पिक)';

  @override
  String get docUpload => 'अपलोड';

  @override
  String get equipTitle => 'उपकरण व्यवस्थापन';

  @override
  String get equipAdd => 'उपकरण थप्नुहोस्';

  @override
  String get equipEmptyTitle => 'दर्ता भएको उपकरण छैन';

  @override
  String get equipEmptySub =>
      'एक्साभेटर, फोर्कलिफ्ट जस्ता उपकरण दर्ता गरी कागजात एकसाथ राख्नुहोस्';

  @override
  String equipDocCount(int n) {
    return '$n कागजात';
  }

  @override
  String get equipDocs => 'कागजात';

  @override
  String get equipTypeHint => 'उपकरणको प्रकार (जस्तै: एक्साभेटर)';

  @override
  String get equipVehicleHint => 'गाडी नम्बर (वैकल्पिक)';

  @override
  String get equipSpecHint => 'स्पेक (जस्तै: 06W) (वैकल्पिक)';

  @override
  String get equipSubmit => 'थप्नुहोस्';

  @override
  String get maskDoneToast =>
      'ढाकिएको प्रति बन्यो। साझा गर्दा व्यक्तिगत जानकारी लुक्छ।';

  @override
  String maskFailed(String error) {
    return 'मास्किङ गर्न सकिएन: $error';
  }

  @override
  String get maskTitle => 'व्यक्तिगत जानकारी मास्किङ';

  @override
  String get maskReset => 'रिसेट';

  @override
  String get maskGuide =>
      'ढाक्नुपर्ने ठाउँ औंलाले तानेर आयतमा छान्नुहोस्। (जस्तै: नागरिकता नम्बर, ठेगाना)';

  @override
  String maskRegionCount(int n) {
    return '$n क्षेत्र छानियो';
  }

  @override
  String get maskSave => 'ढाकिएको प्रति सुरक्षित गर्नुहोस्';

  @override
  String get wshareTitle => 'मेरो साझेदारी';

  @override
  String wshareLoadFailed(String error) {
    return 'लोड गर्न सकिएन: $error';
  }

  @override
  String get wshareEmpty => 'अहिलेसम्म कुनै कागजात सेट साझा गर्नुभएको छैन';

  @override
  String get wshareActive => 'सक्रिय';

  @override
  String get wshareInactive => 'म्याद सकियो/रद्द';

  @override
  String wshareViewCount(int n) {
    return '$n पटक हेरियो';
  }

  @override
  String get wshareReshare => 'फेरि साझा गर्नुहोस्';

  @override
  String get wshareRevoke => 'रद्द गर्नुहोस्';

  @override
  String myjobFailed(String error) {
    return 'असफल: $error';
  }

  @override
  String get myjobConditionTitle => 'स्वास्थ्य जाँच';

  @override
  String get myjobConditionBody =>
      'आज शरीर कस्तो छ? सुरक्षित कामका लागि जाँच गर्छौं।';

  @override
  String get myjobConditionBad => 'ठिक छैन';

  @override
  String get myjobConditionGood => 'ठिक छ';

  @override
  String get myjobConditionReported =>
      'तपाईंको अवस्था ठेकेदारलाई जानकारी गराइयो। धेरै जोर नगर्नुहोस्।';

  @override
  String myjobLoadFailed(String error) {
    return 'लोड गर्न सकिएन: $error';
  }

  @override
  String get myjobEmpty => 'प्राप्त काम आदेश छैन';

  @override
  String get myjobAccept => 'स्वीकार';

  @override
  String get myjobStart => 'काम सुरु';

  @override
  String get myjobComplete => 'काम पूरा';

  @override
  String get signPadHint => 'यहाँ औंलाले हस्ताक्षर गर्नुहोस्';

  @override
  String get teamMenuTitle => 'मेरो टोली';

  @override
  String get teamMenuSub =>
      'फोरम्यानको रूपमा टोली सदस्य सूची र दररेट व्यवस्थापन';

  @override
  String get teamListTitle => 'मेरो टोली';

  @override
  String get teamEmptyTitle => 'अझै कुनै टोली बनाइएको छैन';

  @override
  String get teamEmptySub =>
      'टोली बनाएर सदस्य थपेपछि टोली पुष्टिपत्र एउटै पानामा मिलाउन सकिन्छ';

  @override
  String get teamCreate => 'टोली बनाउनुहोस्';

  @override
  String get teamNameLabel => 'टोलीको नाम';

  @override
  String get teamNameHint => 'टोलीको नाम (जस्तै: पार्क फोरम्यान A टोली)';

  @override
  String get teamAddMember => 'सदस्य थप्नुहोस्';

  @override
  String get teamMembersTitle => 'सदस्यहरू';

  @override
  String get teamNoMembers => 'कृपया सदस्य थप्नुहोस्';

  @override
  String teamMemberCountLabel(int count) {
    return '$count सदस्य';
  }

  @override
  String get teamMemberLinked => 'जडान भएको';

  @override
  String get teamMemberManual => 'म्यानुअल';

  @override
  String get teamDefaultRate => 'पूर्वनिर्धारित दररेट';

  @override
  String get teamDefaultRateHint => 'पूर्वनिर्धारित दररेट (१ गोङ्सु)';

  @override
  String get teamAddByPhone => 'फोन नम्बरबाट खोज्नुहोस्';

  @override
  String get teamAddManual => 'आफैं प्रविष्ट गर्नुहोस्';

  @override
  String get teamMemberNameHint => 'नाम';

  @override
  String get teamMemberPhoneHint => 'फोन नम्बर (वैकल्पिक)';

  @override
  String get teamSearchPhoneHint => 'सदस्यको फोन नम्बर';

  @override
  String get teamSearchHint =>
      'फोन खोजीमा सहमति जनाएका दर्ता प्रयोगकर्ता मात्र भेटिन्छन्';

  @override
  String get teamSearchNoResult => 'कुनै नतिजा भेटिएन';

  @override
  String get teamMemberAdded => 'सदस्य थपियो';

  @override
  String get teamMemberExists => 'यो सदस्य पहिले नै टोलीमा छ';

  @override
  String get teamConsentRequired =>
      'फोन खोजीमा सहमति जनाएका दर्ता प्रयोगकर्ता मात्र जडान गर्न सकिन्छ';

  @override
  String get teamDeleteConfirm =>
      'यो टोली मेटाउने? पहिले नै जारी भएका पुष्टिपत्र यथावत् रहन्छन्।';

  @override
  String get teamDeleteMemberConfirm => 'यो सदस्य मेटाउने?';

  @override
  String get confTeamMode => 'टोली पुष्टिपत्र';

  @override
  String get confTeamModeSub =>
      'प्रत्येक सदस्यको गोङ्सु एउटै पानामा मिलाउनुहोस्';

  @override
  String get confTeamSelect => 'टोली छान्नुहोस्';

  @override
  String get confTeamPickTeam => 'कृपया टोली छान्नुहोस्';

  @override
  String get confTeamNoTeam => 'पहिले \'मेरो टोली\' मा टोली बनाउनुहोस्';

  @override
  String get confTeamTotal => 'टोली जम्मा';

  @override
  String get confTeamEmptyEntries => 'गोङ्सु प्रविष्ट गरेको कुनै सदस्य छैन';

  @override
  String get ledgerTeamBadge => 'टोली';

  @override
  String ledgerTeamDerived(String boss) {
    return '$boss फोरम्यान टोली काम';
  }

  @override
  String get ledgerDerivedReadonly =>
      'यो फोरम्यानले बनाएको टोली काम हो (तपाईं भुक्तानी मात्र रेकर्ड गर्न सक्नुहुन्छ)';

  @override
  String get lcKicker => 'मानक श्रम सम्झौता';

  @override
  String get lcStamp => 'मानक श्रम सम्झौता';

  @override
  String get lcParties => 'सम्झौताका पक्षहरू';

  @override
  String get lcEmployer => 'रोजगारदाता (पक्ष क)';

  @override
  String get lcWorkerParty => 'कामदार (पक्ष ख)';

  @override
  String get lcBizNumber => 'व्यवसाय दर्ता नम्बर';

  @override
  String get lcPeriod => 'श्रम सम्झौता अवधि';

  @override
  String get lcPeriodOpen => 'निश्चित अवधि नभएको · दैनिक';

  @override
  String get lcWorkplace => 'कार्यस्थल';

  @override
  String get lcJob => 'कामको विवरण';

  @override
  String get lcWorkTime => 'कार्य समय';

  @override
  String get lcBreak => 'विश्राम';

  @override
  String get lcWage => 'ज्याला';

  @override
  String get lcWageDaily => 'दैनिक ज्याला';

  @override
  String get lcWageHourly => 'घण्टा ज्याला';

  @override
  String get lcPayday => 'ज्याला भुक्तानी दिन';

  @override
  String get lcPayMethod => 'भुक्तानी विधि';

  @override
  String get lcAllowance => 'भत्ता';

  @override
  String get lcWeeklyHoliday =>
      'साप्ताहिक बिदा भत्ता: हप्ताको तोकिएको कार्यदिन पूर्ण उपस्थित भएमा साप्ताहिक बिदा भत्ता दिइन्छ।';

  @override
  String get lcWeeklyHolidayNone =>
      'साप्ताहिक बिदा भत्ता: लागू हुँदैन (दैनिक/अल्पकालीन)।';

  @override
  String get lcOvertime =>
      'ओभरटाइम, रात्री र बिदाको काममा श्रम ऐन अनुसार सामान्य ज्यालाको ५०% थप दिइन्छ।';

  @override
  String get lcOvertimeNone =>
      'ओभरटाइम/रात्री/बिदा थप भत्ता: छुट्टै तोकिएको छैन।';

  @override
  String get lcInsurance => 'सामाजिक बीमा लागू';

  @override
  String get lcInsEmployment => 'रोजगार बीमा';

  @override
  String get lcInsHealth => 'स्वास्थ्य बीमा';

  @override
  String get lcInsPension => 'राष्ट्रिय पेन्सन';

  @override
  String get lcInsAccident => 'दुर्घटना बीमा';

  @override
  String get lcApplied => 'लागू';

  @override
  String get lcNotApplied => 'लागू छैन';

  @override
  String get lcSpecial => 'विशेष सर्त';

  @override
  String get lcMasterNote =>
      'यस सम्झौताको मूल प्रति कोरियाली भाषामा हो। अनुवाद बुझ्न सहयोगका लागि मात्र हो; व्याख्यामा भिन्नता भएमा कोरियाली प्रति मान्य हुन्छ।';

  @override
  String get lcEmployerSigned => 'रोजगारदाताले हस्ताक्षर गर्नुभयो';

  @override
  String get lcMenuDesc => 'कामदारसँग विद्युतीय हस्ताक्षरमा सम्झौता';

  @override
  String get lcListEmptyTitle => 'अहिलेसम्म कुनै सम्झौता छैन';

  @override
  String get lcListEmptySub => 'आफ्नो कामदारसँग श्रम सम्झौता बनाउनुहोस्';

  @override
  String get lcNewContract => 'नयाँ सम्झौता';

  @override
  String get lcStatusDraft => 'मस्यौदा';

  @override
  String get lcStatusSent => 'पठाइयो';

  @override
  String get lcStatusSigned => 'हस्ताक्षरित';

  @override
  String get lcWorkerSection => 'कामदार';

  @override
  String get lcWorkerByPhone => 'फोनबाट खोज्नुहोस्';

  @override
  String get lcWorkerManual => 'हातैले लेख्नुहोस्';

  @override
  String get lcWorkerNameHint => 'कामदारको नाम';

  @override
  String get lcWorkerPhoneHint => 'कामदारको फोन (वैकल्पिक)';

  @override
  String get lcSearchPhoneHint => 'कामदारको फोन';

  @override
  String get lcSearchHint => 'फोन खोजीमा सहमत भएका प्रयोगकर्ता मात्र भेटिन्छन्';

  @override
  String get lcSearchNoResult => 'कुनै परिणाम छैन';

  @override
  String get lcWorkerLinkedBadge => 'जोडिएको';

  @override
  String get lcStartDate => 'सुरु मिति';

  @override
  String get lcEndDate => 'अन्त्य मिति (वैकल्पिक)';

  @override
  String get lcEndDateNotSet => 'तोकिएको छैन';

  @override
  String get lcWorkplaceHint => 'उदा) गाङनाम A साइट';

  @override
  String get lcJobHint => 'उदा) रिबार काम';

  @override
  String get lcBreakHint => 'उदा) 12:00~13:00';

  @override
  String get lcWageAmountHint => 'रकम';

  @override
  String get lcPaydayHint => 'उदा) हरेक महिना २५';

  @override
  String get lcPayMethodHint => 'उदा) बैंक ट्रान्सफर';

  @override
  String get lcWeeklyHolidaySwitch => 'साप्ताहिक बिदा भत्ता';

  @override
  String get lcOvertimeSwitch => 'ओभरटाइम/रात्री/बिदा थप भत्ता';

  @override
  String get lcSpecialHint => 'विशेष सर्त (वैकल्पिक)';

  @override
  String get lcSaveCommon => 'बारम्बार प्रयोग हुने मान सुरक्षित';

  @override
  String get lcSaveCommonSub => 'अर्को पटक स्वतः भरिन्छ';

  @override
  String get lcSubmit => 'सम्झौता बनाउनुहोस्';

  @override
  String get lcCreated => 'सम्झौता बन्यो';

  @override
  String get lcDetailTitle => 'सम्झौता';

  @override
  String get lcSignEmployerTitle => 'मेरो हस्ताक्षर (रोजगारदाता)';

  @override
  String get lcSignEmployerDesc => 'हस्ताक्षर गरेपछि कामदारलाई पठाउन सकिन्छ';

  @override
  String get lcSignerNameLabel => 'हस्ताक्षरकर्ताको नाम';

  @override
  String get lcSignRedraw => 'फेरि कोर्नुहोस्';

  @override
  String get lcSignSubmit => 'हस्ताक्षर गर्नुहोस्';

  @override
  String get lcSigned => 'हस्ताक्षर पूरा भयो';

  @override
  String get lcSignErrPad => 'कृपया पहिले हस्ताक्षर गर्नुहोस्';

  @override
  String get lcSignErrName => 'कृपया हस्ताक्षरकर्ताको नाम लेख्नुहोस्';

  @override
  String get lcSend => 'कामदारलाई पठाउनुहोस्';

  @override
  String get lcSentLinked => 'कामदारलाई पठाइयो';

  @override
  String get lcSentShare => 'लिङ्क साझा गरेर पठाउनुहोस्';

  @override
  String get lcShareBody => 'तलको लिङ्कमा सम्झौता हेरेर हस्ताक्षर गर्नुहोस्';

  @override
  String get lcViewPdf => 'PDF हेर्नुहोस्';

  @override
  String get lcDeleteConfirm => 'यो सम्झौता मेटाउने?';

  @override
  String get lcDeleted => 'मेटाइयो';

  @override
  String get lcWaitingWorker => 'कामदारको हस्ताक्षर पर्खँदै';

  @override
  String get lcMyContractsTitle => 'मेरा सम्झौता';

  @override
  String get lcMyContractsSub => 'प्राप्त सम्झौता हेर्नुहोस्·हस्ताक्षर';

  @override
  String get lcMyEmptyTitle => 'कुनै सम्झौता प्राप्त भएको छैन';

  @override
  String get lcMyEmptySub => 'रोजगारदाताले पठाएको सम्झौता यहाँ देखिन्छ';

  @override
  String get lcWorkerSignTitle => 'मेरो हस्ताक्षर (कामदार)';

  @override
  String get lcWorkerSignDesc => 'कृपया हेरेर हस्ताक्षर गर्नुहोस्';

  @override
  String get lcAlreadySigned => 'पहिले नै हस्ताक्षर गरिएको';

  @override
  String lcCreateFailed(String msg) {
    return 'सम्झौता सुरक्षित गर्न सकिएन: $msg';
  }

  @override
  String lcSignFailed(String msg) {
    return 'हस्ताक्षर गर्न सकिएन: $msg';
  }

  @override
  String lcSendFailed(String msg) {
    return 'पठाउन सकिएन: $msg';
  }

  @override
  String lcPdfFailed(String msg) {
    return 'PDF खोल्न सकिएन: $msg';
  }

  @override
  String get tbmMenuTitle => 'TBM रेकर्ड';

  @override
  String get tbmMenuDesc => 'सुरक्षा बैठक · जोखिम र उपस्थिति पुष्टि';

  @override
  String get tbmMyTitle => 'प्राप्त TBM';

  @override
  String get tbmMySub => 'मेरो सुरक्षा रेकर्ड · पुष्टि';

  @override
  String get tbmTitle => 'TBM (सुरक्षा बैठक)';

  @override
  String get tbmStamp => 'T B M';

  @override
  String get tbmListEmptyTitle => 'अहिलेसम्म TBM छैन';

  @override
  String get tbmListEmptySub => 'साइट सुरक्षा बैठक रेकर्ड गर्नुहोस्।';

  @override
  String get tbmNew => 'नयाँ TBM';

  @override
  String get tbmFormTitle => 'TBM लेख्नुहोस्';

  @override
  String get tbmSite => 'साइट';

  @override
  String get tbmSiteHint => 'उदा: साइट A, तेस्रो तल्ला';

  @override
  String get tbmDate => 'मिति र समय';

  @override
  String get tbmHazards => 'जोखिम';

  @override
  String get tbmHazardsHint => 'चिप छान्नुहोस् वा आफैँ लेख्नुहोस्';

  @override
  String get tbmAddCustom => 'आफ्नै';

  @override
  String get tbmCustomHint => 'जोखिम लेख्नुहोस्';

  @override
  String get tbmMeasures => 'सुरक्षा उपाय';

  @override
  String get tbmMeasuresHint => 'उदा: सेफ्टी बेल्ट, गाइड राख्नु';

  @override
  String get tbmNotes => 'टिप्पणी';

  @override
  String get tbmNotesHint => 'टिप्पणी (वैकल्पिक)';

  @override
  String get tbmAttendees => 'उपस्थित';

  @override
  String get tbmSelectWorkers => 'जोडिएका कामदार छान्नुहोस्';

  @override
  String get tbmNoConnections => 'जोडिएको कामदार छैन';

  @override
  String get tbmAddAttendeeManual => 'हातैले उपस्थित थप्नुहोस्';

  @override
  String get tbmAttendeeNameHint => 'उपस्थितको नाम';

  @override
  String get tbmPhotos => 'साइट फोटो';

  @override
  String get tbmAddPhoto => 'फोटो थप्नुहोस्';

  @override
  String get tbmSave => 'TBM सुरक्षित';

  @override
  String get tbmSaved => 'TBM रेकर्ड भयो';

  @override
  String tbmSaveFailed(String msg) {
    return 'सुरक्षित भएन: $msg';
  }

  @override
  String get tbmNeedHazard => 'कम्तीमा एउटा जोखिम छान्नुहोस्';

  @override
  String get tbmNeedSite => 'साइटको नाम लेख्नुहोस्';

  @override
  String get tbmPresetMine => 'मेरो प्रिसेट';

  @override
  String get tbmPresetAddChip => '＋ प्रिसेट सुरक्षित';

  @override
  String get tbmPresetAddTitle => 'बारम्बार वाक्यांश सुरक्षित';

  @override
  String get tbmPresetDeleted => 'प्रिसेट मेटियो';

  @override
  String get tbmDetailTitle => 'TBM विवरण';

  @override
  String get tbmAttendeesStatus => 'उपस्थिति पुष्टि स्थिति';

  @override
  String get tbmAcked => 'पुष्टि भयो';

  @override
  String get tbmNotAcked => 'बाँकी';

  @override
  String tbmAckSummary(int att, int ack) {
    return '$att उपस्थित · $ack पुष्टि';
  }

  @override
  String get tbmReadonly => 'बनाएको दिनपछि पढ्ने मात्र';

  @override
  String get tbmEdit => 'सम्पादन';

  @override
  String get tbmDeleteConfirm => 'यो TBM मेट्ने?';

  @override
  String get tbmDeleted => 'मेटियो';

  @override
  String get tbmSaveUpdated => 'अपडेट भयो';

  @override
  String tbmPhotoFailed(String msg) {
    return 'फोटो असफल: $msg';
  }

  @override
  String get tbmReceivedEmpty => 'कुनै TBM छैन';

  @override
  String get tbmAckButton => 'TBM पुष्टि';

  @override
  String get tbmAckDone => 'पुष्टि भयो';

  @override
  String tbmAckFailed(String msg) {
    return 'पुष्टि भएन: $msg';
  }

  @override
  String get tbmAlreadyAcked => 'पहिले नै पुष्टि';

  @override
  String tbmPhotoCount(int n) {
    return '$n फोटो';
  }

  @override
  String get tbmHzHeavyEquip => 'भारी उपकरण थिचाइ/ठक्कर';

  @override
  String get tbmHzFallHeight => 'उचाइबाट खस्ने';

  @override
  String get tbmHzHeatIllness => 'तातो/लू लाग्ने';

  @override
  String get tbmHzElectric => 'करेन्ट लाग्ने';

  @override
  String get tbmHzFallingObject => 'खस्ने वस्तु';

  @override
  String get tbmHzCollapse => 'भत्किने/पुरिने';

  @override
  String get tbmHzFire => 'आगलागी/विस्फोट';

  @override
  String get tbmHzDustNoise => 'धुलो/आवाज';

  @override
  String get tbmHzSlipTrip => 'चिप्लने/ठेस';

  @override
  String get tbmHzConfined => 'बन्द ठाउँ निसासिने';

  @override
  String get incomeReportMenuTitle => 'आय रिपोर्ट';

  @override
  String get incomeReportMenuSub => 'वार्षिक आय·बाँकी·गोङ्सु एकै ठाउँमा';

  @override
  String get incomeReportTitle => 'आय रिपोर्ट';

  @override
  String incomeReportYear(String year) {
    return '$year साल';
  }

  @override
  String get incomeReportTotalBilled => 'कुल बिल';

  @override
  String get incomeReportTotalPaid => 'कुल प्राप्त';

  @override
  String get incomeReportTotalOutstanding => 'कुल बाँकी';

  @override
  String get incomeReportTotalDays => 'काम गरेका दिन';

  @override
  String get incomeReportTotalGongsu => 'कुल गोङ्सु';

  @override
  String get incomeReportTeamPayout => 'टोली भुक्तानी';

  @override
  String get incomeReportNetBilled => 'खुद आय (सन्दर्भ)';

  @override
  String get incomeReportNetHint =>
      'बिल − सदस्य भुक्तानी (फोरम्यानको आफ्नो भाग)';

  @override
  String get incomeReportMonthlyTrend => 'मासिक प्रवृत्ति';

  @override
  String incomeReportPeakLabel(String amount) {
    return 'उच्च $amount';
  }

  @override
  String get incomeReportByCompany => 'पक्ष अनुसार';

  @override
  String incomeReportEntryCount(int n) {
    return '$n वटा';
  }

  @override
  String incomeReportOutstandingShort(String amount) {
    return 'बाँकी $amount';
  }

  @override
  String get incomeReportTaxTitle => 'आयकर मार्गदर्शन';

  @override
  String get incomeReportTaxL1 =>
      'समग्र आयकर हरेक वर्ष मे महिनामा अघिल्लो वर्षको आयको लागि दाखिला र भुक्तानी गरिन्छ।';

  @override
  String get incomeReportTaxL2 =>
      'व्यक्तिगत सेवा व्यवसाय आयमा भुक्तानी हुँदा प्रायः ३.३% अग्रिम कट्टी हुन्छ।';

  @override
  String get incomeReportTaxL3 =>
      'कट्टी भएको कर मे महिनाको दाखिलामा मिलान (फिर्ता वा थप भुक्तानी) हुन्छ।';

  @override
  String get incomeReportTaxL4 =>
      'खर्च र पुष्टिपत्र·विवरण राख्दा दाखिलामा सहयोग पुग्छ।';

  @override
  String get incomeReportTaxL5 =>
      'यो सामान्य जानकारी हो, कर सल्लाह होइन। सही दाखिलाका लागि कर विशेषज्ञ वा Hometax हेर्नुहोस्।';

  @override
  String get incomeReportSavePdf => 'PDF सुरक्षित / साझा';

  @override
  String incomeReportPdfFail(String msg) {
    return 'रिपोर्ट खोल्न सकिएन: $msg';
  }

  @override
  String get incomeReportEmptyTitle => 'अझै आय रेकर्ड छैन';

  @override
  String get incomeReportEmptySub =>
      'पुष्टिपत्र लेखेपछि यो रिपोर्टमा आय देखिन्छ।';

  @override
  String get ledgerAutoRemind => 'स्वतः भुक्तानी सम्झाउने';

  @override
  String get ledgerAutoRemindHint =>
      'समयसीमा पछि स्वतः भुक्तानी सम्झौटो पठाउँछ';

  @override
  String get ledgerRemindNow => 'अहिले सम्झाउने पठाउनुहोस्';

  @override
  String get ledgerRemindSent => 'भुक्तानी सम्झौटो पठाइयो';

  @override
  String get ledgerRemindHistory => 'सम्झौटो इतिहास';

  @override
  String ledgerRemindHistoryItem(String date, String stage) {
    return '$date · $stage';
  }

  @override
  String get reminderStageD7 => '७ दिनको सम्झौटो';

  @override
  String get reminderStageD30 => '३० दिनको सम्झौटो';

  @override
  String get reminderStageManual => 'म्यानुअल सम्झौटो';

  @override
  String get profilePayoutSection => 'भुक्तानी खाता (सम्झौटोका लागि)';

  @override
  String get profilePayoutBank => 'बैंकको नाम';

  @override
  String get profilePayoutAccount => 'खाता नम्बर';

  @override
  String get profilePayoutHolder => 'खातावाला';

  @override
  String get profilePayoutHint =>
      'भुक्तानी सम्झौटो पठाउँदा यो खाता सँगै पठाइन्छ (वैकल्पिक)';

  @override
  String get profilePayoutSaved => 'भुक्तानी खाता सुरक्षित गरियो';

  @override
  String get badgeExcellent => 'उत्कृष्ट भुक्तानीकर्ता';

  @override
  String get badgeGood => 'राम्रो भुक्तानीकर्ता';

  @override
  String badgeAvgDays(int days) {
    return 'औसत $days दिन';
  }

  @override
  String get badgeSelfImproveGood =>
      '१५ दिनभित्र भुक्तानी गर्नुभयो भने उत्कृष्ट भुक्तानीकर्ता चिन्ह पाइन्छ';

  @override
  String get badgeSelfImproveNone =>
      'समयमै भुक्तानी गर्नुभयो भने उत्कृष्ट भुक्तानीकर्ता चिन्ह पाइन्छ';

  @override
  String badgeInsufficient(int count) {
    return '$count भुक्तानी रेकर्ड — चिन्ह मूल्यांकनका लागि थप रेकर्ड चाहिन्छ';
  }

  @override
  String badgeSampleCount(int count) {
    return 'पछिल्लो $count का आधारमा';
  }

  @override
  String get badgeSelfTitle => 'भुक्तानी विश्वसनीयता';

  @override
  String get qrCardMenuTitle => 'मेरो QR कार्ड';

  @override
  String get qrCardMenuSub => 'QR र लिंकबाट आफ्नो परिचय दिनुहोस्';

  @override
  String get qrCardTitle => 'मेरो QR कार्ड';

  @override
  String get qrCardScanHint => 'QR स्क्यान गर्दा मेरो सार्वजनिक प्रोफाइल खुल्छ';

  @override
  String qrCardViewCount(int count) {
    return '$count पटक हेरिएको';
  }

  @override
  String get qrCardIntroLabel => 'एक लाइन परिचय';

  @override
  String get qrCardIntroPlaceholder => 'जस्तै: २० वर्ष अनुभव भएको रड फोरम्यान';

  @override
  String get qrCardIntroSaved => 'परिचय सुरक्षित भयो';

  @override
  String get qrCardExposeTitle => 'कार्ड देखाउनुहोस्';

  @override
  String get qrCardExposeSub => 'अन गरेपछि QR र लिंकबाट प्रोफाइल देखिन्छ';

  @override
  String get qrCardHiddenHint =>
      'अहिले लुकाइएको छ — लिंक खोले पनि कार्ड देखिँदैन';

  @override
  String get qrCardRotate => 'लिंक पुनः जारी गर्नुहोस्';

  @override
  String get qrCardRotateConfirm =>
      'नयाँ लिंक बनाएपछि पुरानो QR र लिंक काम गर्दैन। जारी राख्ने?';

  @override
  String get qrCardRotateConfirmBtn => 'पुनः जारी';

  @override
  String get qrCardRotated => 'नयाँ कार्ड लिंक जारी भयो';

  @override
  String get qrCardDocValid => 'कागजात मान्य';

  @override
  String get qrCardDocProblem => 'जाँच गर्नुपर्ने कागजात';

  @override
  String qrCardDocExpiryLabel(String date) {
    return 'म्याद $date';
  }
}
