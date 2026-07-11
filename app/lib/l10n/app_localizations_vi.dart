// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get widgetToday => 'Lịch hôm nay';

  @override
  String get widgetNoSchedule => 'Không có lịch';

  @override
  String get widgetOutstanding => 'Nợ tháng này';

  @override
  String get widgetLoginPlease => 'Vui lòng đăng nhập';

  @override
  String widgetSyncedAt(String time) {
    return 'Cập nhật $time';
  }

  @override
  String get cancel => 'Huỷ';

  @override
  String get confirm => 'OK';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xoá';

  @override
  String get retry => 'Thử lại';

  @override
  String get close => 'Đóng';

  @override
  String get edit => 'Sửa';

  @override
  String get share => 'Chia sẻ';

  @override
  String get download => 'Tải về';

  @override
  String get view => 'Xem';

  @override
  String get loading => 'Đang tải…';

  @override
  String get errorConnTitle => 'Có vấn đề kết nối';

  @override
  String get errorConnSubtitle => 'Hãy kiểm tra kết nối mạng và thử lại.';

  @override
  String get statusDeposited => 'Đã nhận tiền';

  @override
  String get statusOverdue => 'Quá hạn';

  @override
  String collectDday(String dday) {
    return 'Thu tiền $dday';
  }

  @override
  String get amtBase => 'Cơ bản';

  @override
  String get amtOvertime => 'Tăng ca';

  @override
  String get amtEarly => 'Vào sớm';

  @override
  String get amtNight => 'Làm đêm';

  @override
  String get amtAllnight => 'Làm xuyên đêm';

  @override
  String get itemOther => 'Khác';

  @override
  String get baseDaily => 'Cơ bản (theo ngày)';

  @override
  String get baseHourly => 'Cơ bản (theo giờ)';

  @override
  String get basePerCase => 'Cơ bản (theo việc)';

  @override
  String get baseGongsu => 'Cơ bản (gongsu)';

  @override
  String get unitGongsu => 'gongsu';

  @override
  String qtyGongsu(String qty) {
    return '$qty gongsu';
  }

  @override
  String vatLabel(String rate) {
    return 'Thuế GTGT ($rate%)';
  }

  @override
  String daysCount(int days) {
    return '$days ngày';
  }

  @override
  String daysWithGongsu(int days, String gongsu) {
    return '$days ngày · $gongsu gongsu';
  }

  @override
  String get moreTitle => 'Thêm';

  @override
  String get sectionManage => 'Quản lý';

  @override
  String get sectionSettings => 'Cài đặt';

  @override
  String get menuWallet => 'Ví giấy tờ';

  @override
  String get menuWalletSub =>
      'Quản lý hạn chứng chỉ·bảo hiểm·kiểm định · gửi theo bộ';

  @override
  String get menuBizHome => 'Trang nhà thầu';

  @override
  String get menuBizMode => 'Chế độ nhà thầu';

  @override
  String get menuBizSub => 'Giao việc·phiếu nhận·thanh toán·báo cáo an toàn';

  @override
  String get menuJobs => 'Việc nhận được';

  @override
  String get menuJobsSub => 'Nhận, bắt đầu và hoàn thành việc';

  @override
  String get menuTax => 'Chuẩn bị hoá đơn thuế';

  @override
  String get menuTaxSub => 'Phiếu đã ký → dữ liệu để nhập vào Hometax';

  @override
  String get menuNotifications => 'Thông báo';

  @override
  String get menuNotificationsSub =>
      'Thu tiền·hạn giấy tờ·lịch việc·an toàn nắng nóng';

  @override
  String get consentTitle => 'Cho phép tìm bằng số điện thoại';

  @override
  String get consentSub =>
      'Nhà thầu có thể tìm và kết nối với bạn qua số của bạn';

  @override
  String get kakaoLinkTitle => 'Liên kết tài khoản Kakao';

  @override
  String get kakaoLinkedSub => 'Đã liên kết';

  @override
  String get kakaoLinkSub => 'Liên kết để đăng nhập được bằng Kakao';

  @override
  String get kakaoLinked => 'Đã liên kết tài khoản Kakao.';

  @override
  String get kakaoNotReady => 'Đăng nhập Kakao sắp có.';

  @override
  String get kakaoAlreadyLinked => 'Kakao này đã liên kết với tài khoản khác.';

  @override
  String kakaoLinkFailed(String message) {
    return 'Liên kết thất bại: $message';
  }

  @override
  String get kakaoLinkCanceled => 'Đã huỷ liên kết Kakao.';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Đăng xuất chứ?';

  @override
  String get noName => 'Chưa có tên';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get paperStamp => 'PHIẾU XÁC NHẬN CÔNG VIỆC';

  @override
  String get paperDate => 'Ngày làm';

  @override
  String get paperTime => 'Thời gian';

  @override
  String get paperSite => 'Công trình';

  @override
  String get paperWorker => 'Người làm';

  @override
  String get paperOrderer => 'Người giao việc';

  @override
  String get paperWork => 'Nội dung công việc';

  @override
  String get paperEquipment => 'Thiết bị';

  @override
  String get paperGuide => 'Người hướng dẫn';

  @override
  String get paperTotal => 'Số tiền nhận';

  @override
  String get paperMemo => 'Ghi chú';

  @override
  String get paperSignHead => 'Chữ ký người giao việc';

  @override
  String paperSignedBy(String name) {
    return '$name đã ký';
  }

  @override
  String shareCount(int n) {
    return '$n giấy tờ được chia sẻ';
  }

  @override
  String shareValidUntil(String date) {
    return 'Xem được đến $date';
  }

  @override
  String shareExpiry(String date) {
    return 'Hết hạn $date';
  }

  @override
  String get shareNoExpiry => 'Không có hạn';

  @override
  String get shareMasked => 'Bản che thông tin';

  @override
  String get statusTransientTitle => 'Lỗi tạm thời';

  @override
  String get statusTransientMsg => 'Vui lòng thử lại sau giây lát.';

  @override
  String get statusNotFoundTitle => 'Không tìm thấy liên kết';

  @override
  String get statusNotFoundMsg =>
      'Liên kết có thể đã hết hạn hoặc bị vô hiệu. Hãy hỏi người gửi để lấy liên kết mới.';

  @override
  String get authStartWithPhone => 'Bắt đầu bằng số điện thoại';

  @override
  String get authTagline =>
      'Ghi lại công việc trong 30 giây, tự động quản lý phiếu xác nhận, sổ sách và thanh toán.';

  @override
  String get authPhoneLabel => 'Số điện thoại';

  @override
  String get authCodeLabel => 'Mã xác minh';

  @override
  String get authCodeHint => 'Mã 6 chữ số';

  @override
  String get authDevAutofill => 'Chế độ phát triển: mã được điền tự động.';

  @override
  String get authRequestCode => 'Nhận mã xác minh';

  @override
  String get authVerifyStart => 'Xác minh và bắt đầu';

  @override
  String get authReenterPhone => 'Nhập lại số điện thoại';

  @override
  String get authOr => 'hoặc';

  @override
  String get authKakaoStart => 'Bắt đầu với Kakao';

  @override
  String get authKakaoPreparing =>
      'Đăng nhập Kakao đang được chuẩn bị. Vui lòng bắt đầu bằng số điện thoại.';

  @override
  String get onbWelcome => 'Chào mừng!';

  @override
  String get onbNamePrompt =>
      'Cho chúng tôi biết tên sẽ hiển thị trên phiếu xác nhận.';

  @override
  String get onbNameLabel => 'Tên';

  @override
  String get onbNameHint => 'ví dụ) Nguyễn Văn A';

  @override
  String get onbStart => 'Bắt đầu';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navCalendar => 'Lịch';

  @override
  String get navLedger => 'Sổ sách';

  @override
  String get navMore => 'Thêm';

  @override
  String get navWrite => 'Tạo';

  @override
  String navDraftsSent(int n) {
    return 'Đã tự động gửi $n bản nháp.';
  }

  @override
  String navDraftsFailed(int n) {
    return 'Gửi $n bản nháp thất bại. Vui lòng kiểm tra ở Trang chủ.';
  }

  @override
  String get notiTitle => 'Thông báo';

  @override
  String get notiEmpty => 'Không có thông báo';

  @override
  String get notiAckDone => 'Đã xác nhận.';

  @override
  String notiAckFailed(String error) {
    return 'Xác nhận thất bại: $error';
  }

  @override
  String get bizModeTitle => 'Chế độ nhà thầu';

  @override
  String bizCreateFailed(String error) {
    return 'Tạo thất bại: $error';
  }

  @override
  String get bizCreateHeading => 'Tạo nhà thầu để bắt đầu';

  @override
  String get bizCreateDesc =>
      'Kết nối người làm, giao việc, ký phiếu, thanh toán và báo cáo an toàn — tất cả ở một nơi.';

  @override
  String get bizNameHint => 'Tên công ty (ví dụ: Daesung Construction)';

  @override
  String get bizBnoHint => 'Mã số kinh doanh (không bắt buộc)';

  @override
  String get bizCreateButton => 'Tạo nhà thầu';

  @override
  String bizInviteCode(String code) {
    return 'Mã mời $code';
  }

  @override
  String get inboxTitle => 'Hộp nhận';

  @override
  String get bizMenuInboxDesc => 'Xem phiếu đã nhận, ký trong ứng dụng';

  @override
  String get settleTitle => 'Thanh toán';

  @override
  String get bizMenuSettleDesc =>
      'Tổng chưa trả theo người làm, xử lý thanh toán';

  @override
  String get workerTitle => 'Người làm & giao việc';

  @override
  String get bizMenuWorkerDesc => 'Tìm & kết nối người làm, tạo lệnh việc';

  @override
  String get jobTitle => 'Danh sách giao việc';

  @override
  String get bizMenuJobDesc => 'Xem trạng thái đặt lịch, đang làm, xong';

  @override
  String get safetyTitle => 'An toàn';

  @override
  String get bizMenuSafetyDesc => 'Báo cáo an toàn PDF, hồ sơ an toàn gần đây';

  @override
  String bizLoadFailed(String error) {
    return 'Không tải được: $error';
  }

  @override
  String get inboxEmpty => 'Chưa nhận phiếu nào';

  @override
  String get inboxStatusSigned => 'Đã ký';

  @override
  String get inboxStatusPending => 'Chờ ký';

  @override
  String get jobStatusScheduled => 'Đã đặt lịch';

  @override
  String get jobStatusInProgress => 'Đang làm';

  @override
  String get jobStatusDone => 'Xong';

  @override
  String get jobEmpty => 'Tháng này chưa có lệnh việc';

  @override
  String get jobAccepted => 'Đã nhận';

  @override
  String get jobAcceptPending => 'Chờ nhận';

  @override
  String safetyReportOpenFailed(String error) {
    return 'Mở báo cáo thất bại: $error';
  }

  @override
  String get safetyReportTitle => 'Báo cáo thực hiện an toàn';

  @override
  String get safetyReportDesc =>
      'Xem kiểm tra sức khỏe, hiệu lực giấy tờ và ghi nhận cảnh báo nắng nóng theo PDF hằng tháng.';

  @override
  String safetyOpenReport(String month) {
    return 'Mở báo cáo $month';
  }

  @override
  String get safetyHeatNotice =>
      'Khi có cảnh báo nắng nóng, người làm đã kết nối tự động nhận thông báo an toàn và được lưu lại.';

  @override
  String settlePaidSnack(String name, String amount) {
    return 'Đã trả $amount cho $name';
  }

  @override
  String settlePayFailed(String error) {
    return 'Thanh toán thất bại: $error';
  }

  @override
  String get settleEmpty => 'Tháng này không có khoản chưa trả';

  @override
  String settleEntryCount(int count) {
    return '$count khoản';
  }

  @override
  String get settlePaidDone => 'Đã trả';

  @override
  String settlePayAmount(String amount) {
    return 'Trả $amount';
  }

  @override
  String workerSearchFailed(String error) {
    return 'Tìm kiếm thất bại: $error';
  }

  @override
  String workerConnectRequested(String name) {
    return 'Đã gửi yêu cầu kết nối tới $name.';
  }

  @override
  String workerRequestFailed(String error) {
    return 'Yêu cầu thất bại: $error';
  }

  @override
  String get workerSearchHint => 'Tìm theo số điện thoại người làm';

  @override
  String get workerSearchButton => 'Tìm';

  @override
  String get workerConnectButton => 'Yêu cầu kết nối';

  @override
  String get workerConnectedHeading => 'Người làm đã kết nối';

  @override
  String get workerNoneConnected => 'Chưa có người làm nào kết nối';

  @override
  String get workerStatusConnected => 'Đã kết nối';

  @override
  String get workerStatusPending => 'Đang chờ';

  @override
  String get workerJobButton => 'Giao việc';

  @override
  String get workerAccept => 'Chấp nhận';

  @override
  String get workerJobSent => 'Đã gửi lệnh việc. Người làm sẽ được thông báo.';

  @override
  String jobFormTitle(String name) {
    return 'Giao việc cho $name';
  }

  @override
  String get jobFormSiteHint => 'Công trình (ví dụ: cải tạo Banpo Xi)';

  @override
  String get jobRateDaily => 'Theo ngày';

  @override
  String get jobRateHourly => 'Theo giờ';

  @override
  String get jobRatePerCase => 'Theo việc';

  @override
  String get jobFormRateHint => 'Đơn giá (KRW)';

  @override
  String get jobFormSubmit => 'Gửi lệnh việc';

  @override
  String jobCreateFailed(String error) {
    return 'Gửi lệnh thất bại: $error';
  }

  @override
  String get bizConfirmTitle => 'Phiếu xác nhận công việc';

  @override
  String get bizSignErrSign => 'Vui lòng ký tên.';

  @override
  String get bizSignErrName => 'Vui lòng nhập tên người ký.';

  @override
  String get bizSignDone => 'Đã ký xong. (SIGNED)';

  @override
  String bizSignFailed(String error) {
    return 'Ký thất bại: $error';
  }

  @override
  String get bizStampDefault => 'Phiếu xác nhận · WORKON';

  @override
  String get bizStampSigned => 'ĐÃ KÝ · WORKON';

  @override
  String get bizLineCounterpart => 'Bên kia';

  @override
  String get bizLineRateType => 'Loại đơn giá';

  @override
  String bizSignedBadge(String name, String at) {
    return '$name đã ký · $at';
  }

  @override
  String get bizSignInAppTitle => 'Ký ngay trong ứng dụng';

  @override
  String get bizSignInAppDesc =>
      'Ký ở dưới thì phiếu được gửi ngay cho người làm và xác nhận được chốt.';

  @override
  String get bizSignerNameLabel => 'Tên người ký';

  @override
  String get bizSignRedraw => 'Ký lại';

  @override
  String get bizSignSubmit => 'Ký và xác nhận';

  @override
  String get confNoCopySource => 'Không có phiếu cũ nào để sao chép.';

  @override
  String get confCopyPrevious => 'Sao chép phiếu cũ';

  @override
  String get confFormTitle => 'Tạo phiếu xác nhận công việc';

  @override
  String get confSiteHint => 'ví dụ) Tòa nhà A, khu 3';

  @override
  String get confWorkHint => 'Ghi lại nội dung công việc bạn đã làm';

  @override
  String get confRateType => 'Loại đơn giá';

  @override
  String get confRateDaily => 'Theo ngày';

  @override
  String get confRateHourly => 'Theo giờ';

  @override
  String get confRatePerCase => 'Theo việc';

  @override
  String get confPricePerCase => 'Đơn giá mỗi việc';

  @override
  String get confPriceGongsu => 'Đơn giá gongsu (1 gongsu = 1 ngày)';

  @override
  String get confQtyHours => 'Số giờ';

  @override
  String get confQtyCases => 'Số việc';

  @override
  String get confQtyDays => 'Số ngày';

  @override
  String get confErrGongsu => 'Nhập gongsu theo bước 0.1 (ví dụ: 0.5, 1.5).';

  @override
  String get confErrHours => 'Nhập số giờ từ 1 trở lên.';

  @override
  String get confErrCases => 'Nhập số việc từ 1 trở lên.';

  @override
  String get confErrDays => 'Nhập số ngày từ 1 trở lên.';

  @override
  String get confDueDate => 'Ngày dự kiến nhận tiền (tùy chọn)';

  @override
  String get confNotSet => 'Chưa đặt';

  @override
  String get confSaveSend => 'Lưu và gửi';

  @override
  String get confSaveHint => 'Lưu là vào sổ ngay · Gửi bằng liên kết';

  @override
  String get confStartTime => 'Giờ bắt đầu';

  @override
  String get confEndTime => 'Giờ kết thúc';

  @override
  String get confOrdererCompany => 'Người giao việc (công ty)';

  @override
  String get confLinkedBiz => 'Nhà thầu đã kết nối';

  @override
  String get confManualEntry => 'Nhập tay';

  @override
  String get confSelectBiz => 'Chọn nhà thầu đã kết nối';

  @override
  String get confCompanyHint => 'Tên công ty / người phụ trách công trình';

  @override
  String get confContactHint => 'Người liên hệ / số điện thoại (tùy chọn)';

  @override
  String get confEquipSection => 'Mục thiết bị';

  @override
  String get confEquipAutoInclude => 'Tự động thêm vào phiếu';

  @override
  String get confEquipName => 'Tên thiết bị';

  @override
  String get confVehicleNo => 'Biển số xe';

  @override
  String get confUnitPrice => 'Đơn giá';

  @override
  String get confQuantity => 'Số lượng';

  @override
  String get confAddExtra => 'Thêm mục tăng ca / làm đêm';

  @override
  String get confSavedLinked => 'Đã lưu · Đã gửi cho nhà thầu đã kết nối.';

  @override
  String get confSavedBook => 'Đã lưu · Đã vào sổ.';

  @override
  String get confDraftQueued => 'Đã lưu nháp — sẽ tự gửi khi có mạng.';

  @override
  String confSaveFailed(String message) {
    return 'Lưu thất bại: $message';
  }

  @override
  String get confRestoreTitle => 'Bạn có một bản chưa viết xong.';

  @override
  String get confRestore => 'Khôi phục';

  @override
  String get confDetailTitle => 'Phiếu xác nhận công việc';

  @override
  String get confSentLinked => 'Đã gửi cho nhà thầu đã kết nối.';

  @override
  String confSendFailed(String message) {
    return 'Gửi thất bại: $message';
  }

  @override
  String get confReshare => 'Chia sẻ lại';

  @override
  String get confSendToLinked => 'Sẽ gửi cho nhà thầu đã kết nối';

  @override
  String get confSendViaShare =>
      'Có thể gửi liên kết qua bảng chia sẻ (KakaoTalk, v.v.)';

  @override
  String get confCounterparty => 'bên kia';

  @override
  String get confSentWaitingSign => 'Đã gửi · Đang chờ bên kia ký';

  @override
  String get confDraftBeforeSend => 'Đã soạn · Chưa gửi';

  @override
  String confShareHeader(String site) {
    return '[Phiếu xác nhận công việc] $site';
  }

  @override
  String get confShareBody =>
      'Vui lòng xem nội dung và ký ở liên kết bên dưới.';

  @override
  String confShareSubject(String site) {
    return 'Phiếu xác nhận công việc · $site';
  }

  @override
  String get draftFlushNone => 'Chưa gửi được. Hãy kiểm tra kết nối.';

  @override
  String draftFlushSent(int n) {
    return 'Đã gửi $n · Đã vào sổ.';
  }

  @override
  String get draftFlushFailed =>
      'Một số bản nháp gửi không thành công. Hãy kiểm tra lại.';

  @override
  String get draftTitle => 'Bản nháp đã lưu';

  @override
  String get draftEmpty => 'Không có bản nháp nào chờ gửi.';

  @override
  String get draftHint =>
      'Sẽ tự gửi khi có mạng lại. Muốn gửi ngay thì bấm thử lại bên dưới.';

  @override
  String get draftSendAll => 'Gửi tất cả ngay';

  @override
  String get draftNoSite => '(Chưa nhập công trình)';

  @override
  String draftCheckNeeded(String error) {
    return 'Cần kiểm tra: $error';
  }

  @override
  String homeGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String get homeToday => 'Lịch hôm nay';

  @override
  String get homeMonthSummary => 'Tháng này';

  @override
  String get homeCheckNeeded => 'Cần kiểm tra';

  @override
  String homeDocExpiry(String type, String dday) {
    return '$type hết hạn $dday';
  }

  @override
  String get homeDocExpirySub => 'Cập nhật trong ví giấy tờ rồi đăng ký lại';

  @override
  String homeDraftsPending(int n) {
    return '$n bản nháp chờ gửi';
  }

  @override
  String get homeDraftsError => 'Vài bản nháp cần kiểm tra · Chạm để xem';

  @override
  String get homeDraftsAuto => 'Sẽ tự gửi khi có mạng · Chạm để xem';

  @override
  String get homeStampDraft => 'ĐÃ SOẠN · WORKON';

  @override
  String get homeStampScheduled => 'SẮP LÀM · WORKON';

  @override
  String get homeTodayBadge => 'Hôm nay';

  @override
  String get homeStampToday => 'HÔM NAY · WORKON';

  @override
  String get homeEmptyToday => 'Hôm nay chưa có lịch làm';

  @override
  String get homeEmptyTodaySub =>
      'Chạm nút + bên dưới để ghi việc hôm nay trong 30 giây.';

  @override
  String get homeDaysWorked => 'Số ngày làm';

  @override
  String get homeReceivable => 'Tiền cần thu (chưa trả)';

  @override
  String get homeReceived => 'Đã nhận (đã trả)';

  @override
  String get calViewMonth => 'Tháng';

  @override
  String get calViewWeek => 'Tuần';

  @override
  String calWorkCount(int n) {
    return '$n công việc';
  }

  @override
  String get calManUnit => 'k';

  @override
  String get calEmptyMonth => 'Chưa có công việc trong tháng này.';

  @override
  String get calEmptyDay => 'Chưa có công việc trong ngày này.';

  @override
  String get calRecordThisDay => 'Ghi việc cho ngày này';

  @override
  String get ledgerTitle => 'Sổ sách';

  @override
  String get ledgerOutstandingTotal => 'Chưa thu tháng này';

  @override
  String ledgerWorkedThisMonth(String summary) {
    return 'Tháng này làm $summary';
  }

  @override
  String get ledgerByCompany => 'Theo công ty';

  @override
  String ledgerCompanyCount(int n) {
    return '$n công ty';
  }

  @override
  String get ledgerStamp => 'SỔ SÁCH · WORKON';

  @override
  String get ledgerEmptyTitle => 'Chưa có ghi chép trong tháng này';

  @override
  String get ledgerEmptySub => 'Viết phiếu xác nhận, sổ sẽ tự cập nhật.';

  @override
  String get ledgerWriteConfirmation => 'Viết phiếu xác nhận';

  @override
  String ledgerDaysWorked(int days) {
    return 'Làm $days ngày';
  }

  @override
  String ledgerPaidAmount(String amount) {
    return '$amount đã trả';
  }

  @override
  String ledgerStatementFail(String error) {
    return 'Không mở được bảng kê: $error';
  }

  @override
  String get ledgerMonthlyStatement => 'Bảng kê tháng (PDF)';

  @override
  String get ledgerRemaining => 'Còn chưa thu';

  @override
  String get ledgerWorkHistory => 'Lịch sử công việc';

  @override
  String ledgerBilled(String amount) {
    return 'Yêu cầu $amount';
  }

  @override
  String ledgerDeposited(String amount) {
    return 'Đã trả $amount';
  }

  @override
  String get ledgerPaymentSaved => 'Đã ghi khoản trả.';

  @override
  String ledgerPaymentFail(String message) {
    return 'Thất bại: $message';
  }

  @override
  String get ledgerRecordPayment => 'Ghi khoản trả';

  @override
  String ledgerRemainingAmount(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String get ledgerPaymentAmount => 'Số tiền trả';

  @override
  String get ledgerWonSuffix => '₩';

  @override
  String get ledgerFull => 'Toàn bộ';

  @override
  String get ledgerHalf => 'Một nửa';

  @override
  String get ledgerRecordPaymentBtn => 'Ghi khoản trả';

  @override
  String get taxTitle => 'Chuẩn bị hóa đơn thuế';

  @override
  String taxSupplierPrefix(String name) {
    return 'Bên cung cấp · $name';
  }

  @override
  String get taxNoBizName => '(Chưa có tên doanh nghiệp)';

  @override
  String taxBizNumberLine(String number) {
    return 'Mã số DN $number';
  }

  @override
  String get taxHometaxGuide =>
      'Dán nội dung đã sao chép vào Hometax (hometax.go.kr) khi phát hành hóa đơn thuế. Sau khi phát hành, nhấn \"Đánh dấu đã phát hành\" để xóa khỏi danh sách.';

  @override
  String get taxEmptyTitle => 'Không có phiếu xác nhận nào cần phát hành.';

  @override
  String get taxEmptySubtitle =>
      'Chỉ những phiếu đã ký (SIGNED) và chưa phát hành mới hiện ở đây.';

  @override
  String get taxStamp => 'HÓA ĐƠN THUẾ · WORKON';

  @override
  String get taxSupplierPromptTitle => 'Nhập thông tin doanh nghiệp trước';

  @override
  String get taxSupplierPromptDesc =>
      'Cần mã số doanh nghiệp và tên của bên cung cấp (bạn) cho hóa đơn thuế.';

  @override
  String get taxEnterBizInfo => 'Nhập thông tin doanh nghiệp';

  @override
  String get taxCopiedSnack => 'Đã sao chép · dán vào Hometax.';

  @override
  String get taxMarkedSnack =>
      'Đã đánh dấu đã phát hành · đã xóa khỏi danh sách.';

  @override
  String get taxAlreadyMarkedSnack => 'Mục này đã được đánh dấu đã phát hành.';

  @override
  String taxMarkFailed(String msg) {
    return 'Đánh dấu thất bại: $msg';
  }

  @override
  String taxBuyerBizLine(String number, int count) {
    return 'Mã số DN $number · $count mục';
  }

  @override
  String get taxNotRegistered => '(Chưa đăng ký)';

  @override
  String get taxSupplyAmount => 'Giá trị cung cấp';

  @override
  String get taxGrandTotal => 'Tổng cộng';

  @override
  String get taxCopy => 'Sao chép';

  @override
  String get taxMarkIssued => 'Đánh dấu đã phát hành';

  @override
  String get taxRegisteredBadge => 'Đã đăng ký';

  @override
  String get taxCheckNeeded => 'Cần kiểm tra';

  @override
  String get bizinfoTitle => 'Thông tin doanh nghiệp';

  @override
  String get bizinfoDesc =>
      'Đây là thông tin bên cung cấp (bạn) dùng để phát hành hóa đơn thuế.';

  @override
  String get bizinfoBizNumberLabel => 'Mã số doanh nghiệp';

  @override
  String get bizinfoBizNameLabel => 'Tên doanh nghiệp';

  @override
  String get bizinfoBizNameHint => 'Tên doanh nghiệp (công ty)';

  @override
  String get bizinfoAddressLabel => 'Địa chỉ kinh doanh (tùy chọn)';

  @override
  String get bizinfoAddressHint => 'Địa chỉ kinh doanh';

  @override
  String get bizinfoSavedSnack => 'Đã lưu thông tin doanh nghiệp.';

  @override
  String bizinfoSaveFailed(String msg) {
    return 'Lưu thất bại: $msg';
  }

  @override
  String get walletTitle => 'Ví giấy tờ';

  @override
  String walletSelectedCount(int n) {
    return 'Đã chọn $n';
  }

  @override
  String get walletAddDoc => 'Thêm giấy tờ';

  @override
  String get walletMaskPromptTitle => 'Che thông tin cá nhân?';

  @override
  String get walletMaskPromptBody =>
      'Che thông tin nhạy cảm như số CMND, địa chỉ để chia sẻ an toàn.';

  @override
  String get walletLater => 'Để sau';

  @override
  String get walletMaskEdit => 'Chỉnh che';

  @override
  String walletExpiredTitle(String type) {
    return '$type đã hết hạn';
  }

  @override
  String walletExpiringTitle(String type, String dday) {
    return '$type hết hạn $dday';
  }

  @override
  String walletExpiringMultiSub(int n) {
    return '$n giấy tờ sắp hết hạn — hãy gia hạn rồi đăng ký lại';
  }

  @override
  String get walletRenewHint => 'Hãy gia hạn rồi đăng ký lại';

  @override
  String get walletEmptyTitle => 'Chưa có giấy tờ nào';

  @override
  String get walletEmptySub =>
      'Thêm chứng chỉ, bảo hiểm, giấy kiểm định và theo dõi hạn dùng';

  @override
  String walletShareMessage(int count, int days, String url) {
    return '[작업온] Gửi $count giấy tờ.\nXem ở liên kết bên dưới (còn hạn $days ngày).\n$url';
  }

  @override
  String get walletShareSubject => 'Chia sẻ giấy tờ 작업온';

  @override
  String walletShareFailed(String error) {
    return 'Chia sẻ thất bại: $error';
  }

  @override
  String walletSendBundle(int count) {
    return 'Gửi gộp $count giấy tờ';
  }

  @override
  String get walletBundleSend => 'Gửi theo bộ';

  @override
  String get walletValidPeriod => 'Thời hạn';

  @override
  String get walletMaskedInfo =>
      'Giấy tờ có bản che sẽ được gửi với thông tin cá nhân đã bị che.';

  @override
  String get walletUnmaskedInfo =>
      'Nếu không có bản che, bản gốc sẽ được gửi nguyên trạng. Bạn có thể che trong phần chi tiết.';

  @override
  String get walletMakeLinkShare => 'Tạo liên kết & chia sẻ';

  @override
  String docOpenFailed(String error) {
    return 'Không mở được: $error';
  }

  @override
  String docUpdateFailed(String error) {
    return 'Cập nhật thất bại: $error';
  }

  @override
  String get docDeleteConfirmTitle => 'Xóa giấy tờ này?';

  @override
  String get docDeleteConfirmBody =>
      'Giấy tờ này và các liên kết chia sẻ sẽ bị xóa cùng.';

  @override
  String docDeleteFailed(String error) {
    return 'Xóa thất bại: $error';
  }

  @override
  String get docOpenPdf => 'Mở PDF';

  @override
  String get docHasMask => 'Có bản che';

  @override
  String get docExpiryDate => 'Ngày hết hạn';

  @override
  String get docNone => 'Không có';

  @override
  String get docIssuedDate => 'Ngày cấp';

  @override
  String get docReMask => 'Chỉnh lại bản che';

  @override
  String get docMaskEdit => 'Che thông tin cá nhân';

  @override
  String get docModify => 'Sửa';

  @override
  String get docExpired => 'Đã hết hạn';

  @override
  String docUploadFailed(String error) {
    return 'Tải lên thất bại: $error';
  }

  @override
  String get docSourceCamera => 'Chụp ảnh';

  @override
  String get docSourceGallery => 'Chọn từ thư viện';

  @override
  String get docSourcePdf => 'Chọn tệp PDF';

  @override
  String get docInfoTitle => 'Thông tin giấy tờ';

  @override
  String docFilePdf(String name) {
    return 'PDF · $name';
  }

  @override
  String docFileImage(int kb) {
    return 'Ảnh · ${kb}KB';
  }

  @override
  String get docTypeLabel => 'Loại';

  @override
  String get docLinkEquip => 'Liên kết thiết bị (tùy chọn)';

  @override
  String get docPersonal => 'Cá nhân';

  @override
  String get docPickExpiry => 'Chọn ngày hết hạn (tùy chọn)';

  @override
  String get docUpload => 'Tải lên';

  @override
  String get equipTitle => 'Quản lý thiết bị';

  @override
  String get equipAdd => 'Thêm thiết bị';

  @override
  String get equipEmptyTitle => 'Chưa có thiết bị nào';

  @override
  String get equipEmptySub =>
      'Thêm thiết bị như máy xúc, xe nâng và gom giấy tờ của chúng';

  @override
  String equipDocCount(int n) {
    return '$n giấy tờ';
  }

  @override
  String get equipDocs => 'Giấy tờ';

  @override
  String get equipTypeHint => 'Loại thiết bị (ví dụ: máy xúc)';

  @override
  String get equipVehicleHint => 'Biển số xe (tùy chọn)';

  @override
  String get equipSpecHint => 'Thông số (ví dụ: 06W) (tùy chọn)';

  @override
  String get equipSubmit => 'Thêm';

  @override
  String get maskDoneToast =>
      'Đã tạo bản che. Khi chia sẻ, thông tin cá nhân sẽ bị ẩn.';

  @override
  String maskFailed(String error) {
    return 'Che thất bại: $error';
  }

  @override
  String get maskTitle => 'Che thông tin cá nhân';

  @override
  String get maskReset => 'Đặt lại';

  @override
  String get maskGuide =>
      'Dùng ngón tay kéo để khoanh vùng cần che thành hình chữ nhật. (ví dụ: số CMND, địa chỉ)';

  @override
  String maskRegionCount(int n) {
    return 'Đã khoanh $n vùng';
  }

  @override
  String get maskSave => 'Lưu bản che';

  @override
  String get wshareTitle => 'Chia sẻ của tôi';

  @override
  String wshareLoadFailed(String error) {
    return 'Không tải được: $error';
  }

  @override
  String get wshareEmpty => 'Bạn chưa chia sẻ bộ giấy tờ nào';

  @override
  String get wshareActive => 'Đang hoạt động';

  @override
  String get wshareInactive => 'Hết hạn/vô hiệu';

  @override
  String wshareViewCount(int n) {
    return '$n lượt xem';
  }

  @override
  String get wshareReshare => 'Chia sẻ lại';

  @override
  String get wshareRevoke => 'Vô hiệu hóa';

  @override
  String myjobFailed(String error) {
    return 'Thất bại: $error';
  }

  @override
  String get myjobConditionTitle => 'Kiểm tra sức khoẻ';

  @override
  String get myjobConditionBody =>
      'Hôm nay bạn thấy trong người thế nào? Kiểm tra để làm việc an toàn.';

  @override
  String get myjobConditionBad => 'Không khoẻ';

  @override
  String get myjobConditionGood => 'Khoẻ';

  @override
  String get myjobConditionReported =>
      'Đã báo cho nhà thầu về tình trạng sức khoẻ của bạn. Đừng cố quá sức.';

  @override
  String myjobLoadFailed(String error) {
    return 'Không tải được: $error';
  }

  @override
  String get myjobEmpty => 'Chưa có việc được giao';

  @override
  String get myjobAccept => 'Nhận việc';

  @override
  String get myjobStart => 'Bắt đầu làm';

  @override
  String get myjobComplete => 'Hoàn thành';

  @override
  String get signPadHint => 'Ký ở đây bằng ngón tay';

  @override
  String get teamMenuTitle => 'Đội của tôi';

  @override
  String get teamMenuSub =>
      'Quản lý danh sách và đơn giá thành viên với tư cách đội trưởng';

  @override
  String get teamListTitle => 'Đội của tôi';

  @override
  String get teamEmptyTitle => 'Bạn chưa tạo đội nào';

  @override
  String get teamEmptySub =>
      'Tạo đội và thêm thành viên để gộp phiếu xác nhận của đội vào một tờ';

  @override
  String get teamCreate => 'Tạo đội';

  @override
  String get teamNameLabel => 'Tên đội';

  @override
  String get teamNameHint => 'Tên đội (ví dụ: Đội A của Park)';

  @override
  String get teamAddMember => 'Thêm thành viên';

  @override
  String get teamMembersTitle => 'Thành viên';

  @override
  String get teamNoMembers => 'Vui lòng thêm thành viên';

  @override
  String teamMemberCountLabel(int count) {
    return '$count thành viên';
  }

  @override
  String get teamMemberLinked => 'Đã liên kết';

  @override
  String get teamMemberManual => 'Thủ công';

  @override
  String get teamDefaultRate => 'Đơn giá mặc định';

  @override
  String get teamDefaultRateHint => 'Đơn giá mặc định (1 công)';

  @override
  String get teamAddByPhone => 'Tìm bằng số điện thoại';

  @override
  String get teamAddManual => 'Nhập thủ công';

  @override
  String get teamMemberNameHint => 'Tên';

  @override
  String get teamMemberPhoneHint => 'Số điện thoại (tùy chọn)';

  @override
  String get teamSearchPhoneHint => 'Số điện thoại thành viên';

  @override
  String get teamSearchHint =>
      'Chỉ tìm được người dùng đã đồng ý tìm kiếm bằng số điện thoại';

  @override
  String get teamSearchNoResult => 'Không có kết quả';

  @override
  String get teamMemberAdded => 'Đã thêm thành viên';

  @override
  String get teamMemberExists => 'Thành viên này đã có trong đội';

  @override
  String get teamConsentRequired =>
      'Chỉ liên kết được người dùng đã đồng ý tìm kiếm bằng số điện thoại';

  @override
  String get teamDeleteConfirm =>
      'Xóa đội này? Các phiếu xác nhận đã phát hành vẫn được giữ nguyên.';

  @override
  String get teamDeleteMemberConfirm => 'Xóa thành viên này?';

  @override
  String get confTeamMode => 'Phiếu xác nhận đội';

  @override
  String get confTeamModeSub => 'Gộp công của từng thành viên vào một tờ';

  @override
  String get confTeamSelect => 'Chọn đội';

  @override
  String get confTeamPickTeam => 'Vui lòng chọn đội';

  @override
  String get confTeamNoTeam => 'Trước tiên hãy tạo đội trong \'Đội của tôi\'';

  @override
  String get confTeamTotal => 'Tổng của đội';

  @override
  String get confTeamEmptyEntries => 'Chưa có thành viên nào nhập công';

  @override
  String get ledgerTeamBadge => 'Đội';

  @override
  String ledgerTeamDerived(String boss) {
    return 'Công việc đội của $boss';
  }

  @override
  String get ledgerDerivedReadonly =>
      'Đây là công việc đội do đội trưởng lập (bạn chỉ có thể ghi nhận thanh toán)';

  @override
  String get lcKicker => 'Hợp đồng lao động tiêu chuẩn';

  @override
  String get lcStamp => 'HỢP ĐỒNG LAO ĐỘNG';

  @override
  String get lcParties => 'Các bên hợp đồng';

  @override
  String get lcEmployer => 'Người sử dụng lao động (bên A)';

  @override
  String get lcWorkerParty => 'Người lao động (bên B)';

  @override
  String get lcBizNumber => 'Mã số doanh nghiệp';

  @override
  String get lcPeriod => 'Thời hạn hợp đồng';

  @override
  String get lcPeriodOpen => 'Không xác định thời hạn · theo ngày';

  @override
  String get lcWorkplace => 'Nơi làm việc';

  @override
  String get lcJob => 'Nội dung công việc';

  @override
  String get lcWorkTime => 'Thời gian làm việc';

  @override
  String get lcBreak => 'Nghỉ giải lao';

  @override
  String get lcWage => 'Tiền lương';

  @override
  String get lcWageDaily => 'Lương ngày';

  @override
  String get lcWageHourly => 'Lương giờ';

  @override
  String get lcPayday => 'Ngày trả lương';

  @override
  String get lcPayMethod => 'Phương thức trả';

  @override
  String get lcAllowance => 'Phụ cấp';

  @override
  String get lcWeeklyHoliday =>
      'Phụ cấp nghỉ tuần: đi làm đủ ngày quy định trong tuần sẽ được trả phụ cấp nghỉ tuần.';

  @override
  String get lcWeeklyHolidayNone =>
      'Phụ cấp nghỉ tuần: không áp dụng (lao động ngày/bán thời gian).';

  @override
  String get lcOvertime =>
      'Làm thêm giờ, ban đêm, ngày nghỉ được trả thêm 50% tiền lương thông thường theo luật lao động.';

  @override
  String get lcOvertimeNone =>
      'Phụ cấp làm thêm/ban đêm/ngày nghỉ: không quy định riêng.';

  @override
  String get lcInsurance => 'Áp dụng bảo hiểm xã hội';

  @override
  String get lcInsEmployment => 'Bảo hiểm việc làm';

  @override
  String get lcInsHealth => 'Bảo hiểm y tế';

  @override
  String get lcInsPension => 'Bảo hiểm hưu trí quốc gia';

  @override
  String get lcInsAccident => 'Bảo hiểm tai nạn lao động';

  @override
  String get lcApplied => 'Áp dụng';

  @override
  String get lcNotApplied => 'Không áp dụng';

  @override
  String get lcSpecial => 'Điều khoản đặc biệt';

  @override
  String get lcMasterNote =>
      'Bản chính của hợp đồng này là bản tiếng Hàn. Bản dịch chỉ nhằm hỗ trợ hiểu; nếu có khác biệt về giải thích, bản tiếng Hàn được ưu tiên.';

  @override
  String get lcEmployerSigned => 'Người sử dụng lao động đã ký';

  @override
  String get lcMenuDesc => 'Ký hợp đồng điện tử với người lao động';

  @override
  String get lcListEmptyTitle => 'Chưa có hợp đồng';

  @override
  String get lcListEmptySub =>
      'Tạo hợp đồng lao động với người lao động của bạn';

  @override
  String get lcNewContract => 'Tạo hợp đồng';

  @override
  String get lcStatusDraft => 'Bản nháp';

  @override
  String get lcStatusSent => 'Đã gửi';

  @override
  String get lcStatusSigned => 'Đã ký';

  @override
  String get lcWorkerSection => 'Người lao động';

  @override
  String get lcWorkerByPhone => 'Tìm theo SĐT';

  @override
  String get lcWorkerManual => 'Nhập thủ công';

  @override
  String get lcWorkerNameHint => 'Tên người lao động';

  @override
  String get lcWorkerPhoneHint => 'SĐT người lao động (tùy chọn)';

  @override
  String get lcSearchPhoneHint => 'SĐT người lao động';

  @override
  String get lcSearchHint =>
      'Chỉ tìm được người dùng đã đồng ý tìm kiếm qua SĐT';

  @override
  String get lcSearchNoResult => 'Không có kết quả';

  @override
  String get lcWorkerLinkedBadge => 'Đã liên kết';

  @override
  String get lcStartDate => 'Ngày bắt đầu';

  @override
  String get lcEndDate => 'Ngày kết thúc (tùy chọn)';

  @override
  String get lcEndDateNotSet => 'Không đặt';

  @override
  String get lcWorkplaceHint => 'VD) Công trường A, Gangnam';

  @override
  String get lcJobHint => 'VD) Lắp cốt thép';

  @override
  String get lcBreakHint => 'VD) 12:00-13:00';

  @override
  String get lcWageAmountHint => 'Số tiền';

  @override
  String get lcPaydayHint => 'VD) Ngày 25 hằng tháng';

  @override
  String get lcPayMethodHint => 'VD) Chuyển khoản';

  @override
  String get lcWeeklyHolidaySwitch => 'Trả phụ cấp nghỉ tuần';

  @override
  String get lcOvertimeSwitch => 'Phụ cấp làm thêm/đêm/ngày nghỉ';

  @override
  String get lcSpecialHint => 'Điều khoản đặc biệt (tùy chọn)';

  @override
  String get lcSaveCommon => 'Lưu giá trị thường dùng';

  @override
  String get lcSaveCommonSub => 'Tự động điền lần sau';

  @override
  String get lcSubmit => 'Tạo hợp đồng';

  @override
  String get lcCreated => 'Đã tạo hợp đồng';

  @override
  String get lcDetailTitle => 'Hợp đồng';

  @override
  String get lcSignEmployerTitle => 'Chữ ký của tôi (NSDLĐ)';

  @override
  String get lcSignEmployerDesc => 'Ký để gửi cho người lao động';

  @override
  String get lcSignerNameLabel => 'Tên người ký';

  @override
  String get lcSignRedraw => 'Vẽ lại';

  @override
  String get lcSignSubmit => 'Ký';

  @override
  String get lcSigned => 'Đã ký';

  @override
  String get lcSignErrPad => 'Vui lòng ký trước';

  @override
  String get lcSignErrName => 'Vui lòng nhập tên người ký';

  @override
  String get lcSend => 'Gửi cho người lao động';

  @override
  String get lcSentLinked => 'Đã gửi cho người lao động';

  @override
  String get lcSentShare => 'Chia sẻ liên kết để gửi';

  @override
  String get lcShareBody => 'Vui lòng xem và ký hợp đồng tại liên kết bên dưới';

  @override
  String get lcViewPdf => 'Xem PDF';

  @override
  String get lcDeleteConfirm => 'Xóa hợp đồng này?';

  @override
  String get lcDeleted => 'Đã xóa';

  @override
  String get lcWaitingWorker => 'Đang chờ người lao động ký';

  @override
  String get lcMyContractsTitle => 'Hợp đồng của tôi';

  @override
  String get lcMyContractsSub => 'Xem và ký hợp đồng đã nhận';

  @override
  String get lcMyEmptyTitle => 'Chưa nhận hợp đồng';

  @override
  String get lcMyEmptySub => 'Hợp đồng do NSDLĐ gửi sẽ hiện ở đây';

  @override
  String get lcWorkerSignTitle => 'Chữ ký của tôi (NLĐ)';

  @override
  String get lcWorkerSignDesc => 'Vui lòng xem và ký';

  @override
  String get lcAlreadySigned => 'Đã ký rồi';

  @override
  String lcCreateFailed(String msg) {
    return 'Không thể lưu hợp đồng: $msg';
  }

  @override
  String lcSignFailed(String msg) {
    return 'Không thể ký: $msg';
  }

  @override
  String lcSendFailed(String msg) {
    return 'Không thể gửi: $msg';
  }

  @override
  String lcPdfFailed(String msg) {
    return 'Không thể mở PDF: $msg';
  }

  @override
  String get tbmMenuTitle => 'Ghi TBM';

  @override
  String get tbmMenuDesc => 'Họp an toàn · rủi ro & xác nhận người dự';

  @override
  String get tbmMyTitle => 'TBM đã nhận';

  @override
  String get tbmMySub => 'Hồ sơ an toàn của tôi · xác nhận';

  @override
  String get tbmTitle => 'TBM (Họp an toàn)';

  @override
  String get tbmStamp => 'T B M';

  @override
  String get tbmListEmptyTitle => 'Chưa có TBM nào';

  @override
  String get tbmListEmptySub => 'Ghi lại buổi họp an toàn tại công trường.';

  @override
  String get tbmNew => 'TBM mới';

  @override
  String get tbmFormTitle => 'Viết TBM';

  @override
  String get tbmSite => 'Công trường';

  @override
  String get tbmSiteHint => 'vd: Công trường A, tầng 3';

  @override
  String get tbmDate => 'Ngày giờ';

  @override
  String get tbmHazards => 'Rủi ro';

  @override
  String get tbmHazardsHint => 'Chạm để chọn hoặc tự nhập';

  @override
  String get tbmAddCustom => 'Tự nhập';

  @override
  String get tbmCustomHint => 'Nhập rủi ro';

  @override
  String get tbmMeasures => 'Biện pháp an toàn';

  @override
  String get tbmMeasuresHint => 'vd: đeo dây an toàn, bố trí người điều phối';

  @override
  String get tbmNotes => 'Ghi chú';

  @override
  String get tbmNotesHint => 'Ghi chú (tuỳ chọn)';

  @override
  String get tbmAttendees => 'Người dự';

  @override
  String get tbmSelectWorkers => 'Chọn thợ đã liên kết';

  @override
  String get tbmNoConnections => 'Chưa có thợ liên kết';

  @override
  String get tbmAddAttendeeManual => 'Thêm người dự thủ công';

  @override
  String get tbmAttendeeNameHint => 'Tên người dự';

  @override
  String get tbmPhotos => 'Ảnh công trường';

  @override
  String get tbmAddPhoto => 'Thêm ảnh';

  @override
  String get tbmSave => 'Lưu TBM';

  @override
  String get tbmSaved => 'Đã ghi TBM';

  @override
  String tbmSaveFailed(String msg) {
    return 'Không lưu được: $msg';
  }

  @override
  String get tbmNeedHazard => 'Chọn ít nhất một rủi ro';

  @override
  String get tbmNeedSite => 'Nhập tên công trường';

  @override
  String get tbmPresetMine => 'Mẫu của tôi';

  @override
  String get tbmPresetAddChip => '＋ Lưu mẫu';

  @override
  String get tbmPresetAddTitle => 'Lưu cụm từ hay dùng';

  @override
  String get tbmPresetDeleted => 'Đã xoá mẫu';

  @override
  String get tbmDetailTitle => 'Chi tiết TBM';

  @override
  String get tbmAttendeesStatus => 'Trạng thái xác nhận';

  @override
  String get tbmAcked => 'Đã xác nhận';

  @override
  String get tbmNotAcked => 'Chưa xác nhận';

  @override
  String tbmAckSummary(int att, int ack) {
    return '$att dự · $ack xác nhận';
  }

  @override
  String get tbmReadonly => 'Chỉ đọc sau ngày tạo';

  @override
  String get tbmEdit => 'Sửa';

  @override
  String get tbmDeleteConfirm => 'Xoá bản ghi TBM này?';

  @override
  String get tbmDeleted => 'Đã xoá';

  @override
  String get tbmSaveUpdated => 'Đã cập nhật';

  @override
  String tbmPhotoFailed(String msg) {
    return 'Lỗi ảnh: $msg';
  }

  @override
  String get tbmReceivedEmpty => 'Chưa nhận TBM';

  @override
  String get tbmAckButton => 'Xác nhận TBM';

  @override
  String get tbmAckDone => 'Đã xác nhận';

  @override
  String tbmAckFailed(String msg) {
    return 'Không xác nhận được: $msg';
  }

  @override
  String get tbmAlreadyAcked => 'Đã xác nhận';

  @override
  String tbmPhotoCount(int n) {
    return '$n ảnh';
  }

  @override
  String get tbmHzHeavyEquip => 'Kẹt/va chạm máy nặng';

  @override
  String get tbmHzFallHeight => 'Ngã từ trên cao';

  @override
  String get tbmHzHeatIllness => 'Bệnh do nắng nóng';

  @override
  String get tbmHzElectric => 'Điện giật';

  @override
  String get tbmHzFallingObject => 'Vật rơi';

  @override
  String get tbmHzCollapse => 'Sập/vùi lấp';

  @override
  String get tbmHzFire => 'Cháy/nổ';

  @override
  String get tbmHzDustNoise => 'Bụi/tiếng ồn';

  @override
  String get tbmHzSlipTrip => 'Trượt/vấp';

  @override
  String get tbmHzConfined => 'Ngạt không gian kín';

  @override
  String get incomeReportMenuTitle => 'Báo cáo thu nhập';

  @override
  String get incomeReportMenuSub => 'Thu nhập năm, nợ chưa thu & công';

  @override
  String get incomeReportTitle => 'Báo cáo thu nhập';

  @override
  String incomeReportYear(String year) {
    return 'Năm $year';
  }

  @override
  String get incomeReportTotalBilled => 'Tổng yêu cầu';

  @override
  String get incomeReportTotalPaid => 'Tổng đã nhận';

  @override
  String get incomeReportTotalOutstanding => 'Tổng chưa thu';

  @override
  String get incomeReportTotalDays => 'Số ngày làm';

  @override
  String get incomeReportTotalGongsu => 'Tổng công';

  @override
  String get incomeReportTeamPayout => 'Chi cho đội';

  @override
  String get incomeReportNetBilled => 'Thu nhập ròng (tham khảo)';

  @override
  String get incomeReportNetHint =>
      'Yêu cầu − chi cho thành viên (phần của tổ trưởng)';

  @override
  String get incomeReportMonthlyTrend => 'Xu hướng theo tháng';

  @override
  String incomeReportPeakLabel(String amount) {
    return 'Cao nhất $amount';
  }

  @override
  String get incomeReportByCompany => 'Theo đối tác';

  @override
  String incomeReportEntryCount(int n) {
    return '$n mục';
  }

  @override
  String incomeReportOutstandingShort(String amount) {
    return 'Chưa thu $amount';
  }

  @override
  String get incomeReportTaxTitle => 'Hướng dẫn thuế thu nhập';

  @override
  String get incomeReportTaxL1 =>
      'Thuế thu nhập tổng hợp được khai và nộp vào tháng 5 hằng năm cho thu nhập năm trước.';

  @override
  String get incomeReportTaxL2 =>
      'Thu nhập dịch vụ cá nhân thường bị khấu trừ 3,3% khi thanh toán.';

  @override
  String get incomeReportTaxL3 =>
      'Thuế đã khấu trừ được quyết toán (hoàn hoặc nộp thêm) khi khai tháng 5.';

  @override
  String get incomeReportTaxL4 =>
      'Giữ chi phí và giấy xác nhận·bảng kê sẽ giúp khi khai thuế.';

  @override
  String get incomeReportTaxL5 =>
      'Đây là thông tin chung, không phải tư vấn thuế. Hãy hỏi chuyên gia thuế hoặc Hometax để khai chính xác.';

  @override
  String get incomeReportSavePdf => 'Lưu / chia sẻ PDF';

  @override
  String incomeReportPdfFail(String msg) {
    return 'Không mở được báo cáo: $msg';
  }

  @override
  String get incomeReportEmptyTitle => 'Chưa có dữ liệu thu nhập';

  @override
  String get incomeReportEmptySub =>
      'Hãy lập giấy xác nhận, thu nhập sẽ hiện ở báo cáo này.';
}
