import 'package:shared_preferences/shared_preferences.dart';

/// 문자 전송 후 "거래처로 저장할까요?" 제안을 이미 띄운 번호를 로컬에 기록한다.
/// 같은 번호로는 다시 제안하지 않기 위함(사용자가 저장하든 닫든 1회 제한).
/// 권한/서버 불필요 — 순수 로컬(SharedPreferences).
class PartnerPromptStore {
  static const String _key = 'workon_partner_prompt_seen';

  /// 전화번호에서 숫자만 남긴 정규화 키(하이픈/공백/기호 무시).
  static String normPhone(String raw) => raw.replaceAll(RegExp(r'[^0-9]'), '');

  /// 이 번호에 대해 이미 제안을 띄운 적이 있는가.
  static Future<bool> wasSeen(String normalizedPhone) async {
    if (normalizedPhone.isEmpty) return true;
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? const [];
    return list.contains(normalizedPhone);
  }

  /// 이 번호를 "제안함"으로 기록.
  static Future<void> markSeen(String normalizedPhone) async {
    if (normalizedPhone.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key)?.toList() ?? <String>[];
    if (list.contains(normalizedPhone)) return;
    list.add(normalizedPhone);
    // 무한 성장 방지 — 최근 200개만 유지.
    final trimmed =
        list.length > 200 ? list.sublist(list.length - 200) : list;
    await p.setStringList(_key, trimmed);
  }
}
