import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT 를 OS 보안 저장소(iOS Keychain / Android Keystore)에 보관.
class TokenStore {
  static const _key = 'workon_jwt';
  final FlutterSecureStorage _storage;

  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> clear() => _storage.delete(key: _key);
}
