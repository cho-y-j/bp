import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P3b 내 QR 명함 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///   로그인(김작업 01011112222 — 유효 서류 1건 시드) →
///   더보기 → 내 QR 명함 진입:
///   (a) 로컬 렌더 QR + 명함 링크 + 서류 유효 상태
///   (b) 한 줄 소개 편집 상호작용
///   (c) 노출 OFF 토글 상태
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

  testWidgets('P3b 내 QR 명함 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8));
    await login(tester, '01011112222', '김작업');

    // 더보기 → 내 QR 명함
    await tester.tap(find.text('더보기').last);
    final gotMenu = await pumpUntil(tester, find.text('내 QR 명함'),
        timeout: const Duration(seconds: 10));
    expect(gotMenu, isTrue, reason: '더보기에 내 QR 명함 메뉴 노출');
    await tester.tap(find.text('내 QR 명함').first);

    // (a) QR 화면 — 링크 + 서류 유효
    final gotCard = await pumpUntil(tester, find.text('서류 유효'),
        timeout: const Duration(seconds: 15));
    expect(gotCard, isTrue, reason: 'QR 명함 화면에 서류 유효 상태 노출');
    expect(find.textContaining('/p/'), findsWidgets, reason: '명함 링크 노출');
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, 'p3b-qr-01-card');

    // (b) 한 줄 소개 편집 상호작용 (하단 필드로 스크롤)
    final sc = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('한 줄 소개'),
      220,
      scrollable: sc,
      maxScrolls: 30,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final introField = find.byType(TextField).first;
    await tester.tap(introField);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(introField, '20년 경력 철근 반장입니다');
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'p3b-qr-02-intro');
    await unfocus(tester);

    // (c) 노출 OFF 토글 (하단 재발급 버튼까지 스크롤 → 토글 노출 보장)
    await tester.scrollUntilVisible(
      find.text('링크 재발급'),
      220,
      scrollable: sc,
      maxScrolls: 30,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final toggle = find.byType(Switch);
    expect(toggle, findsWidgets, reason: '명함 공개 토글 노출');
    await tester.tap(toggle.first);
    // OFF 힌트 등장 대기
    final gotHint = await pumpUntil(
        tester, find.textContaining('비공개'),
        timeout: const Duration(seconds: 8));
    expect(gotHint, isTrue, reason: 'OFF 시 비공개 힌트 노출');
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, 'p3b-qr-03-off');
  });
}
