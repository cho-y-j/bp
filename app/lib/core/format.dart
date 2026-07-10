import 'package:intl/intl.dart';

final _won = NumberFormat.decimalPattern('ko_KR');

/// 1234500 -> "1,234,500"
String formatWon(num v) => _won.format(v.round());

/// "1,234,500 원"
String formatWonUnit(num v) => '${formatWon(v)} 원';

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
