// @TASK P1-S0-T2 - Material 3 ThemeData 생성
// @SPEC docs/planning/05-design-system.md

import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// IRIS 앱 기본 테마 (라이트 모드)
///
/// Material 3 기반, AppColors + AppTypography 활용
/// IrisApp (app.dart) 에서 theme: appTheme 으로 사용
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.surface,
    secondary: AppColors.secondary,
    onSecondary: AppColors.surface,
    error: AppColors.error,
    onError: AppColors.surface,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  ),
  scaffoldBackgroundColor: AppColors.background,
  textTheme: TextTheme(
    headlineLarge: AppTypography.h1.copyWith(color: AppColors.textPrimary),
    headlineMedium: AppTypography.h2.copyWith(color: AppColors.textPrimary),
    bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimary),
    bodyMedium: AppTypography.caption.copyWith(color: AppColors.textSecondary),
    labelSmall: AppTypography.label.copyWith(color: AppColors.textSecondary),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.surface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.h2.copyWith(color: AppColors.surface),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    backgroundColor: AppColors.surface,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  cardTheme: const CardTheme(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.textSecondary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.textSecondary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);
