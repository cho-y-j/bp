// UX 위계 개선(2026-07-18, 2차) AFTER 스크린샷 캡처.
// 홈 "내 돈" 단일 히어로 + 캘린더 장부 펼침 + 만료 문구 수정 검증.
// 각 화면 독립 testWidgets — 새 위젯 트리로 부팅해 내비게이션 오염 방지.
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

  // 세션 없으면 로그인(시드 워커 01077770001, dev OTP 자동).
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
    // 히어로(이번 달 받을 돈) 로드 완료 대기.
    await pumpUntil(tester, find.text('이번 달 받을 돈'),
        timeout: const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('07 홈 히어로 + CTA', (tester) async {
    await boot(tester);
    // 히어로 라벨과 상시 CTA가 함께 보여야 함.
    expect(find.text('이번 달 받을 돈'), findsOneWidget,
        reason: '홈 히어로 라벨 미표시');
    expect(find.text('확인서 쓰기'), findsWidgets, reason: 'CTA 미표시');
    assertClean();
    await shot(tester, 'uxfix-07-home-hero-after');
  });

  testWidgets('09 홈 만료 문구(자격증 만료됨)', (tester) async {
    await boot(tester);
    // 확인 필요 배너의 만료 서류(expiring) 비동기 로드 대기.
    // 홈이 한 화면에 들어와 배너는 뷰포트 내에 렌더된다(스크롤 불필요).
    final expiry = find.text('자격증 만료됨');
    expect(await pumpUntil(tester, expiry, timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '수정된 만료 문구("자격증 만료됨") 미표시 — 중복 버그 회귀');
    await tester.pump(const Duration(milliseconds: 400));
    assertClean();
    await shot(tester, 'uxfix-09-home-expiry-label-after');
  });

  testWidgets('08 캘린더 장부 펼침', (tester) async {
    await boot(tester);
    await tapIf(tester, find.byIcon(Icons.calendar_today_outlined)); // 캘린더 탭
    // 월 합계(받을 돈) 헤더 로드 대기.
    expect(
        await pumpUntil(tester, find.text('받을 돈'),
            timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '캘린더 월 합계(받을 돈) 헤더 미등장');
    await tester.pump(const Duration(milliseconds: 500));
    // 판교 오피스 신축(작업 있는 날) 셀 탭 → 그 아래 장부 펼침.
    final dayCell = find.byKey(const ValueKey('cal-day-2026-07-11'));
    expect(dayCell, findsOneWidget, reason: '대상 날짜 셀 미존재');
    await tester.tap(dayCell, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 700));
    // 펼쳐진 장부 패널은 그리드 아래(지연 빌드) → 외부 ListView 를 직접 스크롤.
    final row = find.text('판교 오피스 신축');
    final listView = find.byType(ListView).first;
    for (var i = 0; i < 10 && row.evaluate().isEmpty; i++) {
      await tester.drag(listView, const Offset(0, -220));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(row, findsWidgets,
        reason: '날짜 탭 후 장부 펼침 실패(판교 오피스 신축 미등장)');
    assertClean();
    await shot(tester, 'uxfix-08-calendar-ledger-after');
  });
}
