import 'package:dio/dio.dart';

import 'auth_interceptor.dart';

/// 표준 [Dio] 인스턴스를 만든다.
///
/// 타임아웃·기본 헤더·인증 인터셉터를 한 곳에서 구성한다(docs/ARCHITECTURE.md §1·§6).
Dio buildDio({
  required String baseUrl,
  required AuthInterceptor authInterceptor,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(authInterceptor);
  return dio;
}
