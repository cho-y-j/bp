// 팀원 파생 소득(teamShares) 캘린더 AFTER 스크린샷 캡처.
//  - 01: 월 그리드 — 날짜 칸에 '팀·판교 팀 현장' 미니 라인(팀 작업 몫) 표시.
//  - 02: 날짜 탭(2026-09-10) — '박현장 반장 팀 작업' 읽기 전용 카드 + 본인 몫 + PARTIAL 입금.
// 시드: 팀원 01088880002. 2026-09-05 본인 확인서(100,000) + 2026-09-10 팀 작업 몫(180,000, 부분입금 80,000).
// BASE_URL=http://localhost:3070/api. 기본 월(디바이스)에서 다음 달로 2회 이동해 2026-09 로.
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
      await tester.enterText(find.byType(TextField).first, '01088880002');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      if (await pumpUntil(tester, find.text('인증하고 시작하기'))) {
        await tester.tap(find.text('인증하고 시작하기'));
        await tester.pump(const Duration(milliseconds: 700));
      }
    }
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 3))) {
      await tester.enterText(find.byType(TextField).first, '이팀원');
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

  // 기본 월에서 다음 달로 이동해 2026-09 그리드를 노출한다(최대 18회).
  Future<void> gotoSep2026(WidgetTester tester) async {
    for (var i = 0; i < 18; i++) {
      if (find.byKey(const ValueKey('cal-day-2026-09-10')).evaluate().isNotEmpty) {
        return;
      }
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntil(tester, find.text('받을 돈'),
          timeout: const Duration(seconds: 6));
    }
  }

  Future<void> gotoCalendar(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkonApp()));
    await tester.pump(const Duration(seconds: 2));
    await loginIfNeeded(tester);
    expect(
        await pumpUntil(tester, find.text('확인서 쓰기'),
            timeout: const Duration(seconds: 25)),
        isTrue,
        reason: '홈 진입 실패');
    await tapIf(tester, find.byIcon(Icons.calendar_today_outlined));
    expect(
        await pumpUntil(tester, find.text('받을 돈'),
            timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '캘린더 월 합계(받을 돈) 헤더 미등장');
    await gotoSep2026(tester);
    expect(find.byKey(const ValueKey('cal-day-2026-09-10')), findsOneWidget,
        reason: '2026-09 그리드 진입 실패');
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('01 월 그리드 — 팀 작업 미니 라인(팀·현장) 표시', (tester) async {
    await gotoCalendar(tester);
    // 09-10 칸에 '팀·판교 팀 현장' 미니 라인.
    expect(find.textContaining('판교 팀 현장'), findsWidgets,
        reason: '날짜 칸 안 팀 작업 미니 라인 미표시');
    await tester.pump(const Duration(milliseconds: 500));
    assertClean();
    await shot(tester, 'teamshare-01-calendar');
  });

  testWidgets('02 날짜 탭(09-10) — 팀 작업 카드 + 본인 몫 + PARTIAL 입금', (tester) async {
    await gotoCalendar(tester);
    final dayCell = find.byKey(const ValueKey('cal-day-2026-09-10'));
    expect(dayCell, findsOneWidget, reason: '대상 날짜(09-10) 셀 미존재');
    await tester.tap(dayCell, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 700));
    // 펼침 패널은 그리드 아래 → 외부 ListView 스크롤로 노출.
    final card = find.textContaining('반장 팀 작업');
    final listView = find.byType(ListView).first;
    for (var i = 0; i < 14 && card.evaluate().isEmpty; i++) {
      await tester.drag(listView, const Offset(0, -220));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 600));
    // 읽기 전용 팀 작업 카드('박현장 반장 팀 작업') + 현장 + 부분입금(입금 80,000).
    expect(find.textContaining('반장 팀 작업'), findsWidgets,
        reason: '팀 작업 카드 미표시');
    expect(find.textContaining('판교 팀 현장'), findsWidgets,
        reason: '팀 작업 현장명 미표시');
    expect(find.textContaining('입금 80,000'), findsWidgets,
        reason: '부분입금 보조 표기(입금 80,000) 미표시');
    await tester.ensureVisible(find.textContaining('반장 팀 작업').last);
    await tester.pump(const Duration(milliseconds: 500));
    assertClean();
    await shot(tester, 'teamshare-02-day');
  });
}
