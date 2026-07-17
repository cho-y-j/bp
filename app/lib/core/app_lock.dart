import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 생체/기기암호 인증 추상화 — 테스트에서 가짜 구현으로 대체 가능.
abstract class LockAuthenticator {
  /// 생체 또는 기기 암호(폴백)로 인증 가능한 기기인지.
  Future<bool> canAuthenticate();

  /// 인증 시도 → 성공하면 true. 취소/실패/오류는 false.
  Future<bool> authenticate(String reason);
}

/// local_auth 기반 실제 구현. 생체(FaceID·지문)를 우선하되
/// 기기 미지원·미등록 시 기기 암호(passcode/PIN/pattern)로 폴백한다.
class LocalAuthenticator implements LockAuthenticator {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      // isDeviceSupported(): 생체 미등록이어도 기기 암호가 설정돼 있으면 true.
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // biometricOnly:false → 생체 미지원/실패 시 기기 암호로 폴백.
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

enum LockStatus { locked, unlocked }

class AppLockState {
  final bool enabled;
  final LockStatus status;
  const AppLockState({required this.enabled, required this.status});

  /// 실제로 잠금 화면을 노출해야 하는지(켜져 있고 잠긴 상태).
  bool get isLocked => enabled && status == LockStatus.locked;

  AppLockState copyWith({bool? enabled, LockStatus? status}) => AppLockState(
        enabled: enabled ?? this.enabled,
        status: status ?? this.status,
      );
}

typedef PersistEnabled = Future<void> Function(bool enabled);

/// 앱 잠금 상태 머신.
///  - 앱 시작: 잠금이 켜져 있으면 잠긴 상태로 시작.
///  - 백그라운드 30초 이상 후 복귀: 다시 잠금.
///  - 인증 성공 / 새 로그인 / OFF 전환: 해제.
/// 네트워크(리프레시 토큰)와 독립된 순수 로컬 게이트.
class AppLockController extends StateNotifier<AppLockState>
    with WidgetsBindingObserver {
  final LockAuthenticator authenticator;
  final PersistEnabled persist;

  /// 백그라운드가 이 시간 이상이면 복귀 시 재잠금.
  static const backgroundLockThreshold = Duration(seconds: 30);

  DateTime? _backgroundedAt;
  bool _observing = false;

  AppLockController(
    this.authenticator, {
    required bool initialEnabled,
    required this.persist,
    bool observeLifecycle = true,
  })  : super(AppLockState(
          enabled: initialEnabled,
          status: initialEnabled ? LockStatus.locked : LockStatus.unlocked,
        )) {
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  Future<bool> canUseDeviceAuth() => authenticator.canAuthenticate();

  /// 설정에서 잠금 켜기/끄기. 켤 때는 이미 앱을 쓰는 중이므로 잠그지 않는다.
  Future<void> setEnabled(bool value) async {
    await persist(value);
    _backgroundedAt = null;
    state = AppLockState(enabled: value, status: LockStatus.unlocked);
  }

  /// 잠금 화면에서 인증 시도. 성공 시 해제.
  Future<bool> authenticate(String reason) async {
    final ok = await authenticator.authenticate(reason);
    if (ok) {
      _backgroundedAt = null;
      state = state.copyWith(status: LockStatus.unlocked);
    }
    return ok;
  }

  /// 새 로그인 등 신원이 이미 확인된 경우 해제(로그인 직후 잠금 재노출 방지).
  void markUnlocked() {
    _backgroundedAt = null;
    if (state.status != LockStatus.unlocked) {
      state = state.copyWith(status: LockStatus.unlocked);
    }
  }

  // --- 라이프사이클 훅 (테스트에서 직접 호출 가능하도록 분리) ---

  void onBackground(DateTime at) {
    // 최초 백그라운드 시각만 기록(inactive→paused 중복 무시).
    _backgroundedAt ??= at;
  }

  void onForeground(DateTime at) {
    final bg = _backgroundedAt;
    _backgroundedAt = null;
    if (!state.enabled || bg == null) return;
    if (at.difference(bg) >= backgroundLockThreshold &&
        state.status != LockStatus.locked) {
      state = state.copyWith(status: LockStatus.locked);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = DateTime.now();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      onBackground(now);
    } else if (state == AppLifecycleState.resumed) {
      onForeground(now);
    }
  }

  @override
  void dispose() {
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// SharedPreferences 저장 키.
const appLockPrefKey = 'workon_app_lock_enabled';

/// main() 에서 SharedPreferences 로 읽은 초기값으로 override 한다(기본 false).
final appLockInitialEnabledProvider = Provider<bool>((_) => false);

/// 인증기 — 테스트에서 가짜 구현으로 override 가능.
final lockAuthenticatorProvider =
    Provider<LockAuthenticator>((_) => LocalAuthenticator());

final StateNotifierProvider<AppLockController, AppLockState>
    appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  return AppLockController(
    ref.watch(lockAuthenticatorProvider),
    initialEnabled: ref.watch(appLockInitialEnabledProvider),
    persist: (v) async {
      final p = await SharedPreferences.getInstance();
      await p.setBool(appLockPrefKey, v);
    },
  );
});
