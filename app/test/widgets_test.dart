import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/theme/app_colors.dart';
import 'package:workon/widgets/common.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('MoneyLine 미수는 빨강+금액, 입금은 초록+금액', (tester) async {
    await tester.pumpWidget(_host(const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MoneyLine(4350000, received: false),
        MoneyLine(2800000, received: true),
      ],
    )));
    expect(find.text('4,350,000'), findsOneWidget);
    expect(find.text('2,800,000'), findsOneWidget);
    // 미수 텍스트 색이 receivable 인지 확인
    final rcv = tester.widget<Text>(find.text('4,350,000'));
    expect(rcv.style!.color, AppColors.light.receivable);
    final dep = tester.widget<Text>(find.text('2,800,000'));
    expect(dep.style!.color, AppColors.light.deposited);
  });

  testWidgets('DdayBadge 는 상태별 라벨을 그린다', (tester) async {
    await tester.pumpWidget(_host(const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DdayBadge(dday: 3, status: 'PENDING', label: '수금 D-3'),
        DdayBadge(dday: -6, status: 'OVERDUE', label: '기한 지남'),
        DdayBadge(dday: null, status: 'PAID', label: '입금완료'),
      ],
    )));
    expect(find.text('수금 D-3'), findsOneWidget);
    expect(find.text('기한 지남'), findsOneWidget);
    expect(find.text('입금완료'), findsOneWidget);
  });

  testWidgets('PaperCard 는 스탬프 텍스트를 표시한다', (tester) async {
    await tester.pumpWidget(_host(
      const PaperCard(stamp: '작 업 확 인 서', child: Text('본문')),
    ));
    expect(find.text('작 업 확 인 서'), findsOneWidget);
    expect(find.text('본문'), findsOneWidget);
  });
}
