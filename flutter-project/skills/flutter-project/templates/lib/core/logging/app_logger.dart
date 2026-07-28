import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전역 싱글톤 로거.
/// Debug 빌드에서만 활성화되며 Release에서는 모든 로그가 억제된다.
class AppLogger {
  AppLogger._() {
    _logger = Logger(
      filter: kReleaseMode ? _SilentFilter() : DevelopmentFilter(),
      printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: ConsoleOutput(),
    );
  }

  static AppLogger? _instance;

  static AppLogger get instance => _instance ??= AppLogger._();

  late final Logger _logger;

  /// 정상 흐름 (API 호출 시작, SDK 호출 완료 등)
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  /// 복구 가능한 오류 (캐시 미스, 폴백 처리 등)
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// 실패 (AppFailure, Exception, UI 에러 상태 전환)
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

/// Release 빌드에서 모든 로그를 억제하는 필터
class _SilentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}
