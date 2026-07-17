import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/app_lock.dart';

/// 인증 결과를 제어할 수 있는 가짜 인증기.
class FakeAuthenticator implements LockAuthenticator {
  bool canAuth;
  bool authResult;
  int authCalls = 0;
  FakeAuthenticator({this.canAuth = true, this.authResult = true});

  @override
  Future<bool> canAuthenticate() async => canAuth;

  @override
  Future<bool> authenticate(String reason) async {
    authCalls++;
    return authResult;
  }
}

AppLockController build(
  FakeAuthenticator auth, {
  required bool enabled,
}) {
  return AppLockController(
    auth,
    initialEnabled: enabled,
    persist: (_) async {},
    observeLifecycle: false, // 라이프사이클은 onBackground/onForeground 로 직접 구동.
  );
}

void main() {
  final t0 = DateTime(2026, 7, 17, 9, 0, 0);

  test('시작 잠금: 잠금 ON 이면 앱 시작 시 잠긴 상태', () {
    final c = build(FakeAuthenticator(), enabled: true);
    expect(c.state.enabled, true);
    expect(c.state.isLocked, true);
  });

  test('OFF 시 통과: 잠금 OFF 면 시작·백그라운드 후 복귀 모두 잠기지 않음', () {
    final c = build(FakeAuthenticator(), enabled: false);
    expect(c.state.isLocked, false);
    // 아무리 오래 백그라운드에 있다 복귀해도 잠기지 않는다.
    c.onBackground(t0);
    c.onForeground(t0.add(const Duration(hours: 1)));
    expect(c.state.isLocked, false);
  });

  test('백그라운드 타이머: 30초 이상 후 복귀면 재잠금, 미만이면 유지', () {
    final c = build(FakeAuthenticator(), enabled: true);
    // 인증으로 해제된 상태에서 시작.
    return c.authenticate('r').then((_) {
      expect(c.state.isLocked, false);

      // 29초 백그라운드 → 복귀해도 잠기지 않음.
      c.onBackground(t0);
      c.onForeground(t0.add(const Duration(seconds: 29)));
      expect(c.state.isLocked, false);

      // 31초 백그라운드 → 복귀 시 재잠금.
      c.onBackground(t0);
      c.onForeground(t0.add(const Duration(seconds: 31)));
      expect(c.state.isLocked, true);
    });
  });

  test('인증 성공 → 해제, 실패 → 잠금 유지', () async {
    final auth = FakeAuthenticator(authResult: false);
    final c = build(auth, enabled: true);
    expect(c.state.isLocked, true);

    final failed = await c.authenticate('r');
    expect(failed, false);
    expect(c.state.isLocked, true); // 실패 시 잠금 유지(재시도 화면).

    auth.authResult = true;
    final ok = await c.authenticate('r');
    expect(ok, true);
    expect(c.state.isLocked, false);
  });

  test('setEnabled: 켜면 잠그지 않고(사용 중) 끄면 해제', () async {
    final c = build(FakeAuthenticator(), enabled: false);
    await c.setEnabled(true);
    expect(c.state.enabled, true);
    expect(c.state.isLocked, false); // 설정에서 막 켰으므로 잠그지 않음.

    // 이후 백그라운드 30초+ → 재잠금 동작.
    c.onBackground(t0);
    c.onForeground(t0.add(const Duration(seconds: 40)));
    expect(c.state.isLocked, true);

    await c.setEnabled(false);
    expect(c.state.enabled, false);
    expect(c.state.isLocked, false);
  });

  test('markUnlocked: 새 로그인 시 잠금 해제', () {
    final c = build(FakeAuthenticator(), enabled: true);
    expect(c.state.isLocked, true);
    c.markUnlocked();
    expect(c.state.isLocked, false);
  });
}
