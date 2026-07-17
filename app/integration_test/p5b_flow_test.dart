import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';

/// P5b 사업장 3종 화면 통합 시나리오 (실 백엔드 3060 / 임시 pg 5438):
///   로그인(사장님 01055550501) → 더보기 → 사업장 홈 →
///   ① 최상단 출역 현황판 카드(전체4/출근2/완료1/미출근2) → 상세(현장·상태·컨디션)
///   ② 현장별 인건비(총계 144만·현장 3·펼치기 팀 배지)
///   ③ 지급명세서(3.3% ↔ 일용 토글·안내 노트·마감)
///
/// 사전 시드(node seed): 대한건설 — 오늘 jobs 4건(예정/수락/시작/완료),
///   확인서 4건(역삼 60만+15만·판교 27만·반포 팀 42만), 역삼 2건만 지급(75만...
///   김*수 87만 지급: 역삼60 + 판교27 은 pay 시점 outstanding 포함 여부에 따름 — 시드 로그 기준).
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

  Future<void> openBizHome(WidgetTester tester) async {
    await tester.tap(find.text('더보기').first);
    await pumpUntil(tester, find.text('관리'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(milliseconds: 400));
    final sc = find.byType(Scrollable);
    if (find.text('사업장 홈').evaluate().isEmpty && sc.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(find.text('사업장 홈'), 250,
          scrollable: sc.first, maxScrolls: 20);
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('사업장 홈').last);
    final ok = await pumpUntil(tester, find.text('오늘 출역 현황'),
        timeout: const Duration(seconds: 20));
    expect(ok, isTrue, reason: '사업장 홈 + 출역 현황판 카드');
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('P5b 사업장 3종 E2E', (tester) async {
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 3));

    await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 8));
    await login(tester, '01055550501', '사장님');

    // ① 사업장 홈 — 최상단 출역 현황판 카드 (시드: 전체4/출근2/완료1/미출근2)
    await openBizHome(tester);
    expect(find.text('4'), findsWidgets, reason: '전체 4');
    await shot(tester, 'p5b_01_bizhome_attendance_card');

    // 출역 상세 — 현장 그룹·상태 배지·시작 시각·컨디션
    await tester.tap(find.text('오늘 출역 현황').first);
    final onDetail = await pumpUntil(tester, find.text('오늘현장A'),
        timeout: const Duration(seconds: 15));
    expect(onDetail, isTrue, reason: '출역 상세 진입');
    expect(find.text('오늘현장B'), findsWidgets);
    expect(find.text('예정'), findsWidgets);
    expect(find.text('수락'), findsWidgets);
    expect(find.text('시작'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'p5b_02_attendance_detail');
    await tester.tap(find.byType(BackButton).first);
    await tester.pump(const Duration(milliseconds: 600));

    // ② 현장별 인건비 — 총계 헤더·현장 카드·펼치기(팀 배지)
    final sc = find.byType(Scrollable);
    await tester.scrollUntilVisible(find.text('현장별 인건비'), 250,
        scrollable: sc.first, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('현장별 인건비').last);
    final onCosts = await pumpUntil(tester, find.text('전체 총계'),
        timeout: const Duration(seconds: 20));
    expect(onCosts, isTrue, reason: '현장별 인건비 총계 헤더');
    expect(find.text('1,440,000원'), findsOneWidget, reason: '총계 144만');
    expect(find.text('역삼 현장'), findsOneWidget);
    // 반포(팀) 카드 펼치기 → 팀 배지·팀원 2명
    final costsScroll = find.byType(Scrollable);
    await tester.scrollUntilVisible(find.text('반포 현장'), 200,
        scrollable: costsScroll.first, maxScrolls: 10);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('반포 현장'));
    await pumpUntil(tester, find.textContaining('팀원 2명'),
        timeout: const Duration(seconds: 6));
    expect(find.textContaining('팀원 2명'), findsOneWidget, reason: '팀 인원수');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'p5b_03_sitecosts');
    // PDF 버튼 존재 확인(공유 시트는 시뮬 자동화 제외)
    await tester.scrollUntilVisible(find.text('PDF 저장·공유'), 250,
        scrollable: costsScroll.first, maxScrolls: 20);
    expect(find.text('PDF 저장·공유'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'p5b_04_sitecosts_pdf_button');
    await tester.tap(find.byType(BackButton).first);
    await tester.pump(const Duration(milliseconds: 600));

    // ③ 지급명세서 — 3.3% 기본 → 일용 토글 → 안내 노트 → 마감
    final sc2 = find.byType(Scrollable);
    await tester.scrollUntilVisible(find.text('지급명세서(월 마감)'), 250,
        scrollable: sc2.first, maxScrolls: 20);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('지급명세서(월 마감)').last);
    final onWage = await pumpUntil(tester, find.text('전체 지급 총계'),
        timeout: const Duration(seconds: 20));
    expect(onWage, isTrue, reason: '지급명세서 총계 헤더');
    // 시드: 김*수 870,000(3.3% 소득세 26,100) + 이*호 150,000(4,500)
    expect(find.text('870,000원'), findsWidgets, reason: '김*수 지급액');
    expect(find.text('26,100원'), findsWidgets, reason: '3.3% 소득세');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'p5b_05_wage_33');

    // 일용근로 토글 → 세액 변경(김*수 일용 소득세 4,050)
    await tester.tap(find.text('일용근로'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('4,050원'), findsWidgets, reason: '일용 소득세');
    await shot(tester, 'p5b_06_wage_daily');

    // 안내 노트(세무사 확인 권장·홈택스 직접 입력) 필수 표시
    final wageScroll = find.byType(Scrollable);
    await tester.scrollUntilVisible(find.textContaining('홈택스').first, 250,
        scrollable: wageScroll.first, maxScrolls: 20);
    expect(find.textContaining('전문가'), findsWidgets, reason: '세무사 확인 권장');
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'p5b_07_wage_notes');

    // 월 마감 → marked 배지
    await tester.scrollUntilVisible(find.text('이 달 마감'), 250,
        scrollable: wageScroll.first, maxScrolls: 10);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('이 달 마감'));
    final marked = await pumpUntil(tester, find.text('마감됨'),
        timeout: const Duration(seconds: 15));
    expect(marked, isTrue, reason: '월 마감 후 marked 배지');
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'p5b_08_wage_marked');

    await tester.pump(const Duration(seconds: 1));
  });
}
