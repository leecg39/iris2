// @TASK P1-S0-T3 - 매칭 결과 카드 위젯
// @SPEC docs/planning/05-design-system.md#공통-위젯
// @TEST test/widgets/match_card_test.dart

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing.dart';
import 'match_score_gauge.dart';
import 'dday_badge.dart';

/// 매칭된 공고를 카드 형태로 표시하는 위젯
///
/// 공고명(H2) + MatchScoreGauge(sm) + DdayBadge + 기관명(caption)
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.title,
    required this.score,
    required this.deadline,
    required this.organization,
    this.onTap,
  });

  /// 공고 제목
  final String title;

  /// 적합도 점수 (0~100)
  final int score;

  /// 마감일
  final DateTime deadline;

  /// 기관명
  final String organization;

  /// 탭 콜백 (null이면 탭 비활성)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 공고명 + 게이지
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  MatchScoreGauge(
                    score: score,
                    size: MatchScoreSize.sm,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // 하단: 기관명 + D-day 뱃지
              Row(
                children: [
                  Expanded(
                    child: Text(
                      organization,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  DdayBadge(deadline: deadline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
