import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyEmail = 'email';
  static const _keyPassword = 'password';

  static Future<void> saveAuthTokens(String token, String refreshToken) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<Map<String, String?>> getAuthTokens() async {
    return {
      'token': await _storage.read(key: _keyToken),
      'refreshToken': await _storage.read(key: _keyRefreshToken),
    };
  }

  static Future<void> clearAuthTokens() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  static Future<Map<String, String?>> getCredentials() async {
    return {
      'email': await _storage.read(key: _keyEmail),
      'password': await _storage.read(key: _keyPassword),
    };
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }

  static Future<void> clearAll() async {
    await clearAuthTokens();
    await clearCredentials();
  }
}