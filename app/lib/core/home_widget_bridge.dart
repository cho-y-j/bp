import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'format.dart';

/// 홈 화면 위젯(iOS WidgetKit / Android AppWidget)과 데이터를 공유하는 브리지.
///
/// 설계 원칙:
/// - 위젯은 네트워크 호출을 하지 않는다. 앱이 홈/장부 데이터를 로드할 때
///   여기로 **완성된 표시 문자열**(로케일 반영)을 저장하고, 네이티브는 렌더만 한다.
/// - 문구는 앱 언어 설정을 따른다 → 로케일 문자열을 그대로 공유 저장한다.
/// - 로그아웃 시 로그인 유도 상태로 클리어한다.
class HomeWidgetBridge {
  HomeWidgetBridge._();

  /// App Group / 위젯 식별자 (iOS App Group, kr.workon 계열).
  static const String appGroupId = 'group.kr.workon';
  static const String iOSWidgetName = 'WorkonWidget';
  static const String androidWidgetName = 'WorkonWidgetProvider';

  /// 브랜드명 — 정책상 전 언어 공통(미번역).
  static const String _brand = '작업온';

  /// 공유 저장 키 (네이티브와 계약). 값은 모두 이미 렌더된 문자열.
  static const String kState = 'workon_state'; // "in" | "out"
  static const String kBrand = 'workon_brand';
  static const String kTodayLabel = 'workon_today_label';
  static const String kTodaySite = 'workon_today_site'; // 없으면 ''
  static const String kTodayTime = 'workon_today_time'; // 없으면 ''
  static const String kNoSchedule = 'workon_no_schedule';
  static const String kOutstandingLabel = 'workon_outstanding_label';
  static const String kOutstandingAmount = 'workon_outstanding_amount';
  static const String kSynced = 'workon_synced';
  static const String kLoginPlease = 'workon_login_please';

  /// 마지막으로 푸시한 키·값 — 동일하면 네이티브 갱신을 생략(중복 호출 방지).
  static Map<String, String>? _lastPushed;

  @visibleForTesting
  static void resetForTest() => _lastPushed = null;

  /// 로그인 상태 + 오늘 일정 + 이번 달 미수금을 위젯에 반영.
  ///
  /// [site]/[time] 이 비어 있으면 위젯은 "오늘 일정 없음"을 표시한다.
  static Map<String, String> buildLoggedIn({
    required AppLocalizations l,
    required String lang,
    required String site,
    required String time,
    required int outstanding,
    required DateTime syncedAt,
  }) {
    final syncedTime = DateFormat.jm(localeName(lang)).format(syncedAt);
    return <String, String>{
      kState: 'in',
      kBrand: _brand,
      kTodayLabel: l.widgetToday,
      kTodaySite: site,
      kTodayTime: time,
      kNoSchedule: l.widgetNoSchedule,
      kOutstandingLabel: l.widgetOutstanding,
      kOutstandingAmount: formatMoney(outstanding, lang),
      kSynced: l.widgetSyncedAt(syncedTime),
      kLoginPlease: l.widgetLoginPlease,
    };
  }

  /// 로그아웃(또는 미인증) 상태 — "로그인해 주세요".
  static Map<String, String> buildLoggedOut({
    required AppLocalizations l,
  }) {
    return <String, String>{
      kState: 'out',
      kBrand: _brand,
      kLoginPlease: l.widgetLoginPlease,
      // 나머지 키는 빈 값으로 덮어써 이전 데이터 잔상 제거.
      kTodayLabel: '',
      kTodaySite: '',
      kTodayTime: '',
      kNoSchedule: '',
      kOutstandingLabel: '',
      kOutstandingAmount: '',
      kSynced: '',
    };
  }

  /// 위젯 데이터를 저장하고 네이티브 갱신을 트리거한다. 값이 이전과 같으면 생략.
  static Future<void> push(Map<String, String> kv) async {
    if (mapEquals(_lastPushed, kv)) return;
    _lastPushed = Map<String, String>.from(kv);
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      for (final e in kv.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      // 위젯 미지원 플랫폼(웹/데스크톱)·미설치 상황에서도 앱 흐름을 막지 않는다.
      if (kDebugMode) {
        debugPrint('[HomeWidgetBridge] push skipped: $e');
      }
      _lastPushed = null; // 실패 시 다음 기회에 재시도 허용.
    }
  }
}
