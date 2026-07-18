import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/core/sms_composer.dart';
import 'package:workon/main.dart';
import 'package:workon/providers/locale.dart';

/// 거래처 2단계(수동 추가 + 전송 후 저장 제안) 스크린샷 검증.
/// 실 백엔드 3070, 한국어 강제. 로그인 010-5000-0001(dev devCode 자동입력).
///
/// partners-04-add        : "거래처 추가" 시트(이름 필수 + 선택 필드)
/// partners-05-save-prompt: 문자 전송 복귀 후 "거래처로 저장할까요?" 다이얼로그
///   - 시뮬레이터엔 문자앱이 없어 실제 compose 는 시스템 공유 시트(폴백)를 띄우고
///     대기하므로 자동 구동이 불가하다. 따라서 SmsComposer 를 즉시 반환하는
///     페이크로 override(테스트 훅)하여 전송 "복귀" 시점만 재현한다. 제안 로직
///     (출처 판정·기존 거래처 대조·재제안 방지·다이얼로그)은 실제 코드가 그대로 돈다.

class _KoLocale extends LocaleController {
  _KoLocale() {
    state = const Locale('ko');
  }
}

/// 시스템 UI 를 열지 않고 "작성창을 열었다"고 즉시 응답하는 페이크(테스트 훅).
class _FakeSmsComposer implements SmsComposer {
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
  }) async =>
      SmsResult.composed;
}

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

  testWidgets('거래처 추가 + 저장 제안 캡처', (tester) async {
    await binding.convertFlutterSurfaceToImage();

    await tester.pumpWidget(ProviderScopeApp(overrides: [
      localeControllerProvider.overrideWith((ref) => _KoLocale()),
      smsComposerProvider.overrideWith((ref) => _FakeSmsComposer()),
    ]));
    await tester.pump(const Duration(seconds: 1));

    // ── 로그인(이미 로그인 상태면 건너뜀) ──
    await pumpUntil(
        tester,
        () =>
            find.text('인증번호 받기').evaluate().isNotEmpty ||
            find.text('더보기').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 30));
    if (find.text('인증번호 받기').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField).first, '01050000001');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      await pumpUntil(
          tester, () => find.text('인증하고 시작하기').evaluate().isNotEmpty);
      await tester.tap(find.text('인증하고 시작하기'));
      await pumpUntil(tester, () => find.text('더보기').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 30));
    }

    // ── 더보기 → 거래처 → "거래처 추가" 시트 ──
    await tester.tap(find.text('더보기').first);
    await tester.pump(const Duration(milliseconds: 600));
    await pumpUntil(tester, () => find.text('거래처').evaluate().isNotEmpty);
    await tester.tap(find.text('거래처').first);
    await tester.pump(const Duration(milliseconds: 700));
    // FAB "거래처 추가" 탭.
    await pumpUntil(tester, () => find.text('거래처 추가').evaluate().isNotEmpty);
    await tester.tap(find.text('거래처 추가').first);
    await pumpUntil(
        tester, () => find.widgetWithText(TextField, '이름 *').evaluate().isNotEmpty);
    // 이름(필수) + 전화 + 사업자번호 채워 스크린샷을 의미 있게.
    await tester.enterText(find.widgetWithText(TextField, '이름 *'), '한빛자재');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(
        find.widgetWithText(TextField, '전화번호'), '010-2323-4545');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(
        find.widgetWithText(TextField, '사업자등록번호'), '220-81-45678');
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot('partners-04-add');

    // 시트 닫기(저장하지 않음) — 배리어(스크림) 탭.
    await tester.tapAt(const Offset(200, 40));
    await pumpUntil(
        tester, () => find.text('거래처 추가').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 5));
    // 거래처 화면 → 더보기 복귀.
    for (var i = 0; i < 2; i++) {
      if (find.text('빠른 보내기').evaluate().isNotEmpty) break;
      final back = find.byType(BackButton);
      if (back.evaluate().isEmpty) break;
      await tester.tap(back.first);
      await tester.pump(const Duration(milliseconds: 700));
    }

    // ── 빠른 보내기 → 명함 템플릿 → 수신인(직접 입력) → 전송 → 저장 제안 ──
    await pumpUntil(tester, () => find.text('빠른 보내기').evaluate().isNotEmpty);
    await tester.tap(find.text('빠른 보내기').first);
    await tester.pump(const Duration(milliseconds: 700));
    Finder tpl = find.textContaining('명함');
    if (tpl.evaluate().isEmpty) tpl = find.byType(InkWell).first;
    await tester.tap(tpl.first);
    // 수신인 시트 대기.
    await pumpUntil(
        tester, () => find.text('연락처에서 선택').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 20));
    // 직접 입력(거래처/연락처 선택이 아닌) 새 번호.
    await tester.enterText(find.byType(TextField).first, '010-2323-4545');
    await tester.pump(const Duration(milliseconds: 400));
    // 문자 작성창 열기(페이크 → 즉시 복귀).
    await tester.tap(find.text('문자 작성창 열기'));
    // 저장 제안 다이얼로그 대기.
    final shown = await pumpUntil(
        tester, () => find.text('이 번호를 거래처로 저장할까요?').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 20));
    // 이름 1필드 프리필 데모(직접 입력이라 비어 있음 → 이름 채워 캡처).
    if (shown) {
      final nameField = find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(TextField));
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField.first, '한빛자재');
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    await binding.takeScreenshot('partners-05-save-prompt');
    expect(shown, true);
  });
}
