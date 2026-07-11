import type { MessageKey } from './ko';

/** 베트남어 (vi-VN) — 성조 표기(dấu) 정확히. 비한국어권 최대 취업자 대상, 쉬운 구어체. */
const vi: Record<MessageKey, string> = {
  brand: '작업온',
  kickerConfirmation: 'Phiếu xác nhận công việc',
  kickerShare: 'Bộ giấy tờ',

  paperStamp: 'PHIẾU XÁC NHẬN CÔNG VIỆC',
  paperDate: 'Ngày làm',
  paperTime: 'Thời gian',
  paperSite: 'Công trình',
  paperWorker: 'Người làm',
  paperOrderer: 'Người giao việc',
  paperWork: 'Nội dung công việc',
  paperEquipment: 'Thiết bị',
  paperGuide: 'Người hướng dẫn',
  amtBase: 'Cơ bản',
  unitGongsu: 'gongsu',
  amtOvertime: 'Tăng ca',
  amtEarly: 'Vào sớm',
  amtNight: 'Làm đêm',
  amtAllnight: 'Làm xuyên đêm',
  paperVat: 'Thuế GTGT ({rate}%)',
  paperTotal: 'Số tiền nhận',
  paperMemo: 'Ghi chú',
  paperSignHead: 'Chữ ký người giao việc',
  paperSignedBy: '{name} đã ký',

  paperTeam: 'Danh sách tổ',
  paperTeamName: 'Họ tên',
  paperTeamGongsu: 'Công',
  paperTeamRate: 'Đơn giá',
  paperTeamAmount: 'Số tiền',
  paperTeamTotal: 'Tổng công việc của tổ',

  kickerContract: 'Hợp đồng lao động tiêu chuẩn',
  lcStamp: 'HỢP ĐỒNG LAO ĐỘNG',
  lcParties: 'Các bên hợp đồng',
  lcEmployer: 'Người sử dụng lao động (bên A)',
  lcWorker: 'Người lao động (bên B)',
  lcBizNumber: 'Mã số doanh nghiệp',
  lcPeriod: 'Thời hạn hợp đồng',
  lcPeriodOpen: 'Không xác định thời hạn · theo ngày',
  lcWorkplace: 'Nơi làm việc',
  lcJob: 'Nội dung công việc',
  lcWorkTime: 'Thời gian làm việc',
  lcBreak: 'Nghỉ giải lao',
  lcWage: 'Tiền lương',
  lcWageDaily: 'Lương ngày',
  lcWageHourly: 'Lương giờ',
  lcPayday: 'Ngày trả lương',
  lcPayMethod: 'Phương thức trả',
  lcAllowance: 'Phụ cấp',
  lcWeeklyHoliday:
    'Phụ cấp nghỉ tuần: đi làm đủ ngày quy định trong tuần sẽ được trả phụ cấp nghỉ tuần.',
  lcWeeklyHolidayNone:
    'Phụ cấp nghỉ tuần: không áp dụng (lao động ngày/bán thời gian).',
  lcOvertime:
    'Làm thêm giờ, ban đêm, ngày nghỉ được trả thêm 50% tiền lương thông thường theo luật lao động.',
  lcOvertimeNone:
    'Phụ cấp làm thêm/ban đêm/ngày nghỉ: không quy định riêng.',
  lcInsurance: 'Áp dụng bảo hiểm xã hội',
  lcInsEmployment: 'Bảo hiểm việc làm',
  lcInsHealth: 'Bảo hiểm y tế',
  lcInsPension: 'Bảo hiểm hưu trí quốc gia',
  lcInsAccident: 'Bảo hiểm tai nạn lao động',
  lcApplied: 'Áp dụng',
  lcNotApplied: 'Không áp dụng',
  lcSpecial: 'Điều khoản đặc biệt',
  lcMasterNote:
    'Bản chính của hợp đồng này là bản tiếng Hàn. Bản dịch chỉ nhằm hỗ trợ hiểu; nếu có khác biệt về giải thích, bản tiếng Hàn được ưu tiên.',
  lcEmployerSigned: 'Người sử dụng lao động đã ký',
  lcSignHeading: 'Vui lòng ký vào hợp đồng lao động',
  lcSignLegal:
    'Khi ký, bạn đồng ý với các điều kiện lao động trên và chữ ký được lưu như bản ghi có hiệu lực pháp lý.',
  lcSignFootnote:
    'Sau khi ký, hợp đồng có hiệu lực ngay và được lưu cho cả hai bên.',
  lcSignDoneReceived: 'Đã tiếp nhận chữ ký hợp đồng lao động',
  lcViewPdf: 'Xem PDF hợp đồng đã ký',

  signHeading: 'Vui lòng ký vào đây',
  signNameLabel: 'Tên người ký',
  signNamePlaceholder: 'ví dụ) Nguyễn Văn A',
  signSignLabel: 'Chữ ký',
  signPadHint: 'Ký ở đây bằng ngón tay hoặc chuột',
  signPadAria: 'Vùng ký tên',
  signRedraw: 'Ký lại',
  signSubmit: 'Ký và xác nhận',
  signSubmitting: 'Đang gửi…',
  signFootnote: 'Sau khi ký, phiếu xác nhận có hiệu lực ngay cho cả hai bên',
  signLegal:
    'Khi ký, bạn đồng ý với nội dung công việc và số tiền nêu trên. Đây là bản xác nhận có giá trị pháp lý.',
  signErrName: 'Vui lòng nhập tên người ký.',
  signErrSign: 'Vui lòng ký tên.',
  signErrSubmit: 'Gửi chữ ký thất bại. Vui lòng thử lại sau.',

  signDoneTitle: 'Đã ký xong',
  signDoneBy: '{name} đã ký',
  signDoneReceived: 'Đã nhận chữ ký',
  signViewPdf: 'Xem phiếu đã ký (PDF)',

  joinTitle: 'Quản lý phiếu này bằng 작업온',
  joinDesc:
    'Phiếu xác nhận và khoản thanh toán bạn nhận sẽ tự động vào sổ. Nếu là nhà thầu: nhận phiếu, thanh toán và quản lý an toàn trong một nơi.',
  joinCta: 'Bắt đầu với 작업온',

  shareCount: '{n} giấy tờ được chia sẻ',
  shareValidUntil: 'Xem được đến {date}',
  shareExpiry: 'Hết hạn {date}',
  shareNoExpiry: 'Không có hạn',
  shareMasked: 'Bản che thông tin',
  shareView: 'Xem',
  shareDownload: 'Tải về',

  statusTransientTitle: 'Lỗi tạm thời',
  statusTransientMsg: 'Vui lòng thử lại sau giây lát.',
  statusNotFoundTitle: 'Không tìm thấy liên kết',
  statusNotFoundMsg:
    'Liên kết có thể đã hết hạn hoặc bị vô hiệu. Hãy hỏi người gửi để lấy liên kết mới.',
  statusRetry: 'Thử lại',

  langLabel: 'Ngôn ngữ',
};

export default vi;
