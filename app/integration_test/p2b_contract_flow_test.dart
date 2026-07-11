import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P2b 표준근로계약서(전자서명) 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///  Phase A(사업장): 로그인(계약사장 01033330001) → 사업장 홈 → 표준근로계약서 →
///    계약서 작성(전화로 찾기=박근로 연결) → 내 서명(사업주) → 전송
///  Phase B(작업자): 로그아웃 → 로그인(박근로 01033330002) → 내 계약서 →
///    받은 계약서 확인 → 서명
///
/// 사전 시드(seed_lc.sh): boss 01033330001(계약건설테스트 사업장),
///                        worker 01033330002(박근로, phoneSearchConsent=true).
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

  // 스낵바가 완전히 사라질 때까지(퇴장 애니메이션 포함) 프레임 단위로 대기.
  Future<void> waitSnackGone(WidgetTester tester, String text) async {
    for (var i = 0; i < 40 && find.text(text).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 600));
  }

  // 더보기 탭으로 이동 후 관리 화면 로드 대기.
  Future<void> goMore(WidgetTester tester) async {
    await pumpUntil(tester, find.text('더보기'), timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('더보기').first);
    await pumpUntil(tester, find.text('관리'), timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 600));
  }

  // 서명 패드에 두 획 그리기.
  Future<void> drawSignature(WidgetTester tester) async {
    final hint = find.textContaining('서명하세요');
    if (hint.evaluate().isNotEmpty) {
      final p = tester.getCenter(hint.first);
      await tester.dragFrom(p - const Offset(70, 0), const Offset(90, 24));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.dragFrom(p + const Offset(-20, 24), const Offset(80, -30));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // 로그아웃 — 어느 화면에서든 셸로 복귀 후 더보기→로그아웃까지.
  // (drive 재실행 시 이전 세션 토큰이 남아 자동 로그인될 수 있어 필요.)
  Future<void> logout(WidgetTester tester) async {
    // 푸시된 라우트 pop (ko 로케일: BackButton 직접 탭).
    for (var i = 0; i < 5; i++) {
      final bb = find.byType(BackButton);
      if (bb.evaluate().isEmpty) break;
      await tester.tap(bb.first);
      await tester.pump(const Duration(milliseconds: 700));
    }
    // 더보기 탭 → 관리 화면.
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

  testWidgets('P2b 표준근로계약서 E2E', (tester) async {
    // 재실행 누적을 피하기 위해 근무장소를 실행마다 유일하게(계약 식별용).
    final wp = '판교현장-${DateTime.now().millisecondsSinceEpoch % 100000}';

    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    // 이전 drive 실행의 잔여 세션(토큰)이 남아 자동 로그인됐다면 먼저 로그아웃.
    final atLogin = await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 6));
    if (!atLogin) {
      await logout(tester);
    }

    // ══════════ Phase A: 사업장(계약사장) ══════════
    await login(tester, '01033330001', '계약사장');

    // 더보기 → 사업장 홈
    await goMore(tester);
    // 사업장 홈(보유 시) 또는 사업장 모드 타일 — 렌더될 때까지 대기 후 탭.
    final bizTile = await pumpUntil(tester, find.text('사업장 홈'),
            timeout: const Duration(seconds: 6))
        ? find.text('사업장 홈')
        : find.text('사업장 모드');
    await pumpUntil(tester, bizTile, timeout: const Duration(seconds: 6));
    await tester.ensureVisible(bizTile);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(bizTile.first);
    await tester.pump(const Duration(seconds: 2));
    // 사업장 홈 메뉴 → 표준근로계약서(사업장 목록 로드까지 넉넉히 대기).
    final onBiz = await pumpUntil(tester, find.text('표준근로계약서'),
        timeout: const Duration(seconds: 25));
    expect(onBiz, isTrue, reason: '사업장 홈 메뉴에 표준근로계약서');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('표준근로계약서').last);
    // 계약서 목록 → 작성
    final onList = await pumpUntil(tester, find.text('계약서 작성'),
        timeout: const Duration(seconds: 10));
    expect(onList, isTrue, reason: '계약서 목록 화면');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('계약서 작성').first);
    await pumpUntil(tester, find.text('전화로 찾기'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 400));

    // 작업자 = 전화로 찾기 → 박근로 연결
    await tester.tap(find.text('전화로 찾기'));
    await pumpUntil(tester, byHint('작업자 전화번호'));
    await tester.enterText(byHint('작업자 전화번호'), '01033330002');
    await tester.pump(const Duration(milliseconds: 300));
    await unfocus(tester);
    await tester.tap(find.byIcon(Icons.search_rounded));
    final found = await pumpUntil(tester, find.textContaining('박*'),
        timeout: const Duration(seconds: 10));
    expect(found, isTrue, reason: '전화검색 결과(동의 작업자) 노출');
    await tester.tap(find.textContaining('박*').first);
    await tester.pump(const Duration(milliseconds: 400));

    // 표준 필드 입력
    await tester.enterText(byHint('예) 강남 A현장'), wp);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(byHint('예) 철근 조립'), '철근 조립');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(byHint('금액'), '180000');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(byHint('예) 매월 25일'), '매월 25일');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.enterText(byHint('예) 계좌이체'), '계좌이체');
    await tester.pump(const Duration(milliseconds: 150));
    await unfocus(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'contract-01-form');

    // 저장
    await tester.ensureVisible(find.text('계약서 만들기'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('계약서 만들기'));
    final created = await pumpUntil(tester, find.text(wp),
        timeout: const Duration(seconds: 15));
    expect(created, isTrue, reason: '계약서 생성 후 목록에 이번 계약($wp)');
    // 저장 후 목록 새로고침(invalidate → 로딩)으로 잠시 사라질 수 있어 재확인.
    await tester.pump(const Duration(seconds: 2));
    await pumpUntil(tester, find.text(wp), timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(milliseconds: 500));

    // 상세 → 내 서명(사업주)
    await tester.tap(find.text(wp).first);
    final onDetail = await pumpUntil(tester, find.text('내 서명 (사업주)'),
        timeout: const Duration(seconds: 12));
    expect(onDetail, isTrue, reason: '계약서 상세 + 사업주 서명 영역');
    // 서명 패드·버튼을 뷰포트로 스크롤.
    await tester.ensureVisible(find.text('서명하기'));
    await tester.pump(const Duration(milliseconds: 500));
    // 생성 스낵바('계약서를 만들었어요')가 서명 버튼을 가리므로 사라질 때까지 대기.
    await waitSnackGone(tester, '계약서를 만들었어요');
    await drawSignature(tester);
    await tester.ensureVisible(find.text('서명하기'));
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'contract-02-employer-signing');
    await tester.tap(find.widgetWithText(FilledButton, '서명하기').hitTestable());
    // 서명 후 전송 버튼 등장
    final signed = await pumpUntil(tester, find.text('작업자에게 전송'),
        timeout: const Duration(seconds: 15));
    expect(signed, isTrue, reason: '사업주 서명 완료 → 전송 버튼');
    // 서명 스낵바('서명을 완료했어요')가 전송 버튼을 가리므로 사라질 때까지 대기.
    await waitSnackGone(tester, '서명을 완료했어요');

    // 전송
    await tester.ensureVisible(find.text('작업자에게 전송'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(FilledButton, '작업자에게 전송').hitTestable());
    await tester.pump(const Duration(seconds: 3));
    final sent = await pumpUntil(tester, find.text('작업자 서명 대기 중'),
        timeout: const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'contract-03-sent');
    expect(sent, isTrue, reason: '전송됨 → 작업자 서명 대기');

    // ══════════ 로그아웃 → Phase B: 작업자(박근로) ══════════
    await logout(tester);

    // 작업자 로그인
    await login(tester, '01033330002', '박근로');

    // 더보기 → 내 계약서
    await goMore(tester);
    final onMoreW = await pumpUntil(tester, find.text('내 계약서'),
        timeout: const Duration(seconds: 8));
    expect(onMoreW, isTrue, reason: '더보기 관리 섹션에 내 계약서 타일');
    await tester.tap(find.text('내 계약서').last);
    final onMy = await pumpUntil(tester, find.text(wp),
        timeout: const Duration(seconds: 12));
    expect(onMy, isTrue, reason: '내 계약서 목록에 받은 계약서($wp)');
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(wp).first);

    // 받은 계약서 상세 → 근로자 서명
    final onRecv = await pumpUntil(tester, find.text('내 서명 (근로자)'),
        timeout: const Duration(seconds: 12));
    expect(onRecv, isTrue, reason: '받은 계약서 상세 + 근로자 서명 영역');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'contract-04-worker-detail');
    await tester.ensureVisible(find.text('서명하기'));
    await tester.pump(const Duration(milliseconds: 500));
    await drawSignature(tester);
    await tester.ensureVisible(find.text('서명하기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(FilledButton, '서명하기').hitTestable());
    final done = await pumpUntil(tester, find.text('이미 서명한 계약서예요'),
        timeout: const Duration(seconds: 15));
    expect(done, isTrue, reason: '작업자 서명 완료 → SIGNED');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'contract-05-worker-signed');
  });
}
