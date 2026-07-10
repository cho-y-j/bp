import 'package:flutter/material.dart';
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
    await tester.pump(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
  }

  // finder 가 나타날 때까지 최대 [timeout] 동안 펌프.
  Future<bool> pumpUntil(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  testWidgets('작업온 코어 플로우 E2E (실 백엔드)', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 1));

    // 이미 로그인 상태면 홈으로, 아니면 로그인 진행
    final onLogin = find.text('인증번호 받기').evaluate().isNotEmpty ||
        await pumpUntil(tester, find.text('인증번호 받기'),
            timeout: const Duration(seconds: 6));

    if (onLogin) {
      await tester.enterText(find.byType(TextField).first, '01011112222');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      // devCode 자동 채움 + '인증하고 시작하기' 등장 대기
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼이 나타나야 함');
      await tester.tap(find.text('인증하고 시작하기'));
    }

    // 온보딩(신규)인 경우 이름 입력
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 4))) {
      await tester.enterText(find.byType(TextField).first, '김기사');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('시작하기'));
    }

    // 홈 로드 대기 (탭바 '더보기' 존재 = 메인쉘 진입)
    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 15));
    expect(home, isTrue, reason: '홈(메인쉘)에 진입해야 함');
    // 데이터 로드 대기 (이번 달 요약)
    await pumpUntil(tester, find.text('이번 달 요약'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '01-home');

    // 캘린더 탭 → 월간 그리드
    await tester.tap(find.text('캘린더'));
    await pumpUntil(tester, find.text('주'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '02-calendar-grid');

    // 주간 리스트 토글
    await tester.tap(find.text('주'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '03-calendar-week');
    // 월간으로 복귀
    await tester.tap(find.text('월'));
    await tester.pump(const Duration(milliseconds: 500));

    // 장부 탭
    await tester.tap(find.text('장부').first);
    await pumpUntil(tester, find.text('회사별'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '04-ledger');

    // 회사 상세 (대성건설)
    if (find.text('대성건설').evaluate().isNotEmpty) {
      await tester.tap(find.text('대성건설').first);
      await pumpUntil(tester, find.text('작업 내역'));
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, '05-company-detail');
      await tester.pageBack();
      await tester.pump(const Duration(seconds: 1));
    }

    // 확인서 작성 (수기 상대)
    await tester.tap(find.byIcon(Icons.add_rounded));
    await pumpUntil(tester, find.text('작업확인서 작성'));
    await tester.pump(const Duration(milliseconds: 600));

    Finder byHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint);

    await tester.enterText(byHint('예) 래미안 원펜타스 3공구'), '반포자이 리모델링');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('회사/현장 담당 상호'), '대한건설');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('담당자/연락처 (선택)'), '홍길동 소장');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('작업한 내용을 적어주세요'), '지하 굴착 및 잔토 처리');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('0'), '480000'); // 일당
    await tester.pump(const Duration(milliseconds: 500));
    // 계산 미리보기 갱신 확인
    await pumpUntil(tester, find.text('받을 금액'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '06-form-manual');

    // 저장하고 보내기 → 실제 생성/전송 (수기 상대는 공유 시트가 뜨므로 pumpAndSettle 금지)
    await tester.tap(find.text('저장하고 보내기'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await shot(tester, '07-after-save');
  });
}
