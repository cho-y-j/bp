import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workon/core/home_widget_bridge.dart';
import 'package:workon/l10n/app_localizations.dart';

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting();
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('HomeWidgetBridge.buildLoggedIn', () {
    test('오늘 일정 있음 — 현장/시간/미수금 렌더 문자열 포함', () {
      final kv = HomeWidgetBridge.buildLoggedIn(
        l: ko,
        lang: 'ko',
        site: '대성건설 현장',
        time: '오전 8:00 ~ 오후 5:00',
        outstanding: 1234500,
        syncedAt: DateTime(2026, 7, 11, 10, 30),
      );
      expect(kv[HomeWidgetBridge.kState], 'in');
      expect(kv[HomeWidgetBridge.kTodaySite], '대성건설 현장');
      expect(kv[HomeWidgetBridge.kTodayTime], '오전 8:00 ~ 오후 5:00');
      // ko 미수금 표기는 "원" 접미.
      expect(kv[HomeWidgetBridge.kOutstandingAmount], '1,234,500원');
      expect(kv[HomeWidgetBridge.kOutstandingLabel], '이번 달 미수금');
      expect(kv[HomeWidgetBridge.kSynced], contains('10:30'));
      expect(kv[HomeWidgetBridge.kBrand], '작업온');
    });

    test('오늘 일정 없음 — site/time 빈 문자열, no_schedule 채워짐', () {
      final kv = HomeWidgetBridge.buildLoggedIn(
        l: ko,
        lang: 'ko',
        site: '',
        time: '',
        outstanding: 0,
        syncedAt: DateTime(2026, 7, 11, 9, 0),
      );
      expect(kv[HomeWidgetBridge.kTodaySite], '');
      expect(kv[HomeWidgetBridge.kTodayTime], '');
      expect(kv[HomeWidgetBridge.kNoSchedule], '오늘 일정 없음');
      expect(kv[HomeWidgetBridge.kOutstandingAmount], '0원');
    });

    test('영어 로케일 — 통화 접두 ₩ + 영문 라벨', () {
      final kv = HomeWidgetBridge.buildLoggedIn(
        l: en,
        lang: 'en',
        site: 'Daesung Site',
        time: '8:00 AM ~ 5:00 PM',
        outstanding: 500000,
        syncedAt: DateTime(2026, 7, 11, 14, 5),
      );
      expect(kv[HomeWidgetBridge.kOutstandingAmount], '₩500,000');
      expect(kv[HomeWidgetBridge.kOutstandingLabel], 'This month due');
      expect(kv[HomeWidgetBridge.kNoSchedule], 'No schedule today');
    });
  });

  group('HomeWidgetBridge.buildLoggedOut', () {
    test('로그아웃 — state=out, 로그인 유도 문구, 데이터 잔상 제거', () {
      final kv = HomeWidgetBridge.buildLoggedOut(l: ko);
      expect(kv[HomeWidgetBridge.kState], 'out');
      expect(kv[HomeWidgetBridge.kLoginPlease], '로그인해 주세요');
      expect(kv[HomeWidgetBridge.kOutstandingAmount], '');
      expect(kv[HomeWidgetBridge.kTodaySite], '');
    });
  });
}
