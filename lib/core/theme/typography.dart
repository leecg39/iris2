// @TASK P1-S0-T2 - 앱 타이포그래피 시스템 정의
// @SPEC docs/planning/05-design-system.md#타이포그래피

import 'package:flutter/material.dart';

/// IRIS 앱 타이포그래피 상수
///
/// 폰트: Pretendard 또는 Noto Sans KR (기본 시스템 폰트 fallback)
/// 05-design-system.md 기반 정의
class AppTypography {
  AppTypography._();

  /// H1: 24sp, Bold - 주요 타이틀
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.4,
  );

  /// H2: 20sp, SemiBold - 섹션 타이틀
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Body: 16sp, Regular - 본문
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Caption: 14sp, Regular - 보조 텍스트
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  /// Label: 12sp, Medium - 레이블, 배지
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}
