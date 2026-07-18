// UX 개선(2026-07-18) AFTER 스크린샷 캡처.
// 각 화면을 독립 testWidgets 로 분리 — 매번 새 위젯 트리로 부팅해
// 이전 화면의 push 라우트/바텀시트가 남지 않게 한다(내비게이션 오염 방지).
// 캡처 직전: 데이터 로드 완료 대기(특정 텍스트 등장) + 오류화면/스피너 부재 assert.
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

  // 세션 없으면 로그인(시드 워커 01077770001, dev OTP 자동). 이미 로그인 상태면 무동작.
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

  // 오류화면/로딩 스피너가 남아 있으면 실패(캡처 금지).
  void assertClean() {
    expect(find.text('연결에 문제가 있어요'), findsNothing,
        reason: '네트워크 오류 화면이 표시됨');
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: '로딩 스피너가 남아 있음');
  }

  // 새 트리 부팅 → 로그인(필요시) → 홈 데이터 로드 완료까지 대기.
  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkonApp()));
    await tester.pump(const Duration(seconds: 1));
    await loginIfNeeded(tester);
    // 홈: 상시 CTA + 이번 달 요약('일한 날') 로드 완료 대기.
    expect(
        await pumpUntil(tester, find.text('확인서 쓰기'),
            timeout: const Duration(seconds: 15)),
        isTrue,
        reason: '홈 진입 실패(확인서 쓰기 CTA 미등장)');
    await pumpUntil(tester, find.text('일한 날'),
        timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('01 홈', (tester) async {
    await boot(tester);
    assertClean();
    await shot(tester, 'uxfix-01-home-after');
  });

  testWidgets('02·03 서류 지갑 + 선택 모드', (tester) async {
    await boot(tester);
    await tapIf(tester, find.byIcon(Icons.menu_rounded)); // 더보기 탭
    await tapIf(tester, find.text('서류 지갑'));
    expect(
        await pumpUntil(tester, find.text('선택해서 보내기'),
            timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '서류 지갑 로드 실패(선택해서 보내기 버튼 미등장)');
    await tester.pump(const Duration(seconds: 1));
    assertClean();
    await shot(tester, 'uxfix-02-wallet-after');

    // 선택 모드 진입 → 첫 문서 선택(체크 + 묶음 보내기 바).
    await tester.tap(find.text('선택해서 보내기'));
    await tester.pump(const Duration(milliseconds: 700));
    final radios = find.byIcon(Icons.radio_button_unchecked);
    expect(radios, findsWidgets, reason: '선택 모드 체크박스 미등장');
    await tester.tap(radios.first, warnIfMissed: false);
    expect(
        await pumpUntil(tester, find.byIcon(Icons.check_circle_rounded),
            timeout: const Duration(seconds: 4)),
        isTrue,
        reason: '문서 선택 반영 실패(체크 미표시)');
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'uxfix-03-wallet-select-after');
  });

  testWidgets('04·05 장부 회사 상세 + 이 건 관리 시트', (tester) async {
    await boot(tester);
    await tapIf(tester, find.byIcon(Icons.receipt_long_outlined)); // 장부 탭
    expect(
        await pumpUntil(tester, find.text('온플러스건설'),
            timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '장부 로드 실패(온플러스건설 미등장)');
    await tester.tap(find.text('온플러스건설').first, warnIfMissed: false);
    expect(
        await pumpUntil(tester, find.text('입금 기록'),
            timeout: const Duration(seconds: 10)),
        isTrue,
        reason: '회사 상세 로드 실패(입금 기록 버튼 미등장)');
    await tester.pump(const Duration(seconds: 1));
    assertClean();
    await shot(tester, 'uxfix-04-ledger-detail-after');

    await tapIf(tester, find.byIcon(Icons.more_horiz_rounded)); // ⋯
    expect(
        await pumpUntil(tester, find.text('이 건 관리'),
            timeout: const Duration(seconds: 6)),
        isTrue,
        reason: '⋯ 시트 미등장(이 건 관리)');
    await tester.pump(const Duration(milliseconds: 700));
    await shot(tester, 'uxfix-05-ledger-actions-sheet-after');
  });

  testWidgets('06 서명 완료 확인서 상세', (tester) async {
    await boot(tester);
    await tapIf(tester, find.byIcon(Icons.calendar_today_outlined)); // 캘린더 탭
    await tester.pump(const Duration(milliseconds: 600));
    await tapIf(tester, find.text('주')); // 주간(목록) 보기 → 월 전체 확인서
    expect(
        await pumpUntil(tester, find.text('판교 오피스 신축'),
            timeout: const Duration(seconds: 12)),
        isTrue,
        reason: '캘린더 목록 로드 실패(판교 오피스 신축 미등장)');
    await tester.tap(find.text('판교 오피스 신축').first, warnIfMissed: false);
    expect(
        await pumpUntil(tester, find.text('박현장 님 서명 완료'),
            timeout: const Duration(seconds: 10)),
        isTrue,
        reason: '확인서 상세 로드 실패(서명 완료 미등장)');
    await tester.pump(const Duration(seconds: 1));
    assertClean();
    await shot(tester, 'uxfix-06-confirmation-signed-after');
  });
}
