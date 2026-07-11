import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/models/models.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/core/tbm_hazards.dart';
import 'package:workon/widgets/tbm_view.dart';

Widget _app(Widget home, {Locale locale = const Locale('ko')}) => ProviderScope(
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

Map<String, dynamic> _dto({int photoCount = 0}) => {
      'id': 't1',
      'businessId': 'b1',
      'businessName': '대성건설',
      'site': '강동 현장 3층',
      'occurredAt': '2026-07-11 08:30',
      'date': '2026-07-11',
      'hazards': [
        {'code': 'FALL_HEIGHT'},
        {'code': 'HEAVY_EQUIP'},
        {'text': '개구부 추락'},
      ],
      'hazardLabelsKo': ['고소작업 추락', '중장비 협착·충돌(굴착기·지게차)', '개구부 추락'],
      'measures': '안전벨트 착용, 유도원 배치',
      'notes': null,
      'photoCount': photoCount,
      'photoUrls': [
        for (int i = 0; i < photoCount; i++) '/api/biz/tbm/t1/photos/$i'
      ],
      'attendeeCount': 2,
      'ackCount': 1,
      'attendees': [
        {'id': 'a1', 'profileId': 'p1', 'linked': true, 'name': '홍길동', 'acked': true, 'ackAt': '2026-07-11 09:00'},
        {'id': 'a2', 'profileId': null, 'linked': false, 'name': '수기참석', 'acked': false, 'ackAt': null},
      ],
      'editable': true,
    };

void main() {
  test('TbmRecord.fromJson 파싱 (hazards/attendees/카운트)', () {
    final r = TbmRecord.fromJson(_dto(photoCount: 2));
    expect(r.site, '강동 현장 3층');
    expect(r.hazards.length, 3);
    expect(r.hazards[0].code, 'FALL_HEIGHT');
    expect(r.hazards[2].text, '개구부 추락');
    expect(r.attendeeCount, 2);
    expect(r.ackCount, 1);
    expect(r.attendees[0].acked, true);
    expect(r.attendees[1].linked, false);
    expect(r.photoUrls.length, 2);
    expect(r.editable, true);
  });

  test('TbmReceivedItem.fromJson 파싱', () {
    final it = TbmReceivedItem.fromJson(
        {'attendeeId': 'a1', 'acked': false, 'record': _dto()});
    expect(it.attendeeId, 'a1');
    expect(it.acked, false);
    expect(it.record.site, '강동 현장 3층');
  });

  testWidgets('tbmHazardLabel: 기본 코드는 언어별 번역, 커스텀은 원문', (tester) async {
    late AppLocalizations lKo;
    await tester.pumpWidget(_app(Builder(builder: (ctx) {
      lKo = AppLocalizations.of(ctx);
      return const SizedBox();
    })));
    expect(tbmHazardCodeLabel(lKo, 'FALL_HEIGHT'), '고소작업 추락');
    expect(tbmHazardLabel(lKo, const TbmHazard(code: 'HEAT_ILLNESS')), '폭염 온열질환');
    expect(tbmHazardLabel(lKo, const TbmHazard(text: '직접입력')), '직접입력');

    // 베트남어 로케일이면 다른 번역
    late AppLocalizations lVi;
    await tester.pumpWidget(_app(
        Builder(builder: (ctx) {
          lVi = AppLocalizations.of(ctx);
          return const SizedBox();
        }),
        locale: const Locale('vi')));
    expect(tbmHazardCodeLabel(lVi, 'FALL_HEIGHT'), 'Ngã từ trên cao');
    expect(tbmDefaultHazardCodes.length, 10);
  });

  testWidgets('TbmView 렌더 — 현장/위험요인/조치 표시', (tester) async {
    final r = TbmRecord.fromJson(_dto());
    await tester.pumpWidget(_app(
        Scaffold(body: SingleChildScrollView(child: TbmView(record: r)))));
    await tester.pumpAndSettle();
    expect(find.text('강동 현장 3층'), findsOneWidget);
    expect(find.text('고소작업 추락'), findsOneWidget); // 위험요인 칩(현재 언어)
    expect(find.text('안전벨트 착용, 유도원 배치'), findsOneWidget); // 조치
  });
}
