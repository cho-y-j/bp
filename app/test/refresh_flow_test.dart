import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/api_client.dart';
import 'package:workon/core/token_store.dart';

/// 인메모리 토큰 저장소(보안 저장소 플랫폼 채널 없이 단위 테스트).
class FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;
  FakeTokenStore({this.access, this.refresh}) : super(_noopStorage);

  @override
  Future<String?> read() async => access;
  @override
  Future<void> write(String token) async => access = token;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> writeRefresh(String token) async => refresh = token;
  @override
  Future<void> writeTokens(String a, String? r) async {
    access = a;
    if (r != null && r.isNotEmpty) refresh = r;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

// 기본 생성자는 read/write 시에만 스토리지를 쓰므로 위 오버라이드로 미사용.
const _noopStorage = null;

/// 요청 경로/헤더에 따라 응답을 흉내내는 어댑터.
///  - /auth/refresh: 지연 후 200 + 새 토큰. 호출 횟수 카운트(합류 검증).
///  - /me: authorization 이 새 액세스면 200, 아니면 401.
class FakeAdapter implements HttpClientAdapter {
  int refreshCalls = 0;
  int meCalls = 0;
  bool failRefresh;
  FakeAdapter({this.failRefresh = false});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final auth = options.headers['authorization']?.toString() ?? '';

    if (path.contains('/auth/refresh')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (failRefresh) {
        return ResponseBody.fromString(
          jsonEncode({
            'error': {'code': 'REFRESH_REUSED', 'message': 'x'}
          }),
          401,
          headers: _json,
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
          }
        }),
        200,
        headers: _json,
      );
    }

    if (path.contains('/me')) {
      meCalls++;
      if (auth == 'Bearer new-access') {
        return ResponseBody.fromString(
          jsonEncode({
            'data': {'phone': '01000000000'}
          }),
          200,
          headers: _json,
        );
      }
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'code': 'UNAUTHORIZED', 'message': '로그인이 필요합니다.'}
        }),
        401,
        headers: _json,
      );
    }

    return ResponseBody.fromString('{}', 200, headers: _json);
  }

  static const Map<String, List<String>> _json = {
    'content-type': ['application/json'],
  };
}

ApiClient buildClient(FakeTokenStore store, FakeAdapter adapter) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://test.local',
    validateStatus: (_) => true,
  ));
  dio.httpClientAdapter = adapter;
  return ApiClient(tokens: store, dio: dio);
}

void main() {
  test('401 → 자동 refresh → 새 토큰으로 원 요청 재시도 성공', () async {
    final store = FakeTokenStore(access: 'old-access', refresh: 'old-refresh');
    final adapter = FakeAdapter();
    final api = buildClient(store, adapter);

    final res = await api.get('/me');
    expect((res as Map)['phone'], '01000000000');
    expect(adapter.refreshCalls, 1);
    expect(store.access, 'new-access');
    expect(store.refresh, 'new-refresh');
  });

  test('동시 다중 401 → refresh 는 1회로 합류(single-flight)', () async {
    final store = FakeTokenStore(access: 'old-access', refresh: 'old-refresh');
    final adapter = FakeAdapter();
    final api = buildClient(store, adapter);

    final results = await Future.wait([
      api.get('/me'),
      api.get('/me'),
      api.get('/me'),
      api.get('/me'),
    ]);
    for (final r in results) {
      expect((r as Map)['phone'], '01000000000');
    }
    // 4개 요청이 동시에 401 을 받아도 refresh 는 1회만.
    expect(adapter.refreshCalls, 1);
  });

  test('refresh 실패 → 강제 로그아웃 콜백 + UNAUTHORIZED', () async {
    final store = FakeTokenStore(access: 'old-access', refresh: 'old-refresh');
    final adapter = FakeAdapter(failRefresh: true);
    final api = buildClient(store, adapter);
    var forcedOut = false;
    api.onUnauthorized = () => forcedOut = true;

    await expectLater(
      api.get('/me'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'UNAUTHORIZED')),
    );
    expect(forcedOut, true);
  });

  test('리프레시 토큰 없음 → refresh 미시도 → 강제 로그아웃', () async {
    final store = FakeTokenStore(access: 'old-access', refresh: null);
    final adapter = FakeAdapter();
    final api = buildClient(store, adapter);
    var forcedOut = false;
    api.onUnauthorized = () => forcedOut = true;

    await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
    expect(adapter.refreshCalls, 0);
    expect(forcedOut, true);
  });
}
