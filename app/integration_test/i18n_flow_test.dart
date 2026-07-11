import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/main.dart';

/// P1 다국어 통합 시나리오 (실 백엔드 3040 / 임시 pg 5436):
///  설정(더보기)에서 언어 전환(베트남어→러시아어→네팔어) 후
///  홈/확인서 작성 폼/장부 렌더 스크린샷 캡처 + 베트남어 상태로 확인서 저장.
/// 파인더 문자열은 lookupAppLocalizations 로 언어별 사전에서 직접 조회한다.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  bool converted = false;

  final ko = lookupAppLocalizations(const Locale('ko'));
  final vi = lookupAppLocalizations(const Locale('vi'));
  final ru = lookupAppLocalizations(const Locale('ru'));
  final ne = lookupAppLocalizations(const Locale('ne'));

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

  // 더보기 → 언어 타일 → 자국어 이름 탭.
  Future<void> switchLanguage(WidgetTester tester, AppLocalizations current,
      String nativeName, AppLocalizations next) async {
    await tester.tap(find.text(current.navMore).last);
    await pumpUntil(tester, find.text(current.language));
    await tester.ensureVisible(find.text(current.language));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(current.language));
    // 시트에서 언어 선택(시트 목록의 마지막 매치).
    final row = await pumpUntil(tester, find.text(nativeName));
    expect(row, isTrue, reason: '언어 시트에 $nativeName 노출');
    await tester.tap(find.text(nativeName).last);
    // 전환 완료 = 더보기 제목이 새 언어로 렌더.
    final done = await pumpUntil(tester, find.text(next.moreTitle));
    expect(done, isTrue, reason: '언어 전환 후 더보기 제목: ${next.moreTitle}');
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('다국어 전환·렌더·베트남어 확인서 저장 E2E', (tester) async {
    await initializeDateFormatting();
    await tester.pumpWidget(const ProviderScopeApp());
    await tester.pump(const Duration(seconds: 1));

    // ── 로그인 (시드 사용자 01011110010, 온보딩 완료 상태) ──
    final onLogin = await pumpUntil(tester, find.text(ko.authRequestCode),
        timeout: const Duration(seconds: 8));
    if (onLogin) {
      await tester.enterText(find.byType(TextField).first, '01011110010');
      await tester.pump(const Duration(milliseconds: 400));
      await unfocus(tester);
      await tester.tap(find.text(ko.authRequestCode));
      final ready = await pumpUntil(tester, find.text(ko.authVerifyStart));
      expect(ready, isTrue, reason: '인증코드 요청 후 버튼 등장');
      await unfocus(tester);
      await tester.tap(find.text(ko.authVerifyStart));
    }
    final home = await pumpUntil(tester, find.text(ko.navMore),
        timeout: const Duration(seconds: 15));
    expect(home, isTrue, reason: '홈(메인쉘) 진입');
    await pumpUntil(tester, find.text(ko.homeMonthSummary));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-01-home-ko');

    // ── 베트남어 전환 ──
    await switchLanguage(tester, ko, 'Tiếng Việt', vi);
    await tester.tap(find.text(vi.navHome).last);
    final homeVi = await pumpUntil(tester, find.text(vi.homeMonthSummary));
    expect(homeVi, isTrue, reason: '홈이 베트남어로 렌더');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-02-home-vi');

    // ── 베트남어 확인서 작성 + 저장 ──
    await tester.tap(find.byIcon(Icons.add_rounded));
    final formVi = await pumpUntil(tester, find.text(vi.confFormTitle));
    expect(formVi, isTrue, reason: '작성 폼이 베트남어로 렌더');
    await tester.pump(const Duration(milliseconds: 600));

    // 연결 사업장 선택(키보드 뜨기 전).
    await tester.tap(find.text(vi.confLinkedBiz));
    await pumpUntil(tester, find.text(vi.confSelectBiz));
    await tester.tap(find.text(vi.confSelectBiz));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('대성건설').last); // 데이터(사업장명)는 원문 유지
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(byHint(vi.confSiteHint), '서초 리모델링 현장');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint(vi.confWorkHint), 'Sơn nội thất tầng 3');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(byHint('0'), '230000'); // 일당 단가
    await tester.pump(const Duration(milliseconds: 400));
    await unfocus(tester);
    // 미리보기 합계(₩230.000, vi 로케일 점 천단위) 확인.
    final preview = await pumpUntil(tester, find.textContaining('₩230.000'));
    expect(preview, isTrue, reason: 'vi 로케일 금액(₩230.000) 미리보기');
    await shot(tester, 'i18n-03-form-vi');

    await tester.tap(find.text(vi.confSaveSend));
    final saved = await pumpUntil(tester, find.text(vi.homeMonthSummary),
        timeout: const Duration(seconds: 15));
    expect(saved, isTrue, reason: '베트남어 상태로 확인서 저장 → 홈 복귀');
    await tester.pump(const Duration(seconds: 1));

    // ── 베트남어 장부 ──
    await tester.tap(find.text(vi.navLedger).last);
    final ledgerVi = await pumpUntil(tester, find.text(vi.ledgerByCompany));
    expect(ledgerVi, isTrue, reason: '장부가 베트남어로 렌더');
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-04-ledger-vi');

    // ── 러시아어 전환: 홈/작성 폼/장부 ──
    await switchLanguage(tester, vi, 'Русский', ru);
    await tester.tap(find.text(ru.navHome).last);
    await pumpUntil(tester, find.text(ru.homeMonthSummary));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-05-home-ru');

    await tester.tap(find.byIcon(Icons.add_rounded));
    final formRu = await pumpUntil(tester, find.text(ru.confFormTitle));
    expect(formRu, isTrue, reason: '작성 폼이 러시아어로 렌더');
    await tester.pump(const Duration(milliseconds: 800));
    await shot(tester, 'i18n-06-form-ru');
    await tester.tap(find.byIcon(Icons.close_rounded)); // 폼 닫기(커스텀 leading)
    await pumpUntil(tester, find.text(ru.navMore));

    await tester.tap(find.text(ru.navLedger).last);
    await pumpUntil(tester, find.text(ru.ledgerByCompany));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-07-ledger-ru');

    // ── 네팔어 전환: 홈/작성 폼/장부 ──
    await switchLanguage(tester, ru, 'नेपाली', ne);
    await tester.tap(find.text(ne.navHome).last);
    await pumpUntil(tester, find.text(ne.homeMonthSummary));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-08-home-ne');

    await tester.tap(find.byIcon(Icons.add_rounded));
    final formNe = await pumpUntil(tester, find.text(ne.confFormTitle));
    expect(formNe, isTrue, reason: '작성 폼이 네팔어로 렌더');
    await tester.pump(const Duration(milliseconds: 800));
    await shot(tester, 'i18n-09-form-ne');
    await tester.tap(find.byIcon(Icons.close_rounded));
    await pumpUntil(tester, find.text(ne.navMore));

    await tester.tap(find.text(ne.navLedger).last);
    await pumpUntil(tester, find.text(ne.ledgerByCompany));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 'i18n-10-ledger-ne');

    // ── 한국어 복귀(다음 실행 대비) ──
    await switchLanguage(tester, ne, '한국어', ko);
  });
}
