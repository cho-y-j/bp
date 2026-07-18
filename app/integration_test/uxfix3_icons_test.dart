// 아이콘 통일(2026-07-18, ★10) AFTER 스크린샷 캡처.
// 홈+하단 탭바(아웃라인 아이콘 톤) / 장부(수금 액션·상태 아이콘) 일관성 눈검수용.
// uxfix2 패턴 재사용 — 화면별 독립 testWidgets.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

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
      {Duration timeout = const Duration(seconds: 15)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> tapIf(WidgetTester tester, Finder f) async {
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 700));
    }
  }

  Future<void> loginIfNeeded(WidgetTester tester) async {
    if (await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 6))) {
      await tester.enterText(find.byType(TextField).first, '01077770001');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      if (await pumpUntil(tester, find.text('인증하고 시작하기'))) {
        await tester.tap(find.text('인증하고 시작하기'));
        await tester.pump(const Duration(milliseconds: 700));
      }
    }
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 3))) {
      await tester.enterText(find.byType(TextField).first, '이작업');
      await tester.pump(const Duration(milliseconds: 300));
      await tapIf(tester, find.text('시작하기'));
    }
  }

  void assertClean() {
    expect(find.text('연결에 문제가 있어요'), findsNothing,
        reason: '네트워크 오류 화면이 표시됨');
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: '로딩 스피너가 남아 있음');
  }

  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkonApp()));
    await tester.pump(const Duration(seconds: 2));
    await loginIfNeeded(tester);
    expect(
        await pumpUntil(tester, find.text('확인서 쓰기'),
            timeout: const Duration(seconds: 25)),
        isTrue,
        reason: '홈 진입 실패(확인서 쓰기 CTA 미등장)');
    await pumpUntil(tester, find.text('이번 달 받을 돈'),
        timeout: const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('10 홈 + 하단 탭바 아이콘', (tester) async {
    await boot(tester);
    // 하단 탭바(홈 활성=filled 예외, 나머지 outline)와 본문 아이콘이 한 화면에.
    assertClean();
    await shot(tester, 'uxfix-10-icons-home');
  });

  testWidgets('11 장부 아이콘', (tester) async {
    await boot(tester);
    await tapIf(tester, find.byIcon(Icons.receipt_long_outlined)); // 장부 탭
    // 월 미수 합계 헤더 로드 대기.
    expect(
        await pumpUntil(tester, find.text('이번 달 미수 합계'),
            timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '장부 월 합계 헤더 미등장');
    await tester.pump(const Duration(milliseconds: 600));
    assertClean();
    await shot(tester, 'uxfix-11-icons-wallet');
  });
}
