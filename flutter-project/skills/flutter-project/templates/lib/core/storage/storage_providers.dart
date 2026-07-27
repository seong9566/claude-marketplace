import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';

part 'storage_providers.g.dart';

/// 앱 공용 비민감 설정 prefs. SharedPreferences 초기화가 async라 Future를 노출한다.
/// 소비자는 `ref.watch(appPreferencesProvider.future)`로 Future를 주입받는다.
@Riverpod(keepAlive: true)
Future<AppPreferences> appPreferences(Ref ref) async =>
    AppPreferences(await SharedPreferences.getInstance());
