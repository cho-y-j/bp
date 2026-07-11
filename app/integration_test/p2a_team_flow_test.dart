import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P2a 팀(반장) 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///  ① 내 팀 화면에서 팀 생성
///  ② 팀원 2명 추가 — 1명 전화검색 연결(이철수, 동의자) + 1명 수기(김수기)
///  ③ 확인서 작성: 팀 확인서 토글 + 팀원 공수 + 실시간 팀 합계
///  ④ 저장(연결 사업장 → 링크 전송, 공유시트 없음)
///  ⑤ 장부에 팀 확인서 반영
///
/// 사전 시드: 이철수(01077778888, phoneSearchConsent=true) 가 존재해야 함.
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

  testWidgets('P2a 팀 확인서 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    // ── 로그인 (기존 시드 반장 01011112222 = 김기사, 대성건설 연결됨) ──
    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 12));
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
        timeout: const Duration(seconds: 30));
    expect(home, isTrue, reason: '홈(메인쉘) 진입');
    await tester.pump(const Duration(seconds: 1));

    // ── ① 내 팀 화면 진입 + 팀 생성 ──
    await tester.tap(find.text('더보기'));
    await pumpUntil(tester, find.text('내 팀'));
    await tester.tap(find.text('내 팀').last);
    final onTeam = await pumpUntil(tester, find.text('팀 만들기'),
        timeout: const Duration(seconds: 10));
    expect(onTeam, isTrue, reason: '내 팀 화면 진입');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('팀 만들기').first);
    await pumpUntil(tester, byHint('팀 이름 (예: 박반장 A팀)'));
    await tester.enterText(byHint('팀 이름 (예: 박반장 A팀)'), '통합테스트팀');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('저장'));
    final teamMade = await pumpUntil(tester, find.text('통합테스트팀'),
        timeout: const Duration(seconds: 10));
    expect(teamMade, isTrue, reason: '팀 생성됨');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p2a-01-team-created');

    // ── ② 팀원 추가: 전화 검색 연결(이철수) ──
    await tester.tap(find.text('팀원 추가').first);
    await pumpUntil(tester, byHint('팀원 전화번호'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(byHint('팀원 전화번호'), '01077778888');
    await tester.pump(const Duration(milliseconds: 300));
    await unfocus(tester);
    await tester.tap(find.byIcon(Icons.search_rounded));
    final found = await pumpUntil(tester, find.textContaining('이*'),
        timeout: const Duration(seconds: 10));
    expect(found, isTrue, reason: '전화검색 결과(동의자) 노출');
    await tester.pump(const Duration(milliseconds: 400));
    // 기본단가 입력 후 결과 탭 → 연결 추가
    if (byHint('기본 단가 (공수 1일)').evaluate().isNotEmpty) {
      await tester.enterText(byHint('기본 단가 (공수 1일)'), '150000');
      await tester.pump(const Duration(milliseconds: 300));
      await unfocus(tester);
    }
    await tester.tap(find.textContaining('이*').first);
    final added1 = await pumpUntil(tester, find.text('이철수'),
        timeout: const Duration(seconds: 10));
    expect(added1, isTrue, reason: '전화검색 팀원 연결됨');
    await tester.pump(const Duration(milliseconds: 600));

    // ── 팀원 추가: 수기(김수기) ──
    await tester.tap(find.text('팀원 추가').first);
    await pumpUntil(tester, find.text('직접 입력'));
    await tester.tap(find.text('직접 입력'));
    await pumpUntil(tester, byHint('이름'));
    await tester.enterText(byHint('이름'), '김수기');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('기본 단가 (공수 1일)'), '150000');
    await tester.pump(const Duration(milliseconds: 200));
    await unfocus(tester);
    await tester.tap(find.widgetWithText(FilledButton, '팀원 추가'));
    final added2 = await pumpUntil(tester, find.text('김수기'),
        timeout: const Duration(seconds: 10));
    expect(added2, isTrue, reason: '수기 팀원 추가됨');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p2a-02-members-added');

    // ── ③ 확인서 작성 (팀 확인서) ──
    // TeamScreen 팝(ko 로케일이라 pageBack 툴팁 'Back' 이 없음 → BackButton 직접 탭) → More 탭
    await tester.tap(find.byType(BackButton).first);
    await pumpUntil(tester, find.text('관리'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('홈').first);
    await pumpUntil(tester, find.text('이번 달 요약'));
    await tester.pump(const Duration(milliseconds: 400));
    // 하단 내비 [+] (온스테이지만) — hitTestable 로 오프스테이지 탭의 add 아이콘 제외.
    await tester.tap(find.byIcon(Icons.add_rounded).hitTestable());
    await pumpUntil(tester, find.text('작업확인서 작성'));
    await tester.pump(const Duration(milliseconds: 600));

    // 연결 사업장(대성건설) 선택 → 저장 시 링크 전송(공유시트 없음)
    final hasChip = await pumpUntil(tester, find.text('연결 사업장'),
        timeout: const Duration(seconds: 10));
    expect(hasChip, isTrue, reason: '연결 사업장 칩 노출');
    await tester.tap(find.text('연결 사업장'));
    await pumpUntil(tester, find.text('연결 사업장 선택'));
    await tester.tap(find.text('연결 사업장 선택'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('대성건설').last);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(byHint('예) 래미안 원펜타스 3공구'), '팀 현장 A');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('작업한 내용을 적어주세요'), '팀 철근 작업');
    await tester.pump(const Duration(milliseconds: 200));
    await unfocus(tester);

    // 팀 확인서 토글 ON
    await tester.ensureVisible(find.text('팀 확인서'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 500));

    // 팀 선택
    await tester.ensureVisible(find.text('팀을 선택하세요'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('팀을 선택하세요'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.textContaining('통합테스트팀').last);
    await tester.pump(const Duration(milliseconds: 600));

    // 실시간 팀 합계 표시 — 팀원 2명 각 150,000 × 1공수 = 300,000
    await tester.ensureVisible(find.text('팀 합계'));
    await tester.pump(const Duration(milliseconds: 400));
    final showsTotal = await pumpUntil(tester, find.textContaining('300,000'),
        timeout: const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p2a-03-team-form');
    expect(showsTotal, isTrue, reason: '팀 합계 실시간 계산(2명 × 150,000 × 1공수 = 300,000)');

    // ── ④ 저장 ──
    await tester.tap(find.text('저장하고 보내기'));
    final backHome = await pumpUntil(tester, find.text('이번 달 요약'),
        timeout: const Duration(seconds: 15));
    expect(backHome, isTrue, reason: '저장 후 홈 복귀');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p2a-04-saved');

    // ── ⑤ 장부에 팀 확인서 반영 ──
    await unfocus(tester);
    await tester.tap(find.text('장부').first);
    final ledger = await pumpUntil(tester, find.text('대성건설'),
        timeout: const Duration(seconds: 10));
    expect(ledger, isTrue, reason: '장부 회사별에 대성건설(팀 확인서 포함)');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'p2a-05-ledger');
  });
}
