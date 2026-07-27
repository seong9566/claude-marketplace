import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// 에러 응답 본문에서 사용자용 메시지를 추출한다.
///
/// 커스텀 envelope `{message,...}` 또는 ASP.NET validation `{title,...}`을 지원한다(실측).
String? serverMessageOf(Object? data) {
  if (data is Map) {
    final Object? message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    final Object? title = data['title'];
    if (title is String && title.isNotEmpty) return title;
  }
  return null;
}

/// 원시 [DioException]을 도메인 [AppException]으로 변환한다(docs/ARCHITECTURE.md §6·§7).
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final int? status = e.response?.statusCode;
      final String? message = serverMessageOf(e.response?.data);
      if (status == 401) {
        return message == null ? const AuthException() : AuthException(message);
      }
      return ServerException(message ?? '서버 오류가 발생했습니다.', statusCode: status);
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const UnknownException();
  }
}
