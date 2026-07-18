// 서명 완료 도장 박스(SignatureSeal) 단독 캡처 — 캘린더 주간 목록 → 서명된 확인서 상세.
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
      {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
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

  testWidgets('서명 도장 박스 캡처', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkonApp()));
    await tester.pump(const Duration(seconds: 1));
    if (await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8))) {
      await tester.enterText(find.byType(TextField).first, '01077770001');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      if (await pumpUntil(tester, find.text('인증하고 시작하기'))) {
        await tester.tap(find.text('인증하고 시작하기'));
      }
    }
    await pumpUntil(tester, find.text('확인서 쓰기'),
        timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));

    // 캘린더 탭 → 주간(목록) 보기 → 서명된 확인서(판교) 탭.
    await tapIf(tester, find.byIcon(Icons.calendar_today_outlined));
    await tester.pump(const Duration(milliseconds: 800));
    await tapIf(tester, find.text('주'));
    final found = await pumpUntil(tester, find.text('판교 오피스 신축'),
        timeout: const Duration(seconds: 8));
    await shot(tester, 'uxfix-06b-calendar-week-after');
    if (found) {
      await tester.tap(find.text('판교 오피스 신축').first, warnIfMissed: false);
      await pumpUntil(tester, find.text('박현장 님 서명 완료'),
          timeout: const Duration(seconds: 8));
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, 'uxfix-06-confirmation-signed-after');
    }
  });
}
