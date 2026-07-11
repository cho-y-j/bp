import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 오프라인 확인서 초안 — 저장 실패(네트워크) 시 로컬 큐에 보관했다가
/// 연결 복구되면 자동 전송한다. `body` 는 `POST /confirmations` 요청 본문 그대로.
class ConfirmationDraft {
  final String id; // 로컬 고유 id (생성 시각 기반)
  final Map<String, dynamic> body; // 확인서 생성 요청 본문
  final DateTime createdAt;
  final String? lastError; // 마지막 전송 시도 실패 사유(서버 검증 실패 등)
  final int attempts; // 전송 시도 횟수

  const ConfirmationDraft({
    required this.id,
    required this.body,
    required this.createdAt,
    this.lastError,
    this.attempts = 0,
  });

  ConfirmationDraft copyWith({String? lastError, int? attempts}) =>
      ConfirmationDraft(
        id: id,
        body: body,
        createdAt: createdAt,
        lastError: lastError,
        attempts: attempts ?? this.attempts,
      );

  /// 사람이 읽는 요약(초안 목록·배너용).
  String get siteName => (body['siteName'] ?? '').toString();
  String get companyName =>
      (body['companyName'] ?? body['businessId'] ?? '상대 미지정').toString();
  String get date => (body['date'] ?? '').toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        if (lastError != null) 'lastError': lastError,
        'attempts': attempts,
      };

  factory ConfirmationDraft.fromJson(Map<String, dynamic> j) => ConfirmationDraft(
        id: j['id']?.toString() ?? '',
        body: (j['body'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        createdAt:
            DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        lastError: j['lastError'] as String?,
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      );

  /// 초안 리스트 <-> JSON 문자열 직렬화(순수 함수 — 단위 테스트 대상).
  static String encodeList(List<ConfirmationDraft> drafts) =>
      jsonEncode(drafts.map((d) => d.toJson()).toList());

  static List<ConfirmationDraft> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => ConfirmationDraft.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// 초안 큐 영속화 추상화(테스트에서 in-memory 로 교체 가능).
abstract class DraftStorage {
  Future<List<ConfirmationDraft>> load();
  Future<void> save(List<ConfirmationDraft> drafts);
  Future<ConfirmationDraft?> loadAuto();
  Future<void> saveAuto(ConfirmationDraft? draft);
}

/// shared_preferences 기반 기본 구현.
class PrefsDraftStorage implements DraftStorage {
  static const _queueKey = 'confirmation_draft_queue';
  static const _autoKey = 'confirmation_auto_draft';

  @override
  Future<List<ConfirmationDraft>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ConfirmationDraft.decodeList(prefs.getString(_queueKey));
  }

  @override
  Future<void> save(List<ConfirmationDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, ConfirmationDraft.encodeList(drafts));
  }

  @override
  Future<ConfirmationDraft?> loadAuto() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_autoKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is Map) return ConfirmationDraft.fromJson(m.cast<String, dynamic>());
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveAuto(ConfirmationDraft? draft) async {
    final prefs = await SharedPreferences.getInstance();
    if (draft == null) {
      await prefs.remove(_autoKey);
    } else {
      await prefs.setString(_autoKey, jsonEncode(draft.toJson()));
    }
  }
}
