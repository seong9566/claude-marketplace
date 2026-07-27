import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// access·refresh token을 Keychain/Keystore에 보관한다.
///
/// 자동 로그인(영속) 세션에서 두 토큰을 모두 저장한다. 서버가 refresh 요청에서도
/// access token을 요구하므로, 콜드 스타트 refresh의 Authorization 헤더에 실어
/// 보낼 수 있도록 access token을 refresh token과 함께 영속 저장한다.
class SecureTokenStorage {
  const SecureTokenStorage(this._storage);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// access·refresh 토큰을 모두 삭제한다(로그아웃·만료).
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
