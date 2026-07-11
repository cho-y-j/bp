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
  amtOvertime: 'Tăng ca',
  amtEarly: 'Vào sớm',
  amtNight: 'Làm đêm',
  amtAllnight: 'Làm xuyên đêm',
  paperVat: 'Thuế GTGT ({rate}%)',
  paperTotal: 'Số tiền nhận',
  paperMemo: 'Ghi chú',
  paperSignHead: 'Chữ ký người giao việc',
  paperSignedBy: '{name} đã ký',

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
