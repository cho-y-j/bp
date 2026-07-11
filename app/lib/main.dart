import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale.dart';
import 'theme/app_theme.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Intl 날짜 심볼(전 로케일) 선로딩 — fmtDate/fmtMonth 등 로케일 포맷용.
  await initializeDateFormatting();
  runApp(const ProviderScopeApp());
}

/// 통합 테스트에서 pump 할 수 있도록 분리한 앱 루트.
class ProviderScopeApp extends StatelessWidget {
  const ProviderScopeApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const ProviderScope(child: WorkonApp());
}

class WorkonApp extends ConsumerWidget {
  const WorkonApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final saved = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: '작업온',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // 저장값 없으면 시스템 로케일 → 미지원이면 ko 로 폴백(localeResolutionCallback).
      locale: saved,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        if (saved != null) return saved;
        if (deviceLocale != null) {
          for (final s in supported) {
            if (s.languageCode == deviceLocale.languageCode) return s;
          }
        }
        return const Locale('ko');
      },
      routerConfig: router,
    );
  }
}
