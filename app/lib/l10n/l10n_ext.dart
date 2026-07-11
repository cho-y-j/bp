import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// 위젯에서 `context.l.<key>` 로 번역 문자열에 접근하는 단축 확장.
/// (nullable-getter: false 설정이라 non-null 반환.)
extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);

  /// 현재 앱 로케일의 언어 코드(ko/zh/ru/vi/ne/en). 포맷 함수에 넘긴다.
  String get lang => Localizations.localeOf(this).languageCode;
}
