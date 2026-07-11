// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get edit => '编辑';

  @override
  String get share => '共享';

  @override
  String get download => '下载';

  @override
  String get view => '查看';

  @override
  String get loading => '加载中…';

  @override
  String get errorConnTitle => '连接有问题';

  @override
  String get errorConnSubtitle => '请检查网络连接后重试。';

  @override
  String get statusDeposited => '已收款';

  @override
  String get statusOverdue => '已逾期';

  @override
  String collectDday(String dday) {
    return '收款 $dday';
  }

  @override
  String get amtBase => '基本';

  @override
  String get amtOvertime => '加班';

  @override
  String get amtEarly => '早班';

  @override
  String get amtNight => '夜班';

  @override
  String get amtAllnight => '通宵';

  @override
  String get itemOther => '其他';

  @override
  String get baseDaily => '基本（日薪）';

  @override
  String get baseHourly => '基本（时薪）';

  @override
  String get basePerCase => '基本（按件）';

  @override
  String get baseGongsu => '基本（工数）';

  @override
  String get unitGongsu => '工数';

  @override
  String qtyGongsu(String qty) {
    return '$qty工数';
  }

  @override
  String vatLabel(String rate) {
    return '增值税 ($rate%)';
  }

  @override
  String daysCount(int days) {
    return '$days天';
  }

  @override
  String daysWithGongsu(int days, String gongsu) {
    return '$days天 · $gongsu工数';
  }

  @override
  String get moreTitle => '更多';

  @override
  String get sectionManage => '管理';

  @override
  String get sectionSettings => '设置';

  @override
  String get menuWallet => '证件夹';

  @override
  String get menuWalletSub => '证书·保险·检验证到期管理 · 打包发送';

  @override
  String get menuBizHome => '工地主页';

  @override
  String get menuBizMode => '工地模式';

  @override
  String get menuBizSub => '派工·接收确认单·结算·安全报告';

  @override
  String get menuJobs => '收到的活';

  @override
  String get menuJobsSub => '接受·开始·完成派工';

  @override
  String get menuTax => '税票准备';

  @override
  String get menuTaxSub => '已签名确认单 → 整理成 Hometax 录入数据';

  @override
  String get menuNotifications => '通知';

  @override
  String get menuNotificationsSub => '收款·证件到期·预约作业·高温安全';

  @override
  String get consentTitle => '允许通过手机号搜索';

  @override
  String get consentSub => '工地方可用我的号码找到并联系我';

  @override
  String get kakaoLinkTitle => '绑定 Kakao 账号';

  @override
  String get kakaoLinkedSub => '已绑定';

  @override
  String get kakaoLinkSub => '绑定后也可用 Kakao 登录';

  @override
  String get kakaoLinked => '已绑定 Kakao 账号。';

  @override
  String get kakaoNotReady => 'Kakao 登录正在准备中。';

  @override
  String get kakaoAlreadyLinked => '该 Kakao 已绑定到其他账号。';

  @override
  String kakaoLinkFailed(String message) {
    return '绑定失败：$message';
  }

  @override
  String get kakaoLinkCanceled => '已取消绑定 Kakao。';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '要退出登录吗？';

  @override
  String get noName => '无姓名';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get paperStamp => '作 业 确 认 单';

  @override
  String get paperDate => '作业日期';

  @override
  String get paperTime => '时间';

  @override
  String get paperSite => '工地';

  @override
  String get paperWorker => '作业人';

  @override
  String get paperOrderer => '派工方';

  @override
  String get paperWork => '作业内容';

  @override
  String get paperEquipment => '设备';

  @override
  String get paperGuide => '引导员';

  @override
  String get paperTotal => '应收金额';

  @override
  String get paperMemo => '备注';

  @override
  String get paperSignHead => '派工方签名';

  @override
  String paperSignedBy(String name) {
    return '$name 已签名';
  }

  @override
  String shareCount(int n) {
    return '共享的文件 $n 份';
  }

  @override
  String shareValidUntil(String date) {
    return '有效期至 $date';
  }

  @override
  String shareExpiry(String date) {
    return '到期 $date';
  }

  @override
  String get shareNoExpiry => '无到期日';

  @override
  String get shareMasked => '打码版';

  @override
  String get statusTransientTitle => '出现临时错误';

  @override
  String get statusTransientMsg => '请稍后再试。';

  @override
  String get statusNotFoundTitle => '找不到该链接';

  @override
  String get statusNotFoundMsg => '链接可能已过期或被作废。请向发送人索取新链接。';

  @override
  String get authStartWithPhone => '用手机号开始';

  @override
  String get authTagline => '30秒记录你的工作，确认单、账本、结算自动管理。';

  @override
  String get authPhoneLabel => '手机号';

  @override
  String get authCodeLabel => '验证码';

  @override
  String get authCodeHint => '6位验证码';

  @override
  String get authDevAutofill => '开发环境：验证码会自动填入。';

  @override
  String get authRequestCode => '获取验证码';

  @override
  String get authVerifyStart => '验证并开始';

  @override
  String get authReenterPhone => '重新输入手机号';

  @override
  String get authOr => '或';

  @override
  String get authKakaoStart => '用 Kakao 开始';

  @override
  String get authKakaoPreparing => 'Kakao 登录正在准备中，请先用手机号开始。';

  @override
  String get onbWelcome => '欢迎！';

  @override
  String get onbNamePrompt => '请告诉我们要显示在确认单上的姓名。';

  @override
  String get onbNameLabel => '姓名';

  @override
  String get onbNameHint => '例）张伟';

  @override
  String get onbStart => '开始';

  @override
  String get navHome => '首页';

  @override
  String get navCalendar => '日历';

  @override
  String get navLedger => '账本';

  @override
  String get navMore => '更多';

  @override
  String get navWrite => '新建';

  @override
  String navDraftsSent(int n) {
    return '$n 份草稿已自动发送。';
  }

  @override
  String navDraftsFailed(int n) {
    return '$n 份草稿发送失败。请在首页查看。';
  }

  @override
  String get notiTitle => '通知';

  @override
  String get notiEmpty => '暂无通知';

  @override
  String get notiAckDone => '已确认。';

  @override
  String notiAckFailed(String error) {
    return '确认失败：$error';
  }

  @override
  String get bizModeTitle => '企业模式';

  @override
  String bizCreateFailed(String error) {
    return '创建失败：$error';
  }

  @override
  String get bizCreateHeading => '创建企业开始使用';

  @override
  String get bizCreateDesc => '连接作业人、派工、签收确认单、结算、安全报告，全在一处。';

  @override
  String get bizNameHint => '商号（例：大成建设）';

  @override
  String get bizBnoHint => '营业执照号（选填）';

  @override
  String get bizCreateButton => '创建企业';

  @override
  String bizInviteCode(String code) {
    return '邀请码 $code';
  }

  @override
  String get inboxTitle => '收件箱';

  @override
  String get bizMenuInboxDesc => '查看收到的确认单·应用内签名';

  @override
  String get settleTitle => '结算';

  @override
  String get bizMenuSettleDesc => '按作业人汇总未付·处理支付';

  @override
  String get workerTitle => '作业人·派工';

  @override
  String get bizMenuWorkerDesc => '搜索·连接作业人·创建派工';

  @override
  String get jobTitle => '派工列表';

  @override
  String get bizMenuJobDesc => '查看预约·进行中·完成状态';

  @override
  String get safetyTitle => '安全';

  @override
  String get bizMenuSafetyDesc => '安全管理报告 PDF·近期安全记录';

  @override
  String bizLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get inboxEmpty => '还没有收到确认单';

  @override
  String get inboxStatusSigned => '已签名';

  @override
  String get inboxStatusPending => '待签名';

  @override
  String get jobStatusScheduled => '预约';

  @override
  String get jobStatusInProgress => '进行中';

  @override
  String get jobStatusDone => '完成';

  @override
  String get jobEmpty => '本月没有派工';

  @override
  String get jobAccepted => '已接受';

  @override
  String get jobAcceptPending => '待接受';

  @override
  String safetyReportOpenFailed(String error) {
    return '打开报告失败：$error';
  }

  @override
  String get safetyReportTitle => '安全管理执行报告';

  @override
  String get safetyReportDesc => '按月 PDF 查看健康检查·证件有效性·高温预警记录。';

  @override
  String safetyOpenReport(String month) {
    return '打开 $month 报告';
  }

  @override
  String get safetyHeatNotice => '发布高温预警时，会自动向已连接的作业人发送安全提醒并留下确认记录。';

  @override
  String settlePaidSnack(String name, String amount) {
    return '已向 $name 支付 $amount';
  }

  @override
  String settlePayFailed(String error) {
    return '支付失败：$error';
  }

  @override
  String get settleEmpty => '本月没有未付款项';

  @override
  String settleEntryCount(int count) {
    return '$count 笔';
  }

  @override
  String get settlePaidDone => '已支付';

  @override
  String settlePayAmount(String amount) {
    return '支付 $amount';
  }

  @override
  String workerSearchFailed(String error) {
    return '搜索失败：$error';
  }

  @override
  String workerConnectRequested(String name) {
    return '已向 $name 发送连接请求。';
  }

  @override
  String workerRequestFailed(String error) {
    return '请求失败：$error';
  }

  @override
  String get workerSearchHint => '按作业人手机号搜索';

  @override
  String get workerSearchButton => '搜索';

  @override
  String get workerConnectButton => '请求连接';

  @override
  String get workerConnectedHeading => '已连接的作业人';

  @override
  String get workerNoneConnected => '还没有已连接的作业人';

  @override
  String get workerStatusConnected => '已连接';

  @override
  String get workerStatusPending => '等待请求';

  @override
  String get workerJobButton => '派工';

  @override
  String get workerAccept => '接受';

  @override
  String get workerJobSent => '已发送派工。会通知作业人。';

  @override
  String jobFormTitle(String name) {
    return '给 $name 派工';
  }

  @override
  String get jobFormSiteHint => '工地（例：盘浦Xi改造）';

  @override
  String get jobRateDaily => '日薪';

  @override
  String get jobRateHourly => '时薪';

  @override
  String get jobRatePerCase => '按件';

  @override
  String get jobFormRateHint => '单价（韩元）';

  @override
  String get jobFormSubmit => '发送派工';

  @override
  String jobCreateFailed(String error) {
    return '派工失败：$error';
  }

  @override
  String get bizConfirmTitle => '作业确认单';

  @override
  String get bizSignErrSign => '请先签名。';

  @override
  String get bizSignErrName => '请输入签名人姓名。';

  @override
  String get bizSignDone => '签名完成。(SIGNED)';

  @override
  String bizSignFailed(String error) {
    return '签名失败：$error';
  }

  @override
  String get bizStampDefault => '作业确认单 · WORKON';

  @override
  String get bizStampSigned => '已签名 · WORKON';

  @override
  String get bizLineCounterpart => '对方';

  @override
  String get bizLineRateType => '单价类型';

  @override
  String bizSignedBadge(String name, String at) {
    return '$name 签名 · $at';
  }

  @override
  String get bizSignInAppTitle => '在应用内直接签名';

  @override
  String get bizSignInAppDesc => '在下方签名后会立即发送给作业人，确认单即刻确定。';

  @override
  String get bizSignerNameLabel => '签名人姓名';

  @override
  String get bizSignRedraw => '重新签';

  @override
  String get bizSignSubmit => '签名并确认';

  @override
  String get confNoCopySource => '没有可复制的确认单。';

  @override
  String get confCopyPrevious => '复制以前的确认单';

  @override
  String get confFormTitle => '填写作业确认单';

  @override
  String get confSiteHint => '例）江畔大厦 3标段';

  @override
  String get confWorkHint => '请写下您做的作业内容';

  @override
  String get confRateType => '单价类型';

  @override
  String get confRateDaily => '日薪';

  @override
  String get confRateHourly => '时薪';

  @override
  String get confRatePerCase => '按件';

  @override
  String get confPricePerCase => '每件单价';

  @override
  String get confPriceGongsu => '工数单价（1工数=1天）';

  @override
  String get confQtyHours => '小时数';

  @override
  String get confQtyCases => '件数';

  @override
  String get confQtyDays => '天数';

  @override
  String get confErrGongsu => '工数请以0.1为单位输入（例：0.5、1.5）。';

  @override
  String get confErrHours => '请输入1以上的小时数。';

  @override
  String get confErrCases => '请输入1以上的件数。';

  @override
  String get confErrDays => '请输入1以上的天数。';

  @override
  String get confDueDate => '预计收款日（选填）';

  @override
  String get confNotSet => '未设置';

  @override
  String get confSaveSend => '保存并发送';

  @override
  String get confSaveHint => '保存后立即记入账本 · 以链接发送';

  @override
  String get confStartTime => '开始时间';

  @override
  String get confEndTime => '结束时间';

  @override
  String get confOrdererCompany => '派工方（公司）';

  @override
  String get confLinkedBiz => '已连接的工地';

  @override
  String get confManualEntry => '手动输入';

  @override
  String get confSelectBiz => '选择已连接的工地';

  @override
  String get confCompanyHint => '公司/工地负责方名称';

  @override
  String get confContactHint => '负责人/联系方式（选填）';

  @override
  String get confEquipSection => '设备栏';

  @override
  String get confEquipAutoInclude => '自动加入确认单';

  @override
  String get confEquipName => '设备名称';

  @override
  String get confVehicleNo => '车牌号';

  @override
  String get confUnitPrice => '单价';

  @override
  String get confQuantity => '数量';

  @override
  String get confAddExtra => '添加加班·夜班项目';

  @override
  String get confSavedLinked => '已保存 · 已发送给连接的工地。';

  @override
  String get confSavedBook => '已保存 · 已记入账本。';

  @override
  String get confDraftQueued => '已临时保存 — 联网后自动发送。';

  @override
  String confSaveFailed(String message) {
    return '保存失败：$message';
  }

  @override
  String get confRestoreTitle => '有一份没写完的内容。';

  @override
  String get confRestore => '恢复';

  @override
  String get confDetailTitle => '作业确认单';

  @override
  String get confSentLinked => '已发送给连接的工地。';

  @override
  String confSendFailed(String message) {
    return '发送失败：$message';
  }

  @override
  String get confReshare => '再次分享';

  @override
  String get confSendToLinked => '将发送给连接的工地';

  @override
  String get confSendViaShare => '可通过分享面板（KakaoTalk 等）发送链接';

  @override
  String get confCounterparty => '对方';

  @override
  String get confSentWaitingSign => '已发送 · 等待对方签名';

  @override
  String get confDraftBeforeSend => '已填写 · 尚未发送';

  @override
  String confShareHeader(String site) {
    return '【作业确认单】$site';
  }

  @override
  String get confShareBody => '请在下方链接查看内容并签名。';

  @override
  String confShareSubject(String site) {
    return '作业确认单 · $site';
  }

  @override
  String get draftFlushNone => '还没能发送。请检查网络连接。';

  @override
  String draftFlushSent(int n) {
    return '已发送 $n 份 · 已记入账本。';
  }

  @override
  String get draftFlushFailed => '有草稿发送失败。请检查内容。';

  @override
  String get draftTitle => '临时保存的草稿';

  @override
  String get draftEmpty => '没有待发送的草稿。';

  @override
  String get draftHint => '网络恢复后会自动发送。想立即发送请点击下方重试。';

  @override
  String get draftSendAll => '立即全部发送';

  @override
  String get draftNoSite => '（未填工地）';

  @override
  String draftCheckNeeded(String error) {
    return '需要确认：$error';
  }

  @override
  String homeGreeting(String name) {
    return '您好，$name';
  }

  @override
  String get homeToday => '今天日程';

  @override
  String get homeMonthSummary => '本月概况';

  @override
  String get homeCheckNeeded => '需确认';

  @override
  String homeDocExpiry(String type, String dday) {
    return '$type 到期 $dday';
  }

  @override
  String get homeDocExpirySub => '请在证件夹里更新后重新登记';

  @override
  String homeDraftsPending(int n) {
    return '$n 份草稿待发送';
  }

  @override
  String get homeDraftsError => '部分草稿需确认 · 点击查看';

  @override
  String get homeDraftsAuto => '联网后会自动发送 · 点击查看';

  @override
  String get homeStampDraft => '已 填 写 · WORKON';

  @override
  String get homeStampScheduled => '待 作 业 · WORKON';

  @override
  String get homeTodayBadge => '今天';

  @override
  String get homeStampToday => '今 天 · WORKON';

  @override
  String get homeEmptyToday => '今天没有安排作业';

  @override
  String get homeEmptyTodaySub => '点击下方 + 按钮，30秒记录今天的作业。';

  @override
  String get homeDaysWorked => '出勤天数';

  @override
  String get homeReceivable => '应收（未收）';

  @override
  String get homeReceived => '已收（入账）';

  @override
  String get calViewMonth => '月';

  @override
  String get calViewWeek => '周';

  @override
  String calWorkCount(int n) {
    return '作业 $n 件';
  }

  @override
  String get calManUnit => '万';

  @override
  String get calEmptyMonth => '本月没有作业记录。';

  @override
  String get calEmptyDay => '这一天没有作业记录。';

  @override
  String get calRecordThisDay => '记录这一天的作业';

  @override
  String get ledgerTitle => '账本';

  @override
  String get ledgerOutstandingTotal => '本月未收合计';

  @override
  String ledgerWorkedThisMonth(String summary) {
    return '本月工作 $summary';
  }

  @override
  String get ledgerByCompany => '按公司';

  @override
  String ledgerCompanyCount(int n) {
    return '$n 家';
  }

  @override
  String get ledgerStamp => '账 本 · WORKON';

  @override
  String get ledgerEmptyTitle => '本月没有账本记录';

  @override
  String get ledgerEmptySub => '填写确认单后，账本会自动记录。';

  @override
  String get ledgerWriteConfirmation => '填写确认单';

  @override
  String ledgerDaysWorked(int days) {
    return '工作 $days 天';
  }

  @override
  String ledgerPaidAmount(String amount) {
    return '$amount 已入账';
  }

  @override
  String ledgerStatementFail(String error) {
    return '打开明细单失败：$error';
  }

  @override
  String get ledgerMonthlyStatement => '月度明细单 PDF';

  @override
  String get ledgerRemaining => '剩余未收';

  @override
  String get ledgerWorkHistory => '作业记录';

  @override
  String ledgerBilled(String amount) {
    return '应收 $amount';
  }

  @override
  String ledgerDeposited(String amount) {
    return '入账 $amount';
  }

  @override
  String get ledgerPaymentSaved => '已记录入账。';

  @override
  String ledgerPaymentFail(String message) {
    return '失败：$message';
  }

  @override
  String get ledgerRecordPayment => '记录入账';

  @override
  String ledgerRemainingAmount(String amount) {
    return '剩余未收 $amount';
  }

  @override
  String get ledgerPaymentAmount => '入账金额';

  @override
  String get ledgerWonSuffix => '₩';

  @override
  String get ledgerFull => '全额';

  @override
  String get ledgerHalf => '一半';

  @override
  String get ledgerRecordPaymentBtn => '记录入账';

  @override
  String get taxTitle => '税金计算书准备';

  @override
  String taxSupplierPrefix(String name) {
    return '供货方 · $name';
  }

  @override
  String get taxNoBizName => '(未登记商号)';

  @override
  String taxBizNumberLine(String number) {
    return '营业执照号 $number';
  }

  @override
  String get taxHometaxGuide =>
      '把复制的内容粘贴到 Hometax（hometax.go.kr）开税金计算书。开好后点“标记为已开”，它就会从列表里消失。';

  @override
  String get taxEmptyTitle => '没有需要开票的确认单。';

  @override
  String get taxEmptySubtitle => '这里只显示已签名(SIGNED)且未开票的确认单。';

  @override
  String get taxStamp => '税金计算书 · WORKON';

  @override
  String get taxSupplierPromptTitle => '请先填写营业信息';

  @override
  String get taxSupplierPromptDesc => '需要税金计算书供货方(您)的营业执照号和商号。';

  @override
  String get taxEnterBizInfo => '填写营业信息';

  @override
  String get taxCopiedSnack => '已复制 · 粘贴到 Hometax。';

  @override
  String get taxMarkedSnack => '已标记为已开票 · 已从列表移除。';

  @override
  String get taxAlreadyMarkedSnack => '该项目已标记为已开票。';

  @override
  String taxMarkFailed(String msg) {
    return '标记失败：$msg';
  }

  @override
  String taxBuyerBizLine(String number, int count) {
    return '营业执照号 $number · 品目 $count 项';
  }

  @override
  String get taxNotRegistered => '(未登记)';

  @override
  String get taxSupplyAmount => '供货金额';

  @override
  String get taxGrandTotal => '合计金额';

  @override
  String get taxCopy => '复制';

  @override
  String get taxMarkIssued => '标记为已开票';

  @override
  String get taxRegisteredBadge => '已登记';

  @override
  String get taxCheckNeeded => '需确认';

  @override
  String get bizinfoTitle => '营业信息';

  @override
  String get bizinfoDesc => '这是开税金计算书时使用的供货方(您)信息。';

  @override
  String get bizinfoBizNumberLabel => '营业执照号';

  @override
  String get bizinfoBizNameLabel => '商号';

  @override
  String get bizinfoBizNameHint => '商号(公司名)';

  @override
  String get bizinfoAddressLabel => '营业场所地址(选填)';

  @override
  String get bizinfoAddressHint => '营业场所地址';

  @override
  String get bizinfoSavedSnack => '营业信息已保存。';

  @override
  String bizinfoSaveFailed(String msg) {
    return '保存失败：$msg';
  }

  @override
  String get walletTitle => '证件夹';

  @override
  String walletSelectedCount(int n) {
    return '已选 $n 项';
  }

  @override
  String get walletAddDoc => '添加证件';

  @override
  String get walletMaskPromptTitle => '要遮住个人信息吗？';

  @override
  String get walletMaskPromptBody => '把身份证号、住址等敏感信息打码后，就能安全共享。';

  @override
  String get walletLater => '以后再说';

  @override
  String get walletMaskEdit => '打码编辑';

  @override
  String walletExpiredTitle(String type) {
    return '$type 已过期';
  }

  @override
  String walletExpiringTitle(String type, String dday) {
    return '$type 到期 $dday';
  }

  @override
  String walletExpiringMultiSub(int n) {
    return '$n 份证件即将到期 — 请更新后重新登记';
  }

  @override
  String get walletRenewHint => '请更新后重新登记';

  @override
  String get walletEmptyTitle => '还没有登记的证件';

  @override
  String get walletEmptySub => '登记资格证、保险、检验证，管理到期日';

  @override
  String walletShareMessage(int count, int days, String url) {
    return '[작업온] 发送 $count 份证件。\n请在下方链接查看（有效 $days 天）。\n$url';
  }

  @override
  String get walletShareSubject => '작업온 证件共享';

  @override
  String walletShareFailed(String error) {
    return '共享失败：$error';
  }

  @override
  String walletSendBundle(int count) {
    return '打包发送 $count 份';
  }

  @override
  String get walletBundleSend => '打包发送';

  @override
  String get walletValidPeriod => '有效期';

  @override
  String get walletMaskedInfo => '有打码版的证件，会以遮住个人信息的状态发送。';

  @override
  String get walletUnmaskedInfo => '没有打码版时会原样发送原件。可在详情里打码。';

  @override
  String get walletMakeLinkShare => '生成链接并共享';

  @override
  String docOpenFailed(String error) {
    return '打开失败：$error';
  }

  @override
  String docUpdateFailed(String error) {
    return '修改失败：$error';
  }

  @override
  String get docDeleteConfirmTitle => '要删除这份证件吗？';

  @override
  String get docDeleteConfirmBody => '该证件及其共享链接会一并删除。';

  @override
  String docDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String get docOpenPdf => '打开 PDF';

  @override
  String get docHasMask => '有打码版';

  @override
  String get docExpiryDate => '到期日';

  @override
  String get docNone => '无';

  @override
  String get docIssuedDate => '签发日';

  @override
  String get docReMask => '重新打码';

  @override
  String get docMaskEdit => '打码个人信息';

  @override
  String get docModify => '修改';

  @override
  String get docExpired => '已过期';

  @override
  String docUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get docSourceCamera => '用相机拍摄';

  @override
  String get docSourceGallery => '从相册选择';

  @override
  String get docSourcePdf => '选择 PDF 文件';

  @override
  String get docInfoTitle => '证件信息';

  @override
  String docFilePdf(String name) {
    return 'PDF · $name';
  }

  @override
  String docFileImage(int kb) {
    return '图片 · ${kb}KB';
  }

  @override
  String get docTypeLabel => '类型';

  @override
  String get docLinkEquip => '关联设备（可选）';

  @override
  String get docPersonal => '个人';

  @override
  String get docPickExpiry => '选择到期日（可选）';

  @override
  String get docUpload => '上传';

  @override
  String get equipTitle => '设备管理';

  @override
  String get equipAdd => '添加设备';

  @override
  String get equipEmptyTitle => '还没有登记的设备';

  @override
  String get equipEmptySub => '登记挖掘机、叉车等设备，把证件归到一起';

  @override
  String equipDocCount(int n) {
    return '$n 份证件';
  }

  @override
  String get equipDocs => '证件';

  @override
  String get equipTypeHint => '设备种类（例：挖掘机）';

  @override
  String get equipVehicleHint => '车牌号（可选）';

  @override
  String get equipSpecHint => '规格（例：06W）（可选）';

  @override
  String get equipSubmit => '添加';

  @override
  String get maskDoneToast => '已生成打码版。共享时会遮住个人信息。';

  @override
  String maskFailed(String error) {
    return '打码失败：$error';
  }

  @override
  String get maskTitle => '个人信息打码';

  @override
  String get maskReset => '重置';

  @override
  String get maskGuide => '用手指拖动，框出要遮住的区域。（例：身份证号、住址）';

  @override
  String maskRegionCount(int n) {
    return '已框选 $n 个区域';
  }

  @override
  String get maskSave => '保存打码版';

  @override
  String get wshareTitle => '我的共享';

  @override
  String wshareLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get wshareEmpty => '还没有共享过证件包';

  @override
  String get wshareActive => '有效';

  @override
  String get wshareInactive => '已过期/失效';

  @override
  String wshareViewCount(int n) {
    return '查看 $n 次';
  }

  @override
  String get wshareReshare => '再次共享';

  @override
  String get wshareRevoke => '作废';

  @override
  String myjobFailed(String error) {
    return '失败：$error';
  }

  @override
  String get myjobConditionTitle => '身体状况确认';

  @override
  String get myjobConditionBody => '今天身体状况如何？为了安全作业需要确认。';

  @override
  String get myjobConditionBad => '不太好';

  @override
  String get myjobConditionGood => '很好';

  @override
  String get myjobConditionReported => '已把身体不适告知工地方。请不要勉强。';

  @override
  String myjobLoadFailed(String error) {
    return '无法加载：$error';
  }

  @override
  String get myjobEmpty => '没有收到的派工';

  @override
  String get myjobAccept => '接受';

  @override
  String get myjobStart => '开始作业';

  @override
  String get myjobComplete => '完成作业';

  @override
  String get signPadHint => '用手指在这里签名';
}
