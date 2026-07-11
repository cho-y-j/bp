import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'env.dart';

/// 카카오 로그인 SDK 래퍼 — `KAKAO_APP_KEY` 가 주입된 경우에만 사용한다.
/// (호출부는 [Env.kakaoEnabled] 로 UI 노출을 먼저 가드한다.)
class KakaoAuth {
  static bool _inited = false;

  /// 앱 키가 있을 때 1회 초기화.
  static void ensureInit() {
    if (!Env.kakaoEnabled || _inited) return;
    KakaoSdk.init(nativeAppKey: Env.kakaoAppKey);
    _inited = true;
  }

  /// 카카오 로그인 → 사용자 access token 반환. 카카오톡 설치 시 톡 로그인 우선,
  /// 실패/미설치면 카카오계정 로그인으로 폴백.
  static Future<String> obtainAccessToken() async {
    ensureInit();
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    return token.accessToken;
  }
}
