import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash_screen.dart';

/// Riverpod 상태 변화를 go_router refresh 로 연결.
class _RiverpodRefresh extends ChangeNotifier {
  _RiverpodRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RiverpodRefresh(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const MainShell()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    ],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      if (auth.status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return loc == '/login' ? null : '/login';
      }
      // authenticated
      if (auth.needsOnboarding) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/login' || loc == '/onboarding' || loc == '/splash') {
        return '/';
      }
      return null;
    },
  );
});
