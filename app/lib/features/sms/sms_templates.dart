import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 템플릿이 첨부/링크하는 대상 종류.
enum SmsLinkKind {
  /// 링크·첨부 없음(본문만).
  none,

  /// QR 명함 링크.
  card,

  /// 서류 지갑에서 해당 유형 서류 → 공유 링크 생성 후 본문에 첨부.
  docShare,

  /// 서류 이미지(마스킹본 우선/원본) 직접 첨부.
  docImage,
}

SmsLinkKind _kindFrom(String? s) {
  switch (s) {
    case 'card':
      return SmsLinkKind.card;
    case 'docShare':
      return SmsLinkKind.docShare;
    case 'docImage':
      return SmsLinkKind.docImage;
    default:
      return SmsLinkKind.none;
  }
}

String _kindTo(SmsLinkKind k) => switch (k) {
      SmsLinkKind.card => 'card',
      SmsLinkKind.docShare => 'docShare',
      SmsLinkKind.docImage => 'docImage',
      SmsLinkKind.none => 'none',
    };

/// 빠른 전송 템플릿 1건.
class SmsTemplate {
  final String id;
  final String title;
  final String body;
  final SmsLinkKind linkKind;

  /// docShare/docImage 일 때 매칭할 서류 유형 키워드(예: '사업자', '통장').
  final String? docType;
  final bool builtin;

  /// 기본 템플릿 식별자(card/biz/bank) — 본문은 l10n 에서 실값으로 생성한다.
  final String? builtinKey;

  const SmsTemplate({
    required this.id,
    required this.title,
    required this.body,
    this.linkKind = SmsLinkKind.none,
    this.docType,
    this.builtin = false,
    this.builtinKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'linkKind': _kindTo(linkKind),
        if (docType != null) 'docType': docType,
      };

  factory SmsTemplate.fromJson(Map j) => SmsTemplate(
        id: j['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        linkKind: _kindFrom(j['linkKind']?.toString()),
        docType: j['docType'] as String?,
        builtin: false,
      );
}

/// 사용자 커스텀 템플릿 저장소(shared_preferences). 기본 3종은 화면에서 l10n 으로 생성.
class CustomTemplatesController extends StateNotifier<List<SmsTemplate>> {
  static const String prefKey = 'workon_sms_templates';
  final Future<SharedPreferences> Function() _prefs;

  CustomTemplatesController(this._prefs) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final p = await _prefs();
    final raw = p.getString(prefKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => SmsTemplate.fromJson(e))
          .toList();
      state = list;
    } catch (_) {
      // 손상된 데이터는 무시.
    }
  }

  Future<void> _persist() async {
    final p = await _prefs();
    await p.setString(
        prefKey, jsonEncode(state.map((t) => t.toJson()).toList()));
  }

  Future<void> add(SmsTemplate t) async {
    state = [...state, t];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _persist();
  }
}

final customTemplatesProvider =
    StateNotifierProvider<CustomTemplatesController, List<SmsTemplate>>((ref) {
  return CustomTemplatesController(() => SharedPreferences.getInstance());
});
