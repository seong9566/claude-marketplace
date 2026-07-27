import 'dart:convert';

import 'package:__APP_NAME__/core/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 민감한 네트워크 정보를 마스킹해 개발 빌드에 기록한다.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  static const String _loggingStartMs = 'logging_start_ms';
  static const Set<String> _sensitiveKeys = <String>{
    'loginpw',
    'password',
    'accesstoken',
    'refreshtoken',
    'token',
    'fcmtoken',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_loggingStartMs] = DateTime.now().millisecondsSinceEpoch;
    final List<String> lines = <String>[
      '→ ${options.method} ${options.uri.path}',
      'Authorization: ${options.headers.containsKey('Authorization') ? '있음' : '없음'}',
      if (options.data != null) 'body: ${maskedBody(options.data)}',
    ];
    AppLogger.instance.info(lines.join('\n'));
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final int? elapsedMs = _elapsedMs(response.requestOptions);
    final List<String> lines = <String>[
      '← ${response.statusCode} ${response.requestOptions.uri.path} (${elapsedMs ?? '-'}ms)',
      if (response.data != null) 'body: ${maskedBody(response.data)}',
    ];
    AppLogger.instance.info(lines.join('\n'));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final int? elapsedMs = _elapsedMs(err.requestOptions);
    final Object? data = err.response?.data;
    final List<String> lines = <String>[
      '✗ ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.uri.path} (${elapsedMs ?? '-'}ms)',
      if (data != null)
        'body: ${maskedBody(data)}'
      else if (err.message != null)
        'error: ${err.message}',
    ];
    AppLogger.instance.warning(lines.join('\n'));
    handler.next(err);
  }

  static int? _elapsedMs(RequestOptions options) {
    final Object? startMs = options.extra[_loggingStartMs];
    if (startMs is! int) {
      return null;
    }
    return DateTime.now().millisecondsSinceEpoch - startMs;
  }

  /// 네트워크 바디의 민감 값을 마스킹한 문자열로 변환한다.
  @visibleForTesting
  static String maskedBody(Object? data) {
    final Object? masked = _maskedValue(data);
    if (masked is Map<Object?, Object?> || masked is List<Object?>) {
      return const JsonEncoder.withIndent('  ').convert(masked);
    }
    return masked.toString();
  }

  static Object? _maskedValue(Object? value) {
    if (value is FormData) {
      return _maskedFormData(value);
    }
    if (value is Map<Object?, Object?>) {
      return <String, Object?>{
        for (final MapEntry<Object?, Object?> entry in value.entries)
          entry.key.toString(): _maskedEntry(entry.key.toString(), entry.value),
      };
    }
    if (value is List<Object?>) {
      return value.map(_maskedValue).toList();
    }
    return value;
  }

  static Map<String, Object?> _maskedFormData(FormData data) {
    final Map<String, Object?> masked = <String, Object?>{};
    for (final MapEntry<String, String> field in data.fields) {
      masked[field.key] = _maskedEntry(field.key, field.value);
    }
    for (final MapEntry<String, MultipartFile> file in data.files) {
      final String fileName = file.value.filename ?? 'unknown';
      masked[file.key] = '[file: $fileName]';
    }
    return masked;
  }

  static Object? _maskedEntry(String key, Object? value) {
    if (_sensitiveKeys.contains(key.toLowerCase())) {
      return '***';
    }
    return _maskedValue(value);
  }
}
