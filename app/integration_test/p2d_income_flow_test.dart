import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P2d 연간 소득 리포트 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///   로그인(박현장 01099990401) → 더보기 → 소득 리포트 →
///   총계 카드 / 월별 추이(커스텀 막대) / 상대별 리스트 / 종소세 안내 렌더 확인.
///
/// 사전 시드(curl): 박현장(01099990401) — 일반 확인서(3월)·공수 확인서(5월)·
///   팀 확인서(6월, 서명) → 2026년 소득 데이터 존재.
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

  testWidgets('P2d 소득 리포트 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8));
    await login(tester, '01099990401', '박현장');

    // 더보기 → 소득 리포트
    await tester.tap(find.text('더보기').first);
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 500));
    final sc = find.byType(Scrollable);
    if (find.text('소득 리포트').evaluate().isEmpty && sc.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(find.text('소득 리포트'), 250,
          scrollable: sc.first, maxScrolls: 20);
    }
    await pumpUntil(tester, find.text('소득 리포트'),
        timeout: const Duration(seconds: 6));
    await tester.ensureVisible(find.text('소득 리포트'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('소득 리포트').last);

    // 총계 카드
    final onReport = await pumpUntil(tester, find.text('총 청구액'),
        timeout: const Duration(seconds: 20));
    expect(onReport, isTrue, reason: '소득 리포트 총계 카드');
    await pumpUntil(tester, find.text('2026년'), timeout: const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, 'income-01-totals');

    // 월별 추이 + 상대별
    final reportScroll = find.byType(Scrollable);
    await tester.scrollUntilVisible(find.text('상대별 합계'), 250,
        scrollable: reportScroll.first, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('월별 추이'), findsWidgets);
    await shot(tester, 'income-02-trend-company');

    // 종소세 안내 + PDF 버튼
    await tester.scrollUntilVisible(find.text('PDF 저장·공유'), 250,
        scrollable: reportScroll.first, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('종합소득세 안내'), findsOneWidget);
    await shot(tester, 'income-03-tax-pdf');

    await tester.pump(const Duration(seconds: 1));
  });
}
