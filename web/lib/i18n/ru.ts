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
  amtOvertime: 'Сверхурочные',
  amtEarly: 'Ранний выход',
  amtNight: 'Ночная смена',
  amtAllnight: 'Всю ночь',
  paperVat: 'НДС ({rate}%)',
  paperTotal: 'К оплате',
  paperMemo: 'Примечание',
  paperSignHead: 'Подпись заказчика',
  paperSignedBy: '{name} подписал(а)',

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

  langLabel: 'Язык',
};

export default ru;
