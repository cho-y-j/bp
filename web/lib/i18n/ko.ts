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
  // 공수(GONGSU) 수량 단위. 앱 ARB unitGongsu 와 일치(현장 통용 표기).
  unitGongsu: '공수',
  amtOvertime: '연장',
  amtEarly: '조출',
  amtNight: '야간',
  amtAllnight: '철야',
  paperVat: '부가세 ({rate}%)',
  paperTotal: '받을 금액',
  paperMemo: '메모',
  paperSignHead: '지시자 서명',
  paperSignedBy: '{name} 님 서명 완료',

  // 팀 명단 (P2a 웹 이월 — 팀 확인서 명단 표)
  paperTeam: '팀 명단',
  paperTeamName: '이름',
  paperTeamGongsu: '공수',
  paperTeamRate: '단가',
  paperTeamAmount: '금액',
  paperTeamTotal: '팀 작업 합계',

  // 표준근로계약서 (P2b) — 조항 라벨은 번역, 계약 데이터 값은 원문
  kickerContract: '표준근로계약서',
  lcStamp: '표 준 근 로 계 약 서',
  lcParties: '계약 당사자',
  lcEmployer: '사업주(갑)',
  lcWorker: '근로자(을)',
  lcBizNumber: '사업자번호',
  lcPeriod: '근로계약기간',
  lcPeriodOpen: '기간의 정함 없음 · 일 단위',
  lcWorkplace: '근무장소',
  lcJob: '업무내용',
  lcWorkTime: '근로시간',
  lcBreak: '휴게',
  lcWage: '임금',
  lcWageDaily: '일급',
  lcWageHourly: '시급',
  lcPayday: '임금 지급일',
  lcPayMethod: '지급 방법',
  lcAllowance: '수당',
  lcWeeklyHoliday: '주휴수당: 1주 소정근로일을 개근하면 주휴수당을 지급합니다.',
  lcWeeklyHolidayNone: '주휴수당: 해당 없음(일용·단시간 등).',
  lcOvertime: '연장·야간·휴일근로 시 근로기준법에 따라 통상임금의 50%를 가산 지급합니다.',
  lcOvertimeNone: '연장·야간·휴일 가산수당: 별도로 정하지 않음.',
  lcInsurance: '사회보험 적용',
  lcInsEmployment: '고용보험',
  lcInsHealth: '건강보험',
  lcInsPension: '국민연금',
  lcInsAccident: '산재보험',
  lcApplied: '적용',
  lcNotApplied: '미적용',
  lcSpecial: '특약사항',
  lcMasterNote:
    '본 계약서의 정본은 한국어본입니다. 번역본은 이해를 돕기 위한 참고용이며, 해석상 차이가 있을 경우 한국어본이 우선합니다.',
  lcEmployerSigned: '사업주 서명 완료',
  lcSignHeading: '근로계약서에 서명해 주세요',
  lcSignLegal:
    '서명하면 위 근로조건에 동의하는 것이며, 법적 효력이 있는 근로계약 서명으로 기록됩니다.',
  lcSignFootnote: '서명 즉시 근로계약이 확정되어 양측에 보관됩니다.',
  lcSignDoneReceived: '근로계약서 서명이 접수되었습니다',
  lcViewPdf: '서명된 근로계약서 PDF 보기',

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

  // QR 명함 공개 프로필 (P3b)
  kickerCard: '작업자 명함',
  cardValidDocs: '서류 유효',
  cardValidDocsDesc: '유효기간이 등록된 서류가 모두 유효합니다.',
  cardIndustryTitle: '업종',
  cardEquipmentTitle: '보유 장비',
  cardJoined: '작업온 가입일',
  cardConnectTitle: '이 작업자와 연결하기',
  cardConnectDesc: '작업온 앱에서 전화번호로 검색해 연결을 요청하세요.',
  cardStoreIos: 'App Store',
  cardStoreAndroid: 'Google Play',

  // 언어 선택
  langLabel: '언어',
} as const;

export type MessageKey = keyof typeof ko;
export default ko;
