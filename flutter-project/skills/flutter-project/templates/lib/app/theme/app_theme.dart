// 이 파일을 프로젝트 브랜드에 맞게 채운다.
import 'package:flutter/material.dart';

import 'app_colors_theme.dart';

ThemeData buildLightTheme() =>
    _buildTheme(brightness: Brightness.light, colors: AppColorsTheme.light);

ThemeData buildDarkTheme() =>
    _buildTheme(brightness: Brightness.dark, colors: AppColorsTheme.dark);

ThemeData _buildTheme({
  required Brightness brightness,
  required AppColorsTheme colors,
}) {
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      error: colors.error,
    ),
    scaffoldBackgroundColor: colors.background,
    extensions: <ThemeExtension<dynamic>>[colors],
  );
}
