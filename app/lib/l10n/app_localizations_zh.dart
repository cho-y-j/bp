// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get widgetToday => '今日日程';

  @override
  String get widgetNoSchedule => '今日无日程';

  @override
  String get widgetOutstanding => '本月应收款';

  @override
  String get widgetLoginPlease => '请登录';

  @override
  String widgetSyncedAt(String time) {
    return '$time 更新';
  }

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
  String get appLockTitle => '应用锁';

  @override
  String get appLockSub => '使用生物识别或设备密码保护应用';

  @override
  String get appLockLockedTitle => '已锁定';

  @override
  String get appLockUnlock => '验证后继续';

  @override
  String get appLockReason => '解锁应用';

  @override
  String get appLockUnavailable => '此设备不支持生物识别或密码锁';

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
  String get bizSignDone => '签名完成。';

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
  String homeDocExpiry(String type, String status) {
    return '$type $status';
  }

  @override
  String homeDocExpiryDue(String dday) {
    return '到期 $dday';
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
  String get homeHeroReceivable => '本月应收';

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
  String get calMonthReceivable => '应收';

  @override
  String get calTapDayHint => '点按日期展开当天确认单';

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
  String get taxEmptySubtitle => '这里只显示已签名且未开票的确认单。';

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
  String get walletSelectSend => '选择后发送';

  @override
  String ddayOverdue(int n) {
    return '+$n天';
  }

  @override
  String get ledgerEntryActions => '管理此项';

  @override
  String get homeWriteConfirmation => '填写确认单';

  @override
  String get settleMonthTotal => '本月应付';

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

  @override
  String get teamMenuTitle => '我的班组';

  @override
  String get teamMenuSub => '作为班长管理组员名单和单价';

  @override
  String get teamListTitle => '我的班组';

  @override
  String get teamEmptyTitle => '还没有创建班组';

  @override
  String get teamEmptySub => '创建班组并添加组员后，可以把班组确认书整理成一张';

  @override
  String get teamCreate => '创建班组';

  @override
  String get teamNameLabel => '班组名称';

  @override
  String get teamNameHint => '班组名称（例：朴班长A组）';

  @override
  String get teamAddMember => '添加组员';

  @override
  String get teamMembersTitle => '组员';

  @override
  String get teamNoMembers => '请添加组员';

  @override
  String teamMemberCountLabel(int count) {
    return '组员 $count 名';
  }

  @override
  String get teamMemberLinked => '已关联';

  @override
  String get teamMemberManual => '手动';

  @override
  String get teamDefaultRate => '默认单价';

  @override
  String get teamDefaultRateHint => '默认单价（1个工数）';

  @override
  String get teamAddByPhone => '用电话号码查找';

  @override
  String get teamAddManual => '手动输入';

  @override
  String get teamMemberNameHint => '姓名';

  @override
  String get teamMemberPhoneHint => '电话号码（可选）';

  @override
  String get teamSearchPhoneHint => '组员电话号码';

  @override
  String get teamSearchHint => '只能找到同意电话搜索的注册用户';

  @override
  String get teamSearchNoResult => '没有搜索结果';

  @override
  String get teamMemberAdded => '已添加组员';

  @override
  String get teamMemberExists => '该组员已在班组中';

  @override
  String get teamConsentRequired => '只能关联同意电话搜索的注册用户';

  @override
  String get teamDeleteConfirm => '要删除此班组吗？已发行的确认书将保持不变。';

  @override
  String get teamDeleteMemberConfirm => '要删除此组员吗？';

  @override
  String get confTeamMode => '班组确认书';

  @override
  String get confTeamModeSub => '按组员工数整理成一张';

  @override
  String get confTeamSelect => '选择班组';

  @override
  String get confTeamPickTeam => '请选择班组';

  @override
  String get confTeamNoTeam => '请先在“我的班组”中创建班组';

  @override
  String get confTeamTotal => '班组合计';

  @override
  String get confTeamEmptyEntries => '没有填写工数的组员';

  @override
  String get ledgerTeamBadge => '班组';

  @override
  String ledgerTeamDerived(String boss) {
    return '$boss 班长班组作业';
  }

  @override
  String get ledgerDerivedReadonly => '这是班长填写的班组作业（只能记录收款）';

  @override
  String get lcKicker => '标准劳动合同';

  @override
  String get lcStamp => '标 准 劳 动 合 同';

  @override
  String get lcParties => '合同当事人';

  @override
  String get lcEmployer => '雇主(甲方)';

  @override
  String get lcWorkerParty => '劳动者(乙方)';

  @override
  String get lcBizNumber => '营业执照号';

  @override
  String get lcPeriod => '劳动合同期限';

  @override
  String get lcPeriodOpen => '无固定期限 · 按日';

  @override
  String get lcWorkplace => '工作地点';

  @override
  String get lcJob => '工作内容';

  @override
  String get lcWorkTime => '工作时间';

  @override
  String get lcBreak => '休息';

  @override
  String get lcWage => '工资';

  @override
  String get lcWageDaily => '日薪';

  @override
  String get lcWageHourly => '时薪';

  @override
  String get lcPayday => '工资支付日';

  @override
  String get lcPayMethod => '支付方式';

  @override
  String get lcAllowance => '津贴';

  @override
  String get lcWeeklyHoliday => '周休津贴：每周法定工作日全勤者支付周休津贴。';

  @override
  String get lcWeeklyHolidayNone => '周休津贴：不适用（日工·短时工等）。';

  @override
  String get lcOvertime => '延长·夜间·休息日劳动时，依《劳动基准法》按通常工资的50%加算支付。';

  @override
  String get lcOvertimeNone => '延长·夜间·休息日加算津贴：另行不作约定。';

  @override
  String get lcInsurance => '社会保险适用';

  @override
  String get lcInsEmployment => '雇佣保险';

  @override
  String get lcInsHealth => '健康保险';

  @override
  String get lcInsPension => '国民年金';

  @override
  String get lcInsAccident => '工伤保险';

  @override
  String get lcApplied => '适用';

  @override
  String get lcNotApplied => '不适用';

  @override
  String get lcSpecial => '特别约定';

  @override
  String get lcMasterNote => '本合同的正本为韩文版。译文仅供理解参考；如有解释差异，以韩文版为准。';

  @override
  String get lcEmployerSigned => '雇主已签名';

  @override
  String get lcMenuDesc => '与劳动者电子签署合同';

  @override
  String get lcListEmptyTitle => '还没有合同';

  @override
  String get lcListEmptySub => '为您的劳动者创建一份劳动合同';

  @override
  String get lcNewContract => '新建合同';

  @override
  String get lcStatusDraft => '草稿';

  @override
  String get lcStatusSent => '已发送';

  @override
  String get lcStatusSigned => '已签署';

  @override
  String get lcWorkerSection => '劳动者';

  @override
  String get lcWorkerByPhone => '按电话查找';

  @override
  String get lcWorkerManual => '手动输入';

  @override
  String get lcWorkerNameHint => '劳动者姓名';

  @override
  String get lcWorkerPhoneHint => '劳动者电话（可选）';

  @override
  String get lcSearchPhoneHint => '劳动者电话';

  @override
  String get lcSearchHint => '只能找到同意电话搜索的注册用户';

  @override
  String get lcSearchNoResult => '没有结果';

  @override
  String get lcWorkerLinkedBadge => '已连接';

  @override
  String get lcStartDate => '开始日期';

  @override
  String get lcEndDate => '结束日期（可选）';

  @override
  String get lcEndDateNotSet => '未设定';

  @override
  String get lcWorkplaceHint => '例）江南A工地';

  @override
  String get lcJobHint => '例）钢筋组装';

  @override
  String get lcBreakHint => '例）12:00~13:00';

  @override
  String get lcWageAmountHint => '金额';

  @override
  String get lcPaydayHint => '例）每月25日';

  @override
  String get lcPayMethodHint => '例）银行转账';

  @override
  String get lcWeeklyHolidaySwitch => '支付周休津贴';

  @override
  String get lcOvertimeSwitch => '延长·夜间·休息日加算津贴';

  @override
  String get lcSpecialHint => '特别约定（可选）';

  @override
  String get lcSaveCommon => '保存常用值';

  @override
  String get lcSaveCommonSub => '下次自动填充';

  @override
  String get lcSubmit => '创建合同';

  @override
  String get lcCreated => '合同已创建';

  @override
  String get lcDetailTitle => '合同';

  @override
  String get lcSignEmployerTitle => '我的签名（雇主）';

  @override
  String get lcSignEmployerDesc => '签名后即可发送给劳动者';

  @override
  String get lcSignerNameLabel => '签名人姓名';

  @override
  String get lcSignRedraw => '重新绘制';

  @override
  String get lcSignSubmit => '签名';

  @override
  String get lcSigned => '已签名';

  @override
  String get lcSignErrPad => '请先签名';

  @override
  String get lcSignErrName => '请输入签名人姓名';

  @override
  String get lcSend => '发送给劳动者';

  @override
  String get lcSentLinked => '已发送给劳动者';

  @override
  String get lcSentShare => '分享链接以送达';

  @override
  String get lcShareBody => '请在下方链接查看并签署合同';

  @override
  String get lcViewPdf => '查看PDF';

  @override
  String get lcDeleteConfirm => '删除此合同？';

  @override
  String get lcDeleted => '已删除';

  @override
  String get lcWaitingWorker => '等待劳动者签名';

  @override
  String get lcMyContractsTitle => '我的合同';

  @override
  String get lcMyContractsSub => '查看并签署收到的合同';

  @override
  String get lcMyEmptyTitle => '没有收到合同';

  @override
  String get lcMyEmptySub => '雇主发送的合同会显示在此';

  @override
  String get lcWorkerSignTitle => '我的签名（劳动者）';

  @override
  String get lcWorkerSignDesc => '请查看并签名';

  @override
  String get lcAlreadySigned => '已签署';

  @override
  String lcCreateFailed(String msg) {
    return '无法保存合同：$msg';
  }

  @override
  String lcSignFailed(String msg) {
    return '无法签名：$msg';
  }

  @override
  String lcSendFailed(String msg) {
    return '无法发送：$msg';
  }

  @override
  String lcPdfFailed(String msg) {
    return '无法打开PDF：$msg';
  }

  @override
  String get tbmMenuTitle => 'TBM 记录';

  @override
  String get tbmMenuDesc => '安全会议 · 危险因素与参会确认';

  @override
  String get tbmMyTitle => '收到的 TBM';

  @override
  String get tbmMySub => '我的安全记录 · 确认';

  @override
  String get tbmTitle => 'TBM(安全会议)';

  @override
  String get tbmStamp => 'T B M';

  @override
  String get tbmListEmptyTitle => '还没有 TBM 记录';

  @override
  String get tbmListEmptySub => '记录现场安全会议。';

  @override
  String get tbmNew => '新建 TBM';

  @override
  String get tbmFormTitle => '填写 TBM';

  @override
  String get tbmSite => '现场名称';

  @override
  String get tbmSiteHint => '例：A现场 3层';

  @override
  String get tbmDate => '日期时间';

  @override
  String get tbmHazards => '危险因素';

  @override
  String get tbmHazardsHint => '点击标签选择或自行输入';

  @override
  String get tbmAddCustom => '自定义';

  @override
  String get tbmCustomHint => '输入危险因素';

  @override
  String get tbmMeasures => '安全措施';

  @override
  String get tbmMeasuresHint => '例：佩戴安全带、安排指挥员';

  @override
  String get tbmNotes => '备注';

  @override
  String get tbmNotesHint => '备注（可选）';

  @override
  String get tbmAttendees => '参会人员';

  @override
  String get tbmSelectWorkers => '选择关联工人';

  @override
  String get tbmNoConnections => '没有关联工人';

  @override
  String get tbmAddAttendeeManual => '手动添加参会人';

  @override
  String get tbmAttendeeNameHint => '参会人姓名';

  @override
  String get tbmPhotos => '现场照片';

  @override
  String get tbmAddPhoto => '添加照片';

  @override
  String get tbmSave => '保存 TBM';

  @override
  String get tbmSaved => 'TBM 已记录';

  @override
  String tbmSaveFailed(String msg) {
    return '保存失败：$msg';
  }

  @override
  String get tbmNeedHazard => '请至少选择一个危险因素';

  @override
  String get tbmNeedSite => '请输入现场名称';

  @override
  String get tbmPresetMine => '我的预设';

  @override
  String get tbmPresetAddChip => '＋ 保存预设';

  @override
  String get tbmPresetAddTitle => '保存常用短语';

  @override
  String get tbmPresetDeleted => '预设已删除';

  @override
  String get tbmDetailTitle => 'TBM 详情';

  @override
  String get tbmAttendeesStatus => '参会确认状态';

  @override
  String get tbmAcked => '已确认';

  @override
  String get tbmNotAcked => '未确认';

  @override
  String tbmAckSummary(int att, int ack) {
    return '参会 $att · 确认 $ack';
  }

  @override
  String get tbmReadonly => '创建当日之后为只读';

  @override
  String get tbmEdit => '编辑';

  @override
  String get tbmDeleteConfirm => '删除此 TBM 记录？';

  @override
  String get tbmDeleted => '已删除';

  @override
  String get tbmSaveUpdated => '已更新';

  @override
  String tbmPhotoFailed(String msg) {
    return '照片处理失败：$msg';
  }

  @override
  String get tbmReceivedEmpty => '没有收到 TBM';

  @override
  String get tbmAckButton => '确认 TBM';

  @override
  String get tbmAckDone => '已确认';

  @override
  String tbmAckFailed(String msg) {
    return '确认失败：$msg';
  }

  @override
  String get tbmAlreadyAcked => '已确认';

  @override
  String tbmPhotoCount(int n) {
    return '$n 张照片';
  }

  @override
  String get tbmHzHeavyEquip => '重型机械挤压·碰撞';

  @override
  String get tbmHzFallHeight => '高处坠落';

  @override
  String get tbmHzHeatIllness => '高温中暑';

  @override
  String get tbmHzElectric => '触电';

  @override
  String get tbmHzFallingObject => '落物';

  @override
  String get tbmHzCollapse => '坍塌·掩埋';

  @override
  String get tbmHzFire => '火灾·爆炸';

  @override
  String get tbmHzDustNoise => '粉尘·噪声';

  @override
  String get tbmHzSlipTrip => '滑倒·绊倒';

  @override
  String get tbmHzConfined => '密闭空间窒息';

  @override
  String get incomeReportMenuTitle => '收入报告';

  @override
  String get incomeReportMenuSub => '年度收入·未收·工数一目了然';

  @override
  String get incomeReportTitle => '收入报告';

  @override
  String incomeReportYear(String year) {
    return '$year年';
  }

  @override
  String get incomeReportTotalBilled => '总请款额';

  @override
  String get incomeReportTotalPaid => '总入账';

  @override
  String get incomeReportTotalOutstanding => '总未收';

  @override
  String get incomeReportTotalDays => '工作天数';

  @override
  String get incomeReportTotalGongsu => '总工数';

  @override
  String get incomeReportTeamPayout => '团队支付';

  @override
  String get incomeReportNetBilled => '净收入(参考)';

  @override
  String get incomeReportNetHint => '请款额 − 队员支付(班长本人份额)';

  @override
  String get incomeReportMonthlyTrend => '月度趋势';

  @override
  String incomeReportPeakLabel(String amount) {
    return '最高 $amount';
  }

  @override
  String get incomeReportByCompany => '按对方汇总';

  @override
  String incomeReportEntryCount(int n) {
    return '$n笔';
  }

  @override
  String incomeReportOutstandingShort(String amount) {
    return '未收 $amount';
  }

  @override
  String get incomeReportTaxTitle => '综合所得税指南';

  @override
  String get incomeReportTaxL1 => '综合所得税每年5月申报并缴纳上一年度所得。';

  @override
  String get incomeReportTaxL2 => '人力服务经营所得在支付时常按3.3%预扣。';

  @override
  String get incomeReportTaxL3 => '预扣的税款在5月申报时结算(退税或补缴)。';

  @override
  String get incomeReportTaxL4 => '保留支出凭证与确认书·明细表有助于申报。';

  @override
  String get incomeReportTaxL5 => '此为一般说明,非税务咨询。准确申报请咨询税务专家或Hometax。';

  @override
  String get incomeReportSavePdf => '保存 / 分享 PDF';

  @override
  String incomeReportPdfFail(String msg) {
    return '无法打开报告:$msg';
  }

  @override
  String get incomeReportEmptyTitle => '还没有收入记录';

  @override
  String get incomeReportEmptySub => '填写确认书后,收入会显示在此报告中。';

  @override
  String get ledgerAutoRemind => '自动催收提醒';

  @override
  String get ledgerAutoRemindHint => '到期日后自动发送款项提醒';

  @override
  String get ledgerRemindNow => '立即发送提醒';

  @override
  String get ledgerRemindSent => '已发送催收提醒';

  @override
  String get ledgerRemindHistory => '提醒发送记录';

  @override
  String ledgerRemindHistoryItem(String date, String stage) {
    return '$date · $stage';
  }

  @override
  String get reminderStageD7 => '7天提醒';

  @override
  String get reminderStageD30 => '30天提醒';

  @override
  String get reminderStageManual => '手动提醒';

  @override
  String get profilePayoutSection => '收款账户（用于催收提醒）';

  @override
  String get profilePayoutBank => '银行名称';

  @override
  String get profilePayoutAccount => '账号';

  @override
  String get profilePayoutHolder => '账户持有人';

  @override
  String get profilePayoutHint => '发送催收提醒时会一并提供此账户（选填）';

  @override
  String get profilePayoutSaved => '已保存收款账户';

  @override
  String get badgeExcellent => '优质付款方';

  @override
  String get badgeGood => '良好付款方';

  @override
  String badgeAvgDays(int days) {
    return '平均$days天';
  }

  @override
  String get badgeSelfImproveGood => '15天内付款即可获得优质付款方徽章';

  @override
  String get badgeSelfImproveNone => '按时付款即可获得优质付款方徽章';

  @override
  String badgeInsufficient(int count) {
    return '付款记录$count条——评定徽章需要更多记录';
  }

  @override
  String badgeSampleCount(int count) {
    return '基于最近$count条';
  }

  @override
  String get badgeSelfTitle => '付款信誉';

  @override
  String get qrCardMenuTitle => '我的二维码名片';

  @override
  String get qrCardMenuSub => '用二维码和链接介绍自己';

  @override
  String get qrCardTitle => '我的二维码名片';

  @override
  String get qrCardScanHint => '扫描二维码即可打开我的公开资料';

  @override
  String qrCardViewCount(int count) {
    return '浏览$count次';
  }

  @override
  String get qrCardIntroLabel => '一句话介绍';

  @override
  String get qrCardIntroPlaceholder => '例：20年经验钢筋班长';

  @override
  String get qrCardIntroSaved => '已保存介绍';

  @override
  String get qrCardExposeTitle => '公开名片';

  @override
  String get qrCardExposeSub => '开启后可通过二维码和链接查看资料';

  @override
  String get qrCardHiddenHint => '当前未公开——即使打开链接也看不到名片';

  @override
  String get qrCardRotate => '重新生成链接';

  @override
  String get qrCardRotateConfirm => '生成新链接后，旧的二维码和链接将失效。是否继续？';

  @override
  String get qrCardRotateConfirmBtn => '重新生成';

  @override
  String get qrCardRotated => '已生成新的名片链接';

  @override
  String get qrCardDocValid => '证件有效';

  @override
  String get qrCardDocProblem => '需确认的证件';

  @override
  String qrCardDocExpiryLabel(String date) {
    return '到期 $date';
  }

  @override
  String get smsSendSms => '用短信发送';

  @override
  String get smsSharedInstead => '不支持短信，已改用分享打开';

  @override
  String get smsFailed => '无法打开短信应用';

  @override
  String get callButtonLabel => '拨打电话';

  @override
  String get callFailed => '无法拨打电话';

  @override
  String smsConfBodyNamed(String name, String site, String link) {
    return '$name，请签署 $site 的作业确认书：$link';
  }

  @override
  String smsConfBodyPlain(String site, String link) {
    return '请签署 $site 的作业确认书：$link';
  }

  @override
  String smsCardShareBody(String link) {
    return '给您发送名片：$link';
  }

  @override
  String smsDocBundleBody(String link) {
    return '给您发送证件：$link';
  }

  @override
  String get smsRecipientTitle => '收件人';

  @override
  String get smsRecipientHint => '输入电话号码';

  @override
  String get smsPickConnection => '从联系人中选择';

  @override
  String get smsOpenCompose => '打开短信编辑窗口';

  @override
  String get quickSendMenuTitle => '快速发送';

  @override
  String get quickSendMenuSub => '一键用短信发送名片或证件';

  @override
  String get quickSendTitle => '快速发送';

  @override
  String get quickSendAddTemplate => '添加模板';

  @override
  String get quickSendPickTemplate => '请选择要发送的模板';

  @override
  String get quickSendBuiltinSection => '默认模板';

  @override
  String get quickSendCustomSection => '我的模板';

  @override
  String quickSendNoDoc(String type) {
    return '没有‘$type’证件。请先在证件夹中登记';
  }

  @override
  String get quickSendAttachImage => '以图片附加';

  @override
  String get quickSendAttachImageSub => '直接附加证件图片，而不是链接';

  @override
  String get tplCardTitle => '名片';

  @override
  String tplCardBody(String name, String me, String link) {
    return '$name您好，$me 给您发送名片：$link';
  }

  @override
  String get tplBizTitle => '营业执照';

  @override
  String tplBizBody(String name, String me, String link) {
    return '$name，$me 给您发送营业执照：$link';
  }

  @override
  String get tplBankTitle => '存折复印件';

  @override
  String tplBankBody(String name, String me, String link) {
    return '$name，$me 给您发送存折复印件：$link';
  }

  @override
  String get tplEditorTitle => '添加模板';

  @override
  String get tplFieldTitle => '标题';

  @override
  String get tplFieldBody => '正文';

  @override
  String get tplFieldBodyHint => '例如：您好，给您发送资料';

  @override
  String get tplVarsHelp => '可用变量';

  @override
  String get tplFieldLink => '关联';

  @override
  String get tplLinkNone => '无';

  @override
  String get tplLinkCard => '名片链接';

  @override
  String get tplLinkDoc => '证件链接';

  @override
  String get tplFieldDocType => '证件类型';

  @override
  String get tplDocTypeHint => '例如：营业执照、存折复印件';

  @override
  String get tplSaveTemplate => '保存模板';

  @override
  String get tplNeedTitleBody => '请输入标题和正文';

  @override
  String postCallTitle(String name) {
    return '刚才和 $name 通话了吗？';
  }

  @override
  String get postCallSendCard => '发送名片';

  @override
  String get postCallQuickSend => '快速发送';

  @override
  String get postCallSettingTitle => '通话后发送建议';

  @override
  String get postCallSettingSub => '从应用拨打电话后返回时，建议发送名片或快速发送';

  @override
  String get attendBoardTitle => '今日出勤';

  @override
  String get attendBoardEmpty => '今天没有排定的作业';

  @override
  String get attendBoardViewDetail => '点按查看详情';

  @override
  String get attendSummaryTotal => '全部';

  @override
  String get attendSummaryAttended => '出勤';

  @override
  String get attendSummaryCompleted => '完成';

  @override
  String get attendSummaryAbsent => '未出勤';

  @override
  String attendPeopleCount(int count) {
    return '$count人';
  }

  @override
  String get attendStatusScheduled => '预定';

  @override
  String get attendStatusAccepted => '已接受';

  @override
  String get attendStatusStarted => '已开始';

  @override
  String get attendStatusDone => '完成';

  @override
  String get attendStatusCancelled => '已取消';

  @override
  String attendStartedAt(String time) {
    return '$time 开始';
  }

  @override
  String attendScheduledAt(String time) {
    return '$time 预定';
  }

  @override
  String get attendCondOk => '状态良好';

  @override
  String get attendCondBad => '状态不佳';

  @override
  String get siteCostsTitle => '各现场人工费';

  @override
  String get bizMenuSiteCostsDesc => '按现场汇总人工费·可提交PDF';

  @override
  String get siteCostsThisMonth => '本月';

  @override
  String get siteCostsLast3 => '近3个月';

  @override
  String get siteCostsLast6 => '近6个月';

  @override
  String get siteCostsLast12 => '近12个月';

  @override
  String siteCostsRangeLabel(String from, String to) {
    return '$from ~ $to';
  }

  @override
  String get siteCostsSubtotal => '小计';

  @override
  String get siteCostsTotalHeader => '总计';

  @override
  String siteCostsWorkerCount(int count) {
    return '作业者$count人';
  }

  @override
  String siteCostsTeamMembers(int count) {
    return '队员$count人';
  }

  @override
  String siteCostsEntryCount(int count) {
    return '确认单$count份';
  }

  @override
  String get siteCostsSavePdf => '保存·分享PDF';

  @override
  String siteCostsPdfFail(String error) {
    return '无法生成PDF ($error)';
  }

  @override
  String get siteCostsEmpty => '该期间没有可汇总的确认单';

  @override
  String get wageStmtTitle => '支付明细(月结)';

  @override
  String get bizMenuWageStmtDesc => '日工工资支付明细·月结';

  @override
  String get wageStmtEmpty => '本月没有支付记录';

  @override
  String get wageStmtType33 => '经营所得3.3%';

  @override
  String get wageStmtTypeDaily => '日工';

  @override
  String get wageStmtPaidTotal => '支付额';

  @override
  String get wageStmtIncomeTax => '所得税';

  @override
  String get wageStmtLocalTax => '地方所得税';

  @override
  String get wageStmtTotalTax => '预扣合计';

  @override
  String get wageStmtNetPay => '实付额';

  @override
  String wageStmtPaymentCount(int count) {
    return '支付$count笔';
  }

  @override
  String get wageStmtCopy => '复制';

  @override
  String get wageStmtCopied => '已复制明细内容';

  @override
  String get wageStmtMark => '结算本月';

  @override
  String get wageStmtMarked => '已结算';

  @override
  String wageStmtMarkedSnack(String month) {
    return '已结算$month明细';
  }

  @override
  String get wageStmtAlreadyMarked => '该月已结算';

  @override
  String wageStmtMarkFail(String error) {
    return '无法结算 ($error)';
  }

  @override
  String get wageStmtTotalHeader => '支付总计';

  @override
  String get wageStmtNoticeTitle => '提示';

  @override
  String get wageStmtWorkerTax => '按所得类型预扣';

  @override
  String siteCostsManDays(String n) {
    return '用工$n人日';
  }
}
