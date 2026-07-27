// 이 파일을 프로젝트 브랜드에 맞게 채운다.
import 'package:flutter/material.dart';
import 'palette.dart';

@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme({
    required this.background,
    required this.surface,
    required this.foreground,
    required this.accent,
    required this.error,
  });
  final Color background, surface, foreground, accent, error;
  static const light = AppColorsTheme(
    background: AppPalette.neutral100,
    surface: AppPalette.white,
    foreground: AppPalette.neutral900,
    accent: AppPalette.accent,
    error: AppPalette.error,
  );
  static const dark = AppColorsTheme(
    background: AppPalette.black,
    surface: AppPalette.neutral900,
    foreground: AppPalette.white,
    accent: AppPalette.accent,
    error: AppPalette.error,
  );
  @override
  AppColorsTheme copyWith() => this;

  @override
  AppColorsTheme lerp(covariant AppColorsTheme? other, double t) =>
      other ?? this;
}

extension AppColorsBuildContext on BuildContext {
  AppColorsTheme get colors => Theme.of(this).extension<AppColorsTheme>()!;
}
