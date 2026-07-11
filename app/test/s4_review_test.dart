import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/format.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/models/models.dart';
import 'package:workon/providers/data.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/widgets/common.dart';
import 'package:workon/features/ledger/ledger_screen.dart';
import 'package:workon/features/confirmation/confirmation_form_screen.dart';

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

void main() {
  group('장부 빈 상태 CTA', () {
    testWidgets('기록이 없으면 안내 문구 + 확인서 작성 버튼을 보여준다', (tester) async {
      final now = DateTime.now();
      final mp = monthParam(DateTime(now.year, now.month));
      await tester.pumpWidget(_app(const LedgerScreen(), [
        ledgerByCompanyProvider(mp).overrideWith((ref) async => <LedgerCompany>[]),
        ledgerSummaryProvider(mp)
            .overrideWith((ref) async => LedgerSummary(mp, 0, 0, 0, 0, 0, 0)),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('이 달의 장부 기록이 없어요'), findsOneWidget);
      expect(find.text('확인서를 작성하면 장부가 자동으로 채워져요.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '확인서 작성하기'), findsOneWidget);
    });
  });

  group('공통 ErrorRetry 위젯', () {
    testWidgets('친화 메시지 + "다시 시도" 버튼을 그리고 onRetry 를 호출한다', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_app(
        Scaffold(body: Center(child: ErrorRetry(onRetry: () => tapped++))),
        const [],
      ));
      expect(find.text('연결에 문제가 있어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      expect(tapped, 1);
    });
  });

  group('확인서 수량(>0) 검증', () {
    Finder byHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint);

    FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
        find.ancestor(
            of: find.text('저장하고 보내기'), matching: find.byType(FilledButton)));

    testWidgets('수량 0 이면 저장 비활성 + 안내, 1 이상이면 활성', (tester) async {
      await tester.pumpWidget(_app(const ConfirmationFormScreen(), [
        connectionsProvider.overrideWith((ref) async => <ConnectionItem>[]),
      ]));
      await tester.pumpAndSettle();

      await tester.enterText(byHint('예) 래미안 원펜타스 3공구'), '현장A');
      await tester.enterText(byHint('작업한 내용을 적어주세요'), '미장');
      await tester.enterText(byHint('회사/현장 담당 상호'), '대성건설');
      await tester.enterText(byHint('0'), '150000'); // 일당
      await tester.pump();

      // 수량 기본값 '1' → 유효, 안내 없음, 버튼 활성.
      expect(find.text('일수를 1 이상 입력해 주세요.'), findsNothing);
      expect(saveButton(tester).onPressed, isNotNull);

      // 수량 0 → 무효, 안내 노출, 버튼 비활성.
      await tester.enterText(byHint('1'), '0');
      await tester.pump();
      expect(find.text('일수를 1 이상 입력해 주세요.'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
    });
  });
}
