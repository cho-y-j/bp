import type { MessageKey } from './ko';

/** 러시아어 (ru-RU) — 중앙아시아권(우즈벡·고려인·카자흐·키르기스) 통합 커버. 쉬운 구어체. */
const ru: Record<MessageKey, string> = {
  brand: '작업온',
  kickerConfirmation: 'Подтверждение работы',
  kickerShare: 'Пакет документов',

  paperStamp: 'ПОДТВЕРЖДЕНИЕ РАБОТЫ',
  paperDate: 'Дата работы',
  paperTime: 'Время',
  paperSite: 'Объект',
  paperWorker: 'Работник',
  paperOrderer: 'Заказчик',
  paperWork: 'Вид работ',
  paperEquipment: 'Техника',
  paperGuide: 'Сигнальщик',
  amtBase: 'Основная оплата',
  unitGongsu: 'гонсу',
  amtOvertime: 'Сверхурочные',
  amtEarly: 'Ранний выход',
  amtNight: 'Ночная смена',
  amtAllnight: 'Всю ночь',
  paperVat: 'НДС ({rate}%)',
  paperTotal: 'К оплате',
  paperMemo: 'Примечание',
  paperSignHead: 'Подпись заказчика',
  paperSignedBy: '{name} подписал(а)',

  paperTeam: 'Список бригады',
  paperTeamName: 'Имя',
  paperTeamGongsu: 'Смены',
  paperTeamRate: 'Ставка',
  paperTeamAmount: 'Сумма',
  paperTeamTotal: 'Итого по бригаде',

  kickerContract: 'Трудовой договор',
  lcStamp: 'Т Р У Д О В О Й   Д О Г О В О Р',
  lcParties: 'Стороны договора',
  lcEmployer: 'Работодатель (сторона А)',
  lcWorker: 'Работник (сторона Б)',
  lcBizNumber: 'Рег. номер предприятия',
  lcPeriod: 'Срок трудового договора',
  lcPeriodOpen: 'Без определённого срока · подённо',
  lcWorkplace: 'Место работы',
  lcJob: 'Содержание работы',
  lcWorkTime: 'Рабочее время',
  lcBreak: 'Перерыв',
  lcWage: 'Заработная плата',
  lcWageDaily: 'Дневная ставка',
  lcWageHourly: 'Почасовая ставка',
  lcPayday: 'День выплаты',
  lcPayMethod: 'Способ выплаты',
  lcAllowance: 'Надбавки',
  lcWeeklyHoliday:
    'Оплата еженедельного выходного: при полной отработке недели выплачивается оплата выходного дня.',
  lcWeeklyHolidayNone:
    'Оплата еженедельного выходного: не применяется (подённая/неполная занятость).',
  lcOvertime:
    'За сверхурочную, ночную и работу в выходные выплачивается надбавка 50% от обычной оплаты согласно закону.',
  lcOvertimeNone:
    'Надбавки за сверхурочную/ночную/праздничную работу: отдельно не оговорены.',
  lcInsurance: 'Социальное страхование',
  lcInsEmployment: 'Страхование занятости',
  lcInsHealth: 'Медицинское страхование',
  lcInsPension: 'Пенсионное страхование',
  lcInsAccident: 'Страхование от несчастных случаев',
  lcApplied: 'Применяется',
  lcNotApplied: 'Не применяется',
  lcSpecial: 'Особые условия',
  lcMasterNote:
    'Оригиналом договора является версия на корейском языке. Перевод предоставлен для удобства понимания; при расхождениях преимущество имеет корейская версия.',
  lcEmployerSigned: 'Работодатель подписал',
  lcSignHeading: 'Пожалуйста, подпишите трудовой договор',
  lcSignLegal:
    'Подписывая, вы соглашаетесь с указанными условиями труда; подпись сохраняется как юридически значимая запись.',
  lcSignFootnote:
    'После подписания договор сразу вступает в силу и хранится у обеих сторон.',
  lcSignDoneReceived: 'Подпись трудового договора принята',
  lcViewPdf: 'Открыть подписанный договор (PDF)',

  signHeading: 'Распишитесь здесь',
  signNameLabel: 'Имя подписавшего',
  signNamePlaceholder: 'напр.) Иван Иванов',
  signSignLabel: 'Подпись',
  signPadHint: 'Распишитесь здесь пальцем или мышью',
  signPadAria: 'Поле для подписи',
  signRedraw: 'Стереть',
  signSubmit: 'Подписать и подтвердить',
  signSubmitting: 'Отправка…',
  signFootnote: 'После подписи акт сразу вступает в силу для обеих сторон',
  signLegal:
    'Подписывая, вы соглашаетесь с указанной работой и суммой к оплате. Это подтверждение имеет юридическую силу.',
  signErrName: 'Введите имя подписавшего.',
  signErrSign: 'Поставьте подпись.',
  signErrSubmit: 'Не удалось отправить подпись. Попробуйте позже.',

  signDoneTitle: 'Подписано',
  signDoneBy: '{name} поставил(а) подпись',
  signDoneReceived: 'Подпись получена',
  signViewPdf: 'Открыть подписанный акт (PDF)',

  joinTitle: 'Управляйте этим актом в 작업온',
  joinDesc:
    'Полученные акты и расчёты автоматически попадают в журнал. Для компаний — приём, расчёты и охрана труда в одном месте.',
  joinCta: 'Начать в 작업온',

  shareCount: 'Документов в доступе: {n}',
  shareValidUntil: 'Доступно до {date}',
  shareExpiry: 'Истекает {date}',
  shareNoExpiry: 'Без срока',
  shareMasked: 'С маскировкой',
  shareView: 'Открыть',
  shareDownload: 'Скачать',

  statusTransientTitle: 'Временная ошибка',
  statusTransientMsg: 'Попробуйте чуть позже.',
  statusNotFoundTitle: 'Ссылка не найдена',
  statusNotFoundMsg:
    'Возможно, ссылка устарела или отключена. Попросите отправителя прислать новую.',
  statusRetry: 'Повторить',

  // QR 명함 공개 프로필 (P3b)
  kickerCard: 'Визитка работника',
  cardValidDocs: 'Документы действительны',
  cardValidDocsDesc: 'Все документы с указанным сроком действия действительны.',
  cardIndustryTitle: 'Специализация',
  cardEquipmentTitle: 'Техника',
  cardJoined: 'Регистрация в 작업온',
  cardConnectTitle: 'Связаться с работником',
  cardConnectDesc:
    'Найдите его по номеру телефона в приложении 작업온 и отправьте запрос на связь.',
  cardStoreIos: 'App Store',
  cardStoreAndroid: 'Google Play',

  langLabel: 'Язык',
};

export default ru;
