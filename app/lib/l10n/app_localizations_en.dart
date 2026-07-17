// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get widgetToday => 'Today';

  @override
  String get widgetNoSchedule => 'No schedule today';

  @override
  String get widgetOutstanding => 'This month due';

  @override
  String get widgetLoginPlease => 'Please log in';

  @override
  String widgetSyncedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get view => 'View';

  @override
  String get loading => 'Loading…';

  @override
  String get errorConnTitle => 'Connection problem';

  @override
  String get errorConnSubtitle =>
      'Check your internet connection and try again.';

  @override
  String get statusDeposited => 'Paid';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String collectDday(String dday) {
    return 'Collect $dday';
  }

  @override
  String get amtBase => 'Base pay';

  @override
  String get amtOvertime => 'Overtime';

  @override
  String get amtEarly => 'Early start';

  @override
  String get amtNight => 'Night';

  @override
  String get amtAllnight => 'All-night';

  @override
  String get itemOther => 'Other';

  @override
  String get baseDaily => 'Base (daily)';

  @override
  String get baseHourly => 'Base (hourly)';

  @override
  String get basePerCase => 'Base (per job)';

  @override
  String get baseGongsu => 'Base (gongsu)';

  @override
  String get unitGongsu => 'gongsu';

  @override
  String qtyGongsu(String qty) {
    return '$qty gongsu';
  }

  @override
  String vatLabel(String rate) {
    return 'VAT ($rate%)';
  }

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String daysWithGongsu(int days, String gongsu) {
    return '$days days · $gongsu gongsu';
  }

  @override
  String get moreTitle => 'More';

  @override
  String get sectionManage => 'Manage';

  @override
  String get sectionSettings => 'Settings';

  @override
  String get menuWallet => 'Document wallet';

  @override
  String get menuWalletSub =>
      'Track certificate/insurance/inspection expiry · send as a set';

  @override
  String get menuBizHome => 'Business home';

  @override
  String get menuBizMode => 'Business mode';

  @override
  String get menuBizSub =>
      'Work orders · received confirmations · settlement · safety reports';

  @override
  String get menuJobs => 'Received jobs';

  @override
  String get menuJobsSub => 'Accept, start, and complete work orders';

  @override
  String get menuTax => 'Tax invoice prep';

  @override
  String get menuTaxSub =>
      'Signed confirmations → data ready for Hometax entry';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String get menuNotificationsSub =>
      'Payments · document expiry · scheduled work · heat safety';

  @override
  String get consentTitle => 'Allow phone number search';

  @override
  String get consentSub =>
      'Businesses can find and connect with you by your number';

  @override
  String get kakaoLinkTitle => 'Link Kakao account';

  @override
  String get kakaoLinkedSub => 'Linked';

  @override
  String get kakaoLinkSub => 'Link so you can also log in with Kakao';

  @override
  String get kakaoLinked => 'Your Kakao account is linked.';

  @override
  String get kakaoNotReady => 'Kakao login is coming soon.';

  @override
  String get kakaoAlreadyLinked =>
      'This Kakao is already linked to another account.';

  @override
  String kakaoLinkFailed(String message) {
    return 'Link failed: $message';
  }

  @override
  String get kakaoLinkCanceled => 'Kakao linking was canceled.';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Log out?';

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockSub =>
      'Protect the app with biometrics or your device passcode';

  @override
  String get appLockLockedTitle => 'Locked';

  @override
  String get appLockUnlock => 'Authenticate to continue';

  @override
  String get appLockReason => 'Unlock the app';

  @override
  String get appLockUnavailable =>
      'This device doesn\'t support biometrics or a passcode lock';

  @override
  String get noName => 'No name';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get paperStamp => 'WORK CONFIRMATION';

  @override
  String get paperDate => 'Work date';

  @override
  String get paperTime => 'Time';

  @override
  String get paperSite => 'Site';

  @override
  String get paperWorker => 'Worker';

  @override
  String get paperOrderer => 'Requester';

  @override
  String get paperWork => 'Work details';

  @override
  String get paperEquipment => 'Equipment';

  @override
  String get paperGuide => 'Signal guide';

  @override
  String get paperTotal => 'Amount due';

  @override
  String get paperMemo => 'Note';

  @override
  String get paperSignHead => 'Requester signature';

  @override
  String paperSignedBy(String name) {
    return 'Signed by $name';
  }

  @override
  String shareCount(int n) {
    return '$n shared document(s)';
  }

  @override
  String shareValidUntil(String date) {
    return 'Viewable until $date';
  }

  @override
  String shareExpiry(String date) {
    return 'Expires $date';
  }

  @override
  String get shareNoExpiry => 'No expiry';

  @override
  String get shareMasked => 'Masked copy';

  @override
  String get statusTransientTitle => 'Temporary error';

  @override
  String get statusTransientMsg => 'Please try again shortly.';

  @override
  String get statusNotFoundTitle => 'Link not found';

  @override
  String get statusNotFoundMsg =>
      'The link may have expired or been revoked. Please ask the sender for a new link.';

  @override
  String get authStartWithPhone => 'Start with your phone number';

  @override
  String get authTagline =>
      'Log your work in 30 seconds and manage confirmations, ledger, and settlements automatically.';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authCodeLabel => 'Verification code';

  @override
  String get authCodeHint => '6-digit code';

  @override
  String get authDevAutofill =>
      'Dev mode: the code is filled in automatically.';

  @override
  String get authRequestCode => 'Get verification code';

  @override
  String get authVerifyStart => 'Verify & start';

  @override
  String get authReenterPhone => 'Re-enter phone number';

  @override
  String get authOr => 'or';

  @override
  String get authKakaoStart => 'Start with Kakao';

  @override
  String get authKakaoPreparing =>
      'Kakao login is coming soon. Please start with your phone number.';

  @override
  String get onbWelcome => 'Welcome!';

  @override
  String get onbNamePrompt => 'Tell us the name to show on confirmations.';

  @override
  String get onbNameLabel => 'Name';

  @override
  String get onbNameHint => 'e.g. John Smith';

  @override
  String get onbStart => 'Get started';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navLedger => 'Ledger';

  @override
  String get navMore => 'More';

  @override
  String get navWrite => 'New';

  @override
  String navDraftsSent(int n) {
    return '$n draft(s) were sent automatically.';
  }

  @override
  String navDraftsFailed(int n) {
    return 'Failed to send $n draft(s). Please check on Home.';
  }

  @override
  String get notiTitle => 'Notifications';

  @override
  String get notiEmpty => 'No notifications';

  @override
  String get notiAckDone => 'Marked as acknowledged.';

  @override
  String notiAckFailed(String error) {
    return 'Acknowledge failed: $error';
  }

  @override
  String get bizModeTitle => 'Business mode';

  @override
  String bizCreateFailed(String error) {
    return 'Failed to create: $error';
  }

  @override
  String get bizCreateHeading => 'Create a business to get started';

  @override
  String get bizCreateDesc =>
      'Connect workers, send job orders, sign confirmations, settle pay, and safety reports — all in one place.';

  @override
  String get bizNameHint => 'Business name (e.g. Daesung Construction)';

  @override
  String get bizBnoHint => 'Business number (optional)';

  @override
  String get bizCreateButton => 'Create business';

  @override
  String bizInviteCode(String code) {
    return 'Invite code $code';
  }

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get bizMenuInboxDesc =>
      'Check received confirmations, sign in the app';

  @override
  String get settleTitle => 'Settlement';

  @override
  String get bizMenuSettleDesc => 'Unpaid totals by worker, mark as paid';

  @override
  String get workerTitle => 'Workers & orders';

  @override
  String get bizMenuWorkerDesc => 'Search & connect workers, create job orders';

  @override
  String get jobTitle => 'Job orders';

  @override
  String get bizMenuJobDesc => 'View scheduled, in-progress, and done';

  @override
  String get safetyTitle => 'Safety';

  @override
  String get bizMenuSafetyDesc => 'Safety report PDF, recent safety records';

  @override
  String bizLoadFailed(String error) {
    return 'Couldn\'t load: $error';
  }

  @override
  String get inboxEmpty => 'No confirmations received';

  @override
  String get inboxStatusSigned => 'Signed';

  @override
  String get inboxStatusPending => 'Awaiting sign';

  @override
  String get jobStatusScheduled => 'Scheduled';

  @override
  String get jobStatusInProgress => 'In progress';

  @override
  String get jobStatusDone => 'Done';

  @override
  String get jobEmpty => 'No job orders this month';

  @override
  String get jobAccepted => 'Accepted';

  @override
  String get jobAcceptPending => 'Awaiting accept';

  @override
  String safetyReportOpenFailed(String error) {
    return 'Failed to open report: $error';
  }

  @override
  String get safetyReportTitle => 'Safety compliance report';

  @override
  String get safetyReportDesc =>
      'Check condition checks, document validity, and heat alert records as a monthly PDF.';

  @override
  String safetyOpenReport(String month) {
    return 'Open $month report';
  }

  @override
  String get safetyHeatNotice =>
      'During a heat warning, connected workers automatically get a safety alert and a record is kept.';

  @override
  String settlePaidSnack(String name, String amount) {
    return 'Paid $amount to $name';
  }

  @override
  String settlePayFailed(String error) {
    return 'Payment failed: $error';
  }

  @override
  String get settleEmpty => 'Nothing unpaid this month';

  @override
  String settleEntryCount(int count) {
    return '$count item(s)';
  }

  @override
  String get settlePaidDone => 'Paid';

  @override
  String settlePayAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String workerSearchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String workerConnectRequested(String name) {
    return 'Sent a connection request to $name.';
  }

  @override
  String workerRequestFailed(String error) {
    return 'Request failed: $error';
  }

  @override
  String get workerSearchHint => 'Search by worker phone number';

  @override
  String get workerSearchButton => 'Search';

  @override
  String get workerConnectButton => 'Request';

  @override
  String get workerConnectedHeading => 'Connected workers';

  @override
  String get workerNoneConnected => 'No connected workers yet';

  @override
  String get workerStatusConnected => 'Connected';

  @override
  String get workerStatusPending => 'Request pending';

  @override
  String get workerJobButton => 'New order';

  @override
  String get workerAccept => 'Accept';

  @override
  String get workerJobSent => 'Job order sent. The worker will be notified.';

  @override
  String jobFormTitle(String name) {
    return 'Job order for $name';
  }

  @override
  String get jobFormSiteHint => 'Site (e.g. Banpo Xi remodeling)';

  @override
  String get jobRateDaily => 'Daily';

  @override
  String get jobRateHourly => 'Hourly';

  @override
  String get jobRatePerCase => 'Per job';

  @override
  String get jobFormRateHint => 'Rate (KRW)';

  @override
  String get jobFormSubmit => 'Send job order';

  @override
  String jobCreateFailed(String error) {
    return 'Failed to send order: $error';
  }

  @override
  String get bizConfirmTitle => 'Work Confirmation';

  @override
  String get bizSignErrSign => 'Please add your signature.';

  @override
  String get bizSignErrName => 'Please enter the signer name.';

  @override
  String get bizSignDone => 'Signed. (SIGNED)';

  @override
  String bizSignFailed(String error) {
    return 'Signing failed: $error';
  }

  @override
  String get bizStampDefault => 'Work Confirmation · WORKON';

  @override
  String get bizStampSigned => 'SIGNED · WORKON';

  @override
  String get bizLineCounterpart => 'Counterparty';

  @override
  String get bizLineRateType => 'Rate type';

  @override
  String bizSignedBadge(String name, String at) {
    return '$name signed · $at';
  }

  @override
  String get bizSignInAppTitle => 'Sign right in the app';

  @override
  String get bizSignInAppDesc =>
      'Sign below and it goes to the worker right away, and the confirmation is finalized.';

  @override
  String get bizSignerNameLabel => 'Signer name';

  @override
  String get bizSignRedraw => 'Sign again';

  @override
  String get bizSignSubmit => 'Sign & confirm';

  @override
  String get confNoCopySource => 'No previous confirmation to copy.';

  @override
  String get confCopyPrevious => 'Copy a previous confirmation';

  @override
  String get confFormTitle => 'New work confirmation';

  @override
  String get confSiteHint => 'e.g. Riverside Tower, Section 3';

  @override
  String get confWorkHint => 'Write what work you did';

  @override
  String get confRateType => 'Rate type';

  @override
  String get confRateDaily => 'Daily';

  @override
  String get confRateHourly => 'Hourly';

  @override
  String get confRatePerCase => 'Per job';

  @override
  String get confPricePerCase => 'Rate per job';

  @override
  String get confPriceGongsu => 'Gongsu rate (1 gongsu = 1 day)';

  @override
  String get confQtyHours => 'Hours';

  @override
  String get confQtyCases => 'Jobs';

  @override
  String get confQtyDays => 'Days';

  @override
  String get confErrGongsu => 'Enter gongsu in steps of 0.1 (e.g. 0.5, 1.5).';

  @override
  String get confErrHours => 'Enter 1 hour or more.';

  @override
  String get confErrCases => 'Enter 1 job or more.';

  @override
  String get confErrDays => 'Enter 1 day or more.';

  @override
  String get confDueDate => 'Expected payment date (optional)';

  @override
  String get confNotSet => 'Not set';

  @override
  String get confSaveSend => 'Save & send';

  @override
  String get confSaveHint => 'Saved straight to your ledger · Sent as a link';

  @override
  String get confStartTime => 'Start time';

  @override
  String get confEndTime => 'End time';

  @override
  String get confOrdererCompany => 'Requester (company)';

  @override
  String get confLinkedBiz => 'Linked business';

  @override
  String get confManualEntry => 'Enter manually';

  @override
  String get confSelectBiz => 'Select a linked business';

  @override
  String get confCompanyHint => 'Company / site contact name';

  @override
  String get confContactHint => 'Contact person / phone (optional)';

  @override
  String get confEquipSection => 'Equipment section';

  @override
  String get confEquipAutoInclude => 'Added to the confirmation automatically';

  @override
  String get confEquipName => 'Equipment name';

  @override
  String get confVehicleNo => 'Vehicle number';

  @override
  String get confUnitPrice => 'Rate';

  @override
  String get confQuantity => 'Qty';

  @override
  String get confAddExtra => 'Add overtime / night item';

  @override
  String get confSavedLinked => 'Saved · Sent to the linked business.';

  @override
  String get confSavedBook => 'Saved · Added to your ledger.';

  @override
  String get confDraftQueued =>
      'Saved as draft — will send automatically once online.';

  @override
  String confSaveFailed(String message) {
    return 'Save failed: $message';
  }

  @override
  String get confRestoreTitle => 'You have an unfinished entry.';

  @override
  String get confRestore => 'Restore';

  @override
  String get confDetailTitle => 'Work confirmation';

  @override
  String get confSentLinked => 'Sent to the linked business.';

  @override
  String confSendFailed(String message) {
    return 'Send failed: $message';
  }

  @override
  String get confReshare => 'Share again';

  @override
  String get confSendToLinked => 'Sent to the linked business';

  @override
  String get confSendViaShare =>
      'Send the link via the share sheet (KakaoTalk, etc.)';

  @override
  String get confCounterparty => 'the other party';

  @override
  String get confSentWaitingSign => 'Sent · Waiting for their signature';

  @override
  String get confDraftBeforeSend => 'Drafted · Not sent yet';

  @override
  String confShareHeader(String site) {
    return '[Work Confirmation] $site';
  }

  @override
  String get confShareBody =>
      'Please check the details and sign at the link below.';

  @override
  String confShareSubject(String site) {
    return 'Work confirmation · $site';
  }

  @override
  String get draftFlushNone =>
      'Couldn\'t send yet. Please check your connection.';

  @override
  String draftFlushSent(int n) {
    return 'Sent $n · Added to your ledger.';
  }

  @override
  String get draftFlushFailed =>
      'Some drafts failed to send. Please check them.';

  @override
  String get draftTitle => 'Saved drafts';

  @override
  String get draftEmpty => 'No drafts waiting to send.';

  @override
  String get draftHint =>
      'They\'ll send automatically once you\'re back online. To send now, tap retry below.';

  @override
  String get draftSendAll => 'Send all now';

  @override
  String get draftNoSite => '(No site entered)';

  @override
  String draftCheckNeeded(String error) {
    return 'Needs a check: $error';
  }

  @override
  String homeGreeting(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeToday => 'Today\'s schedule';

  @override
  String get homeMonthSummary => 'This month';

  @override
  String get homeCheckNeeded => 'Needs attention';

  @override
  String homeDocExpiry(String type, String dday) {
    return '$type expires $dday';
  }

  @override
  String get homeDocExpirySub =>
      'Renew it in your document wallet and register again';

  @override
  String homeDraftsPending(int n) {
    return '$n draft(s) waiting to send';
  }

  @override
  String get homeDraftsError => 'Some drafts need attention · Tap to view';

  @override
  String get homeDraftsAuto =>
      'They\'ll send automatically once online · Tap to view';

  @override
  String get homeStampDraft => 'DRAFTED · WORKON';

  @override
  String get homeStampScheduled => 'SCHEDULED · WORKON';

  @override
  String get homeTodayBadge => 'Today';

  @override
  String get homeStampToday => 'TODAY · WORKON';

  @override
  String get homeEmptyToday => 'No work scheduled today';

  @override
  String get homeEmptyTodaySub =>
      'Tap the + button below to log today\'s work in 30 seconds.';

  @override
  String get homeDaysWorked => 'Days worked';

  @override
  String get homeReceivable => 'To collect (unpaid)';

  @override
  String get homeReceived => 'Received (paid)';

  @override
  String get calViewMonth => 'Month';

  @override
  String get calViewWeek => 'Week';

  @override
  String calWorkCount(int n) {
    return '$n job(s)';
  }

  @override
  String get calManUnit => 'k';

  @override
  String get calEmptyMonth => 'No work recorded this month.';

  @override
  String get calEmptyDay => 'No work recorded on this day.';

  @override
  String get calRecordThisDay => 'Log work for this day';

  @override
  String get ledgerTitle => 'Ledger';

  @override
  String get ledgerOutstandingTotal => 'Unpaid this month';

  @override
  String ledgerWorkedThisMonth(String summary) {
    return 'Worked $summary this month';
  }

  @override
  String get ledgerByCompany => 'By company';

  @override
  String ledgerCompanyCount(int n) {
    return '$n companies';
  }

  @override
  String get ledgerStamp => 'LEDGER · WORKON';

  @override
  String get ledgerEmptyTitle => 'No ledger records this month';

  @override
  String get ledgerEmptySub =>
      'Write a confirmation and your ledger fills in automatically.';

  @override
  String get ledgerWriteConfirmation => 'Write a confirmation';

  @override
  String ledgerDaysWorked(int days) {
    return '$days day(s) worked';
  }

  @override
  String ledgerPaidAmount(String amount) {
    return '$amount paid';
  }

  @override
  String ledgerStatementFail(String error) {
    return 'Failed to open statement: $error';
  }

  @override
  String get ledgerMonthlyStatement => 'Monthly statement PDF';

  @override
  String get ledgerRemaining => 'Remaining unpaid';

  @override
  String get ledgerWorkHistory => 'Work history';

  @override
  String ledgerBilled(String amount) {
    return 'Billed $amount';
  }

  @override
  String ledgerDeposited(String amount) {
    return 'Paid $amount';
  }

  @override
  String get ledgerPaymentSaved => 'Payment recorded.';

  @override
  String ledgerPaymentFail(String message) {
    return 'Failed: $message';
  }

  @override
  String get ledgerRecordPayment => 'Record payment';

  @override
  String ledgerRemainingAmount(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get ledgerPaymentAmount => 'Payment amount';

  @override
  String get ledgerWonSuffix => '₩';

  @override
  String get ledgerFull => 'Full';

  @override
  String get ledgerHalf => 'Half';

  @override
  String get ledgerRecordPaymentBtn => 'Record payment';

  @override
  String get taxTitle => 'Tax invoice prep';

  @override
  String taxSupplierPrefix(String name) {
    return 'Supplier · $name';
  }

  @override
  String get taxNoBizName => '(No business name)';

  @override
  String taxBizNumberLine(String number) {
    return 'Business no. $number';
  }

  @override
  String get taxHometaxGuide =>
      'Paste the copied text into Hometax (hometax.go.kr) when issuing the tax invoice. After issuing, tap \"Mark as issued\" to remove it from the list.';

  @override
  String get taxEmptyTitle => 'No confirmations to issue.';

  @override
  String get taxEmptySubtitle =>
      'Only signed (SIGNED) and not-yet-issued confirmations appear here.';

  @override
  String get taxStamp => 'TAX INVOICE · WORKON';

  @override
  String get taxSupplierPromptTitle => 'Enter your business info first';

  @override
  String get taxSupplierPromptDesc =>
      'We need the business number and name of the supplier (you) for the tax invoice.';

  @override
  String get taxEnterBizInfo => 'Enter business info';

  @override
  String get taxCopiedSnack => 'Copied · paste it into Hometax.';

  @override
  String get taxMarkedSnack => 'Marked as issued · removed from the list.';

  @override
  String get taxAlreadyMarkedSnack => 'This item is already marked as issued.';

  @override
  String taxMarkFailed(String msg) {
    return 'Marking failed: $msg';
  }

  @override
  String taxBuyerBizLine(String number, int count) {
    return 'Business no. $number · $count item(s)';
  }

  @override
  String get taxNotRegistered => '(Not registered)';

  @override
  String get taxSupplyAmount => 'Supply amount';

  @override
  String get taxGrandTotal => 'Total amount';

  @override
  String get taxCopy => 'Copy';

  @override
  String get taxMarkIssued => 'Mark as issued';

  @override
  String get taxRegisteredBadge => 'Registered';

  @override
  String get taxCheckNeeded => 'Check needed';

  @override
  String get bizinfoTitle => 'Business info';

  @override
  String get bizinfoDesc =>
      'This is the supplier (your) info used to issue tax invoices.';

  @override
  String get bizinfoBizNumberLabel => 'Business registration no.';

  @override
  String get bizinfoBizNameLabel => 'Business name';

  @override
  String get bizinfoBizNameHint => 'Business name (company)';

  @override
  String get bizinfoAddressLabel => 'Business address (optional)';

  @override
  String get bizinfoAddressHint => 'Business address';

  @override
  String get bizinfoSavedSnack => 'Business info saved.';

  @override
  String bizinfoSaveFailed(String msg) {
    return 'Save failed: $msg';
  }

  @override
  String get walletTitle => 'Document wallet';

  @override
  String walletSelectedCount(int n) {
    return '$n selected';
  }

  @override
  String get walletAddDoc => 'Add document';

  @override
  String get walletMaskPromptTitle => 'Hide personal info?';

  @override
  String get walletMaskPromptBody =>
      'Mask sensitive info like your ID number or address so you can share safely.';

  @override
  String get walletLater => 'Later';

  @override
  String get walletMaskEdit => 'Edit mask';

  @override
  String walletExpiredTitle(String type) {
    return '$type expired';
  }

  @override
  String walletExpiringTitle(String type, String dday) {
    return '$type expires $dday';
  }

  @override
  String walletExpiringMultiSub(int n) {
    return '$n documents expiring soon — renew and re-register them';
  }

  @override
  String get walletRenewHint => 'Renew and re-register';

  @override
  String get walletEmptyTitle => 'No documents yet';

  @override
  String get walletEmptySub =>
      'Add licenses, insurance, and inspection certificates and track their expiry';

  @override
  String walletShareMessage(int count, int days, String url) {
    return '[작업온] Sending $count document(s).\nCheck them at the link below (valid for $days days).\n$url';
  }

  @override
  String get walletShareSubject => '작업온 document share';

  @override
  String walletShareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String walletSendBundle(int count) {
    return 'Send $count together';
  }

  @override
  String get walletBundleSend => 'Send as a set';

  @override
  String get walletValidPeriod => 'Valid for';

  @override
  String get walletMaskedInfo =>
      'Documents with a masked copy are sent with personal info hidden.';

  @override
  String get walletUnmaskedInfo =>
      'Without a masked copy, the original is sent as is. You can mask it from the details.';

  @override
  String get walletMakeLinkShare => 'Create link & share';

  @override
  String docOpenFailed(String error) {
    return 'Failed to open: $error';
  }

  @override
  String docUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get docDeleteConfirmTitle => 'Delete this document?';

  @override
  String get docDeleteConfirmBody =>
      'This document and its share links will be deleted.';

  @override
  String docDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get docOpenPdf => 'Open PDF';

  @override
  String get docHasMask => 'Masked copy available';

  @override
  String get docExpiryDate => 'Expiry date';

  @override
  String get docNone => 'None';

  @override
  String get docIssuedDate => 'Issue date';

  @override
  String get docReMask => 'Edit mask again';

  @override
  String get docMaskEdit => 'Mask personal info';

  @override
  String get docModify => 'Edit';

  @override
  String get docExpired => 'Expired';

  @override
  String docUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get docSourceCamera => 'Take a photo';

  @override
  String get docSourceGallery => 'Choose from gallery';

  @override
  String get docSourcePdf => 'Choose a PDF file';

  @override
  String get docInfoTitle => 'Document info';

  @override
  String docFilePdf(String name) {
    return 'PDF · $name';
  }

  @override
  String docFileImage(int kb) {
    return 'Image · ${kb}KB';
  }

  @override
  String get docTypeLabel => 'Type';

  @override
  String get docLinkEquip => 'Link equipment (optional)';

  @override
  String get docPersonal => 'Personal';

  @override
  String get docPickExpiry => 'Choose expiry date (optional)';

  @override
  String get docUpload => 'Upload';

  @override
  String get equipTitle => 'Equipment';

  @override
  String get equipAdd => 'Add equipment';

  @override
  String get equipEmptyTitle => 'No equipment yet';

  @override
  String get equipEmptySub =>
      'Add equipment like excavators or forklifts and group their documents';

  @override
  String equipDocCount(int n) {
    return '$n document(s)';
  }

  @override
  String get equipDocs => 'Documents';

  @override
  String get equipTypeHint => 'Equipment type (e.g. excavator)';

  @override
  String get equipVehicleHint => 'Vehicle number (optional)';

  @override
  String get equipSpecHint => 'Spec (e.g. 06W) (optional)';

  @override
  String get equipSubmit => 'Add';

  @override
  String get maskDoneToast =>
      'Masked copy created. Personal info will be hidden when shared.';

  @override
  String maskFailed(String error) {
    return 'Masking failed: $error';
  }

  @override
  String get maskTitle => 'Mask personal info';

  @override
  String get maskReset => 'Reset';

  @override
  String get maskGuide =>
      'Drag with your finger to mark the areas to hide as rectangles. (e.g. ID number, address)';

  @override
  String maskRegionCount(int n) {
    return '$n area(s) marked';
  }

  @override
  String get maskSave => 'Save masked copy';

  @override
  String get wshareTitle => 'My shares';

  @override
  String wshareLoadFailed(String error) {
    return 'Couldn\'t load: $error';
  }

  @override
  String get wshareEmpty => 'You haven\'t shared any document sets yet';

  @override
  String get wshareActive => 'Active';

  @override
  String get wshareInactive => 'Expired/revoked';

  @override
  String wshareViewCount(int n) {
    return '$n view(s)';
  }

  @override
  String get wshareReshare => 'Share again';

  @override
  String get wshareRevoke => 'Revoke';

  @override
  String myjobFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get myjobConditionTitle => 'Condition check';

  @override
  String get myjobConditionBody =>
      'How are you feeling today? We check this for safe work.';

  @override
  String get myjobConditionBad => 'Not good';

  @override
  String get myjobConditionGood => 'Good';

  @override
  String get myjobConditionReported =>
      'The business has been notified of your condition. Please don\'t push yourself.';

  @override
  String myjobLoadFailed(String error) {
    return 'Could not load: $error';
  }

  @override
  String get myjobEmpty => 'No work orders received';

  @override
  String get myjobAccept => 'Accept';

  @override
  String get myjobStart => 'Start work';

  @override
  String get myjobComplete => 'Complete work';

  @override
  String get signPadHint => 'Sign here with your finger';

  @override
  String get teamMenuTitle => 'My Team';

  @override
  String get teamMenuSub => 'Manage crew members and rates as a team lead';

  @override
  String get teamListTitle => 'My Team';

  @override
  String get teamEmptyTitle => 'You haven\'t created a team yet';

  @override
  String get teamEmptySub =>
      'Create a team and add members to organize a team confirmation on one sheet';

  @override
  String get teamCreate => 'Create team';

  @override
  String get teamNameLabel => 'Team name';

  @override
  String get teamNameHint => 'Team name (e.g. Park\'s Crew A)';

  @override
  String get teamAddMember => 'Add member';

  @override
  String get teamMembersTitle => 'Members';

  @override
  String get teamNoMembers => 'Please add members';

  @override
  String teamMemberCountLabel(int count) {
    return '$count members';
  }

  @override
  String get teamMemberLinked => 'Linked';

  @override
  String get teamMemberManual => 'Manual';

  @override
  String get teamDefaultRate => 'Default rate';

  @override
  String get teamDefaultRateHint => 'Default rate (per 1 gongsu)';

  @override
  String get teamAddByPhone => 'Find by phone';

  @override
  String get teamAddManual => 'Enter manually';

  @override
  String get teamMemberNameHint => 'Name';

  @override
  String get teamMemberPhoneHint => 'Phone (optional)';

  @override
  String get teamSearchPhoneHint => 'Member\'s phone number';

  @override
  String get teamSearchHint =>
      'Only registered users who consented to phone search can be found';

  @override
  String get teamSearchNoResult => 'No results found';

  @override
  String get teamMemberAdded => 'Member added';

  @override
  String get teamMemberExists => 'This member is already in the team';

  @override
  String get teamConsentRequired =>
      'Only registered users who consented to phone search can be linked';

  @override
  String get teamDeleteConfirm =>
      'Delete this team? Confirmations already issued stay as they are.';

  @override
  String get teamDeleteMemberConfirm => 'Delete this member?';

  @override
  String get confTeamMode => 'Team confirmation';

  @override
  String get confTeamModeSub => 'Organize each member\'s gongsu on one sheet';

  @override
  String get confTeamSelect => 'Select team';

  @override
  String get confTeamPickTeam => 'Please select a team';

  @override
  String get confTeamNoTeam => 'First create a team in \'My Team\'';

  @override
  String get confTeamTotal => 'Team total';

  @override
  String get confTeamEmptyEntries => 'No members have gongsu entered';

  @override
  String get ledgerTeamBadge => 'Team';

  @override
  String ledgerTeamDerived(String boss) {
    return '$boss\'s team work';
  }

  @override
  String get ledgerDerivedReadonly =>
      'This is team work created by the team lead (you can only record payments)';

  @override
  String get lcKicker => 'Standard Labor Contract';

  @override
  String get lcStamp => 'STANDARD LABOR CONTRACT';

  @override
  String get lcParties => 'Contracting parties';

  @override
  String get lcEmployer => 'Employer (Party A)';

  @override
  String get lcWorkerParty => 'Employee (Party B)';

  @override
  String get lcBizNumber => 'Business reg. no.';

  @override
  String get lcPeriod => 'Contract period';

  @override
  String get lcPeriodOpen => 'No fixed term · daily basis';

  @override
  String get lcWorkplace => 'Workplace';

  @override
  String get lcJob => 'Job description';

  @override
  String get lcWorkTime => 'Working hours';

  @override
  String get lcBreak => 'Break';

  @override
  String get lcWage => 'Wage';

  @override
  String get lcWageDaily => 'Daily wage';

  @override
  String get lcWageHourly => 'Hourly wage';

  @override
  String get lcPayday => 'Payday';

  @override
  String get lcPayMethod => 'Payment method';

  @override
  String get lcAllowance => 'Allowances';

  @override
  String get lcWeeklyHoliday =>
      'Weekly holiday pay: paid when the week’s scheduled workdays are fully attended.';

  @override
  String get lcWeeklyHolidayNone =>
      'Weekly holiday pay: not applicable (daily/short-term).';

  @override
  String get lcOvertime =>
      'Overtime, night, and holiday work are paid an extra 50% of ordinary wage per the Labor Standards Act.';

  @override
  String get lcOvertimeNone =>
      'Overtime/night/holiday premiums: not separately agreed.';

  @override
  String get lcInsurance => 'Social insurance';

  @override
  String get lcInsEmployment => 'Employment insurance';

  @override
  String get lcInsHealth => 'Health insurance';

  @override
  String get lcInsPension => 'National pension';

  @override
  String get lcInsAccident => 'Industrial accident insurance';

  @override
  String get lcApplied => 'Applied';

  @override
  String get lcNotApplied => 'Not applied';

  @override
  String get lcSpecial => 'Special terms';

  @override
  String get lcMasterNote =>
      'The Korean version is the authoritative original of this contract. Translations are for understanding only; the Korean version prevails in case of any discrepancy.';

  @override
  String get lcEmployerSigned => 'Employer signed';

  @override
  String get lcMenuDesc => 'Sign labor contracts with workers';

  @override
  String get lcListEmptyTitle => 'No contracts yet';

  @override
  String get lcListEmptySub => 'Create a labor contract with your worker';

  @override
  String get lcNewContract => 'New contract';

  @override
  String get lcStatusDraft => 'Draft';

  @override
  String get lcStatusSent => 'Sent';

  @override
  String get lcStatusSigned => 'Signed';

  @override
  String get lcWorkerSection => 'Worker';

  @override
  String get lcWorkerByPhone => 'Find by phone';

  @override
  String get lcWorkerManual => 'Enter manually';

  @override
  String get lcWorkerNameHint => 'Worker name';

  @override
  String get lcWorkerPhoneHint => 'Worker phone (optional)';

  @override
  String get lcSearchPhoneHint => 'Worker phone';

  @override
  String get lcSearchHint =>
      'Only members who allowed phone search can be found';

  @override
  String get lcSearchNoResult => 'No results';

  @override
  String get lcWorkerLinkedBadge => 'Linked';

  @override
  String get lcStartDate => 'Start date';

  @override
  String get lcEndDate => 'End date (optional)';

  @override
  String get lcEndDateNotSet => 'Not set';

  @override
  String get lcWorkplaceHint => 'e.g. Site A, Gangnam';

  @override
  String get lcJobHint => 'e.g. Rebar work';

  @override
  String get lcBreakHint => 'e.g. 12:00-13:00';

  @override
  String get lcWageAmountHint => 'Amount';

  @override
  String get lcPaydayHint => 'e.g. 25th monthly';

  @override
  String get lcPayMethodHint => 'e.g. Bank transfer';

  @override
  String get lcWeeklyHolidaySwitch => 'Weekly holiday pay';

  @override
  String get lcOvertimeSwitch => 'Overtime/night/holiday premium';

  @override
  String get lcSpecialHint => 'Special terms (optional)';

  @override
  String get lcSaveCommon => 'Save common values';

  @override
  String get lcSaveCommonSub => 'Auto-fill next time';

  @override
  String get lcSubmit => 'Create contract';

  @override
  String get lcCreated => 'Contract created';

  @override
  String get lcDetailTitle => 'Contract';

  @override
  String get lcSignEmployerTitle => 'My signature (employer)';

  @override
  String get lcSignEmployerDesc => 'Sign to send it to the worker';

  @override
  String get lcSignerNameLabel => 'Signer name';

  @override
  String get lcSignRedraw => 'Redraw';

  @override
  String get lcSignSubmit => 'Sign';

  @override
  String get lcSigned => 'Signed';

  @override
  String get lcSignErrPad => 'Please sign first';

  @override
  String get lcSignErrName => 'Please enter signer name';

  @override
  String get lcSend => 'Send to worker';

  @override
  String get lcSentLinked => 'Sent to the worker';

  @override
  String get lcSentShare => 'Share the link to deliver it';

  @override
  String get lcShareBody =>
      'Please review and sign the contract at the link below';

  @override
  String get lcViewPdf => 'View PDF';

  @override
  String get lcDeleteConfirm => 'Delete this contract?';

  @override
  String get lcDeleted => 'Deleted';

  @override
  String get lcWaitingWorker => 'Waiting for worker signature';

  @override
  String get lcMyContractsTitle => 'My contracts';

  @override
  String get lcMyContractsSub => 'Review and sign received contracts';

  @override
  String get lcMyEmptyTitle => 'No contracts received';

  @override
  String get lcMyEmptySub => 'Contracts sent by employers appear here';

  @override
  String get lcWorkerSignTitle => 'My signature (worker)';

  @override
  String get lcWorkerSignDesc => 'Please review and sign';

  @override
  String get lcAlreadySigned => 'Already signed';

  @override
  String lcCreateFailed(String msg) {
    return 'Could not save contract: $msg';
  }

  @override
  String lcSignFailed(String msg) {
    return 'Could not sign: $msg';
  }

  @override
  String lcSendFailed(String msg) {
    return 'Could not send: $msg';
  }

  @override
  String lcPdfFailed(String msg) {
    return 'Could not open PDF: $msg';
  }

  @override
  String get tbmMenuTitle => 'TBM Log';

  @override
  String get tbmMenuDesc => 'Toolbox meeting · hazards & attendee check';

  @override
  String get tbmMyTitle => 'Received TBM';

  @override
  String get tbmMySub => 'My safety records · confirm';

  @override
  String get tbmTitle => 'TBM (Toolbox Meeting)';

  @override
  String get tbmStamp => 'T B M';

  @override
  String get tbmListEmptyTitle => 'No TBM logged yet';

  @override
  String get tbmListEmptySub => 'Log your site safety meeting.';

  @override
  String get tbmNew => 'New TBM';

  @override
  String get tbmFormTitle => 'Write TBM';

  @override
  String get tbmSite => 'Site';

  @override
  String get tbmSiteHint => 'e.g. Site A, 3rd floor';

  @override
  String get tbmDate => 'Date & time';

  @override
  String get tbmHazards => 'Hazards';

  @override
  String get tbmHazardsHint => 'Tap chips to select or type your own';

  @override
  String get tbmAddCustom => 'Custom';

  @override
  String get tbmCustomHint => 'Enter a hazard';

  @override
  String get tbmMeasures => 'Safety measures';

  @override
  String get tbmMeasuresHint => 'e.g. wear harness, assign spotter';

  @override
  String get tbmNotes => 'Notes';

  @override
  String get tbmNotesHint => 'Notes (optional)';

  @override
  String get tbmAttendees => 'Attendees';

  @override
  String get tbmSelectWorkers => 'Select linked workers';

  @override
  String get tbmNoConnections => 'No linked workers';

  @override
  String get tbmAddAttendeeManual => 'Add attendee manually';

  @override
  String get tbmAttendeeNameHint => 'Attendee name';

  @override
  String get tbmPhotos => 'Site photos';

  @override
  String get tbmAddPhoto => 'Add photo';

  @override
  String get tbmSave => 'Save TBM';

  @override
  String get tbmSaved => 'TBM logged';

  @override
  String tbmSaveFailed(String msg) {
    return 'Could not save: $msg';
  }

  @override
  String get tbmNeedHazard => 'Select at least one hazard';

  @override
  String get tbmNeedSite => 'Enter the site name';

  @override
  String get tbmPresetMine => 'My presets';

  @override
  String get tbmPresetAddChip => '＋ Save preset';

  @override
  String get tbmPresetAddTitle => 'Save a frequent phrase';

  @override
  String get tbmPresetDeleted => 'Preset deleted';

  @override
  String get tbmDetailTitle => 'TBM detail';

  @override
  String get tbmAttendeesStatus => 'Attendee confirmations';

  @override
  String get tbmAcked => 'Confirmed';

  @override
  String get tbmNotAcked => 'Pending';

  @override
  String tbmAckSummary(int att, int ack) {
    return '$att attended · $ack confirmed';
  }

  @override
  String get tbmReadonly => 'Read-only after the day it was created';

  @override
  String get tbmEdit => 'Edit';

  @override
  String get tbmDeleteConfirm => 'Delete this TBM record?';

  @override
  String get tbmDeleted => 'Deleted';

  @override
  String get tbmSaveUpdated => 'Updated';

  @override
  String tbmPhotoFailed(String msg) {
    return 'Photo failed: $msg';
  }

  @override
  String get tbmReceivedEmpty => 'No TBM received';

  @override
  String get tbmAckButton => 'Confirm TBM';

  @override
  String get tbmAckDone => 'Confirmed';

  @override
  String tbmAckFailed(String msg) {
    return 'Could not confirm: $msg';
  }

  @override
  String get tbmAlreadyAcked => 'Already confirmed';

  @override
  String tbmPhotoCount(int n) {
    return '$n photos';
  }

  @override
  String get tbmHzHeavyEquip => 'Heavy equipment pinch/collision';

  @override
  String get tbmHzFallHeight => 'Fall from height';

  @override
  String get tbmHzHeatIllness => 'Heat illness';

  @override
  String get tbmHzElectric => 'Electric shock';

  @override
  String get tbmHzFallingObject => 'Falling objects';

  @override
  String get tbmHzCollapse => 'Collapse/burial';

  @override
  String get tbmHzFire => 'Fire/explosion';

  @override
  String get tbmHzDustNoise => 'Dust/noise';

  @override
  String get tbmHzSlipTrip => 'Slip/trip';

  @override
  String get tbmHzConfined => 'Confined space asphyxia';

  @override
  String get incomeReportMenuTitle => 'Income report';

  @override
  String get incomeReportMenuSub =>
      'Yearly income, unpaid & gongsu at a glance';

  @override
  String get incomeReportTitle => 'Income report';

  @override
  String incomeReportYear(String year) {
    return '$year';
  }

  @override
  String get incomeReportTotalBilled => 'Total billed';

  @override
  String get incomeReportTotalPaid => 'Total paid';

  @override
  String get incomeReportTotalOutstanding => 'Total unpaid';

  @override
  String get incomeReportTotalDays => 'Days worked';

  @override
  String get incomeReportTotalGongsu => 'Total gongsu';

  @override
  String get incomeReportTeamPayout => 'Team payout';

  @override
  String get incomeReportNetBilled => 'Net (reference)';

  @override
  String get incomeReportNetHint =>
      'Billed − team member payout (your own share)';

  @override
  String get incomeReportMonthlyTrend => 'Monthly trend';

  @override
  String incomeReportPeakLabel(String amount) {
    return 'Peak $amount';
  }

  @override
  String get incomeReportByCompany => 'By counterparty';

  @override
  String incomeReportEntryCount(int n) {
    return '$n item(s)';
  }

  @override
  String incomeReportOutstandingShort(String amount) {
    return '$amount unpaid';
  }

  @override
  String get incomeReportTaxTitle => 'Income tax guide';

  @override
  String get incomeReportTaxL1 =>
      'Comprehensive income tax is filed and paid every May for the previous year\'s income.';

  @override
  String get incomeReportTaxL2 =>
      'Personal-service business income is often withheld at 3.3% when paid.';

  @override
  String get incomeReportTaxL3 =>
      'Withheld tax is settled (refund or additional payment) at the May filing.';

  @override
  String get incomeReportTaxL4 =>
      'Keeping your expenses and confirmations/statements helps at filing time.';

  @override
  String get incomeReportTaxL5 =>
      'This is general information, not tax advice. Check a tax professional or Hometax for accurate filing.';

  @override
  String get incomeReportSavePdf => 'Save / share PDF';

  @override
  String incomeReportPdfFail(String msg) {
    return 'Couldn\'t open the report: $msg';
  }

  @override
  String get incomeReportEmptyTitle => 'No income records yet';

  @override
  String get incomeReportEmptySub =>
      'Write a confirmation and your income will appear here.';

  @override
  String get ledgerAutoRemind => 'Auto payment reminder';

  @override
  String get ledgerAutoRemindHint =>
      'Automatically sends a payment reminder after the due date';

  @override
  String get ledgerRemindNow => 'Send reminder now';

  @override
  String get ledgerRemindSent => 'Payment reminder sent';

  @override
  String get ledgerRemindHistory => 'Reminder history';

  @override
  String ledgerRemindHistoryItem(String date, String stage) {
    return '$date · $stage';
  }

  @override
  String get reminderStageD7 => '7-day reminder';

  @override
  String get reminderStageD30 => '30-day reminder';

  @override
  String get reminderStageManual => 'Manual reminder';

  @override
  String get profilePayoutSection => 'Payout account (for reminders)';

  @override
  String get profilePayoutBank => 'Bank';

  @override
  String get profilePayoutAccount => 'Account number';

  @override
  String get profilePayoutHolder => 'Account holder';

  @override
  String get profilePayoutHint =>
      'This account is included when you send a payment reminder (optional)';

  @override
  String get profilePayoutSaved => 'Payout account saved';

  @override
  String get badgeExcellent => 'Excellent payer';

  @override
  String get badgeGood => 'Good payer';

  @override
  String badgeAvgDays(int days) {
    return 'Avg $days days';
  }

  @override
  String get badgeSelfImproveGood =>
      'Pay within 15 days to earn the Excellent payer badge';

  @override
  String get badgeSelfImproveNone =>
      'Pay on time to earn the Excellent payer badge';

  @override
  String badgeInsufficient(int count) {
    return '$count payment records — more history is needed to rate a badge';
  }

  @override
  String badgeSampleCount(int count) {
    return 'Based on last $count';
  }

  @override
  String get badgeSelfTitle => 'Payment reliability';

  @override
  String get qrCardMenuTitle => 'My QR card';

  @override
  String get qrCardMenuSub => 'Introduce yourself with a QR and link';

  @override
  String get qrCardTitle => 'My QR card';

  @override
  String get qrCardScanHint => 'Scan the QR to open my public profile';

  @override
  String qrCardViewCount(int count) {
    return '$count views';
  }

  @override
  String get qrCardIntroLabel => 'One-line intro';

  @override
  String get qrCardIntroPlaceholder => 'e.g. Rebar foreman, 20 yrs experience';

  @override
  String get qrCardIntroSaved => 'Intro saved';

  @override
  String get qrCardExposeTitle => 'Show card';

  @override
  String get qrCardExposeSub =>
      'When on, your profile is visible via QR and link';

  @override
  String get qrCardHiddenHint =>
      'Hidden for now — the link won\'t show your card';

  @override
  String get qrCardRotate => 'Reissue link';

  @override
  String get qrCardRotateConfirm =>
      'A new link will make the old QR and link stop working. Continue?';

  @override
  String get qrCardRotateConfirmBtn => 'Reissue';

  @override
  String get qrCardRotated => 'New card link issued';

  @override
  String get qrCardDocValid => 'Documents valid';

  @override
  String get qrCardDocProblem => 'Documents to check';

  @override
  String qrCardDocExpiryLabel(String date) {
    return 'Expires $date';
  }

  @override
  String get smsSendSms => 'Send by text';

  @override
  String get smsSharedInstead =>
      'Texting isn\'t supported, so we opened Share instead';

  @override
  String get smsFailed => 'Couldn\'t open the messaging app';

  @override
  String get callButtonLabel => 'Call';

  @override
  String get callFailed => 'Couldn\'t place the call';

  @override
  String smsConfBodyNamed(String name, String site, String link) {
    return '$name, please sign the work confirmation for $site: $link';
  }

  @override
  String smsConfBodyPlain(String site, String link) {
    return 'Please sign the work confirmation for $site: $link';
  }

  @override
  String smsCardShareBody(String link) {
    return 'Here is my business card: $link';
  }

  @override
  String smsDocBundleBody(String link) {
    return 'Here are the documents: $link';
  }

  @override
  String get smsRecipientTitle => 'Recipient';

  @override
  String get smsRecipientHint => 'Enter phone number';

  @override
  String get smsPickConnection => 'Pick from contacts';

  @override
  String get smsOpenCompose => 'Open message composer';

  @override
  String get quickSendMenuTitle => 'Quick send';

  @override
  String get quickSendMenuSub => 'Text a business card or documents in one tap';

  @override
  String get quickSendTitle => 'Quick send';

  @override
  String get quickSendAddTemplate => 'Add template';

  @override
  String get quickSendPickTemplate => 'Choose a template to send';

  @override
  String get quickSendBuiltinSection => 'Default templates';

  @override
  String get quickSendCustomSection => 'My templates';

  @override
  String quickSendNoDoc(String type) {
    return 'No \'$type\' document. Add it to your document wallet first';
  }

  @override
  String get quickSendAttachImage => 'Attach as image';

  @override
  String get quickSendAttachImageSub =>
      'Attach the document image directly instead of a link';

  @override
  String get tplCardTitle => 'Business card';

  @override
  String tplCardBody(String name, String me, String link) {
    return 'Hello $name, $me is sending you a business card: $link';
  }

  @override
  String get tplBizTitle => 'Business registration';

  @override
  String tplBizBody(String name, String me, String link) {
    return '$name, $me is sending the business registration: $link';
  }

  @override
  String get tplBankTitle => 'Bankbook copy';

  @override
  String tplBankBody(String name, String me, String link) {
    return '$name, $me is sending a copy of the bankbook: $link';
  }

  @override
  String get tplEditorTitle => 'Add template';

  @override
  String get tplFieldTitle => 'Title';

  @override
  String get tplFieldBody => 'Message';

  @override
  String get tplFieldBodyHint => 'e.g. Hello, sending you the file';

  @override
  String get tplVarsHelp => 'Available variables';

  @override
  String get tplFieldLink => 'Attachment';

  @override
  String get tplLinkNone => 'None';

  @override
  String get tplLinkCard => 'Card link';

  @override
  String get tplLinkDoc => 'Document link';

  @override
  String get tplFieldDocType => 'Document type';

  @override
  String get tplDocTypeHint => 'e.g. Business registration, bankbook copy';

  @override
  String get tplSaveTemplate => 'Save template';

  @override
  String get tplNeedTitleBody => 'Enter a title and message';

  @override
  String postCallTitle(String name) {
    return 'Did you just talk with $name?';
  }

  @override
  String get postCallSendCard => 'Send card';

  @override
  String get postCallQuickSend => 'Quick send';

  @override
  String get postCallSettingTitle => 'Suggest sending after a call';

  @override
  String get postCallSettingSub =>
      'When you return after calling from the app, we suggest sending a card or quick send';

  @override
  String get attendBoardTitle => 'Today\'s Attendance';

  @override
  String get attendBoardEmpty => 'No work scheduled today';

  @override
  String get attendBoardViewDetail => 'Tap for details';

  @override
  String get attendSummaryTotal => 'Total';

  @override
  String get attendSummaryAttended => 'On site';

  @override
  String get attendSummaryCompleted => 'Done';

  @override
  String get attendSummaryAbsent => 'Absent';

  @override
  String attendPeopleCount(int count) {
    return '$count people';
  }

  @override
  String get attendStatusScheduled => 'Scheduled';

  @override
  String get attendStatusAccepted => 'Accepted';

  @override
  String get attendStatusStarted => 'Started';

  @override
  String get attendStatusDone => 'Done';

  @override
  String get attendStatusCancelled => 'Cancelled';

  @override
  String attendStartedAt(String time) {
    return 'Started $time';
  }

  @override
  String attendScheduledAt(String time) {
    return 'Scheduled $time';
  }

  @override
  String get attendCondOk => 'Feeling good';

  @override
  String get attendCondBad => 'Not well';

  @override
  String get siteCostsTitle => 'Labor Cost by Site';

  @override
  String get bizMenuSiteCostsDesc => 'Labor cost per site · client-ready PDF';

  @override
  String get siteCostsThisMonth => 'This month';

  @override
  String get siteCostsLast3 => 'Last 3 months';

  @override
  String get siteCostsLast6 => 'Last 6 months';

  @override
  String get siteCostsLast12 => 'Last 12 months';

  @override
  String siteCostsRangeLabel(String from, String to) {
    return '$from ~ $to';
  }

  @override
  String get siteCostsSubtotal => 'Subtotal';

  @override
  String get siteCostsTotalHeader => 'Grand total';

  @override
  String siteCostsWorkerCount(int count) {
    return '$count workers';
  }

  @override
  String siteCostsTeamMembers(int count) {
    return 'Team of $count';
  }

  @override
  String siteCostsEntryCount(int count) {
    return '$count confirmations';
  }

  @override
  String get siteCostsSavePdf => 'Save/Share PDF';

  @override
  String siteCostsPdfFail(String error) {
    return 'Couldn\'t create PDF ($error)';
  }

  @override
  String get siteCostsEmpty => 'No confirmations in this period';

  @override
  String get wageStmtTitle => 'Payment Statement (Monthly)';

  @override
  String get bizMenuWageStmtDesc =>
      'Daily-wage payment statement · monthly close';

  @override
  String get wageStmtEmpty => 'No payments made this month';

  @override
  String get wageStmtType33 => 'Business income 3.3%';

  @override
  String get wageStmtTypeDaily => 'Daily wage';

  @override
  String get wageStmtPaidTotal => 'Paid';

  @override
  String get wageStmtIncomeTax => 'Income tax';

  @override
  String get wageStmtLocalTax => 'Local income tax';

  @override
  String get wageStmtTotalTax => 'Total withheld';

  @override
  String get wageStmtNetPay => 'Net pay';

  @override
  String wageStmtPaymentCount(int count) {
    return '$count payments';
  }

  @override
  String get wageStmtCopy => 'Copy';

  @override
  String get wageStmtCopied => 'Copied statement text';

  @override
  String get wageStmtMark => 'Close this month';

  @override
  String get wageStmtMarked => 'Closed';

  @override
  String wageStmtMarkedSnack(String month) {
    return 'Closed the $month statement';
  }

  @override
  String get wageStmtAlreadyMarked => 'Already closed';

  @override
  String wageStmtMarkFail(String error) {
    return 'Couldn\'t close ($error)';
  }

  @override
  String get wageStmtTotalHeader => 'Total paid';

  @override
  String get wageStmtNoticeTitle => 'Notes';

  @override
  String get wageStmtWorkerTax => 'Withholding by income type';

  @override
  String siteCostsManDays(String n) {
    return '$n man-days';
  }
}
