import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P1 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///  ① 공수 1.5 × 180,000 → 270,000 작성·저장 → 장부 totalGongsu
///  ③ 세금계산서 데이터(시드된 SIGNED 확인서) → 복사 → 발행 완료 표시 → 제외
///  ② 백엔드 차단 중 저장 → 임시저장 배너 → 복구 후 수동 전송
///
/// ②의 백엔드 차단/복구는 외부 스크립트가 세금계산서 mark(groupCount→0)를
/// 감지해 백엔드를 kill/restart 하도록 조율한다(실제 오프라인 재현).
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

  // 텍스트 필드 포커스 해제(키보드가 탭 대상을 가리는 문제 방지).
  Future<void> unfocus(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);

  testWidgets('P1 공수·세금계산서·오프라인 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 1));

    // ── 로그인 (기존 시드 사용자 01011112222) ──
    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 6));
    if (onLogin) {
      await tester.enterText(find.byType(TextField).first, '01011112222');
      await tester.pump(const Duration(milliseconds: 400));
      await unfocus(tester);
      await tester.tap(find.text('인증번호 받기'));
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼 등장');
      await unfocus(tester);
      await tester.tap(find.text('인증하고 시작하기'));
    }
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 4))) {
      await tester.enterText(find.byType(TextField).first, '김기사');
      await tester.pump(const Duration(milliseconds: 300));
      await unfocus(tester);
      await tester.tap(find.text('시작하기'));
    }
    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 15));
    expect(home, isTrue, reason: '홈(메인쉘) 진입');
    await pumpUntil(tester, find.text('이번 달 요약'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p1-01-home');

    // ── ① 공수 확인서 작성 (연결 사업장 → 링크 전송, 공유시트 없음) ──
    await tester.tap(find.byIcon(Icons.add_rounded));
    await pumpUntil(tester, find.text('작업확인서 작성'));
    await tester.pump(const Duration(milliseconds: 600));

    // 상대(연결 사업장)를 먼저 선택 — 키보드 뜨기 전.
    final hasChip = await pumpUntil(tester, find.text('연결 사업장'),
        timeout: const Duration(seconds: 10));
    expect(hasChip, isTrue, reason: '연결 사업장 칩 노출(연결 존재)');
    await tester.tap(find.text('연결 사업장'));
    await pumpUntil(tester, find.text('연결 사업장 선택'));
    await tester.tap(find.text('연결 사업장 선택'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('대성건설').last);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(byHint('예) 래미안 원펜타스 3공구'), '반포 현장 3공구');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('작업한 내용을 적어주세요'), '철근 배근 작업');
    await tester.pump(const Duration(milliseconds: 200));
    await unfocus(tester);
    // 공수 세그먼트 선택 (스크롤로 보이게 한 뒤 탭)
    await tester.ensureVisible(find.text('공수'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('공수'));
    await tester.pump(const Duration(milliseconds: 400));
    // 공수가 실제 선택됐는지 확인(기본(공수) 라벨 등장)
    final gongsuActive = await pumpUntil(tester, find.text('기본(공수)'),
        timeout: const Duration(seconds: 6));
    expect(gongsuActive, isTrue, reason: '공수 단가유형 선택됨');
    await tester.enterText(byHint('0'), '180000');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(byHint('1'), '1.5');
    await tester.pump(const Duration(milliseconds: 500));
    await unfocus(tester);
    final showsTotal = await pumpUntil(tester, find.textContaining('270,000'));
    expect(showsTotal, isTrue, reason: '공수 1.5×180,000 = 270,000 표시');
    // 공수 라벨(× 1.5공수) 확인
    expect(find.textContaining('1.5공수'), findsWidgets,
        reason: '공수 라벨(1.5공수) 표시');
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'p1-02-gongsu-form');

    await tester.tap(find.text('저장하고 보내기'));
    await pumpUntil(tester, find.text('이번 달 요약'),
        timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));

    // ── 장부에서 공수 확인 ──
    await unfocus(tester);
    await tester.tap(find.text('장부').first);
    await pumpUntil(tester, find.textContaining('공수'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('공수'), findsWidgets, reason: '장부에 공수 표시');
    await shot(tester, 'p1-03-ledger-gongsu');

    // ── ③ 세금계산서 준비 ──
    await tester.tap(find.text('더보기'));
    await pumpUntil(tester, find.text('세금계산서 준비'));
    await tester.tap(find.text('세금계산서 준비'));
    final taxLoaded = await pumpUntil(tester, find.text('발행 완료 표시'),
        timeout: const Duration(seconds: 12));
    expect(taxLoaded, isTrue, reason: '세금계산서 그룹(대성건설) 로드');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p1-04-tax-invoice');

    await tester.tap(find.text('복사').first);
    await pumpUntil(tester, find.textContaining('복사됐어요'));
    await tester.pump(const Duration(milliseconds: 700));
    await shot(tester, 'p1-05-tax-copied');

    // 발행 완료 표시 → 제외 (이 시점 groupCount→0, 외부 스크립트가 백엔드 차단)
    await tester.tap(find.text('발행 완료 표시').first);
    await pumpUntil(tester, find.textContaining('발행 대상 확인서가 없어요'),
        timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p1-06-tax-marked');

    // ── ② 오프라인 임시저장 (백엔드 차단 상태) ──
    await tester.pageBack();
    await pumpUntil(tester, find.text('더보기'));
    await tester.tap(find.text('홈'));
    await pumpUntil(tester, find.text('이번 달 요약'));
    await tester.pump(const Duration(seconds: 4)); // 백엔드 다운 대기

    await tester.tap(find.byIcon(Icons.add_rounded));
    await pumpUntil(tester, find.text('작업확인서 작성'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(byHint('예) 래미안 원펜타스 3공구'), '오프라인 현장');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('회사/현장 담당 상호'), '현장직영');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('작업한 내용을 적어주세요'), '콘크리트 타설');
    await tester.pump(const Duration(milliseconds: 200));
    await unfocus(tester);
    await tester.ensureVisible(find.text('공수'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('공수'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(byHint('0'), '200000');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('1'), '2');
    await tester.pump(const Duration(milliseconds: 400));
    await unfocus(tester);
    await tester.tap(find.text('저장하고 보내기'));
    final banner = await pumpUntil(tester, find.textContaining('전송 대기'),
        timeout: const Duration(seconds: 30));
    expect(banner, isTrue, reason: '오프라인 저장 시 임시저장 배너 노출');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p1-07-offline-banner');

    await tester.tap(find.textContaining('전송 대기'));
    await pumpUntil(tester, find.text('임시저장 초안'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p1-08-drafts');

    // 백엔드 복구까지 대기 후 수동 전송 (최대 4회 재시도)
    var sentOk = false;
    for (var i = 0; i < 4 && !sentOk; i++) {
      await tester.pump(const Duration(seconds: 6));
      if (find.text('지금 모두 전송').evaluate().isNotEmpty) {
        await tester.tap(find.text('지금 모두 전송'));
      }
      sentOk = await pumpUntil(
          tester, find.textContaining('전송 대기 중인 초안이 없어요'),
          timeout: const Duration(seconds: 8));
    }
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p1-09-drafts-sent');
    expect(sentOk, isTrue, reason: '백엔드 복구 후 초안 수동 전송 완료');
  });
}
