/// 함수형 에러 처리를 위한 sealed Result 타입.
/// Repository 계층 경계에서 예외 대신 사용하여 에러를 명시적으로 처리한다.
library;

import 'package:__APP_NAME__/core/errors/failures.dart';

/// 성공(Success) 또는 실패(Failure)를 표현하는 sealed 클래스.
/// switch 식으로 완전 처리(exhaustive handling)가 보장된다.
sealed class Result<T> {
  const Result();

  /// 성공 결과 생성 편의 팩토리
  static Result<T> success<T>(T data) => Success(data);

  /// 실패 결과 생성 편의 팩토리
  static Result<T> failure<T>(Failure fail) => AppFailure(fail);

  /// 성공 여부 확인
  bool get isSuccess => this is Success<T>;

  /// 성공 데이터 반환. 실패 시 null 반환
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    AppFailure() => null,
  };

  /// 실패 정보 반환. 성공 시 null 반환
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    AppFailure(:final failure) => failure,
  };
}

/// 성공 케이스: 비즈니스 데이터를 포함한다
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// 실패 케이스: Failure 타입으로 에러 종류를 명시한다
final class AppFailure<T> extends Result<T> {
  final Failure failure;
  const AppFailure(this.failure);
}
