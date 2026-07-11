/**
 * 한국어 사전 — 다국어의 기준(source of truth).
 * 여기 정의된 키 집합이 MessageKey 가 되고, 다른 언어 파일은 이 키를 모두 채워야 한다.
 * (사용자 입력 데이터(현장명·회사명·작업내용)는 번역 대상이 아니며, UI 라벨/안내/버튼만 번역한다.)
 */
const ko = {
  // 브랜드(고유명사 — 전 언어 공통 유지)
  brand: '작업온',
  kickerConfirmation: '작업확인서',
  kickerShare: '서류 묶음',

  // 종이 확인서
  paperStamp: '작 업 확 인 서',
  paperDate: '작업일',
  paperTime: '시간',
  paperSite: '현장',
  paperWorker: '작업자',
  paperOrderer: '지시자',
  paperWork: '작업내용',
  paperEquipment: '장비',
  paperGuide: '유도원',
  amtBase: '기본',
  amtOvertime: '연장',
  amtEarly: '조출',
  amtNight: '야간',
  amtAllnight: '철야',
  paperVat: '부가세 ({rate}%)',
  paperTotal: '받을 금액',
  paperMemo: '메모',
  paperSignHead: '지시자 서명',
  paperSignedBy: '{name} 님 서명 완료',

  // 서명 폼
  signHeading: '여기에 서명해 주세요',
  signNameLabel: '서명자 이름',
  signNamePlaceholder: '예) 이현수',
  signSignLabel: '서명',
  signPadHint: '여기에 손가락 또는 마우스로 서명하세요',
  signPadAria: '서명 입력 영역',
  signRedraw: '다시 그리기',
  signSubmit: '서명하고 확인 완료',
  signSubmitting: '전송 중…',
  signFootnote: '서명 즉시 작업자와 양측에 확인서가 확정됩니다',
  signLegal:
    '서명하면 위 작업 내용과 받을 금액에 동의하는 것이며, 법적 효력이 있는 확인 기록으로 남습니다.',
  signErrName: '서명자 이름을 입력하세요.',
  signErrSign: '서명을 입력하세요.',
  signErrSubmit: '서명 전송에 실패했습니다. 잠시 후 다시 시도하세요.',

  // 서명 완료
  signDoneTitle: '서명 완료',
  signDoneBy: '{name} 님이 서명했습니다',
  signDoneReceived: '서명이 접수되었습니다',
  signViewPdf: '서명된 확인서 PDF 보기',

  // 가입 유도 배너
  joinTitle: '이 확인서를 작업온으로 관리하세요',
  joinDesc:
    '받은 확인서와 정산 내역이 자동으로 장부에 쌓입니다. 사업장이라면 수신·정산·안전관리까지 한 번에.',
  joinCta: '작업온 시작하기',

  // 서류 묶음
  shareCount: '공유된 서류 {n}건',
  shareValidUntil: '유효기간 {date}까지 열람 가능',
  shareExpiry: '만료 {date}',
  shareNoExpiry: '만료일 없음',
  shareMasked: '마스킹본',
  shareView: '보기',
  shareDownload: '다운로드',

  // 상태 화면(404 / 오류)
  statusTransientTitle: '일시적인 오류입니다',
  statusTransientMsg: '잠시 후 다시 시도해 주세요.',
  statusNotFoundTitle: '찾을 수 없는 링크입니다',
  statusNotFoundMsg:
    '링크가 만료되었거나 무효화되었을 수 있습니다. 보낸 분에게 새 링크를 요청하세요.',
  statusRetry: '다시 시도',

  // 언어 선택
  langLabel: '언어',
} as const;

export type MessageKey = keyof typeof ko;
export default ko;
