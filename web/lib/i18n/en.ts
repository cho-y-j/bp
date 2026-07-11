import type { MessageKey } from './ko';

/** 영어 (en) — 필리핀·스리랑카 및 범용 폴백. */
const en: Record<MessageKey, string> = {
  brand: '작업온',
  kickerConfirmation: 'Work Confirmation',
  kickerShare: 'Document Set',

  paperStamp: 'WORK CONFIRMATION',
  paperDate: 'Work date',
  paperTime: 'Time',
  paperSite: 'Site',
  paperWorker: 'Worker',
  paperOrderer: 'Requester',
  paperWork: 'Work details',
  paperEquipment: 'Equipment',
  paperGuide: 'Signal guide',
  amtBase: 'Base pay',
  amtOvertime: 'Overtime',
  amtEarly: 'Early start',
  amtNight: 'Night',
  amtAllnight: 'All-night',
  paperVat: 'VAT ({rate}%)',
  paperTotal: 'Amount due',
  paperMemo: 'Note',
  paperSignHead: 'Requester signature',
  paperSignedBy: 'Signed by {name}',

  signHeading: 'Please sign here',
  signNameLabel: 'Signer name',
  signNamePlaceholder: 'e.g. John Smith',
  signSignLabel: 'Signature',
  signPadHint: 'Sign here with your finger or mouse',
  signPadAria: 'Signature input area',
  signRedraw: 'Redraw',
  signSubmit: 'Sign & confirm',
  signSubmitting: 'Sending…',
  signFootnote: 'Once signed, the confirmation takes effect for both parties',
  signLegal:
    'By signing, you agree to the work and amount above. This is a legally valid confirmation record.',
  signErrName: 'Please enter the signer name.',
  signErrSign: 'Please add your signature.',
  signErrSubmit: 'Failed to submit the signature. Please try again later.',

  signDoneTitle: 'Signed',
  signDoneBy: '{name} has signed',
  signDoneReceived: 'Signature received',
  signViewPdf: 'View signed confirmation (PDF)',

  joinTitle: 'Manage this confirmation with 작업온',
  joinDesc:
    'Confirmations and settlements you receive are logged automatically. For businesses: receive, settle, and manage safety all in one place.',
  joinCta: 'Get started with 작업온',

  shareCount: '{n} shared document(s)',
  shareValidUntil: 'Viewable until {date}',
  shareExpiry: 'Expires {date}',
  shareNoExpiry: 'No expiry',
  shareMasked: 'Masked copy',
  shareView: 'View',
  shareDownload: 'Download',

  statusTransientTitle: 'Temporary error',
  statusTransientMsg: 'Please try again shortly.',
  statusNotFoundTitle: 'Link not found',
  statusNotFoundMsg:
    'The link may have expired or been revoked. Please ask the sender for a new link.',
  statusRetry: 'Retry',

  langLabel: 'Language',
};

export default en;
