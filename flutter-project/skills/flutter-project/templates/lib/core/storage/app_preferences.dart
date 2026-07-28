import 'package:shared_preferences/shared_preferences.dart';

/// 비민감 설정 KV 래퍼(민감 값은 `SecureTokenStorage`).
///
/// **도메인 키를 여기에 두지 않는다.** core는 인프라라 어떤 기능이 무엇을
/// 저장하는지 몰라야 한다(검사 1.1). 키 상수와 의미 있는 접근자는 그 값을
/// 소유한 feature의 `data/` 레이어에 두고, 이 클래스는 타입별 접근만 제공한다.
class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
