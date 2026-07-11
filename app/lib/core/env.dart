/// 빌드 시 주입: --dart-define=BASE_URL=...
class Env {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3030/api',
  );

  /// 카카오 네이티브 앱 키. `--dart-define=KAKAO_APP_KEY=...` 로 주입.
  /// 비어 있으면 카카오 로그인/연결 UI 를 노출하지 않는다(전화 인증만).
  static const kakaoAppKey = String.fromEnvironment('KAKAO_APP_KEY');

  /// 카카오 로그인 기능 노출 여부.
  static bool get kakaoEnabled => kakaoAppKey.isNotEmpty;
}
