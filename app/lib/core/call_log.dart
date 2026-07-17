import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱에서 건 통화 1건의 로컬 기록(상대·시각). 권한 불필요 — 앱이 tel: 를 열 때만 기록.
class RecordedCall {
  final String name;
  final String? phone;
  final DateTime at;

  /// 이 통화에 대해 제안 카드를 이미 노출했는가(같은 통화 1회 제한).
  final bool suggested;

  const RecordedCall({
    required this.name,
    required this.phone,
    required this.at,
    this.suggested = false,
  });

  RecordedCall copyWith({bool? suggested}) => RecordedCall(
        name: name,
        phone: phone,
        at: at,
        suggested: suggested ?? this.suggested,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'at': at.toIso8601String(),
        'suggested': suggested,
      };

  static RecordedCall? fromJson(Map? j) {
    if (j == null) return null;
    final at = DateTime.tryParse(j['at']?.toString() ?? '');
    if (at == null) return null;
    return RecordedCall(
      name: j['name']?.toString() ?? '',
      phone: j['phone'] as String?,
      at: at,
      suggested: j['suggested'] == true,
    );
  }
}

class CallLogState {
  final bool enabled;

  /// 지금 상단에 노출할 제안 대상(없으면 null).
  final RecordedCall? suggestion;

  const CallLogState({required this.enabled, this.suggestion});

  CallLogState copyWith({bool? enabled, RecordedCall? suggestion, bool clearSuggestion = false}) =>
      CallLogState(
        enabled: enabled ?? this.enabled,
        suggestion: clearSuggestion ? null : (suggestion ?? this.suggestion),
      );
}

typedef PersistString = Future<void> Function(String key, String value);

/// 통화 후 제안 상태 머신.
///  - `recordCall`: tel: 로 전화를 걸 때 상대·시각 기록.
///  - 앱 복귀(resumed) 시 최근 [window] 내 미제안 통화가 있으면 제안 카드 노출.
///  - 같은 통화 1회만, 설정 OFF 면 아예 노출 안 함.
class CallLogController extends StateNotifier<CallLogState>
    with WidgetsBindingObserver {
  final PersistString persistString;

  static const Duration window = Duration(minutes: 10);
  static const String prefEnabledKey = 'workon_postcall_enabled';
  static const String prefLastCallKey = 'workon_postcall_last';

  RecordedCall? _lastCall;
  bool _observing = false;

  CallLogController({
    required bool initialEnabled,
    RecordedCall? initialLastCall,
    required this.persistString,
    bool observeLifecycle = true,
  })  : _lastCall = initialLastCall,
        super(CallLogState(enabled: initialEnabled)) {
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  /// 전화를 건 직후 호출 — 상대·시각을 기록(제안은 다음 앱 복귀 때).
  Future<void> recordCall({required String name, String? phone, DateTime? at}) async {
    _lastCall = RecordedCall(name: name, phone: phone, at: at ?? DateTime.now());
    await persistString(prefLastCallKey, jsonEncode(_lastCall!.toJson()));
  }

  /// 설정 토글. OFF 로 바꾸면 현재 제안도 닫는다.
  Future<void> setEnabled(bool value) async {
    await persistString(prefEnabledKey, value ? '1' : '0');
    state = state.copyWith(enabled: value, clearSuggestion: !value);
  }

  /// 제안 카드 닫기 — 같은 통화는 다시 뜨지 않도록 표시.
  Future<void> dismiss() async {
    final c = _lastCall;
    if (c != null) {
      _lastCall = c.copyWith(suggested: true);
      await persistString(prefLastCallKey, jsonEncode(_lastCall!.toJson()));
    }
    state = state.copyWith(clearSuggestion: true);
  }

  /// 앱 복귀 시점 로직(테스트에서 직접 호출).
  void onForeground(DateTime now) {
    final c = _lastCall;
    if (!state.enabled || c == null || c.suggested) return;
    if (now.difference(c.at) <= window && now.isAfter(c.at.subtract(const Duration(seconds: 1)))) {
      state = state.copyWith(suggestion: c);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onForeground(DateTime.now());
    }
  }

  @override
  void dispose() {
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// main() 에서 SharedPreferences 로 읽은 초기값으로 override.
final callLogInitialEnabledProvider = Provider<bool>((_) => true);
final callLogInitialLastCallProvider = Provider<RecordedCall?>((_) => null);

final StateNotifierProvider<CallLogController, CallLogState>
    callLogControllerProvider =
    StateNotifierProvider<CallLogController, CallLogState>((ref) {
  return CallLogController(
    initialEnabled: ref.watch(callLogInitialEnabledProvider),
    initialLastCall: ref.watch(callLogInitialLastCallProvider),
    persistString: (key, value) async {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, value);
    },
  );
});
