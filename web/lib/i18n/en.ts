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
  unitGongsu: 'gongsu',
  amtOvertime: 'Overtime',
  amtEarly: 'Early start',
  amtNight: 'Night',
  amtAllnight: 'All-night',
  paperVat: 'VAT ({rate}%)',
  paperTotal: 'Amount due',
  paperMemo: 'Note',
  paperSignHead: 'Requester signature',
  paperSignedBy: 'Signed by {name}',

  paperTeam: 'Team roster',
  paperTeamName: 'Name',
  paperTeamGongsu: 'Day-units',
  paperTeamRate: 'Rate',
  paperTeamAmount: 'Amount',
  paperTeamTotal: 'Team work total',

  kickerContract: 'Standard Labor Contract',
  lcStamp: 'STANDARD LABOR CONTRACT',
  lcParties: 'Contracting parties',
  lcEmployer: 'Employer (Party A)',
  lcWorker: 'Employee (Party B)',
  lcBizNumber: 'Business reg. no.',
  lcPeriod: 'Contract period',
  lcPeriodOpen: 'No fixed term · daily basis',
  lcWorkplace: 'Workplace',
  lcJob: 'Job description',
  lcWorkTime: 'Working hours',
  lcBreak: 'Break',
  lcWage: 'Wage',
  lcWageDaily: 'Daily wage',
  lcWageHourly: 'Hourly wage',
  lcPayday: 'Payday',
  lcPayMethod: 'Payment method',
  lcAllowance: 'Allowances',
  lcWeeklyHoliday:
    'Weekly holiday pay: paid when the week’s scheduled workdays are fully attended.',
  lcWeeklyHolidayNone: 'Weekly holiday pay: not applicable (daily/short-term).',
  lcOvertime:
    'Overtime, night, and holiday work are paid an extra 50% of ordinary wage per the Labor Standards Act.',
  lcOvertimeNone: 'Overtime/night/holiday premiums: not separately agreed.',
  lcInsurance: 'Social insurance',
  lcInsEmployment: 'Employment insurance',
  lcInsHealth: 'Health insurance',
  lcInsPension: 'National pension',
  lcInsAccident: 'Industrial accident insurance',
  lcApplied: 'Applied',
  lcNotApplied: 'Not applied',
  lcSpecial: 'Special terms',
  lcMasterNote:
    'The Korean version is the authoritative original of this contract. Translations are for understanding only; the Korean version prevails in case of any discrepancy.',
  lcEmployerSigned: 'Employer signed',
  lcSignHeading: 'Please sign the labor contract',
  lcSignLegal:
    'By signing, you agree to the labor conditions above; your signature is kept as a legally effective contract record.',
  lcSignFootnote:
    'Once signed, the contract takes effect immediately and is kept by both parties.',
  lcSignDoneReceived: 'Labor contract signature received',
  lcViewPdf: 'View signed contract PDF',

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
