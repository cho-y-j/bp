import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P3a 지급 신뢰도 배지 — EXCELLENT 상태 캡처 (실 백엔드 3040 / 임시 pg 5436):
///   사전 조건: 현장건설(소유 박현장 01099990401)에 SIGNED→전액 PAID 3건 시드
///   + 배지 캐시 재계산(avg 10일·표본 3건 → EXCELLENT).
///   로그인 → 더보기 → 사업장 홈 → "⚡ 우수 지급처" 카드 스크린샷.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  bool converted = false;

  Future<void> shot(WidgetTester tester, String name) async {
    if (!converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
    }
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot(name);
  }

  Future<bool> pumpUntil(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> unfocus(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> login(WidgetTester tester, String phone, String name) async {
    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 15));
    if (onLogin) {
      await tester.enterText(find.byType(TextField).first, phone);
      await tester.pump(const Duration(milliseconds: 400));
      await unfocus(tester);
      await tester.tap(find.text('인증번호 받기'));
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'),
          timeout: const Duration(seconds: 15));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼 등장 ($phone)');
      await unfocus(tester);
      await tester.tap(find.text('인증하고 시작하기'));
    }
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 4))) {
      await tester.enterText(find.byType(TextField).first, name);
      await tester.pump(const Duration(milliseconds: 300));
      await unfocus(tester);
      await tester.tap(find.text('시작하기'));
    }
    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 30));
    expect(home, isTrue, reason: '홈(메인쉘) 진입 ($phone)');
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('P3a 자체 배지 EXCELLENT 상태 렌더', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8));
    await login(tester, '01099990401', '박현장');

    // 더보기 → 사업장 홈
    await tester.tap(find.text('더보기').last);
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 10));
    final sc = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('사업장 홈'),
      250,
      scrollable: sc,
      maxScrolls: 30,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('사업장 홈').first);

    // EXCELLENT 카드: "⚡ 우수 지급처" + "평균 10일 · 최근 3건 기준"
    final gotBadge = await pumpUntil(tester, find.textContaining('우수 지급처'),
        timeout: const Duration(seconds: 12));
    expect(gotBadge, isTrue, reason: '사업장 홈 자체 배지 EXCELLENT 카드 노출');
    expect(find.textContaining('평균 10일'), findsOneWidget);
    await shot(tester, 'p3a-04-biz-self-badge-excellent');
  });
}
