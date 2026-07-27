import 'package:dio/dio.dart';

/// 모든 요청에 현재 access token을 Bearer로 주입한다.
///
/// 토큰 소스는 세션 provider이며, [accessToken] 콜백으로 **요청 시점에** 읽어
/// Dio ↔ 세션 간 빌드타임 순환 의존을 피한다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.accessToken});

  final String? Function() accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = accessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
