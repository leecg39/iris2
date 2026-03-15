// @TASK P1-S0-T3 - 마감 D-day 뱃지 위젯
// @SPEC docs/planning/05-design-system.md#공통-위젯
// @TEST test/widgets/dday_badge_test.dart

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing.dart';

/// 마감일까지 남은 일수를 뱃지로 표시하는 위젯
///
/// - D-3 이하: 빨간색 (#C62828)
/// - D-4 ~ D-7: 노란색 (#F9A825)
/// - D-8 이상: 회색 (#757575)
/// - 마감된 경우: "마감" 텍스트
class DdayBadge extends StatelessWidget {
  const DdayBadge({
    super.key,
    required this.deadline,
  });

  final DateTime deadline;

  int get _daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDate.difference(today).inDays;
  }

  Color get _backgroundColor {
    final days = _daysLeft;
    if (days < 0) return AppColors.textSecondary;
    if (days <= 3) return AppColors.error;
    if (days <= 7) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String get _label {
    final days = _daysLeft;
    if (days < 0) return '마감';
    return 'D-$days';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        _label,
        style: AppTypography.label.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
