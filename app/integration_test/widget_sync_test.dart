import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_widget/home_widget.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/core/home_widget_bridge.dart';
import 'package:workon/main.dart';

/// 홈 화면 위젯 공유 데이터 검증용 E2E (실 백엔드 3040 / 임시 pg 5436):
/// 시드된 사용자(01055557777, 오늘 일정 2건 + 미수금 800,000)로 로그인 →
/// 홈 진입 시 HomeWidgetBridge 가 App Group(group.kr.workon)에 데이터를 기록한다.
/// 종료 후 외부에서 UserDefaults plist 를 읽어 실제 데이터 공유를 확인한다.
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

  testWidgets('로그인→홈 진입 시 위젯 공유 데이터 기록', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 1));

    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 6));
    if (onLogin) {
      await tester.enterText(find.byType(TextField).first, '01055557777');
      await tester.pump(const Duration(milliseconds: 400));
      await unfocus(tester);
      await tester.tap(find.text('인증번호 받기'));
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼 등장');
      await unfocus(tester);
      await tester.tap(find.text('인증하고 시작하기'));
    }
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 4))) {
      await tester.enterText(find.byType(TextField).first, '김기사');
      await tester.pump(const Duration(milliseconds: 300));
      await unfocus(tester);
      await tester.tap(find.text('시작하기'));
    }
    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 15));
    expect(home, isTrue, reason: '홈(메인쉘) 진입');
    // 오늘 일정/이번 달 요약이 로드되면 HomeWidgetBridge.push 가 호출된다.
    await pumpUntil(tester, find.text('이번 달 요약'));
    await tester.pump(const Duration(seconds: 2));
    await shot(tester, 'widget-01-home');

    // ── 위젯 공유 데이터 native 라운드트립 검증 ──
    // App Group(group.kr.workon) UserDefaults 에 실제 기록됐는지 읽어 확인한다.
    await HomeWidget.setAppGroupId(HomeWidgetBridge.appGroupId);
    final state = await HomeWidget.getWidgetData<String>(HomeWidgetBridge.kState);
    final amount =
        await HomeWidget.getWidgetData<String>(HomeWidgetBridge.kOutstandingAmount);
    final site = await HomeWidget.getWidgetData<String>(HomeWidgetBridge.kTodaySite);
    final synced = await HomeWidget.getWidgetData<String>(HomeWidgetBridge.kSynced);
    final outLabel =
        await HomeWidget.getWidgetData<String>(HomeWidgetBridge.kOutstandingLabel);
    // ignore: avoid_print
    print('WIDGET_DATA state=$state amount=$amount site=$site '
        'outLabel=$outLabel synced=$synced');
    expect(state, 'in', reason: 'App Group 에 로그인 상태 기록');
    expect(amount, isNotNull, reason: 'App Group 이 provision 되어 값이 읽혀야 함');
    expect(amount, isNotEmpty, reason: '이번 달 미수금 금액 문자열 기록');
    expect(site, isNotNull);
  });
}
