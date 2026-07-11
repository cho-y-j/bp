import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// 앱이 지원하는 언어 코드(스위처 노출 순서). 한국어 기본 + 리서치 기반 5종.
const supportedLangs = ['ko', 'zh', 'ru', 'vi', 'ne', 'en'];

/// 각 언어의 자국어 표기(언어 선택 UI에 그대로 노출 — 번역하지 않음).
const langNative = {
  'ko': '한국어',
  'zh': '中文',
  'ru': 'Русский',
  'vi': 'Tiếng Việt',
  'ne': 'नेपाली',
  'en': 'English',
};

const _prefsKey = 'workon_lang';

/// 앱 언어 상태. `null` = 시스템 로케일 따름(미지원이면 ko 로 폴백).
class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedLangs.contains(saved)) {
      state = Locale(saved);
    }
  }

  /// `null` 이면 시스템 따름으로 되돌리고 저장값을 제거한다.
  Future<void> setLang(String? lang) async {
    final prefs = await SharedPreferences.getInstance();
    if (lang == null || !supportedLangs.contains(lang)) {
      await prefs.remove(_prefsKey);
      state = null;
    } else {
      await prefs.setString(_prefsKey, lang);
      state = Locale(lang);
    }
  }
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>((ref) => LocaleController());

/// 시스템 로케일이 지원 언어면 그대로, 아니면 ko 로 폴백하는 로케일 해석기.
Locale? resolveLocale(Locale? saved, Iterable<Locale> systemLocales) {
  if (saved != null) return saved;
  for (final loc in systemLocales) {
    if (supportedLangs.contains(loc.languageCode)) return Locale(loc.languageCode);
  }
  return const Locale('ko');
}

/// MaterialApp 에 넘길 지원 로케일 목록.
List<Locale> get appSupportedLocales =>
    AppLocalizations.supportedLocales;
