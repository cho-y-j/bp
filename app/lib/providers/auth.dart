import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/models.dart';

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  client.onUnauthorized = () {
    ref.read(authControllerProvider.notifier).forceLogout();
  };
  return client;
});

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final Profile? profile;
  const AuthState(this.status, this.profile);
  const AuthState.unknown() : this(AuthStatus.unknown, null);
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsOnboarding =>
      isAuthenticated && (profile?.name == null || profile!.name!.trim().isEmpty);
}

class AuthController extends StateNotifier<AuthState> {
  final ApiClient _api;
  AuthController(this._api) : super(const AuthState.unknown()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await _api.tokens.read();
    if (token == null || token.isEmpty) {
      state = const AuthState(AuthStatus.unauthenticated, null);
      return;
    }
    try {
      final me = await _api.get('/me');
      state = AuthState(AuthStatus.authenticated, Profile.fromJson(me as Map));
    } catch (_) {
      await _api.tokens.clear();
      state = const AuthState(AuthStatus.unauthenticated, null);
    }
  }

  /// 인증코드 발송 → dev 는 devCode 반환.
  Future<String?> requestCode(String phone) async {
    final res = await _api.post('/auth/phone/request', body: {'phone': phone});
    return (res as Map)['devCode']?.toString();
  }

  /// 코드 검증 → 저장 + 프로필 로드.
  Future<AuthResult> verify(String phone, String code) async {
    final res =
        await _api.post('/auth/phone/verify', body: {'phone': phone, 'code': code});
    final auth = AuthResult.fromJson(res as Map);
    await _api.tokens.write(auth.accessToken);
    state = AuthState(AuthStatus.authenticated, auth.profile);
    return auth;
  }

  /// 온보딩: 이름/업종 저장.
  Future<void> saveProfile({required String name, List<String>? industryTags}) async {
    final res = await _api.patch('/me', body: {
      'name': name,
      'industryTags': ?industryTags,
    });
    state = AuthState(AuthStatus.authenticated, Profile.fromJson(res as Map));
  }

  /// 전화검색 동의 토글 (PATCH /me).
  Future<void> setPhoneSearchConsent(bool value) async {
    final res = await _api.patch('/me', body: {'phoneSearchConsent': value});
    state = AuthState(AuthStatus.authenticated, Profile.fromJson(res as Map));
  }

  /// 세금계산서 공급자(내 사업자) 정보 저장 (PATCH /me).
  Future<void> saveBusinessInfo({
    required String bizNumber,
    required String bizName,
    required String bizAddress,
  }) async {
    final res = await _api.patch('/me', body: {
      'bizNumber': bizNumber.trim(),
      'bizName': bizName.trim(),
      'bizAddress': bizAddress.trim(),
    });
    state = AuthState(AuthStatus.authenticated, Profile.fromJson(res as Map));
  }

  /// 카카오 로그인 (POST /auth/kakao). accessToken 은 카카오 SDK 로 발급받은 값.
  Future<AuthResult> kakaoLogin(String kakaoAccessToken) async {
    final res =
        await _api.post('/auth/kakao', body: {'accessToken': kakaoAccessToken});
    final auth = AuthResult.fromJson(res as Map);
    await _api.tokens.write(auth.accessToken);
    state = AuthState(AuthStatus.authenticated, auth.profile);
    return auth;
  }

  /// 로그인 상태에서 카카오 계정 연결 (POST /auth/kakao/link) → ProfileDto 반환.
  Future<void> linkKakao(String kakaoAccessToken) async {
    final res = await _api
        .post('/auth/kakao/link', body: {'accessToken': kakaoAccessToken});
    state = AuthState(AuthStatus.authenticated, Profile.fromJson(res as Map));
  }

  /// 수금 안내용 입금 계좌 저장 (PATCH /me). 제공된 키만 전송 (P3a).
  Future<void> savePayout({String? bank, String? account, String? holder}) async {
    final res = await _api.patch('/me', body: {
      if (bank != null) 'payoutBank': bank.trim(),
      if (account != null) 'payoutAccount': account.trim(),
      if (holder != null) 'payoutHolder': holder.trim(),
    });
    state = AuthState(AuthStatus.authenticated, Profile.fromJson(res as Map));
  }

  Future<void> refreshProfile() async {
    try {
      final me = await _api.get('/me');
      state = AuthState(AuthStatus.authenticated, Profile.fromJson(me as Map));
    } catch (_) {}
  }

  Future<void> logout() async {
    await _api.tokens.clear();
    state = const AuthState(AuthStatus.unauthenticated, null);
  }

  void forceLogout() {
    _api.tokens.clear();
    state = const AuthState(AuthStatus.unauthenticated, null);
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(apiClientProvider));
});
