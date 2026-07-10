import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';
import 'package:workon/features/home/home_screen.dart';
import 'package:workon/providers/data.dart';

/// S4 독립 검수 수정 검증 E2E — 실 백엔드(임시 pg 5435 / api 3030).
///
/// bash 오케스트레이터와 `debugPrint` 로그 마커로 동기화한다
/// (드라이버 스크린샷 파일은 종료 시점에 일괄 저장되므로 신호로 쓸 수 없음):
///  1) 신규/기존 계정 로그인 → 장부 빈 상태 CTA 확인 → `S4REV-PHASE1-DONE`
///     → [orch 가 백엔드 종료]
///  2) 앱이 /health 다운을 감지 → 홈 provider 무효화 → 친화 에러+"다시 시도" 확인
///     → `S4REV-PHASE2-DONE` → [orch 가 백엔드 재기동]
///  3) 앱이 /health 복구를 감지 → "다시 시도" 탭 → 데이터 로드 확인
///     스크린샷 3장은 테스트 종료 시 screenshots/ 에 저장된다.
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

  Finder byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);

  // 앱 관점에서 백엔드 /health 가 기대 상태가 될 때까지 대기.
  Future<bool> waitHealth(WidgetTester tester, bool expectUp,
      {Duration timeout = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      var up = false;
      await tester.runAsync(() async {
        try {
          final res = await Dio(BaseOptions(
                  connectTimeout: const Duration(seconds: 2),
                  receiveTimeout: const Duration(seconds: 2)))
              .get('http://localhost:3030/health');
          up = (res.statusCode ?? 0) == 200;
        } catch (_) {
          up = false;
        }
      });
      if (up == expectUp) return true;
      await tester.pump(const Duration(seconds: 1));
    }
    return false;
  }

  testWidgets('S4 검수 수정 — 빈 상태 CTA + 네트워크 에러 재시도', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 1));

    // ── 로그인(전화인증, devCode 자동) — 토큰이 남아있으면 스킵됨 ────────
    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 8));
    if (onLogin) {
      await tester.enterText(byHint('01012345678'), '01088776655');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼이 나타나야 함');
      await tester.tap(find.text('인증하고 시작하기'));
    }

    // 온보딩(신규) 이름 입력 — 라우트 전환 타이밍에 강인하게 홈 도달까지 재시도.
    if (await pumpUntil(tester, byHint('예) 김기사'),
        timeout: const Duration(seconds: 8))) {
      for (var attempt = 0; attempt < 4; attempt++) {
        if (find.text('더보기').evaluate().isNotEmpty) break;
        if (byHint('예) 김기사').evaluate().isEmpty) break; // 온보딩 벗어남
        await tester.enterText(byHint('예) 김기사'), '박검수');
        await tester.pump(const Duration(milliseconds: 600));
        if (find.text('시작하기').evaluate().isNotEmpty) {
          await tester.tap(find.text('시작하기'));
        }
        await pumpUntil(tester, find.text('더보기'),
            timeout: const Duration(seconds: 8));
      }
    }

    // 홈 진입 + 요약 로드
    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 15));
    expect(home, isTrue, reason: '홈(메인쉘)에 진입해야 함');
    await pumpUntil(tester, find.text('일한 날'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));

    // ── 1) 장부 빈 상태 CTA ────────────────────────────────────────
    await tester.tap(find.text('장부').first);
    final empty = await pumpUntil(tester, find.text('이 달의 장부 기록이 없어요'),
        timeout: const Duration(seconds: 10));
    expect(empty, isTrue, reason: '신규 계정 장부는 빈 상태 CTA 를 보여야 함');
    expect(find.text('확인서 작성하기'), findsOneWidget);
    await shot(tester, 's4rev-01-ledger-empty-cta');

    // 홈 탭 복귀
    await tester.tap(find.text('홈').first);
    await pumpUntil(tester, find.text('일한 날'),
        timeout: const Duration(seconds: 6));

    debugPrint('S4REV-PHASE1-DONE'); // → orch 가 백엔드를 내린다

    // ── 2) 백엔드 다운 감지 → 무효화 → 친화 에러 + 재시도 ────────────────
    final down = await waitHealth(tester, false);
    expect(down, isTrue, reason: 'orch 가 백엔드를 내려야 함(60s)');

    // 당겨서-새로고침(onRefresh)과 동일한 provider 무효화 경로를 실제 앱
    // 컨테이너로 직접 트리거 (제스처 플레이크 제거 — 검증 대상은 에러 UI/재시도).
    final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
        listen: false);
    container.invalidate(confirmationsProvider);
    container.invalidate(ledgerSummaryProvider);
    final errorShown = await pumpUntil(tester, find.text('연결에 문제가 있어요'),
        timeout: const Duration(seconds: 30));
    expect(errorShown, isTrue, reason: '백엔드 종료 후 홈은 친화 에러를 보여야 함');
    expect(find.text('다시 시도'), findsWidgets);
    await shot(tester, 's4rev-02-home-error');

    debugPrint('S4REV-PHASE2-DONE'); // → orch 가 백엔드를 올린다

    // ── 3) 백엔드 복구 감지 → "다시 시도" 탭 → 데이터 로드 ───────────────
    final up = await waitHealth(tester, true);
    expect(up, isTrue, reason: 'orch 가 백엔드를 올려야 함(60s)');

    var recovered = false;
    final cDeadline = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(cDeadline)) {
      // 화면에 떠 있는 재시도 버튼들을 순차 탭(각 provider 무효화).
      final cnt = find.text('다시 시도').evaluate().length;
      for (var i = 0; i < cnt; i++) {
        final f = find.text('다시 시도');
        if (f.evaluate().isEmpty) break;
        await tester.tap(f.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.pump(const Duration(seconds: 2));
      if (find.text('일한 날').evaluate().isNotEmpty &&
          find.text('연결에 문제가 있어요').evaluate().isEmpty) {
        recovered = true;
        break;
      }
    }
    expect(recovered, isTrue, reason: '재시도 탭 이후 홈 데이터가 로드되어야 함');
    await shot(tester, 's4rev-03-home-recovered');
    debugPrint('S4REV-PHASE3-DONE');
  });
}
