// 캘린더 미수/입금 분리 표기(2026-07-18) AFTER 스크린샷 캡처.
//  - 12: 월 그리드 — 입금 완료 날(초록) · 미수 잔존 날(주황) 혼재.
//  - 13: 날짜 탭 장부 뷰 — 부분입금(PARTIAL) '입금 N원' 보조 표기.
// 시드 워커 01077770001(2026-07): 07-11/15/16 완납(초록), 07-14 부분입금(100,000),
//   07-17/18 미수(주황). BASE_URL=http://localhost:3070/api.
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
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('12 월 그리드 — 일감 미니 라인(3건 날) + 입금/미수/초안 색', (tester) async {
    await gotoCalendar(tester);
    // 3건 날(07-08): 판교(입금·초록)·역삼(미수·주황)·성수(초안·회색) 미니 라인.
    expect(find.byKey(const ValueKey('cal-day-2026-07-08')), findsOneWidget);
    // 칸 안에 현장명 줄이 렌더되는지(그리드 영역 안 텍스트).
    expect(find.text('판교 오피스 신축'), findsWidgets,
        reason: '날짜 칸 안 일감 미니 라인 미표시');
    await tester.pump(const Duration(milliseconds: 500));
    assertClean();
    await shot(tester, 'uxfix-12-calendar-paid-split');
  });

  testWidgets('13 날짜 탭 — 3건 전부 펼침 + 부분입금 보조 표기', (tester) async {
    await gotoCalendar(tester);
    // 07-08(3건: 판교 완납·역삼 부분입금 100,000·성수 초안) 셀 탭 → 장부 펼침.
    final dayCell = find.byKey(const ValueKey('cal-day-2026-07-08'));
    expect(dayCell, findsOneWidget, reason: '대상 날짜(07-08) 셀 미존재');
    await tester.tap(dayCell, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 700));
    // 펼쳐진 장부 패널은 그리드 아래 → 외부 ListView 스크롤로 노출.
    final panelRow = find.text('역삼 리모델링');
    final listView = find.byType(ListView).first;
    for (var i = 0; i < 14 && panelRow.evaluate().isEmpty; i++) {
      await tester.drag(listView, const Offset(0, -220));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 600));
    // 그날 3건 전부 펼쳐져야 함(단건 제한 없음).
    expect(find.text('판교 오피스 신축'), findsWidgets, reason: '판교 건 미펼침');
    expect(find.text('역삼 리모델링'), findsWidgets, reason: '역삼 건 미펼침');
    expect(find.text('성수 물류창고'), findsWidgets, reason: '성수 건 미펼침');
    // 부분입금 보조 표기('입금 100,000').
    expect(find.textContaining('입금 100,000'), findsWidgets,
        reason: '부분입금 보조 표기(입금 100,000) 미표시');
    // 패널 3건 전부가 화면에 보이도록 마지막 건(성수)까지 스크롤해 노출한 뒤 캡처.
    await tester.ensureVisible(find.text('성수 물류창고').last);
    await tester.pump(const Duration(milliseconds: 500));
    assertClean();
    await shot(tester, 'uxfix-13-calendar-day-split');
  });
}
