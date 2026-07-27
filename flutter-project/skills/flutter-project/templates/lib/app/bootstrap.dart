import 'package:__APP_NAME__/app/app.dart';
import 'package:__APP_NAME__/core/storage/app_preferences.dart';
import 'package:__APP_NAME__/core/storage/storage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱을 (재)기동한다 — ProviderContainer를 새로 만들고 runApp으로 위젯 트리를 (재)구성한다.
///
/// [previousContainer]를 넘기면 새 트리가 화면에 반영된 뒤 이전 컨테이너를 dispose한다.
/// 캐시 초기화 후 앱을 통째로 재시작할 때 사용하며, main()의 최초 기동에서는 생략한다.
Future<ProviderContainer> bootstrapApp({
  ProviderContainer? previousContainer,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWith((ref) async => AppPreferences(prefs)),
    ],
  );

  runApp(UncontrolledProviderScope(container: container, child: const App()));

  // runApp의 attachRootWidget은 Timer로 지연 실행돼 이 시점엔 이전 트리가 아직
  // 마운트돼 있다 — 이전 트리의 State.dispose()가 끝난 뒤에만 이전 container를
  // 폐기해야 한다.
  if (previousContainer != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousContainer.dispose();
    });
  }
  return container;
}
