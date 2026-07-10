/// 빌드 시 주입: --dart-define=BASE_URL=...
class Env {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3030/api',
  );
}
