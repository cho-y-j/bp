import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'router.dart';

void main() {
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
    return MaterialApp.router(
      title: '작업온',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
