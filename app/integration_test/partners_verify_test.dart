import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';
import 'package:workon/providers/locale.dart';

/// 거래처 기능 3화면 스크린샷 검증(실 백엔드 3070, 한국어 강제).
/// 로그인: 010-5000-0001 (dev devCode 자동입력).

/// 앱 언어를 한국어로 고정하는 오버라이드용 컨트롤러.
class _KoLocale extends LocaleController {
  _KoLocale() {
    state = const Locale('ko');
  }
}

/// 조건(finder 등장)까지 반복 pump. 스피너(무한 애니메이션) 때문에 pumpAndSettle 대신 사용.
Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (cond()) return true;
  }
  return false;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('거래처 3화면 캡처', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    await tester.pumpWidget(ProviderScopeApp(overrides: [
      localeControllerProvider.overrideWith((ref) => _KoLocale()),
    ]));
    await tester.pump(const Duration(seconds: 1));

    // ── 로그인 (이미 로그인된 상태면 건너뜀) ──
    // 스플래시/인증 확인 후 로그인 화면 또는 홈(더보기 탭) 등장 대기.
    await pumpUntil(
        tester,
        () =>
            find.text('인증번호 받기').evaluate().isNotEmpty ||
            find.text('더보기').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 30));

    if (find.text('인증번호 받기').evaluate().isNotEmpty) {
      // 전화번호 입력(첫 TextField).
      await tester.enterText(find.byType(TextField).first, '01050000001');
      await tester.pump(const Duration(milliseconds: 400));
      // 인증번호 받기.
      await tester.tap(find.text('인증번호 받기'));
      // devCode 자동입력 + 인증 화면 전환 대기.
      await pumpUntil(
          tester, () => find.text('인증하고 시작하기').evaluate().isNotEmpty);
      // 시작하기(verify).
      await tester.tap(find.text('인증하고 시작하기'));
      // 홈(더보기 탭) 도달 대기.
      await pumpUntil(tester, () => find.text('더보기').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 30));
    }

    // ── 더보기 → 거래처 ──
    await tester.tap(find.text('더보기').first);
    await tester.pump(const Duration(milliseconds: 600));
    // 거래처 타일 탭(더보기 화면의 메뉴).
    await pumpUntil(tester, () => find.text('거래처').evaluate().isNotEmpty);
    await tester.tap(find.text('거래처').first);
    await tester.pump(const Duration(milliseconds: 600));

    // 목록 로드 대기(연결/정산 시드가 보일 때까지).
    await pumpUntil(
        tester,
        () =>
            find.text('코리아건설').evaluate().isNotEmpty ||
            find.text('삼정건설').evaluate().isNotEmpty ||
            find.text('한샘물산').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('partners-01-list');

    // ── 상세(삼정건설 우선, 없으면 대영ENG) ──
    Finder detailTarget = find.text('삼정건설');
    if (detailTarget.evaluate().isEmpty) detailTarget = find.text('대영ENG');
    if (detailTarget.evaluate().isEmpty) detailTarget = find.text('한샘물산');
    await tester.tap(detailTarget.first);
    await tester.pump(const Duration(milliseconds: 800));
    await pumpUntil(tester, () => find.text('거래처 정보').evaluate().isNotEmpty);
    // 별칭 입력(수기 거래처면 필드 존재).
    final aliasField = find.widgetWithText(TextField, '별칭');
    if (aliasField.evaluate().isNotEmpty) {
      await tester.enterText(aliasField, '단골 거래처');
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot('partners-02-detail');

    // ── 빠른 보내기 수신인 시트 ──
    // 더보기 화면이 보일 때까지 백버튼 반복 탭(상세 → 목록 → 더보기).
    for (var i = 0; i < 3; i++) {
      if (find.text('빠른 보내기').evaluate().isNotEmpty) break;
      final back = find.byType(BackButton);
      if (back.evaluate().isEmpty) break;
      await tester.tap(back.first);
      await tester.pump(const Duration(milliseconds: 700));
    }
    await pumpUntil(tester, () => find.text('빠른 보내기').evaluate().isNotEmpty);
    await tester.tap(find.text('빠른 보내기').first);
    await tester.pump(const Duration(milliseconds: 700));
    // 첫 템플릿(명함) 탭 → 수신인 시트.
    await pumpUntil(
        tester, () => find.byType(InkWell).evaluate().isNotEmpty);
    // 템플릿 타일 중 하나 탭. '명함' 관련 텍스트가 있으면 그것을.
    Finder tpl = find.textContaining('명함');
    if (tpl.evaluate().isEmpty) tpl = find.byType(InkWell).first;
    await tester.tap(tpl.first);
    // 수신인 시트(연락처에서 선택 버튼)까지 대기.
    await pumpUntil(
        tester, () => find.text('연락처에서 선택').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 20));
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot('partners-03-sms-picker');
  });
}
