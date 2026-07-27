import 'package:__APP_NAME__/core/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';
import 'logging_interceptor.dart';

part 'network_providers.g.dart';

/// 현재 access token. 인증 feature가 세션 변화에 맞춰 갱신하고,
/// [dio]의 인터셉터가 요청 시점에 읽는다.
/// core는 feature를 모르므로 토큰은 `feature → core` 한 방향으로 push된다.
@Riverpod(keepAlive: true)
class AccessToken extends _$AccessToken {
  @override String? build() => null;
  void setToken(String? token) => state = token;   // ← auth feature가 push
}

/// 앱 공용 인증 Dio. keepAlive provider = 앱 생애 단일 인스턴스(싱글톤)이되
/// 테스트에서 override 가능. 모든 feature의 remote datasource가 이를 watch한다.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  if (kDebugMode) {
    AppLogger.instance.info('BaseUrl : $kApiBaseUrl');
  }
  final Dio instance = buildDio(
    baseUrl: kApiBaseUrl,
    authInterceptor: AuthInterceptor(
      accessToken: () => ref.read(accessTokenProvider),
    ),
  );
  // 로깅은 디버그 빌드에서만. 릴리즈 번들에는 로그가 남지 않는다(요구사항).
  // 헤더·요청 옵션은 출력하지 않고, Authorization 존재 여부와 바디의 민감 토큰만 마스킹한다.
  if (kDebugMode) {
    instance.interceptors.add(const LoggingInterceptor());
  }
  return instance;
}
