// @TASK P4-S1-T1 - 보고서 목록 화면
// @SPEC docs/planning/03-user-flow.md#보고서
// @TEST test/features/report/reports_test.dart

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../widgets/match_score_gauge.dart';
import '../../widgets/empty_state.dart';

/// 보고서 화면의 상태
enum ReportsScreenState {
  /// 데이터 없음
  empty,

  /// 데이터 있음
  normal,
}

/// 보고서 mock 데이터 모델
class _ReportItem {
  const _ReportItem({
    required this.id,
    required this.announcementTitle,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final String announcementTitle;
  final int score;
  final DateTime createdAt;
}

/// mock 보고서 데이터 (5개 이상)
final _mockReports = [
  _ReportItem(
    id: 'r1',
    announcementTitle: '2024년 중소기업 기술혁신 R&D 지원사업',
    score: 92,
    createdAt: DateTime(2024, 3, 10),
  ),
  _ReportItem(
    id: 'r2',
    announcementTitle: '스마트제조 혁신 바우처 지원사업',
    score: 78,
    createdAt: DateTime(2024, 3, 8),
  ),
  _ReportItem(
    id: 'r3',
    announcementTitle: '창업성장 기술개발 사업',
    score: 65,
    createdAt: DateTime(2024, 3, 5),
  ),
  _ReportItem(
    id: 'r4',
    announcementTitle: '디지털 전환 지원사업 (DX바우처)',
    score: 88,
    createdAt: DateTime(2024, 2, 28),
  ),
  _ReportItem(
    id: 'r5',
    announcementTitle: '소재·부품·장비 강소기업 100 육성사업',
    score: 71,
    createdAt: DateTime(2024, 2, 20),
  ),
];

/// 날짜를 "YYYY.MM.DD" 형식으로 포맷
String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

/// 보고서 목록 화면
///
/// - ReportList: 보고서 카드 목록 (공고명 + 적합도 MatchScoreGauge(sm) + 생성일)
/// - EmptyState: "아직 보고서가 없습니다" + 아이콘
/// - 각 카드 탭 시 PDF 뷰어/공유 (placeholder)
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    super.key,
    this.initialState = ReportsScreenState.normal,
  });

  final ReportsScreenState initialState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '보고서',
          style: AppTypography.h2.copyWith(color: AppColors.primary),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (initialState) {
      case ReportsScreenState.empty:
        return const EmptyState(
          icon: Icons.description_outlined,
          message: '아직 보고서가 없습니다.\nAI 매칭 후 보고서를 생성해 보세요.',
        );
      case ReportsScreenState.normal:
        return _ReportList(reports: _mockReports);
    }
  }
}

/// 보고서 카드 목록
class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports});

  final List<_ReportItem> reports;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = reports[index];
        return ReportCard(
          announcementTitle: item.announcementTitle,
          score: item.score,
          createdAt: item.createdAt,
          onTap: () {
            // PDF 뷰어/공유 placeholder
            showModalBottomSheet<void>(
              context: context,
              builder: (ctx) => _ReportActionSheet(
                title: item.announcementTitle,
              ),
            );
          },
        );
      },
    );
  }
}

/// 보고서 카드 위젯 (공개 - 테스트에서 find.byType 사용)
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.announcementTitle,
    required this.score,
    required this.createdAt,
    required this.onTap,
  });

  final String announcementTitle;
  final int score;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 적합도 게이지
            MatchScoreGauge(score: score, size: MatchScoreSize.sm),
            const SizedBox(width: AppSpacing.md),
            // 공고명 + 생성일
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcementTitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(createdAt),
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 화살표 아이콘
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// 보고서 액션 시트 (PDF 보기 / 공유 placeholder)
class _ReportActionSheet extends StatelessWidget {
  const _ReportActionSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.primary),
              title: const Text('PDF 보기'),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined,
                  color: AppColors.primary),
              title: const Text('공유하기'),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
