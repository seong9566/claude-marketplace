import 'package:shared_preferences/shared_preferences.dart';

/// 비민감 설정 KV(docs/ARCHITECTURE.md §1: 설정은 prefs).
///
/// 마지막 선택 사업장 ID를 보관하고 로그아웃 시 제거한다.
class AppPreferences {
  const AppPreferences(this._prefs);

  static const String _lastSelectedSiteIdKey = 'last_selected_site_id';
  static const String _lastLoginIdKey = 'last_login_id';

  final SharedPreferences _prefs;

  String? get lastSelectedSiteId => _prefs.getString(_lastSelectedSiteIdKey);

  Future<void> setLastSelectedSiteId(String siteId) =>
      _prefs.setString(_lastSelectedSiteIdKey, siteId);

  Future<void> clearLastSelectedSiteId() =>
      _prefs.remove(_lastSelectedSiteIdKey);

  String? get lastLoginId => _prefs.getString(_lastLoginIdKey);

  Future<void> setLastLoginId(String loginId) =>
      _prefs.setString(_lastLoginIdKey, loginId);

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}
