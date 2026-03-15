// @TASK P1-S0-T2 - 디자인 시스템 토큰 테스트
// @SPEC docs/planning/05-design-system.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/core/theme/colors.dart';
import 'package:iris/core/theme/typography.dart';
import 'package:iris/core/theme/spacing.dart';
import 'package:iris/core/theme/app_theme.dart';

void main() {
  group('AppColors', () {
    test('primary 색상이 #1565C0 이어야 한다', () {
      expect(AppColors.primary, const Color(0xFF1565C0));
    });

    test('secondary 색상이 #0D47A1 이어야 한다', () {
      expect(AppColors.secondary, const Color(0xFF0D47A1));
    });

    test('accent 색상이 #FF6D00 이어야 한다', () {
      expect(AppColors.accent, const Color(0xFFFF6D00));
    });

    test('success 색상이 #2E7D32 이어야 한다', () {
      expect(AppColors.success, const Color(0xFF2E7D32));
    });

    test('warning 색상이 #F9A825 이어야 한다', () {
      expect(AppColors.warning, const Color(0xFFF9A825));
    });

    test('error 색상이 #C62828 이어야 한다', () {
      expect(AppColors.error, const Color(0xFFC62828));
    });

    test('background 색상이 #F5F5F5 이어야 한다', () {
      expect(AppColors.background, const Color(0xFFF5F5F5));
    });

    test('surface 색상이 #FFFFFF 이어야 한다', () {
      expect(AppColors.surface, const Color(0xFFFFFFFF));
    });

    test('textPrimary 색상이 #212121 이어야 한다', () {
      expect(AppColors.textPrimary, const Color(0xFF212121));
    });

    test('textSecondary 색상이 #757575 이어야 한다', () {
      expect(AppColors.textSecondary, const Color(0xFF757575));
    });
  });

  group('AppTypography', () {
    test('h1이 fontSize 24, bold 이어야 한다', () {
      expect(AppTypography.h1.fontSize, 24);
      expect(AppTypography.h1.fontWeight, FontWeight.bold);
    });

    test('h2가 fontSize 20, w600 이어야 한다', () {
      expect(AppTypography.h2.fontSize, 20);
      expect(AppTypography.h2.fontWeight, FontWeight.w600);
    });

    test('body가 fontSize 16, normal 이어야 한다', () {
      expect(AppTypography.body.fontSize, 16);
      expect(AppTypography.body.fontWeight, FontWeight.normal);
    });

    test('caption이 fontSize 14, normal 이어야 한다', () {
      expect(AppTypography.caption.fontSize, 14);
      expect(AppTypography.caption.fontWeight, FontWeight.normal);
    });

    test('label이 fontSize 12, w500 이어야 한다', () {
      expect(AppTypography.label.fontSize, 12);
      expect(AppTypography.label.fontWeight, FontWeight.w500);
    });
  });

  group('AppSpacing', () {
    test('unit이 4.0 이어야 한다', () {
      expect(AppSpacing.unit, 4.0);
    });

    test('xs가 4.0 이어야 한다', () {
      expect(AppSpacing.xs, 4.0);
    });

    test('sm이 8.0 이어야 한다', () {
      expect(AppSpacing.sm, 8.0);
    });

    test('md가 16.0 이어야 한다', () {
      expect(AppSpacing.md, 16.0);
    });

    test('lg가 24.0 이어야 한다', () {
      expect(AppSpacing.lg, 24.0);
    });

    test('xl이 32.0 이어야 한다', () {
      expect(AppSpacing.xl, 32.0);
    });

    test('cardPadding이 16.0 이어야 한다', () {
      expect(AppSpacing.cardPadding, 16.0);
    });

    test('sectionGap이 24.0 이어야 한다', () {
      expect(AppSpacing.sectionGap, 24.0);
    });

    test('screenPadding이 16.0 이어야 한다', () {
      expect(AppSpacing.screenPadding, 16.0);
    });
  });

  group('AppTheme', () {
    test('appTheme이 ThemeData 인스턴스여야 한다', () {
      expect(appTheme, isA<ThemeData>());
    });

    test('appTheme이 Material3를 사용해야 한다', () {
      expect(appTheme.useMaterial3, isTrue);
    });

    test('appTheme의 colorScheme primary가 AppColors.primary 이어야 한다', () {
      expect(appTheme.colorScheme.primary, AppColors.primary);
    });

    test('appTheme의 scaffoldBackgroundColor가 AppColors.background 이어야 한다', () {
      expect(appTheme.scaffoldBackgroundColor, AppColors.background);
    });
  });
}
