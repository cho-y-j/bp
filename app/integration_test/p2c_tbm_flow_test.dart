import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P2c 간편 TBM 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///  Phase A(사업장): 로그인(안전사장 01055550001) → 사업장 홈 → TBM 기록 →
///    작성(위험요인 프리셋 칩 2개 + 연결 참석자 선택) → 저장 → 목록
///  Phase B(작업자): 로그아웃 → 로그인(안전근로 01055550002) → 받은 TBM →
///    TBM 확인(ack)
///  Phase C(사업장): 로그아웃 → 재로그인(사업장) → TBM 상세 확인 현황(1/1)
///
/// 사전 시드(curl): boss 01055550001(안전건설 사업장),
///   worker 01055550002(안전근로, phoneSearchConsent=true, ACCEPTED 연결).
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

  Future<void> unfocus(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);

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

  Future<void> waitSnackGone(WidgetTester tester, String text) async {
    for (var i = 0; i < 40 && find.text(text).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> goMore(WidgetTester tester) async {
    await pumpUntil(tester, find.text('더보기'), timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('더보기').first);
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> logout(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      final bb = find.byType(BackButton);
      if (bb.evaluate().isEmpty) break;
      await tester.tap(bb.first);
      await tester.pump(const Duration(milliseconds: 700));
    }
    if (find.text('더보기').evaluate().isNotEmpty) {
      await tester.tap(find.text('더보기').first);
      await tester.pump(const Duration(milliseconds: 600));
    }
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 400));
    final sc = find.byType(Scrollable);
    if (find.text('로그아웃').evaluate().isEmpty && sc.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(find.text('로그아웃'), 300,
          scrollable: sc.first, maxScrolls: 20);
    }
    await pumpUntil(tester, find.text('로그아웃'), timeout: const Duration(seconds: 6));
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('로그아웃').first);
    await pumpUntil(tester, find.text('취소'), timeout: const Duration(seconds: 6));
    await tester.tap(find.text('로그아웃').last);
    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 1));
  }

  // 사업장 홈 → TBM 기록 목록 진입.
  Future<void> openTbmList(WidgetTester tester) async {
    await goMore(tester);
    final bizTile = await pumpUntil(tester, find.text('사업장 홈'),
            timeout: const Duration(seconds: 6))
        ? find.text('사업장 홈')
        : find.text('사업장 모드');
    await pumpUntil(tester, bizTile, timeout: const Duration(seconds: 6));
    await tester.ensureVisible(bizTile);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(bizTile.first);
    await tester.pump(const Duration(seconds: 2));
    final onBiz = await pumpUntil(tester, find.text('TBM 기록'),
        timeout: const Duration(seconds: 25));
    expect(onBiz, isTrue, reason: '사업장 홈 메뉴에 TBM 기록');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('TBM 기록').last);
    await pumpUntil(tester, find.text('오늘 TBM 작성'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('P2c 간편 TBM E2E', (tester) async {
    final site = 'TBM현장-${DateTime.now().millisecondsSinceEpoch % 100000}';

    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    final atLogin = await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 6));
    if (!atLogin) {
      await logout(tester);
    }

    // ══════════ Phase A: 사업장(안전사장) — TBM 작성 ══════════
    await login(tester, '01055550001', '안전사장');
    await openTbmList(tester);

    // FAB → 작성 폼
    await tester.tap(find.text('오늘 TBM 작성'));
    final onForm = await pumpUntil(tester, byHint('예: 강동 현장 3층'),
        timeout: const Duration(seconds: 10));
    expect(onForm, isTrue, reason: 'TBM 작성 폼');
    await tester.enterText(byHint('예: 강동 현장 3층'), site);
    await tester.pump(const Duration(milliseconds: 300));
    await unfocus(tester);

    // 위험요인 프리셋 칩 2개 선택
    await tester.ensureVisible(find.text('고소작업 추락'));
    await tester.tap(find.text('고소작업 추락'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(find.text('중장비 협착·충돌'));
    await tester.tap(find.text('중장비 협착·충돌'));
    await tester.pump(const Duration(milliseconds: 250));

    // 조치 입력
    await tester.ensureVisible(byHint('예: 안전벨트 착용, 유도원 배치'));
    await tester.enterText(byHint('예: 안전벨트 착용, 유도원 배치'), '안전벨트 착용, 유도원 배치');
    await tester.pump(const Duration(milliseconds: 200));
    await unfocus(tester);

    // 참석자 = 연결 작업자(안**로) 칩 선택
    final attendee = find.text('안**로');
    await tester.ensureVisible(attendee.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(attendee.first);
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'tbm-01-form');

    // 저장
    await tester.ensureVisible(find.text('TBM 저장'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('TBM 저장'));
    final saved = await pumpUntil(tester, find.text(site),
        timeout: const Duration(seconds: 15));
    expect(saved, isTrue, reason: '저장 후 목록에 이번 TBM($site)');
    await tester.pump(const Duration(seconds: 2));
    await pumpUntil(tester, find.text(site), timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'tbm-02-saved-list');

    // ══════════ 로그아웃 → Phase B: 작업자(안전근로) — 확인 ══════════
    await logout(tester);
    await login(tester, '01055550002', '안전근로');

    await goMore(tester);
    final onMoreW = await pumpUntil(tester, find.text('받은 TBM'),
        timeout: const Duration(seconds: 8));
    expect(onMoreW, isTrue, reason: '더보기 관리 섹션에 받은 TBM 타일');
    await tester.tap(find.text('받은 TBM').last);
    final onRecv = await pumpUntil(tester, find.text(site),
        timeout: const Duration(seconds: 12));
    expect(onRecv, isTrue, reason: '받은 TBM 목록에 이번 TBM($site)');
    await tester.pump(const Duration(seconds: 1));

    // TBM 확인 탭(ack)
    await tester.ensureVisible(find.text('TBM 확인'));
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'tbm-03-worker-received');
    await tester.tap(find.widgetWithText(FilledButton, 'TBM 확인').first);
    final acked = await pumpUntil(tester, find.text('이미 확인함'),
        timeout: const Duration(seconds: 15));
    expect(acked, isTrue, reason: '작업자 TBM 확인(ack) 완료');
    await waitSnackGone(tester, '확인했어요');
    await tester.pump(const Duration(seconds: 1));

    // ══════════ 로그아웃 → Phase C: 사업장 재로그인 — 확인 현황 ══════════
    await logout(tester);
    await login(tester, '01055550001', '안전사장');
    await openTbmList(tester);

    // 목록에서 이번 TBM 상세 진입
    final onListAgain = await pumpUntil(tester, find.text(site),
        timeout: const Duration(seconds: 12));
    expect(onListAgain, isTrue, reason: '재로그인 후 목록에 TBM');
    await tester.tap(find.text(site).first);
    final onDetail = await pumpUntil(tester, find.text('참석자 확인 현황'),
        timeout: const Duration(seconds: 12));
    expect(onDetail, isTrue, reason: 'TBM 상세 참석자 확인 현황');
    // 참석 1명 · 확인 1명 (worker ack 반영)
    final confirmed = await pumpUntil(tester, find.text('참석 1명 · 확인 1명'),
        timeout: const Duration(seconds: 8));
    expect(confirmed, isTrue, reason: '확인 현황 1/1 반영');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'tbm-04-detail-ack');
  });
}
