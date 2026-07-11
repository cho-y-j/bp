import 'package:intl/intl.dart';

final _won = NumberFormat.decimalPattern('ko_KR');

/// 1234500 -> "1,234,500"
String formatWon(num v) => _won.format(v.round());

/// "1,234,500 원"
String formatWonUnit(num v) => '${formatWon(v)} 원';

// ─── 로케일 대응 포맷 (다국어) ──────────────────────────────────────────────
// 앱 언어 코드(ko/zh/ru/vi/ne/en) → Intl 로케일. 웹 LANG_LOCALE 와 동일 규칙.
const Map<String, String> _langLocale = {
  'ko': 'ko_KR',
  'zh': 'zh_CN',
  'ru': 'ru_RU',
  'vi': 'vi_VN',
  'ne': 'ne_NP',
  'en': 'en_US',
};

String localeName(String lang) => _langLocale[lang] ?? 'ko_KR';

final Map<String, NumberFormat> _numFmt = {};
NumberFormat _grouped(String lang) =>
    _numFmt[lang] ??= NumberFormat.decimalPattern(localeName(lang));

/// 로케일 천단위 그룹핑. (ru 공백·ne 데바나가리/라크 등 로케일 규칙 그대로)
String formatGrouped(num v, String lang) => _grouped(lang).format(v.round());

/// 금액 표기 — 원화 고정. ko 는 "1,234원", 그 외는 "₩1,234". (웹 money 규칙 동일)
String formatMoney(num v, String lang) {
  final n = formatGrouped(v, lang);
  return lang == 'ko' ? '$n원' : '₩$n';
}

/// 날짜 — 요일 포함 로케일 표기. ko "7월 11일 (토)", en "Sat, Jul 11".
String fmtDate(DateTime d, String lang) =>
    DateFormat.MMMEd(localeName(lang)).format(d);

/// 짧은 날짜 + 요일. ko "7. 11. (토)" 형태(로케일).
String fmtShortDate(DateTime d, String lang) {
  final loc = localeName(lang);
  return '${DateFormat.Md(loc).format(d)} (${DateFormat.E(loc).format(d)})';
}

/// 연·월·일·요일 전체. ko "2026년 7월 11일 토요일".
String fmtFullDate(DateTime d, String lang) =>
    DateFormat.yMMMMEEEEd(localeName(lang)).format(d);

/// 연·월. ko "2026년 7월".
String fmtMonth(DateTime d, String lang) =>
    DateFormat.yMMMM(localeName(lang)).format(d);

/// HH:mm → 로케일 시간 표기. ko "오전 8:00", en "8:00 AM".
String fmtAmpm(String hhmm, String lang) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return DateFormat.jm(localeName(lang)).format(DateTime(2000, 1, 1, h, m));
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// "2026-07-11" -> "7월 11일 (토)"
String formatDateK(DateTime d) => '${d.month}월 ${d.day}일 (${_weekdays[d.weekday - 1]})';

/// "2026-07-11" -> "07.11 (토)"
String formatShortDate(DateTime d) =>
    '${_two(d.month)}.${_two(d.day)} (${_weekdays[d.weekday - 1]})';

/// "2026년 7월 11일 토요일"
String formatFullDateK(DateTime d) {
  const w = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${d.year}년 ${d.month}월 ${d.day}일 ${w[d.weekday - 1]}';
}

/// "2026년 7월"
String formatMonthK(DateTime d) => '${d.year}년 ${d.month}월';

/// DateTime -> "YYYY-MM"
String monthParam(DateTime d) => '${d.year}-${_two(d.month)}';

/// DateTime -> "YYYY-MM-DD"
String dateParam(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// D-day 사람이 읽는 라벨. dday = 남은 일수(음수면 지남).
String ddayLabel(int? dday) {
  if (dday == null) return '';
  if (dday == 0) return 'D-day';
  return dday > 0 ? 'D-$dday' : 'D+${-dday}';
}

/// 공수 수량 표기. 정수면 소수점 없이. (예: 19.5 → "19.5", 18 → "18")
String formatGongsu(num g) => g == g.roundToDouble() ? '${g.round()}' : '$g';

/// 일한 날 요약 라벨. 공수가 있으면 "18일 · 19.5공수", 없으면 "18일".
String daysWithGongsu(int days, num gongsu) {
  final base = '$days일';
  if (gongsu <= 0) return base;
  return '$base · ${formatGongsu(gongsu)}공수';
}

/// 알림 뱃지 텍스트. 0 이면 빈 문자열(뱃지 숨김), 9 초과면 "9+".
String badgeCount(int count) {
  if (count <= 0) return '';
  if (count > 9) return '9+';
  return '$count';
}

/// HH:mm 표기 → 오전/오후 표기 ("08:00" -> "오전 8:00")
String ampm(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return hhmm;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts[1];
  final isPm = h >= 12;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '${isPm ? '오후' : '오전'} $h12:$m';
}
