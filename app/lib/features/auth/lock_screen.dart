import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_lock.dart';
import '../../core/home_widget_bridge.dart';
import '../../providers/auth.dart';
import '../../theme/app_colors.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/common.dart';

/// 앱 전체를 감싸 잠금 상태일 때 잠금 화면을 오버레이하는 게이트.
/// MaterialApp.router 의 builder 에서 감싸 라우터/네트워크와 독립된 로컬 게이트로 동작한다.
/// 잠금은 로그인(인증) 상태에서만 노출한다(보호할 세션이 있을 때만).
class AppLockGate extends ConsumerWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 명시적 로그인(미인증→인증)일 때만 잠금 해제 — 로그인 직후 잠금 재노출 방지.
    // 앱 시작 시 세션 복원(unknown→인증)은 잠금을 유지해야 하므로 제외한다.
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.status == AuthStatus.unauthenticated && next.isAuthenticated) {
        ref.read(appLockControllerProvider.notifier).markUnlocked();
      }
    });
    final locked = ref.watch(appLockControllerProvider).isLocked;
    final authed = ref.watch(authControllerProvider).isAuthenticated;
    return Stack(
      children: [
        child,
        if (locked && authed) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}

/// 잠금 화면 — 브랜드 아이콘 + 인증 버튼 + 로그아웃.
/// 진입 시 자동으로 1회 인증을 시도하고, 실패/취소 시 재시도 화면을 유지한다.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    final reason = context.l.appLockReason;
    await ref.read(appLockControllerProvider.notifier).authenticate(reason);
    // 성공 시 게이트가 자동으로 화면을 걷어낸다. 실패/취소면 재시도 화면 유지.
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _logout() async {
    final l = context.l;
    ref.read(authControllerProvider.notifier).forceLogout();
    await HomeWidgetBridge.push(HomeWidgetBridge.buildLoggedOut(l: l));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Material(
      color: c.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: c.primary, borderRadius: BorderRadius.circular(22)),
                child: Icon(Icons.lock_outline_rounded, color: c.primaryInk, size: 38),
              ),
              const SizedBox(height: 20),
              Text('작업온',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 8),
              Text(l.appLockLockedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: c.ink2, height: 1.4)),
              const Spacer(),
              PrimaryButton(
                label: l.appLockUnlock,
                icon: Icons.fingerprint_rounded,
                loading: _busy,
                onPressed: _authenticate,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : _logout,
                child: Text(l.logout,
                    style: TextStyle(color: c.receivable, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
