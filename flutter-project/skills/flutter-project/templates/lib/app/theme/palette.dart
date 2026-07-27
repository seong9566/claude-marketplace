// 이 파일을 프로젝트 브랜드에 맞게 채운다.
import 'package:flutter/material.dart';

/// 시맨틱 의미를 갖지 않는 원시 색상표.
///
/// 프로젝트의 모든 Color 리터럴은 이 파일에만 둔다.
abstract final class AppPalette {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111111);

  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral700 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  static const Color accent = Color(0xFF455A64);
  static const Color error = Color(0xFFB3261E);
}
