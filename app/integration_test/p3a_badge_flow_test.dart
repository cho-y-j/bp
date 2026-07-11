import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P3a 지급 신뢰도 배지 시각 상태 추가 캡처 (실 백엔드 3040 / 임시 pg 5436):
///   (1) 사업장 홈 자체 배지 EXCELLENT — 박현장(01099990401, 현장건설 대표,
///       시드: avgDays=10 · sampleSize=3 → 우수 지급처)
///   (2) 확인서 작성 폼 연결 사업장 배지 칩 — 김철근(01088880002,
///       현장건설과 ACCEPTED 연결) 이 연결 사업장 선택 시 ⚡ 우수 지급처 칩.
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

  Future<void> logout(WidgetTester tester) async {
    await tester.tap(find.text('더보기').last);
    await pumpUntil(tester, find.text('설정'), timeout: const Duration(seconds: 10));
    final sc = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('로그아웃'), 250,
        scrollable: sc, maxScrolls: 30);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('로그아웃').first);
    final dlg = await pumpUntil(tester, find.text('로그아웃 하시겠어요?'),
        timeout: const Duration(seconds: 5));
    expect(dlg, isTrue, reason: '로그아웃 확인 다이얼로그');
    await tester.tap(find.text('로그아웃').last);
    final loginScreen = await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 15));
    expect(loginScreen, isTrue, reason: '로그아웃 후 로그인 화면');
  }

  testWidgets('P3a 배지 EXCELLENT 시각 상태 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    // (1) 사업장 홈 자체 배지 EXCELLENT — 박현장 (토큰 남아있으면 로그인 스킵)
    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8));
    await login(tester, '01099990401', '박현장');

    await tester.tap(find.text('더보기').last);
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 10));
    await tester.tap(find.text('사업장 홈').first);
    final gotExcellent = await pumpUntil(
        tester, find.textContaining('우수 지급처'),
        timeout: const Duration(seconds: 12));
    expect(gotExcellent, isTrue, reason: '사업장 홈 자체 배지 EXCELLENT 노출');
    expect(find.textContaining('평균 10일'), findsOneWidget);
    await shot(tester, 'p3a-04-biz-self-badge-excellent');

    // 뒤로 → 로그아웃
    await tester.tap(find.byType(BackButton).first);
    await tester.pump(const Duration(milliseconds: 600));
    await logout(tester);

    // (2) 확인서 폼 연결 사업장 배지 칩 — 김철근
    await login(tester, '01088880002', '김철근');
    await tester.tap(find.text('작성').last);
    final form = await pumpUntil(tester, find.text('연결 사업장'),
        timeout: const Duration(seconds: 12));
    expect(form, isTrue, reason: '확인서 폼 연결 사업장 모드 칩 노출');
    await tester.tap(find.text('연결 사업장').first);
    await tester.pump(const Duration(milliseconds: 400));
    // 드롭다운 열기 → 현장건설 선택
    await tester.tap(find.text('연결 사업장 선택').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('현장건설').last);
    await tester.pump(const Duration(milliseconds: 400));
    final gotChip = await pumpUntil(tester, find.textContaining('우수 지급처'),
        timeout: const Duration(seconds: 12));
    expect(gotChip, isTrue, reason: '연결 사업장 배지 칩(⚡ 우수 지급처) 노출');
    await shot(tester, 'p3a-05-badge-chip');
  });
}
