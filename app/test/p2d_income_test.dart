import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/models/models.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/providers/data.dart';
import 'package:workon/features/ledger/income_report_screen.dart';

Widget _app(Widget home,
        {Locale locale = const Locale('ko'),
        List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
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

Map<String, dynamic> _reportDto() => {
      'range': {'from': '2026-01', 'to': '2026-12', 'year': 2026},
      'monthly': [
        for (var m = 1; m <= 12; m++)
          {
            'month': '2026-${m.toString().padLeft(2, '0')}',
            'billed': m == 3
                ? 180000
                : m == 6
                    ? 420000
                    : 0,
            'paid': m == 3 ? 180000 : 0,
            'outstanding': m == 6 ? 420000 : 0,
            'daysWorked': (m == 3 || m == 6) ? 1 : 0,
            'gongsu': m == 6 ? 2.5 : 0,
          }
      ],
      'companies': [
        {
          'companyName': '삼성물산',
          'businessId': 'b1',
          'count': 2,
          'total': 600000,
          'paid': 180000,
          'outstanding': 420000,
        },
      ],
      'totals': {
        'totalBilled': 600000,
        'totalPaid': 180000,
        'totalOutstanding': 420000,
        'totalDays': 2,
        'totalGongsu': 2.5,
        'entryCount': 2,
        'teamPayout': 420000,
        'netBilled': 180000,
      },
      'taxNote': {
        'period': '2026년',
        'lines': ['종합소득세는 매년 5월...']
      },
    };

void main() {
  test('IncomeReport.fromJson 파싱 (월별/상대별/총계/팀 지급분)', () {
    final r = IncomeReport.fromJson(_reportDto());
    expect(r.year, 2026);
    expect(r.from, '2026-01');
    expect(r.monthly.length, 12);
    expect(r.monthly[5].billed, 420000); // 6월
    expect(r.monthly[5].gongsu, 2.5);
    expect(r.companies.length, 1);
    expect(r.companies[0].companyName, '삼성물산');
    expect(r.companies[0].count, 2);
    expect(r.totalBilled, 600000);
    expect(r.totalPaid, 180000);
    expect(r.totalOutstanding, 420000);
    expect(r.totalDays, 2);
    expect(r.totalGongsu, 2.5);
    expect(r.teamPayout, 420000);
    expect(r.netBilled, 180000);
  });

  testWidgets('소득 리포트 화면 — 총계·팀 지급분·상대별·종소세 렌더', (tester) async {
    await tester.pumpWidget(_app(
      const IncomeReportScreen(),
      overrides: [
        incomeReportProvider.overrideWith(
            (ref, year) async => IncomeReport.fromJson(_reportDto())),
      ],
    ));
    await tester.pumpAndSettle();

    // 총계 카드
    expect(find.text('총 청구액'), findsOneWidget);
    expect(find.text('600,000원'), findsWidgets);
    expect(find.text('총 입금'), findsOneWidget);
    expect(find.text('총 미수'), findsOneWidget);
    // 팀 지급분 / 순소득
    expect(find.text('팀 지급분'), findsOneWidget);
    expect(find.text('순소득 참고'), findsOneWidget);
    // 섹션
    expect(find.text('월별 추이'), findsOneWidget);
    expect(find.text('상대별 합계'), findsOneWidget);
    expect(find.text('삼성물산'), findsOneWidget);
    // 종소세 안내
    expect(find.text('종합소득세 안내'), findsOneWidget);
    // 연도
    expect(find.text('2026년'), findsOneWidget);
    // PDF 버튼
    expect(find.text('PDF 저장·공유'), findsOneWidget);
  });

  testWidgets('빈 리포트 — 안내 문구', (tester) async {
    final empty = {
      'range': {'from': '2026-01', 'to': '2026-12', 'year': 2026},
      'monthly': [],
      'companies': [],
      'totals': {
        'totalBilled': 0,
        'totalPaid': 0,
        'totalOutstanding': 0,
        'totalDays': 0,
        'totalGongsu': 0,
        'entryCount': 0,
        'teamPayout': 0,
        'netBilled': 0,
      },
      'taxNote': {'period': '2026년', 'lines': []},
    };
    await tester.pumpWidget(_app(
      const IncomeReportScreen(),
      overrides: [
        incomeReportProvider
            .overrideWith((ref, year) async => IncomeReport.fromJson(empty)),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('아직 소득 기록이 없어요'), findsOneWidget);
  });
}
