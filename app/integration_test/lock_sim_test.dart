import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/core/api_client.dart';
import 'package:workon/core/app_lock.dart';
import 'package:workon/core/token_store.dart';
import 'package:workon/main.dart';
import 'package:workon/providers/auth.dart';

/// 앱 잠금(생체/PIN) 게이트를 실기기(iOS 시뮬)에서 검증.
/// 백엔드 없이 인증 세션과 인증기(local_auth)를 override 해 잠금 게이트만 격리 검증한다.
///  1) OFF → 잠금 없이 바로 홈 진입
///  2) ON  → 앱 시작 시 잠금 화면 노출(자동 인증 실패 유지: 재시도/로그아웃 화면)
///           → 인증 성공 시 홈 진입
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  bool converted = false;

  Future<void> shot(WidgetTester tester, String name) async {
    if (!converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
    }
    await tester.pump(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
  }

  Future<bool> pumpUntil(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 10)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  List<Override> authedOverrides({
    required bool lockEnabled,
    required LockAuthenticator authenticator,
  }) {
    return [
      appLockInitialEnabledProvider.overrideWithValue(lockEnabled),
      lockAuthenticatorProvider.overrideWithValue(authenticator),
      apiClientProvider.overrideWith((ref) {
        final store = _FakeTokenStore(access: 'seed-access');
        final dio = Dio(BaseOptions(
          baseUrl: 'http://fake.local',
          validateStatus: (_) => true,
        ));
        dio.httpClientAdapter = _FakeAdapter();
        final client = ApiClient(tokens: store, dio: dio);
        client.onUnauthorized =
            () => ref.read(authControllerProvider.notifier).forceLogout();
        return client;
      }),
    ];
  }

  testWidgets('잠금 OFF → 바로 홈 진입(잠금 화면 없음)', (tester) async {
    await tester.pumpWidget(ProviderScopeApp(
      overrides: authedOverrides(
        lockEnabled: false,
        authenticator: _FakeAuth(result: true),
      ),
    ));
    final home = await pumpUntil(tester, find.text('더보기'));
    expect(home, isTrue, reason: 'OFF 면 잠금 없이 메인쉘(더보기) 진입');
    expect(find.text('인증하고 계속하기'), findsNothing);
    await shot(tester, 'lock_01_off_home');
  });

  testWidgets('잠금 ON → 잠금 화면 노출 → 인증 성공 → 홈 진입', (tester) async {
    final auth = _FakeAuth(result: false); // 자동 인증 실패 → 잠금 유지
    await tester.pumpWidget(ProviderScopeApp(
      overrides: authedOverrides(lockEnabled: true, authenticator: auth),
    ));

    // 잠금 화면(인증 버튼 + 로그아웃)이 떠야 한다. 홈(더보기)은 가려짐.
    final locked = await pumpUntil(tester, find.text('인증하고 계속하기'));
    expect(locked, isTrue, reason: 'ON + 인증 상태면 앱 시작 시 잠금 화면');
    expect(find.text('로그아웃'), findsWidgets);
    await shot(tester, 'lock_02_on_locked');

    // 인증 성공으로 전환 후 버튼 탭 → 잠금 해제 → 홈 진입.
    auth.result = true;
    await tester.tap(find.text('인증하고 계속하기'));
    final entered = await pumpUntil(tester, find.text('더보기'));
    expect(entered, isTrue, reason: '인증 성공 시 잠금 해제 후 홈 진입');
    expect(find.text('인증하고 계속하기'), findsNothing);
    await shot(tester, 'lock_03_unlocked_home');
  });
}

/// 결과를 제어할 수 있는 가짜 인증기.
class _FakeAuth implements LockAuthenticator {
  bool result;
  _FakeAuth({required this.result});
  @override
  Future<bool> canAuthenticate() async => true;
  @override
  Future<bool> authenticate(String reason) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return result;
  }
}

class _FakeTokenStore extends TokenStore {
  String? access;
  _FakeTokenStore({this.access}) : super(_noop);
  @override
  Future<String?> read() async => access;
  @override
  Future<void> write(String token) async => access = token;
  @override
  Future<String?> readRefresh() async => null;
  @override
  Future<void> writeRefresh(String token) async {}
  @override
  Future<void> writeTokens(String a, String? r) async => access = a;
  @override
  Future<void> clear() async => access = null;
}

const _noop = null;

/// /me 는 이름 있는 프로필(온보딩 skip)로 200, 그 외는 빈 리스트로 200.
class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final path = options.path;
    if (path.endsWith('/me')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'id': '1', 'name': '테스터', 'phone': '01000000000'}
        }),
        200,
        headers: _json,
      );
    }
    return ResponseBody.fromString(
        jsonEncode({'data': <dynamic>[]}), 200,
        headers: _json);
  }

  static const Map<String, List<String>> _json = {
    'content-type': ['application/json'],
  };
}
