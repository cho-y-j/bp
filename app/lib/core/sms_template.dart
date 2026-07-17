/// 문자 템플릿 변수 치환 엔진 — bizconnect-v2 `TemplateEngine.kt` 를 참고해
/// 작업온에 맞는 최소 변수 집합으로 Dart 재구현(복사 아님).
///
/// 지원 변수(중괄호): `{내이름}` `{상대명}` `{날짜}` `{시간}` `{요일}` `{현장}` `{링크}`
/// 미지원 변수는 원문을 그대로 남긴다(사용자 실수로 본문이 사라지지 않도록).
library;

/// 치환에 쓰이는 컨텍스트(모든 값 선택).
class SmsTemplateContext {
  final String? myName;
  final String? counterpartName;
  final String? site;
  final String? link;
  final DateTime referenceDate;

  SmsTemplateContext({
    this.myName,
    this.counterpartName,
    this.site,
    this.link,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? DateTime.now();
}

const _weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];

String _two(int n) => n.toString().padLeft(2, '0');

/// 앱에 노출하는 지원 변수 목록(도움말 칩 등에 사용).
const List<String> smsTemplateVariables = [
  '{내이름}',
  '{상대명}',
  '{날짜}',
  '{현장}',
  '{링크}',
];

String _valueFor(String name, SmsTemplateContext ctx) {
  switch (name) {
    case '내이름':
      return ctx.myName ?? '';
    case '상대명':
      return ctx.counterpartName ?? '';
    case '현장':
      return ctx.site ?? '';
    case '링크':
      return ctx.link ?? '';
    case '날짜':
      final d = ctx.referenceDate;
      return '${d.year}-${_two(d.month)}-${_two(d.day)}';
    case '시간':
      final d = ctx.referenceDate;
      return '${_two(d.hour)}:${_two(d.minute)}';
    case '요일':
      return '${_weekdaysKo[ctx.referenceDate.weekday - 1]}요일';
    default:
      // 미지원 변수: 원문 유지(null 반환으로 신호).
      return '{$name}';
  }
}

final _brace = RegExp(r'\{([^{}]+)\}');

/// [template] 의 `{변수}` 를 [ctx] 값으로 치환한다.
/// 미지원 변수는 그대로 남는다.
String renderSmsTemplate(String template, SmsTemplateContext ctx) {
  return template.replaceAllMapped(_brace, (m) {
    final name = m.group(1)!.trim();
    return _valueFor(name, ctx);
  });
}

/// 템플릿에서 사용된 `{변수}` 이름 목록(중복 제거).
List<String> extractSmsTemplateVars(String template) {
  final out = <String>[];
  for (final m in _brace.allMatches(template)) {
    final v = m.group(1)!.trim();
    if (v.isNotEmpty && !out.contains(v)) out.add(v);
  }
  return out;
}
