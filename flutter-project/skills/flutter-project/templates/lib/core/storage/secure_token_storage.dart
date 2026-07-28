import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// access·refresh token을 Keychain/Keystore에 보관한다.
///
/// 두 토큰을 모두 영속 저장한다 — 콜드 스타트 refresh에서 access token을
/// Authorization 헤더에 실어야 하는 백엔드가 있어서다. 서버 규약에 따라
/// refresh token만 두어도 되면 그때 줄인다.
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
