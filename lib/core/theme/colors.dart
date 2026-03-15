// @TASK P1-S0-T2 - 앱 컬러 시스템 정의
// @SPEC docs/planning/05-design-system.md#컬러-시스템

import 'package:flutter/material.dart';

/// IRIS 앱 컬러 상수
///
/// 05-design-system.md 기반 정의
/// Material 3 ColorScheme에 연동됨 (app_theme.dart 참조)
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF0D47A1);
  static const Color accent = Color(0xFFFF6D00);

  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);

  // Background & Surface
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}
