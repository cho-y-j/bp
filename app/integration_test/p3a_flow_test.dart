import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P3a 자동 수금 안내 / 입금계좌 / 지급 신뢰도 배지 통합 시나리오
/// (실 백엔드 3040 / 임시 pg 5436):
///   로그인(박현장 01099990401) →
///   (1) 장부 → 대한건설 상세: 자동 수금 안내 토글 + 지금 안내 보내기 + 발송 이력
///   (2) 더보기 → 입금 계좌(수금 안내용) 입력 섹션
///   (3) 더보기 → 사업장 홈: 지급 신뢰도 자체 배지 카드
///
/// 사전 시드(curl): 박현장 확인서(대한건설, 미수/연체) → 장부 항목 1건,
///   autoRemind=true + MANUAL 안내 1건, 사업장(현장건설) 생성.
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

  testWidgets('P3a 수금 안내/입금계좌/배지 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8));
    await login(tester, '01099990401', '박현장');

    // (1) 장부 → 대한건설 상세 (자동 수금 안내 컨트롤)
    await tester.tap(find.text('장부').last);
    final gotCompany = await pumpUntil(tester, find.text('대한건설'),
        timeout: const Duration(seconds: 12));
    expect(gotCompany, isTrue, reason: '장부에 대한건설 노출');
    await tester.tap(find.text('대한건설').first);
    final gotToggle = await pumpUntil(tester, find.text('자동 수금 안내'),
        timeout: const Duration(seconds: 10));
    expect(gotToggle, isTrue, reason: '항목 상세에 자동 수금 안내 토글 노출');
    // 지금 안내 보내기 버튼 + 발송 이력 확인
    expect(find.text('지금 안내 보내기'), findsOneWidget);
    expect(find.text('안내 발송 이력'), findsOneWidget);
    await shot(tester, 'p3a-01-ledger-remind');

    // 뒤로 (Material AppBar BackButton)
    await tester.tap(find.byType(BackButton).first);
    await tester.pump(const Duration(milliseconds: 600));

    // (2) 더보기 → 입금 계좌 섹션
    await tester.tap(find.text('더보기').last);
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 10));
    final sc = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('입금 계좌 (수금 안내용)'),
      250,
      scrollable: sc,
      maxScrolls: 30,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('예금주'), findsWidgets);
    await shot(tester, 'p3a-02-profile-payout');

    // (3) 더보기 → 사업장 홈 (지급 신뢰도 자체 배지)
    await tester.scrollUntilVisible(
      find.text('사업장 홈'),
      -250,
      scrollable: sc,
      maxScrolls: 30,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('사업장 홈').first);
    final gotBadge = await pumpUntil(tester, find.text('지급 신뢰도'),
        timeout: const Duration(seconds: 12));
    expect(gotBadge, isTrue, reason: '사업장 홈에 지급 신뢰도 자체 배지 카드 노출');
    await shot(tester, 'p3a-03-biz-self-badge');
  });
}
