/// 예측 가능한 실패의 도메인 표현(docs/ARCHITECTURE.md §7).
///
/// data 레이어가 원시 예외(DioException 등)를 이 타입으로 변환하고,
/// presentation이 타입별로 사용자 메시지를 분기한다.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 네트워크 연결·타임아웃 등 통신 자체의 실패.
final class NetworkException extends AppException {
  const NetworkException([super.message = '네트워크 연결을 확인해 주세요.']);
}

/// 인증 실패(잘못된 자격증명, 401 등).
final class AuthException extends AppException {
  const AuthException([super.message = '아이디 또는 비밀번호가 올바르지 않습니다.']);
}

/// 서버가 응답했으나 4xx/5xx인 경우.
final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

/// 분류되지 않은 실패.
final class UnknownException extends AppException {
  const UnknownException([super.message = '알 수 없는 오류가 발생했습니다.']);
}
