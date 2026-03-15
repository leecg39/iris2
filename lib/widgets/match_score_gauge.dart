// @TASK P1-S0-T3 - 적합도 점수 원형 게이지 위젯
// @SPEC docs/planning/05-design-system.md#공통-위젯
// @TEST test/widgets/match_score_gauge_test.dart

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

/// 적합도 점수 원형 게이지 크기
enum MatchScoreSize {
  /// 40px - 카드 내 작은 크기
  sm,

  /// 64px - 기본 크기
  md,

  /// 120px - 상세 화면 큰 크기
  lg,
}

/// 적합도 점수를 원형 프로그레스 바로 표시하는 위젯
///
/// 점수 범위: 0~100
/// - 80점 이상: 초록색 (#2E7D32)
/// - 50~79점: 오렌지색 (#FF6D00)
/// - 50점 미만: 회색 (#757575)
class MatchScoreGauge extends StatelessWidget {
  const MatchScoreGauge({
    super.key,
    required this.score,
    this.size = MatchScoreSize.md,
  }) : assert(score >= 0 && score <= 100, 'score must be between 0 and 100');

  final int score;
  final MatchScoreSize size;

  double get _dimension {
    switch (size) {
      case MatchScoreSize.sm:
        return 40.0;
      case MatchScoreSize.md:
        return 64.0;
      case MatchScoreSize.lg:
        return 120.0;
    }
  }

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.accent;
    return AppColors.textSecondary;
  }

  TextStyle get _textStyle {
    switch (size) {
      case MatchScoreSize.sm:
        return AppTypography.label;
      case MatchScoreSize.md:
        return AppTypography.caption;
      case MatchScoreSize.lg:
        return AppTypography.h2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dimension,
      height: _dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100.0,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
            backgroundColor: _color.withOpacity(0.15),
            strokeWidth: size == MatchScoreSize.sm ? 3.0 : 4.0,
          ),
          Text(
            '$score',
            style: _textStyle.copyWith(
              color: _color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
