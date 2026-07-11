// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get widgetToday => 'Сегодня';

  @override
  String get widgetNoSchedule => 'Нет задач';

  @override
  String get widgetOutstanding => 'Долг за месяц';

  @override
  String get widgetLoginPlease => 'Войдите в аккаунт';

  @override
  String widgetSyncedAt(String time) {
    return 'Обновлено $time';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'OK';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get retry => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get edit => 'Изменить';

  @override
  String get share => 'Поделиться';

  @override
  String get download => 'Скачать';

  @override
  String get view => 'Открыть';

  @override
  String get loading => 'Загрузка…';

  @override
  String get errorConnTitle => 'Проблема с подключением';

  @override
  String get errorConnSubtitle => 'Проверьте интернет и попробуйте снова.';

  @override
  String get statusDeposited => 'Оплачено';

  @override
  String get statusOverdue => 'Просрочено';

  @override
  String collectDday(String dday) {
    return 'Оплата $dday';
  }

  @override
  String get amtBase => 'Основная оплата';

  @override
  String get amtOvertime => 'Сверхурочные';

  @override
  String get amtEarly => 'Ранний выход';

  @override
  String get amtNight => 'Ночная смена';

  @override
  String get amtAllnight => 'Всю ночь';

  @override
  String get itemOther => 'Прочее';

  @override
  String get baseDaily => 'Основа (дневная)';

  @override
  String get baseHourly => 'Основа (почасовая)';

  @override
  String get basePerCase => 'Основа (за работу)';

  @override
  String get baseGongsu => 'Основа (гонсу)';

  @override
  String get unitGongsu => 'гонсу';

  @override
  String qtyGongsu(String qty) {
    return '$qty гонсу';
  }

  @override
  String vatLabel(String rate) {
    return 'НДС ($rate%)';
  }

  @override
  String daysCount(int days) {
    return '$days дн.';
  }

  @override
  String daysWithGongsu(int days, String gongsu) {
    return '$days дн. · $gongsu гонсу';
  }

  @override
  String get moreTitle => 'Ещё';

  @override
  String get sectionManage => 'Управление';

  @override
  String get sectionSettings => 'Настройки';

  @override
  String get menuWallet => 'Кошелёк документов';

  @override
  String get menuWalletSub =>
      'Сроки сертификатов·страховок·техосмотра · отправка пакетом';

  @override
  String get menuBizHome => 'Кабинет компании';

  @override
  String get menuBizMode => 'Режим компании';

  @override
  String get menuBizSub =>
      'Наряды·полученные акты·расчёты·отчёты по охране труда';

  @override
  String get menuJobs => 'Полученные наряды';

  @override
  String get menuJobsSub => 'Принять, начать и завершить наряд';

  @override
  String get menuTax => 'Подготовка счёта-фактуры';

  @override
  String get menuTaxSub => 'Подписанные акты → данные для ввода в Hometax';

  @override
  String get menuNotifications => 'Уведомления';

  @override
  String get menuNotificationsSub =>
      'Оплаты·сроки документов·запланированные работы·жара';

  @override
  String get consentTitle => 'Разрешить поиск по номеру';

  @override
  String get consentSub =>
      'Компании смогут найти и связаться со мной по номеру';

  @override
  String get kakaoLinkTitle => 'Привязать аккаунт Kakao';

  @override
  String get kakaoLinkedSub => 'Привязано';

  @override
  String get kakaoLinkSub => 'Привяжите, чтобы входить и через Kakao';

  @override
  String get kakaoLinked => 'Аккаунт Kakao привязан.';

  @override
  String get kakaoNotReady => 'Вход через Kakao скоро будет доступен.';

  @override
  String get kakaoAlreadyLinked =>
      'Этот Kakao уже привязан к другому аккаунту.';

  @override
  String kakaoLinkFailed(String message) {
    return 'Не удалось привязать: $message';
  }

  @override
  String get kakaoLinkCanceled => 'Привязка Kakao отменена.';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Выйти из аккаунта?';

  @override
  String get noName => 'Без имени';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get paperStamp => 'ПОДТВЕРЖДЕНИЕ РАБОТЫ';

  @override
  String get paperDate => 'Дата работы';

  @override
  String get paperTime => 'Время';

  @override
  String get paperSite => 'Объект';

  @override
  String get paperWorker => 'Работник';

  @override
  String get paperOrderer => 'Заказчик';

  @override
  String get paperWork => 'Вид работ';

  @override
  String get paperEquipment => 'Техника';

  @override
  String get paperGuide => 'Сигнальщик';

  @override
  String get paperTotal => 'К оплате';

  @override
  String get paperMemo => 'Примечание';

  @override
  String get paperSignHead => 'Подпись заказчика';

  @override
  String paperSignedBy(String name) {
    return '$name подписал(а)';
  }

  @override
  String shareCount(int n) {
    return 'Документов в доступе: $n';
  }

  @override
  String shareValidUntil(String date) {
    return 'Доступно до $date';
  }

  @override
  String shareExpiry(String date) {
    return 'Истекает $date';
  }

  @override
  String get shareNoExpiry => 'Без срока';

  @override
  String get shareMasked => 'С маскировкой';

  @override
  String get statusTransientTitle => 'Временная ошибка';

  @override
  String get statusTransientMsg => 'Попробуйте чуть позже.';

  @override
  String get statusNotFoundTitle => 'Ссылка не найдена';

  @override
  String get statusNotFoundMsg =>
      'Возможно, ссылка устарела или отключена. Попросите отправителя прислать новую.';

  @override
  String get authStartWithPhone => 'Начать по номеру телефона';

  @override
  String get authTagline =>
      'Записывайте работу за 30 секунд — акты, журнал и расчёты ведутся автоматически.';

  @override
  String get authPhoneLabel => 'Номер телефона';

  @override
  String get authCodeLabel => 'Код подтверждения';

  @override
  String get authCodeHint => '6-значный код';

  @override
  String get authDevAutofill =>
      'Режим разработки: код заполняется автоматически.';

  @override
  String get authRequestCode => 'Получить код';

  @override
  String get authVerifyStart => 'Подтвердить и начать';

  @override
  String get authReenterPhone => 'Ввести номер заново';

  @override
  String get authOr => 'или';

  @override
  String get authKakaoStart => 'Войти через Kakao';

  @override
  String get authKakaoPreparing =>
      'Вход через Kakao скоро появится. Пока начните по номеру телефона.';

  @override
  String get onbWelcome => 'Рады видеть вас!';

  @override
  String get onbNamePrompt => 'Укажите имя для отображения в актах.';

  @override
  String get onbNameLabel => 'Имя';

  @override
  String get onbNameHint => 'напр.) Иван Иванов';

  @override
  String get onbStart => 'Начать';

  @override
  String get navHome => 'Главная';

  @override
  String get navCalendar => 'Календарь';

  @override
  String get navLedger => 'Журнал';

  @override
  String get navMore => 'Ещё';

  @override
  String get navWrite => 'Создать';

  @override
  String navDraftsSent(int n) {
    return 'Черновики отправлены автоматически: $n.';
  }

  @override
  String navDraftsFailed(int n) {
    return 'Не удалось отправить черновики: $n. Проверьте на главной.';
  }

  @override
  String get notiTitle => 'Уведомления';

  @override
  String get notiEmpty => 'Нет уведомлений';

  @override
  String get notiAckDone => 'Отмечено как подтверждённое.';

  @override
  String notiAckFailed(String error) {
    return 'Ошибка подтверждения: $error';
  }

  @override
  String get bizModeTitle => 'Режим бизнеса';

  @override
  String bizCreateFailed(String error) {
    return 'Не удалось создать: $error';
  }

  @override
  String get bizCreateHeading => 'Создайте бизнес, чтобы начать';

  @override
  String get bizCreateDesc =>
      'Работники, наряды, подпись актов, расчёты и отчёты по охране труда — в одном месте.';

  @override
  String get bizNameHint => 'Название (напр. Daesung Construction)';

  @override
  String get bizBnoHint => 'Номер бизнеса (необязательно)';

  @override
  String get bizCreateButton => 'Создать бизнес';

  @override
  String bizInviteCode(String code) {
    return 'Код приглашения $code';
  }

  @override
  String get inboxTitle => 'Входящие';

  @override
  String get bizMenuInboxDesc => 'Полученные акты и подпись в приложении';

  @override
  String get settleTitle => 'Расчёты';

  @override
  String get bizMenuSettleDesc => 'Долги по работникам и выплаты';

  @override
  String get workerTitle => 'Работники и наряды';

  @override
  String get bizMenuWorkerDesc =>
      'Поиск и подключение работников, создание нарядов';

  @override
  String get jobTitle => 'Наряды';

  @override
  String get bizMenuJobDesc => 'Статусы: запланировано, в работе, готово';

  @override
  String get safetyTitle => 'Охрана труда';

  @override
  String get bizMenuSafetyDesc =>
      'PDF-отчёт по охране труда и последние записи';

  @override
  String bizLoadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String get inboxEmpty => 'Полученных актов нет';

  @override
  String get inboxStatusSigned => 'Подписано';

  @override
  String get inboxStatusPending => 'Ждёт подписи';

  @override
  String get jobStatusScheduled => 'Запланировано';

  @override
  String get jobStatusInProgress => 'В работе';

  @override
  String get jobStatusDone => 'Готово';

  @override
  String get jobEmpty => 'В этом месяце нарядов нет';

  @override
  String get jobAccepted => 'Принято';

  @override
  String get jobAcceptPending => 'Ждёт принятия';

  @override
  String safetyReportOpenFailed(String error) {
    return 'Не удалось открыть отчёт: $error';
  }

  @override
  String get safetyReportTitle => 'Отчёт о соблюдении охраны труда';

  @override
  String get safetyReportDesc =>
      'Смотрите проверки состояния, срок документов и оповещения о жаре в месячном PDF.';

  @override
  String safetyOpenReport(String month) {
    return 'Открыть отчёт за $month';
  }

  @override
  String get safetyHeatNotice =>
      'При объявлении жары подключённым работникам автоматически уходит уведомление о безопасности, и остаётся запись.';

  @override
  String settlePaidSnack(String name, String amount) {
    return '$name: выплачено $amount';
  }

  @override
  String settlePayFailed(String error) {
    return 'Не удалось выплатить: $error';
  }

  @override
  String get settleEmpty => 'В этом месяце нет долгов';

  @override
  String settleEntryCount(int count) {
    return '$count шт.';
  }

  @override
  String get settlePaidDone => 'Выплачено';

  @override
  String settlePayAmount(String amount) {
    return 'Выплатить $amount';
  }

  @override
  String workerSearchFailed(String error) {
    return 'Поиск не удался: $error';
  }

  @override
  String workerConnectRequested(String name) {
    return 'Запрос на подключение отправлен $name.';
  }

  @override
  String workerRequestFailed(String error) {
    return 'Не удалось отправить запрос: $error';
  }

  @override
  String get workerSearchHint => 'Поиск по номеру работника';

  @override
  String get workerSearchButton => 'Найти';

  @override
  String get workerConnectButton => 'Подключить';

  @override
  String get workerConnectedHeading => 'Подключённые работники';

  @override
  String get workerNoneConnected => 'Подключённых работников пока нет';

  @override
  String get workerStatusConnected => 'Подключён';

  @override
  String get workerStatusPending => 'Ожидает';

  @override
  String get workerJobButton => 'Наряд';

  @override
  String get workerAccept => 'Принять';

  @override
  String get workerJobSent => 'Наряд отправлен. Работник получит уведомление.';

  @override
  String jobFormTitle(String name) {
    return 'Наряд для $name';
  }

  @override
  String get jobFormSiteHint => 'Объект (напр. ремонт Banpo Xi)';

  @override
  String get jobRateDaily => 'Дневная';

  @override
  String get jobRateHourly => 'Почасовая';

  @override
  String get jobRatePerCase => 'За единицу';

  @override
  String get jobFormRateHint => 'Ставка (KRW)';

  @override
  String get jobFormSubmit => 'Отправить наряд';

  @override
  String jobCreateFailed(String error) {
    return 'Не удалось отправить наряд: $error';
  }

  @override
  String get bizConfirmTitle => 'Подтверждение работы';

  @override
  String get bizSignErrSign => 'Поставьте подпись.';

  @override
  String get bizSignErrName => 'Введите имя подписавшего.';

  @override
  String get bizSignDone => 'Подпись поставлена. (SIGNED)';

  @override
  String bizSignFailed(String error) {
    return 'Не удалось подписать: $error';
  }

  @override
  String get bizStampDefault => 'Подтверждение работы · WORKON';

  @override
  String get bizStampSigned => 'ПОДПИСАНО · WORKON';

  @override
  String get bizLineCounterpart => 'Контрагент';

  @override
  String get bizLineRateType => 'Тип ставки';

  @override
  String bizSignedBadge(String name, String at) {
    return '$name подписал · $at';
  }

  @override
  String get bizSignInAppTitle => 'Подпишите прямо в приложении';

  @override
  String get bizSignInAppDesc =>
      'Распишитесь ниже — работник сразу получит акт, и подтверждение станет окончательным.';

  @override
  String get bizSignerNameLabel => 'Имя подписавшего';

  @override
  String get bizSignRedraw => 'Переподписать';

  @override
  String get bizSignSubmit => 'Подписать и подтвердить';

  @override
  String get confNoCopySource => 'Нет прошлых актов для копирования.';

  @override
  String get confCopyPrevious => 'Скопировать прошлый акт';

  @override
  String get confFormTitle => 'Новое подтверждение работы';

  @override
  String get confSiteHint => 'напр.) ЖК «Ривер», участок 3';

  @override
  String get confWorkHint => 'Опишите, какую работу выполнили';

  @override
  String get confRateType => 'Тип оплаты';

  @override
  String get confRateDaily => 'Дневная';

  @override
  String get confRateHourly => 'Почасовая';

  @override
  String get confRatePerCase => 'За случай';

  @override
  String get confPricePerCase => 'Ставка за случай';

  @override
  String get confPriceGongsu => 'Ставка за гонсу (1 гонсу = 1 день)';

  @override
  String get confQtyHours => 'Часы';

  @override
  String get confQtyCases => 'Кол-во';

  @override
  String get confQtyDays => 'Дни';

  @override
  String get confErrGongsu => 'Вводите гонсу с шагом 0,1 (напр. 0,5; 1,5).';

  @override
  String get confErrHours => 'Введите не меньше 1 часа.';

  @override
  String get confErrCases => 'Введите не меньше 1.';

  @override
  String get confErrDays => 'Введите не меньше 1 дня.';

  @override
  String get confDueDate => 'Дата получения оплаты (необязательно)';

  @override
  String get confNotSet => 'Не задано';

  @override
  String get confSaveSend => 'Сохранить и отправить';

  @override
  String get confSaveHint => 'Сразу попадёт в журнал · Отправка ссылкой';

  @override
  String get confStartTime => 'Время начала';

  @override
  String get confEndTime => 'Время окончания';

  @override
  String get confOrdererCompany => 'Заказчик (компания)';

  @override
  String get confLinkedBiz => 'Связанная компания';

  @override
  String get confManualEntry => 'Ввести вручную';

  @override
  String get confSelectBiz => 'Выберите связанную компанию';

  @override
  String get confCompanyHint => 'Название компании / прораба';

  @override
  String get confContactHint => 'Контактное лицо / телефон (необязательно)';

  @override
  String get confEquipSection => 'Раздел техники';

  @override
  String get confEquipAutoInclude => 'Автоматически добавится в акт';

  @override
  String get confEquipName => 'Название техники';

  @override
  String get confVehicleNo => 'Гос. номер';

  @override
  String get confUnitPrice => 'Ставка';

  @override
  String get confQuantity => 'Кол-во';

  @override
  String get confAddExtra => 'Добавить сверхурочные / ночные';

  @override
  String get confSavedLinked => 'Сохранено · Отправлено связанной компании.';

  @override
  String get confSavedBook => 'Сохранено · Внесено в журнал.';

  @override
  String get confDraftQueued =>
      'Сохранено как черновик — отправим, как появится связь.';

  @override
  String confSaveFailed(String message) {
    return 'Не удалось сохранить: $message';
  }

  @override
  String get confRestoreTitle => 'Есть незаконченная запись.';

  @override
  String get confRestore => 'Восстановить';

  @override
  String get confDetailTitle => 'Подтверждение работы';

  @override
  String get confSentLinked => 'Отправлено связанной компании.';

  @override
  String confSendFailed(String message) {
    return 'Не удалось отправить: $message';
  }

  @override
  String get confReshare => 'Поделиться снова';

  @override
  String get confSendToLinked => 'Отправится связанной компании';

  @override
  String get confSendViaShare =>
      'Ссылку можно отправить через меню «Поделиться» (KakaoTalk и т. п.)';

  @override
  String get confCounterparty => 'другая сторона';

  @override
  String get confSentWaitingSign => 'Отправлено · Ждём подпись';

  @override
  String get confDraftBeforeSend => 'Составлено · Ещё не отправлено';

  @override
  String confShareHeader(String site) {
    return '[Подтверждение работы] $site';
  }

  @override
  String get confShareBody => 'Проверьте детали и распишитесь по ссылке ниже.';

  @override
  String confShareSubject(String site) {
    return 'Подтверждение работы · $site';
  }

  @override
  String get draftFlushNone => 'Пока не отправлено. Проверьте связь.';

  @override
  String draftFlushSent(int n) {
    return 'Отправлено: $n · Внесено в журнал.';
  }

  @override
  String get draftFlushFailed =>
      'Часть черновиков не отправилась. Проверьте их.';

  @override
  String get draftTitle => 'Черновики';

  @override
  String get draftEmpty => 'Нет черновиков к отправке.';

  @override
  String get draftHint =>
      'Отправятся автоматически, когда вернётся связь. Чтобы отправить сейчас, нажмите «Повторить» ниже.';

  @override
  String get draftSendAll => 'Отправить все сейчас';

  @override
  String get draftNoSite => '(Объект не указан)';

  @override
  String draftCheckNeeded(String error) {
    return 'Нужна проверка: $error';
  }

  @override
  String homeGreeting(String name) {
    return 'Здравствуйте, $name';
  }

  @override
  String get homeToday => 'На сегодня';

  @override
  String get homeMonthSummary => 'Итоги месяца';

  @override
  String get homeCheckNeeded => 'Требует внимания';

  @override
  String homeDocExpiry(String type, String dday) {
    return '$type истекает $dday';
  }

  @override
  String get homeDocExpirySub =>
      'Обновите в кошельке документов и добавьте заново';

  @override
  String homeDraftsPending(int n) {
    return 'Черновиков к отправке: $n';
  }

  @override
  String get homeDraftsError =>
      'Некоторые черновики требуют внимания · Нажмите, чтобы открыть';

  @override
  String get homeDraftsAuto =>
      'Отправятся автоматически при связи · Нажмите, чтобы открыть';

  @override
  String get homeStampDraft => 'ЧЕРНОВИК · WORKON';

  @override
  String get homeStampScheduled => 'ЗАПЛАНИРОВАНО · WORKON';

  @override
  String get homeTodayBadge => 'Сегодня';

  @override
  String get homeStampToday => 'СЕГОДНЯ · WORKON';

  @override
  String get homeEmptyToday => 'На сегодня работ нет';

  @override
  String get homeEmptyTodaySub =>
      'Нажмите + внизу и запишите работу за 30 секунд.';

  @override
  String get homeDaysWorked => 'Отработано дней';

  @override
  String get homeReceivable => 'К получению (долг)';

  @override
  String get homeReceived => 'Получено (оплачено)';

  @override
  String get calViewMonth => 'Месяц';

  @override
  String get calViewWeek => 'Неделя';

  @override
  String calWorkCount(int n) {
    return 'Работ: $n';
  }

  @override
  String get calManUnit => 'тыс';

  @override
  String get calEmptyMonth => 'В этом месяце записей нет.';

  @override
  String get calEmptyDay => 'В этот день записей нет.';

  @override
  String get calRecordThisDay => 'Записать работу за этот день';

  @override
  String get ledgerTitle => 'Журнал';

  @override
  String get ledgerOutstandingTotal => 'Долг за месяц';

  @override
  String ledgerWorkedThisMonth(String summary) {
    return 'За месяц отработано $summary';
  }

  @override
  String get ledgerByCompany => 'По компаниям';

  @override
  String ledgerCompanyCount(int n) {
    return '$n компаний';
  }

  @override
  String get ledgerStamp => 'ЖУРНАЛ · WORKON';

  @override
  String get ledgerEmptyTitle => 'В этом месяце нет записей';

  @override
  String get ledgerEmptySub => 'Составьте акт — журнал заполнится сам.';

  @override
  String get ledgerWriteConfirmation => 'Составить акт';

  @override
  String ledgerDaysWorked(int days) {
    return 'Отработано дней: $days';
  }

  @override
  String ledgerPaidAmount(String amount) {
    return '$amount оплачено';
  }

  @override
  String ledgerStatementFail(String error) {
    return 'Не удалось открыть ведомость: $error';
  }

  @override
  String get ledgerMonthlyStatement => 'Ведомость за месяц (PDF)';

  @override
  String get ledgerRemaining => 'Остаток долга';

  @override
  String get ledgerWorkHistory => 'История работ';

  @override
  String ledgerBilled(String amount) {
    return 'Начислено $amount';
  }

  @override
  String ledgerDeposited(String amount) {
    return 'Оплачено $amount';
  }

  @override
  String get ledgerPaymentSaved => 'Оплата записана.';

  @override
  String ledgerPaymentFail(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get ledgerRecordPayment => 'Записать оплату';

  @override
  String ledgerRemainingAmount(String amount) {
    return 'Остаток $amount';
  }

  @override
  String get ledgerPaymentAmount => 'Сумма оплаты';

  @override
  String get ledgerWonSuffix => '₩';

  @override
  String get ledgerFull => 'Всё';

  @override
  String get ledgerHalf => 'Половина';

  @override
  String get ledgerRecordPaymentBtn => 'Записать оплату';

  @override
  String get taxTitle => 'Подготовка счёта-фактуры';

  @override
  String taxSupplierPrefix(String name) {
    return 'Поставщик · $name';
  }

  @override
  String get taxNoBizName => '(Название не указано)';

  @override
  String taxBizNumberLine(String number) {
    return 'ИНН $number';
  }

  @override
  String get taxHometaxGuide =>
      'Вставьте скопированный текст в Hometax (hometax.go.kr) при выставлении счёта-фактуры. После выставления нажмите «Отметить как выставленный», и запись исчезнет из списка.';

  @override
  String get taxEmptyTitle => 'Нет актов для выставления.';

  @override
  String get taxEmptySubtitle =>
      'Здесь показаны только подписанные (SIGNED) и ещё не выставленные акты.';

  @override
  String get taxStamp => 'СЧЁТ-ФАКТУРА · WORKON';

  @override
  String get taxSupplierPromptTitle => 'Сначала введите данные бизнеса';

  @override
  String get taxSupplierPromptDesc =>
      'Для счёта-фактуры нужны ИНН и название поставщика (вас).';

  @override
  String get taxEnterBizInfo => 'Ввести данные бизнеса';

  @override
  String get taxCopiedSnack => 'Скопировано · вставьте в Hometax.';

  @override
  String get taxMarkedSnack => 'Отмечено как выставленный · убрано из списка.';

  @override
  String get taxAlreadyMarkedSnack =>
      'Эта запись уже отмечена как выставленная.';

  @override
  String taxMarkFailed(String msg) {
    return 'Не удалось отметить: $msg';
  }

  @override
  String taxBuyerBizLine(String number, int count) {
    return 'ИНН $number · позиций: $count';
  }

  @override
  String get taxNotRegistered => '(Не указан)';

  @override
  String get taxSupplyAmount => 'Сумма поставки';

  @override
  String get taxGrandTotal => 'Итого';

  @override
  String get taxCopy => 'Копировать';

  @override
  String get taxMarkIssued => 'Отметить выставленным';

  @override
  String get taxRegisteredBadge => 'Зарегистрирован';

  @override
  String get taxCheckNeeded => 'Нужна проверка';

  @override
  String get bizinfoTitle => 'Данные бизнеса';

  @override
  String get bizinfoDesc =>
      'Это данные поставщика (ваши), которые используются для выставления счетов-фактур.';

  @override
  String get bizinfoBizNumberLabel => 'ИНН / рег. номер';

  @override
  String get bizinfoBizNameLabel => 'Название';

  @override
  String get bizinfoBizNameHint => 'Название (компания)';

  @override
  String get bizinfoAddressLabel => 'Адрес (необязательно)';

  @override
  String get bizinfoAddressHint => 'Адрес';

  @override
  String get bizinfoSavedSnack => 'Данные бизнеса сохранены.';

  @override
  String bizinfoSaveFailed(String msg) {
    return 'Не удалось сохранить: $msg';
  }

  @override
  String get walletTitle => 'Кошелёк документов';

  @override
  String walletSelectedCount(int n) {
    return 'Выбрано: $n';
  }

  @override
  String get walletAddDoc => 'Добавить документ';

  @override
  String get walletMaskPromptTitle => 'Скрыть личные данные?';

  @override
  String get walletMaskPromptBody =>
      'Замаскируйте личные данные — номер и адрес — и делитесь безопасно.';

  @override
  String get walletLater => 'Позже';

  @override
  String get walletMaskEdit => 'Маскировка';

  @override
  String walletExpiredTitle(String type) {
    return '$type — срок истёк';
  }

  @override
  String walletExpiringTitle(String type, String dday) {
    return '$type истекает $dday';
  }

  @override
  String walletExpiringMultiSub(int n) {
    return 'Скоро истекают: $n — обновите и загрузите заново';
  }

  @override
  String get walletRenewHint => 'Обновите и загрузите заново';

  @override
  String get walletEmptyTitle => 'Пока нет документов';

  @override
  String get walletEmptySub =>
      'Добавьте удостоверения, страховку и акты проверки и следите за сроками';

  @override
  String walletShareMessage(int count, int days, String url) {
    return '[작업온] Отправляю документов: $count.\nОткройте по ссылке ниже (действует $days дн.).\n$url';
  }

  @override
  String get walletShareSubject => '작업온 — общий доступ к документам';

  @override
  String walletShareFailed(String error) {
    return 'Не удалось поделиться: $error';
  }

  @override
  String walletSendBundle(int count) {
    return 'Отправить $count вместе';
  }

  @override
  String get walletBundleSend => 'Отправить пакетом';

  @override
  String get walletValidPeriod => 'Срок действия';

  @override
  String get walletMaskedInfo =>
      'Документы с маскировкой отправляются со скрытыми личными данными.';

  @override
  String get walletUnmaskedInfo =>
      'Без маскировки отправляется оригинал. Замаскировать можно в деталях.';

  @override
  String get walletMakeLinkShare => 'Создать ссылку и поделиться';

  @override
  String docOpenFailed(String error) {
    return 'Не удалось открыть: $error';
  }

  @override
  String docUpdateFailed(String error) {
    return 'Не удалось изменить: $error';
  }

  @override
  String get docDeleteConfirmTitle => 'Удалить документ?';

  @override
  String get docDeleteConfirmBody => 'Документ и его ссылки будут удалены.';

  @override
  String docDeleteFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get docOpenPdf => 'Открыть PDF';

  @override
  String get docHasMask => 'Есть маскировка';

  @override
  String get docExpiryDate => 'Срок годности';

  @override
  String get docNone => 'Нет';

  @override
  String get docIssuedDate => 'Дата выдачи';

  @override
  String get docReMask => 'Изменить маскировку';

  @override
  String get docMaskEdit => 'Замаскировать данные';

  @override
  String get docModify => 'Изменить';

  @override
  String get docExpired => 'Истёк';

  @override
  String docUploadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String get docSourceCamera => 'Сфотографировать';

  @override
  String get docSourceGallery => 'Выбрать из галереи';

  @override
  String get docSourcePdf => 'Выбрать PDF-файл';

  @override
  String get docInfoTitle => 'Данные документа';

  @override
  String docFilePdf(String name) {
    return 'PDF · $name';
  }

  @override
  String docFileImage(int kb) {
    return 'Изображение · $kb КБ';
  }

  @override
  String get docTypeLabel => 'Тип';

  @override
  String get docLinkEquip => 'Привязать технику (по желанию)';

  @override
  String get docPersonal => 'Личное';

  @override
  String get docPickExpiry => 'Выбрать срок годности (по желанию)';

  @override
  String get docUpload => 'Загрузить';

  @override
  String get equipTitle => 'Техника';

  @override
  String get equipAdd => 'Добавить технику';

  @override
  String get equipEmptyTitle => 'Пока нет техники';

  @override
  String get equipEmptySub =>
      'Добавьте технику — экскаватор, погрузчик — и соберите её документы';

  @override
  String equipDocCount(int n) {
    return 'Документов: $n';
  }

  @override
  String get equipDocs => 'Документы';

  @override
  String get equipTypeHint => 'Вид техники (напр. экскаватор)';

  @override
  String get equipVehicleHint => 'Госномер (по желанию)';

  @override
  String get equipSpecHint => 'Характеристика (напр. 06W) (по желанию)';

  @override
  String get equipSubmit => 'Добавить';

  @override
  String get maskDoneToast =>
      'Маскированная копия создана. При отправке личные данные скрыты.';

  @override
  String maskFailed(String error) {
    return 'Не удалось замаскировать: $error';
  }

  @override
  String get maskTitle => 'Маскировка данных';

  @override
  String get maskReset => 'Сбросить';

  @override
  String get maskGuide =>
      'Проведите пальцем и выделите прямоугольниками области, которые нужно скрыть. (напр. номер, адрес)';

  @override
  String maskRegionCount(int n) {
    return 'Выделено областей: $n';
  }

  @override
  String get maskSave => 'Сохранить маскировку';

  @override
  String get wshareTitle => 'Мои ссылки';

  @override
  String wshareLoadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String get wshareEmpty => 'Вы ещё не делились пакетами документов';

  @override
  String get wshareActive => 'Активна';

  @override
  String get wshareInactive => 'Истекла/отключена';

  @override
  String wshareViewCount(int n) {
    return 'Просмотров: $n';
  }

  @override
  String get wshareReshare => 'Поделиться снова';

  @override
  String get wshareRevoke => 'Отключить';

  @override
  String myjobFailed(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get myjobConditionTitle => 'Проверка самочувствия';

  @override
  String get myjobConditionBody =>
      'Как вы себя чувствуете сегодня? Это нужно для безопасной работы.';

  @override
  String get myjobConditionBad => 'Плохо';

  @override
  String get myjobConditionGood => 'Хорошо';

  @override
  String get myjobConditionReported =>
      'Компания уведомлена о вашем самочувствии. Не перенапрягайтесь.';

  @override
  String myjobLoadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String get myjobEmpty => 'Нет полученных нарядов';

  @override
  String get myjobAccept => 'Принять';

  @override
  String get myjobStart => 'Начать работу';

  @override
  String get myjobComplete => 'Завершить работу';

  @override
  String get signPadHint => 'Распишитесь здесь пальцем';

  @override
  String get teamMenuTitle => 'Моя бригада';

  @override
  String get teamMenuSub =>
      'Управление списком и ставками бригады как бригадир';

  @override
  String get teamListTitle => 'Моя бригада';

  @override
  String get teamEmptyTitle => 'Вы ещё не создали бригаду';

  @override
  String get teamEmptySub =>
      'Создайте бригаду и добавьте участников, чтобы оформить бригадный акт одним листом';

  @override
  String get teamCreate => 'Создать бригаду';

  @override
  String get teamNameLabel => 'Название бригады';

  @override
  String get teamNameHint => 'Название бригады (напр.: Бригада А Пака)';

  @override
  String get teamAddMember => 'Добавить участника';

  @override
  String get teamMembersTitle => 'Участники';

  @override
  String get teamNoMembers => 'Пожалуйста, добавьте участников';

  @override
  String teamMemberCountLabel(int count) {
    return 'Участников: $count';
  }

  @override
  String get teamMemberLinked => 'Связан';

  @override
  String get teamMemberManual => 'Вручную';

  @override
  String get teamDefaultRate => 'Ставка по умолчанию';

  @override
  String get teamDefaultRateHint => 'Ставка по умолчанию (за 1 гонсу)';

  @override
  String get teamAddByPhone => 'Найти по телефону';

  @override
  String get teamAddManual => 'Ввести вручную';

  @override
  String get teamMemberNameHint => 'Имя';

  @override
  String get teamMemberPhoneHint => 'Телефон (необязательно)';

  @override
  String get teamSearchPhoneHint => 'Телефон участника';

  @override
  String get teamSearchHint =>
      'Найти можно только пользователей, согласившихся на поиск по телефону';

  @override
  String get teamSearchNoResult => 'Ничего не найдено';

  @override
  String get teamMemberAdded => 'Участник добавлен';

  @override
  String get teamMemberExists => 'Этот участник уже в бригаде';

  @override
  String get teamConsentRequired =>
      'Связать можно только пользователей, согласившихся на поиск по телефону';

  @override
  String get teamDeleteConfirm =>
      'Удалить эту бригаду? Уже выданные акты останутся без изменений.';

  @override
  String get teamDeleteMemberConfirm => 'Удалить этого участника?';

  @override
  String get confTeamMode => 'Бригадный акт';

  @override
  String get confTeamModeSub =>
      'Оформить гонсу каждого участника на одном листе';

  @override
  String get confTeamSelect => 'Выбрать бригаду';

  @override
  String get confTeamPickTeam => 'Пожалуйста, выберите бригаду';

  @override
  String get confTeamNoTeam => 'Сначала создайте бригаду в \'Моя бригада\'';

  @override
  String get confTeamTotal => 'Итого по бригаде';

  @override
  String get confTeamEmptyEntries => 'Нет участников с введённым гонсу';

  @override
  String get ledgerTeamBadge => 'Бригада';

  @override
  String ledgerTeamDerived(String boss) {
    return 'Работа бригады $boss';
  }

  @override
  String get ledgerDerivedReadonly =>
      'Это бригадная работа, оформленная бригадиром (можно только записывать оплату)';

  @override
  String get lcKicker => 'Трудовой договор';

  @override
  String get lcStamp => 'Т Р У Д О В О Й   Д О Г О В О Р';

  @override
  String get lcParties => 'Стороны договора';

  @override
  String get lcEmployer => 'Работодатель (сторона А)';

  @override
  String get lcWorkerParty => 'Работник (сторона Б)';

  @override
  String get lcBizNumber => 'Рег. номер предприятия';

  @override
  String get lcPeriod => 'Срок трудового договора';

  @override
  String get lcPeriodOpen => 'Без определённого срока · подённо';

  @override
  String get lcWorkplace => 'Место работы';

  @override
  String get lcJob => 'Содержание работы';

  @override
  String get lcWorkTime => 'Рабочее время';

  @override
  String get lcBreak => 'Перерыв';

  @override
  String get lcWage => 'Заработная плата';

  @override
  String get lcWageDaily => 'Дневная ставка';

  @override
  String get lcWageHourly => 'Почасовая ставка';

  @override
  String get lcPayday => 'День выплаты';

  @override
  String get lcPayMethod => 'Способ выплаты';

  @override
  String get lcAllowance => 'Надбавки';

  @override
  String get lcWeeklyHoliday =>
      'Оплата еженедельного выходного: при полной отработке недели выплачивается оплата выходного дня.';

  @override
  String get lcWeeklyHolidayNone =>
      'Оплата еженедельного выходного: не применяется (подённая/неполная занятость).';

  @override
  String get lcOvertime =>
      'За сверхурочную, ночную и работу в выходные выплачивается надбавка 50% от обычной оплаты согласно закону.';

  @override
  String get lcOvertimeNone =>
      'Надбавки за сверхурочную/ночную/праздничную работу: отдельно не оговорены.';

  @override
  String get lcInsurance => 'Социальное страхование';

  @override
  String get lcInsEmployment => 'Страхование занятости';

  @override
  String get lcInsHealth => 'Медицинское страхование';

  @override
  String get lcInsPension => 'Пенсионное страхование';

  @override
  String get lcInsAccident => 'Страхование от несчастных случаев';

  @override
  String get lcApplied => 'Применяется';

  @override
  String get lcNotApplied => 'Не применяется';

  @override
  String get lcSpecial => 'Особые условия';

  @override
  String get lcMasterNote =>
      'Оригиналом договора является версия на корейском языке. Перевод предоставлен для удобства понимания; при расхождениях преимущество имеет корейская версия.';

  @override
  String get lcEmployerSigned => 'Работодатель подписал';

  @override
  String get lcMenuDesc => 'Договоры с работниками через э-подпись';

  @override
  String get lcListEmptyTitle => 'Пока нет договоров';

  @override
  String get lcListEmptySub => 'Создайте трудовой договор с работником';

  @override
  String get lcNewContract => 'Новый договор';

  @override
  String get lcStatusDraft => 'Черновик';

  @override
  String get lcStatusSent => 'Отправлен';

  @override
  String get lcStatusSigned => 'Подписан';

  @override
  String get lcWorkerSection => 'Работник';

  @override
  String get lcWorkerByPhone => 'Поиск по телефону';

  @override
  String get lcWorkerManual => 'Ввести вручную';

  @override
  String get lcWorkerNameHint => 'Имя работника';

  @override
  String get lcWorkerPhoneHint => 'Телефон работника (необязательно)';

  @override
  String get lcSearchPhoneHint => 'Телефон работника';

  @override
  String get lcSearchHint =>
      'Найти можно только пользователей, разрешивших поиск по телефону';

  @override
  String get lcSearchNoResult => 'Ничего не найдено';

  @override
  String get lcWorkerLinkedBadge => 'Связан';

  @override
  String get lcStartDate => 'Дата начала';

  @override
  String get lcEndDate => 'Дата окончания (необязательно)';

  @override
  String get lcEndDateNotSet => 'Не задано';

  @override
  String get lcWorkplaceHint => 'напр. Объект А, Каннам';

  @override
  String get lcJobHint => 'напр. Арматурные работы';

  @override
  String get lcBreakHint => 'напр. 12:00-13:00';

  @override
  String get lcWageAmountHint => 'Сумма';

  @override
  String get lcPaydayHint => 'напр. 25-го числа';

  @override
  String get lcPayMethodHint => 'напр. Банковский перевод';

  @override
  String get lcWeeklyHolidaySwitch => 'Оплата выходного дня';

  @override
  String get lcOvertimeSwitch => 'Надбавка за сверхурочную работу';

  @override
  String get lcSpecialHint => 'Особые условия (необязательно)';

  @override
  String get lcSaveCommon => 'Сохранить частые значения';

  @override
  String get lcSaveCommonSub => 'Автозаполнение в следующий раз';

  @override
  String get lcSubmit => 'Создать договор';

  @override
  String get lcCreated => 'Договор создан';

  @override
  String get lcDetailTitle => 'Договор';

  @override
  String get lcSignEmployerTitle => 'Моя подпись (работодатель)';

  @override
  String get lcSignEmployerDesc => 'Подпишите, чтобы отправить работнику';

  @override
  String get lcSignerNameLabel => 'Имя подписавшего';

  @override
  String get lcSignRedraw => 'Перерисовать';

  @override
  String get lcSignSubmit => 'Подписать';

  @override
  String get lcSigned => 'Подписано';

  @override
  String get lcSignErrPad => 'Сначала поставьте подпись';

  @override
  String get lcSignErrName => 'Введите имя подписавшего';

  @override
  String get lcSend => 'Отправить работнику';

  @override
  String get lcSentLinked => 'Отправлено работнику';

  @override
  String get lcSentShare => 'Поделитесь ссылкой для отправки';

  @override
  String get lcShareBody => 'Ознакомьтесь и подпишите договор по ссылке ниже';

  @override
  String get lcViewPdf => 'Открыть PDF';

  @override
  String get lcDeleteConfirm => 'Удалить этот договор?';

  @override
  String get lcDeleted => 'Удалено';

  @override
  String get lcWaitingWorker => 'Ожидается подпись работника';

  @override
  String get lcMyContractsTitle => 'Мои договоры';

  @override
  String get lcMyContractsSub => 'Просмотр и подпись полученных договоров';

  @override
  String get lcMyEmptyTitle => 'Нет полученных договоров';

  @override
  String get lcMyEmptySub => 'Здесь появятся договоры от работодателей';

  @override
  String get lcWorkerSignTitle => 'Моя подпись (работник)';

  @override
  String get lcWorkerSignDesc => 'Ознакомьтесь и подпишите';

  @override
  String get lcAlreadySigned => 'Уже подписан';

  @override
  String lcCreateFailed(String msg) {
    return 'Не удалось сохранить договор: $msg';
  }

  @override
  String lcSignFailed(String msg) {
    return 'Не удалось подписать: $msg';
  }

  @override
  String lcSendFailed(String msg) {
    return 'Не удалось отправить: $msg';
  }

  @override
  String lcPdfFailed(String msg) {
    return 'Не удалось открыть PDF: $msg';
  }

  @override
  String get tbmMenuTitle => 'Журнал TBM';

  @override
  String get tbmMenuDesc => 'Собрание по ТБ · риски и подтверждение участников';

  @override
  String get tbmMyTitle => 'Полученные TBM';

  @override
  String get tbmMySub => 'Мои записи по ТБ · подтверждение';

  @override
  String get tbmTitle => 'TBM (собрание по ТБ)';

  @override
  String get tbmStamp => 'T B M';

  @override
  String get tbmListEmptyTitle => 'Пока нет записей TBM';

  @override
  String get tbmListEmptySub => 'Запишите собрание по ТБ на площадке.';

  @override
  String get tbmNew => 'Новый TBM';

  @override
  String get tbmFormTitle => 'Создать TBM';

  @override
  String get tbmSite => 'Объект';

  @override
  String get tbmSiteHint => 'напр.: Объект А, 3 этаж';

  @override
  String get tbmDate => 'Дата и время';

  @override
  String get tbmHazards => 'Риски';

  @override
  String get tbmHazardsHint => 'Выберите чипы или введите своё';

  @override
  String get tbmAddCustom => 'Своё';

  @override
  String get tbmCustomHint => 'Введите риск';

  @override
  String get tbmMeasures => 'Меры безопасности';

  @override
  String get tbmMeasuresHint => 'напр.: страховочный пояс, сигнальщик';

  @override
  String get tbmNotes => 'Примечания';

  @override
  String get tbmNotesHint => 'Примечания (необяз.)';

  @override
  String get tbmAttendees => 'Участники';

  @override
  String get tbmSelectWorkers => 'Выбрать связанных работников';

  @override
  String get tbmNoConnections => 'Нет связанных работников';

  @override
  String get tbmAddAttendeeManual => 'Добавить участника вручную';

  @override
  String get tbmAttendeeNameHint => 'Имя участника';

  @override
  String get tbmPhotos => 'Фото объекта';

  @override
  String get tbmAddPhoto => 'Добавить фото';

  @override
  String get tbmSave => 'Сохранить TBM';

  @override
  String get tbmSaved => 'TBM записан';

  @override
  String tbmSaveFailed(String msg) {
    return 'Не удалось сохранить: $msg';
  }

  @override
  String get tbmNeedHazard => 'Выберите хотя бы один риск';

  @override
  String get tbmNeedSite => 'Введите объект';

  @override
  String get tbmPresetMine => 'Мои шаблоны';

  @override
  String get tbmPresetAddChip => '＋ Сохранить шаблон';

  @override
  String get tbmPresetAddTitle => 'Сохранить частую фразу';

  @override
  String get tbmPresetDeleted => 'Шаблон удалён';

  @override
  String get tbmDetailTitle => 'Детали TBM';

  @override
  String get tbmAttendeesStatus => 'Статус подтверждений';

  @override
  String get tbmAcked => 'Подтв.';

  @override
  String get tbmNotAcked => 'Ожидание';

  @override
  String tbmAckSummary(int att, int ack) {
    return '$att присут. · $ack подтв.';
  }

  @override
  String get tbmReadonly => 'Только чтение после дня создания';

  @override
  String get tbmEdit => 'Изменить';

  @override
  String get tbmDeleteConfirm => 'Удалить эту запись TBM?';

  @override
  String get tbmDeleted => 'Удалено';

  @override
  String get tbmSaveUpdated => 'Обновлено';

  @override
  String tbmPhotoFailed(String msg) {
    return 'Ошибка фото: $msg';
  }

  @override
  String get tbmReceivedEmpty => 'Нет полученных TBM';

  @override
  String get tbmAckButton => 'Подтвердить TBM';

  @override
  String get tbmAckDone => 'Подтверждено';

  @override
  String tbmAckFailed(String msg) {
    return 'Не удалось подтвердить: $msg';
  }

  @override
  String get tbmAlreadyAcked => 'Уже подтверждено';

  @override
  String tbmPhotoCount(int n) {
    return '$n фото';
  }

  @override
  String get tbmHzHeavyEquip => 'Защемление/удар спецтехникой';

  @override
  String get tbmHzFallHeight => 'Падение с высоты';

  @override
  String get tbmHzHeatIllness => 'Тепловой удар';

  @override
  String get tbmHzElectric => 'Поражение током';

  @override
  String get tbmHzFallingObject => 'Падающие предметы';

  @override
  String get tbmHzCollapse => 'Обрушение/засыпание';

  @override
  String get tbmHzFire => 'Пожар/взрыв';

  @override
  String get tbmHzDustNoise => 'Пыль/шум';

  @override
  String get tbmHzSlipTrip => 'Скольжение/спотыкание';

  @override
  String get tbmHzConfined => 'Удушье в замкнутом пространстве';

  @override
  String get incomeReportMenuTitle => 'Отчёт о доходах';

  @override
  String get incomeReportMenuSub => 'Годовой доход, долги и трудодни';

  @override
  String get incomeReportTitle => 'Отчёт о доходах';

  @override
  String incomeReportYear(String year) {
    return '$year год';
  }

  @override
  String get incomeReportTotalBilled => 'Всего начислено';

  @override
  String get incomeReportTotalPaid => 'Всего оплачено';

  @override
  String get incomeReportTotalOutstanding => 'Всего долг';

  @override
  String get incomeReportTotalDays => 'Рабочих дней';

  @override
  String get incomeReportTotalGongsu => 'Всего гонсу';

  @override
  String get incomeReportTeamPayout => 'Выплата бригаде';

  @override
  String get incomeReportNetBilled => 'Чистый доход (справка)';

  @override
  String get incomeReportNetHint =>
      'Начислено − выплаты членам (доля бригадира)';

  @override
  String get incomeReportMonthlyTrend => 'Помесячная динамика';

  @override
  String incomeReportPeakLabel(String amount) {
    return 'Максимум $amount';
  }

  @override
  String get incomeReportByCompany => 'По контрагентам';

  @override
  String incomeReportEntryCount(int n) {
    return '$n шт.';
  }

  @override
  String incomeReportOutstandingShort(String amount) {
    return 'Долг $amount';
  }

  @override
  String get incomeReportTaxTitle => 'О подоходном налоге';

  @override
  String get incomeReportTaxL1 =>
      'Совокупный подоходный налог подаётся и уплачивается ежегодно в мае за доход предыдущего года.';

  @override
  String get incomeReportTaxL2 =>
      'С дохода от личных услуг часто удерживают 3,3% при выплате.';

  @override
  String get incomeReportTaxL3 =>
      'Удержанный налог пересчитывается (возврат или доплата) при подаче в мае.';

  @override
  String get incomeReportTaxL4 =>
      'Хранение расходов и подтверждений·ведомостей помогает при подаче.';

  @override
  String get incomeReportTaxL5 =>
      'Это общая информация, а не налоговая консультация. Для точной подачи обратитесь к специалисту или на Hometax.';

  @override
  String get incomeReportSavePdf => 'Сохранить / отправить PDF';

  @override
  String incomeReportPdfFail(String msg) {
    return 'Не удалось открыть отчёт: $msg';
  }

  @override
  String get incomeReportEmptyTitle => 'Пока нет данных о доходах';

  @override
  String get incomeReportEmptySub =>
      'Создайте подтверждение — доход появится в этом отчёте.';

  @override
  String get ledgerAutoRemind => 'Авто-напоминание об оплате';

  @override
  String get ledgerAutoRemindHint =>
      'Автоматически отправляет напоминание об оплате после срока';

  @override
  String get ledgerRemindNow => 'Отправить напоминание';

  @override
  String get ledgerRemindSent => 'Напоминание об оплате отправлено';

  @override
  String get ledgerRemindHistory => 'История напоминаний';

  @override
  String ledgerRemindHistoryItem(String date, String stage) {
    return '$date · $stage';
  }

  @override
  String get reminderStageD7 => 'Напоминание 7 дней';

  @override
  String get reminderStageD30 => 'Напоминание 30 дней';

  @override
  String get reminderStageManual => 'Ручное напоминание';

  @override
  String get profilePayoutSection => 'Счёт для получения (для напоминаний)';

  @override
  String get profilePayoutBank => 'Банк';

  @override
  String get profilePayoutAccount => 'Номер счёта';

  @override
  String get profilePayoutHolder => 'Владелец счёта';

  @override
  String get profilePayoutHint =>
      'Этот счёт добавляется при отправке напоминания об оплате (необязательно)';

  @override
  String get profilePayoutSaved => 'Счёт для получения сохранён';

  @override
  String get badgeExcellent => 'Отличный плательщик';

  @override
  String get badgeGood => 'Хороший плательщик';

  @override
  String badgeAvgDays(int days) {
    return 'В среднем $days дн.';
  }

  @override
  String get badgeSelfImproveGood =>
      'Платите в течение 15 дней, чтобы получить значок «Отличный плательщик»';

  @override
  String get badgeSelfImproveNone =>
      'Платите вовремя, чтобы получить значок «Отличный плательщик»';

  @override
  String badgeInsufficient(int count) {
    return 'Записей об оплате: $count — для значка нужно больше данных';
  }

  @override
  String badgeSampleCount(int count) {
    return 'По последним $count';
  }

  @override
  String get badgeSelfTitle => 'Надёжность оплаты';
}
