// @TASK P1-S0-T3 - 로딩 스피너 위젯
// @SPEC docs/planning/05-design-system.md#공통-위젯
// @TEST test/widgets/loading_indicator_test.dart

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing.dart';

/// 로딩 상태를 표시하는 위젯
///
/// 중앙 CircularProgressIndicator + 선택적 메시지
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
  });

  /// 로딩 중 표시할 메시지 (optional)
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
