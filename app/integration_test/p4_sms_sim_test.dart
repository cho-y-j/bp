import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/core/api_client.dart';
import 'package:workon/core/call_log.dart';
import 'package:workon/core/sms_composer.dart';
import 'package:workon/core/token_store.dart';
import 'package:workon/main.dart';
import 'package:workon/providers/auth.dart';

/// P4 문자 연동 — 빠른 보내기 프리필 + 통화 후 제안 카드를 별도 시뮬에서 검증.
/// 문자 작성창(MFMessageComposeViewController)은 시뮬에서 열 수 없어(canSendText=false)
/// FakeSmsComposer 로 프리필 인자(수신인·본문)를 캡처해 실측한다(한계 명시).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  bool converted = false;
  final composer = _FakeComposer();

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

  List<Override> overrides({RecordedCall? lastCall}) => [
        smsComposerProvider.overrideWithValue(composer),
        callLogInitialEnabledProvider.overrideWithValue(true),
        callLogInitialLastCallProvider.overrideWithValue(lastCall),
        apiClientProvider.overrideWith((ref) {
          final dio = Dio(BaseOptions(
              baseUrl: 'http://fake.local', validateStatus: (_) => true));
          dio.httpClientAdapter = _FakeAdapter();
          final client =
              ApiClient(tokens: _FakeTokenStore(access: 'seed'), dio: dio);
          client.onUnauthorized =
              () => ref.read(authControllerProvider.notifier).forceLogout();
          return client;
        }),
      ];

  testWidgets('통화 후 제안 카드 → 빠른 보내기 프리필 실측', (tester) async {
    // 최근(방금) 통화 기록을 주입 → 앱 복귀(resumed) 시 제안 카드 노출.
    await tester.pumpWidget(ProviderScopeApp(
      overrides: overrides(
        lastCall: RecordedCall(
            name: '김반장', phone: '01099998888', at: DateTime.now()),
      ),
    ));
    final home = await pumpUntil(tester, find.text('더보기'));
    expect(home, isTrue, reason: '메인쉘 진입');

    // 앱 복귀 라이프사이클 → CallLogController.onForeground 구동.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final cardShown =
        await pumpUntil(tester, find.textContaining('방금 김반장'));
    expect(cardShown, isTrue, reason: '통화 후 제안 카드 노출');
    await shot(tester, 'p4_01_postcall_card');

    // 통화 후 카드에서 [빠른 보내기] → QuickSendScreen(수신인 프리필).
    await tester.tap(find.text('빠른 보내기').last);
    final onQuick = await pumpUntil(tester, find.text('보낼 템플릿을 선택하세요'));
    expect(onQuick, isTrue, reason: '빠른 보내기 화면');
    await shot(tester, 'p4_02_quicksend_templates');

    // 명함 템플릿 탭 → 수신인 시트(전화 프리필됨).
    await tester.tap(find.text('명함').first);
    final sheet = await pumpUntil(tester, find.text('문자 작성창 열기'));
    expect(sheet, isTrue, reason: '수신인 시트');
    // 통화 후 카드에서 넘어온 수신인(01099998888)이 프리필돼야 한다.
    expect(find.text('01099998888'), findsOneWidget);
    await shot(tester, 'p4_03_recipient_prefill');

    // 문자 작성창 열기 → FakeComposer 가 프리필 인자를 캡처.
    await tester.tap(find.text('문자 작성창 열기'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(composer.lastRecipients, contains('01099998888'),
        reason: '수신인 프리필');
    expect(composer.lastBody, contains('https://workon.example/p/tok123'),
        reason: '명함 링크 본문 프리필');
    expect(composer.lastBody, contains('홍길동'), reason: '내 이름 치환');
    await shot(tester, 'p4_04_composed');
  });

  testWidgets('더보기 — 빠른 보내기 메뉴 + 통화 후 보내기 설정', (tester) async {
    await tester.pumpWidget(ProviderScopeApp(overrides: overrides()));
    final home = await pumpUntil(tester, find.text('더보기'));
    expect(home, isTrue);
    await tester.tap(find.text('더보기'));
    await tester.pump(const Duration(milliseconds: 400));
    final quickTile = await pumpUntil(tester, find.text('빠른 보내기'));
    expect(quickTile, isTrue, reason: '더보기에 빠른 보내기 메뉴');
    // 설정 토글이 보이도록 스크롤.
    await tester.dragUntilVisible(
      find.text('통화 후 보내기 제안'),
      find.byType(Scrollable).first,
      const Offset(0, -250),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('통화 후 보내기 제안'), findsOneWidget);
    await shot(tester, 'p4_05_more_settings');
  });
}

class _FakeComposer implements SmsComposer {
  List<String> lastRecipients = const [];
  String lastBody = '';
  List<String> lastAttachments = const [];

  @override
  Future<bool> canSendText() async => true;
  @override
  Future<bool> canSendAttachments() async => true;
  @override
  Future<SmsResult> compose({
    required List<String> recipients,
    required String body,
    List<String> attachments = const [],
    Rect? sharePositionOrigin,
  }) async {
    lastRecipients = recipients;
    lastBody = body;
    lastAttachments = attachments;
    return SmsResult.composed;
  }
}

class _FakeTokenStore extends TokenStore {
  String? access;
  _FakeTokenStore({this.access});
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

class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final path = options.path;
    Object body;
    if (path.endsWith('/me')) {
      body = {'id': '1', 'name': '홍길동', 'phone': '01000000000'};
    } else if (path.endsWith('/me/card')) {
      body = {
        'token': 'tok123',
        'url': 'https://workon.example/p/tok123',
        'enabled': true,
        'viewCount': 0,
        'preview': {'name': '홍길동', 'industryTags': <String>[]},
        'docStatus': {'valid': true, 'expiredDocs': <dynamic>[]},
      };
    } else if (path.contains('/confirmations')) {
      body = {'count': 0, 'totalAmount': 0, 'byDate': [], 'items': []};
    } else if (path.contains('/ledger/summary')) {
      body = {
        'month': '2026-07',
        'daysWorked': 0,
        'totalBilled': 0,
        'totalOutstanding': 0,
        'totalPaid': 0,
        'entryCount': 0,
        'totalGongsu': 0,
      };
    } else if (path.endsWith('/documents') ||
        path.contains('/documents/expiring') ||
        path.endsWith('/teams') ||
        path.endsWith('/connections') ||
        path.endsWith('/document-shares')) {
      body = {'items': <dynamic>[]};
    } else {
      body = <String, dynamic>{};
    }
    return ResponseBody.fromString(jsonEncode({'data': body}), 200,
        headers: {
          'content-type': ['application/json']
        });
  }
}
