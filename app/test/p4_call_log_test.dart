import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/call_log.dart';

CallLogController build({
  required bool enabled,
  RecordedCall? last,
}) {
  return CallLogController(
    initialEnabled: enabled,
    initialLastCall: last,
    persistString: (_, _) async {},
    observeLifecycle: false, // onForeground 를 직접 구동.
  );
}

void main() {
  final t0 = DateTime(2026, 7, 17, 10, 0, 0);

  test('기록 후 10분 내 복귀 → 제안 노출', () async {
    final c = build(enabled: true);
    await c.recordCall(name: '김반장', phone: '01011112222', at: t0);
    expect(c.state.suggestion, isNull); // 기록만으로는 안 뜸.
    c.onForeground(t0.add(const Duration(minutes: 5)));
    expect(c.state.suggestion, isNotNull);
    expect(c.state.suggestion!.name, '김반장');
  });

  test('10분 초과면 제안 안 함', () async {
    final c = build(enabled: true);
    await c.recordCall(name: '김반장', phone: '010', at: t0);
    c.onForeground(t0.add(const Duration(minutes: 11)));
    expect(c.state.suggestion, isNull);
  });

  test('같은 통화는 1회만(닫은 뒤 다시 안 뜸)', () async {
    final c = build(enabled: true);
    await c.recordCall(name: '김반장', phone: '010', at: t0);
    c.onForeground(t0.add(const Duration(minutes: 1)));
    expect(c.state.suggestion, isNotNull);
    await c.dismiss();
    expect(c.state.suggestion, isNull);
    // 다시 복귀해도 같은 통화는 제안하지 않음.
    c.onForeground(t0.add(const Duration(minutes: 2)));
    expect(c.state.suggestion, isNull);
  });

  test('설정 OFF 면 제안 안 함', () async {
    final c = build(enabled: false);
    await c.recordCall(name: '김반장', phone: '010', at: t0);
    c.onForeground(t0.add(const Duration(minutes: 1)));
    expect(c.state.suggestion, isNull);
  });

  test('노출 중 OFF 로 바꾸면 즉시 닫힘', () async {
    final c = build(enabled: true);
    await c.recordCall(name: '김반장', phone: '010', at: t0);
    c.onForeground(t0.add(const Duration(minutes: 1)));
    expect(c.state.suggestion, isNotNull);
    await c.setEnabled(false);
    expect(c.state.enabled, isFalse);
    expect(c.state.suggestion, isNull);
  });

  test('앱 재시작(초기 lastCall 주입) 후 10분 내면 제안', () async {
    final c = build(
      enabled: true,
      last: RecordedCall(name: '이사장', phone: '010', at: t0),
    );
    c.onForeground(t0.add(const Duration(minutes: 3)));
    expect(c.state.suggestion?.name, '이사장');
  });
}
