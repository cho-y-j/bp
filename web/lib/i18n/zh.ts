import type { MessageKey } from './ko';

/** 중국어 간체 (zh-CN) — 건설현장 중국어권 다수(조선족·본토) 대상, 쉬운 구어체. */
const zh: Record<MessageKey, string> = {
  brand: '작업온',
  kickerConfirmation: '作业确认单',
  kickerShare: '文件包',

  paperStamp: '作 业 确 认 单',
  paperDate: '作业日期',
  paperTime: '时间',
  paperSite: '工地',
  paperWorker: '作业人',
  paperOrderer: '派工方',
  paperWork: '作业内容',
  paperEquipment: '设备',
  paperGuide: '引导员',
  amtBase: '基本',
  amtOvertime: '加班',
  amtEarly: '早班',
  amtNight: '夜班',
  amtAllnight: '通宵',
  paperVat: '增值税 ({rate}%)',
  paperTotal: '应收金额',
  paperMemo: '备注',
  paperSignHead: '派工方签名',
  paperSignedBy: '{name} 已签名',

  signHeading: '请在这里签名',
  signNameLabel: '签名人姓名',
  signNamePlaceholder: '例）张伟',
  signSignLabel: '签名',
  signPadHint: '用手指或鼠标在这里签名',
  signPadAria: '签名输入区',
  signRedraw: '重新签',
  signSubmit: '签名并确认',
  signSubmitting: '提交中…',
  signFootnote: '签名后，确认单立即对双方生效',
  signLegal:
    '签名即表示您同意以上作业内容和应收金额，该确认记录具有法律效力。',
  signErrName: '请输入签名人姓名。',
  signErrSign: '请先签名。',
  signErrSubmit: '签名提交失败，请稍后再试。',

  signDoneTitle: '签名完成',
  signDoneBy: '{name} 已完成签名',
  signDoneReceived: '签名已收到',
  signViewPdf: '查看已签名的确认单 PDF',

  joinTitle: '用 작업온 管理这份确认单',
  joinDesc:
    '收到的确认单和结算记录会自动记入账本。如果您是企业/工地方，接收、结算、安全管理一次搞定。',
  joinCta: '开始使用 작업온',

  shareCount: '共享的文件 {n} 份',
  shareValidUntil: '有效期至 {date}',
  shareExpiry: '到期 {date}',
  shareNoExpiry: '无到期日',
  shareMasked: '打码版',
  shareView: '查看',
  shareDownload: '下载',

  statusTransientTitle: '出现临时错误',
  statusTransientMsg: '请稍后再试。',
  statusNotFoundTitle: '找不到该链接',
  statusNotFoundMsg: '链接可能已过期或被作废。请向发送人索取新链接。',
  statusRetry: '重试',

  langLabel: '语言',
};

export default zh;
