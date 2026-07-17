import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT(액세스) + 리프레시 토큰을 OS 보안 저장소(iOS Keychain / Android Keystore)에 보관.
class TokenStore {
  static const _key = 'workon_jwt';
  static const _refreshKey = 'workon_refresh';
  final FlutterSecureStorage _storage;

  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  // --- 액세스 토큰 ---
  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  // --- 리프레시 토큰 (자동 로그인 연장) ---
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);
  Future<void> writeRefresh(String token) =>
      _storage.write(key: _refreshKey, value: token);

  /// 로그인 성공 시 액세스+리프레시 동시 저장.
  Future<void> writeTokens(String access, String? refresh) async {
    await _storage.write(key: _key, value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  /// 로그아웃/세션 만료: 액세스+리프레시 모두 삭제.
  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _refreshKey);
  }
}
