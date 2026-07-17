import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// 리프레시 자동 연장 실기기(iOS 시뮬) 검증.
/// 전제: 백엔드를 ACCESS_TOKEN_TTL=3s 로 실행(액세스가 곧 만료).
/// 시나리오: 로그인 → 홈 진입 → 5초 대기(액세스 만료) → 탭 이동(인증 요청 발생)
///          → 로그인 화면으로 튕기지 않고 메인쉘 유지(= 자동 refresh 성공).
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

  testWidgets('액세스 만료 후 자동 refresh 로 화면 이동 끊김 없음', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 1));

    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 6));
    if (onLogin) {
      await tester.enterText(find.byType(TextField).first, '01033330001');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼이 나타나야 함');
      await tester.tap(find.text('인증하고 시작하기'));
    }

    // 신규 프로필이면 온보딩 이름 입력
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 5))) {
      await tester.enterText(find.byType(TextField).first, '김리프레시');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('시작하기'));
    }

    // 홈(메인쉘) 진입
    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 25));
    if (!home) {
      await shot(tester, 'refresh-00-stuck-no-home');
    }
    expect(home, isTrue, reason: '홈(메인쉘)에 진입해야 함');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'refresh-01-home');

    // 액세스 토큰(백엔드 ACCESS_TOKEN_TTL=20s) 만료 대기 —
    // 이후 인증 요청은 401 → 자동 refresh 로 이어져야 함.
    final wait = DateTime.now().add(const Duration(seconds: 23));
    while (DateTime.now().isBefore(wait)) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    // 탭 이동(인증 필요 데이터 로드 발생)
    await tester.tap(find.text('캘린더'));
    await pumpUntil(tester, find.text('주'), timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'refresh-02-calendar-after-expiry');

    await tester.tap(find.text('장부').first);
    await pumpUntil(tester, find.text('회사별'), timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'refresh-03-ledger-after-expiry');

    // 다시 더보기 → 프로필 재조회(GET /me)
    await tester.tap(find.text('더보기'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'refresh-04-more-after-expiry');

    // 핵심 단언: 로그인 화면으로 튕기지 않고 메인쉘 유지(자동 refresh 성공).
    expect(find.text('인증번호 받기'), findsNothing,
        reason: '자동 refresh 가 동작하면 재로그인 화면이 뜨면 안 됨');
    expect(find.text('더보기'), findsWidgets,
        reason: '액세스 만료 후에도 메인쉘 유지되어야 함');
  });
}
