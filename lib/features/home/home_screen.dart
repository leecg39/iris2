// @TASK P3-S1-T1 - 홈 대시보드 화면
// @SPEC docs/planning/03-user-flow.md#홈-대시보드
// @TEST test/features/home/home_test.dart

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../widgets/match_card.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/match_score_gauge.dart';
import '../../widgets/loading_indicator.dart';

/// 홈 대시보드 화면의 상태
enum HomeScreenState {
  /// 로딩 중
  loading,

  /// 데이터 없음
  empty,

  /// 데이터 있음
  normal,
}

/// 홈 대시보드 mock 데이터 모델
class _AnnouncementSummary {
  const _AnnouncementSummary({
    required this.id,
    required this.title,
    required this.score,
    required this.deadline,
    required this.organization,
  });

  final String id;
  final String title;
  final int score;
  final DateTime deadline;
  final String organization;
}

/// 샘플 데이터
final _mockDeadlineItems = [
  _AnnouncementSummary(
    id: 'd1',
    title: '2024년 중소기업 기술혁신 R&D 지원사업',
    score: 92,
    deadline: DateTime.now().add(const Duration(days: 2)),
    organization: '중소벤처기업부',
  ),
  _AnnouncementSummary(
    id: 'd2',
    title: '스마트제조 혁신 바우처 지원사업',
    score: 78,
    deadline: DateTime.now().add(const Duration(days: 5)),
    organization: '산업통상자원부',
  ),
  _AnnouncementSummary(
    id: 'd3',
    title: '창업성장 기술개발 사업',
    score: 65,
    deadline: DateTime.now().add(const Duration(days: 7)),
    organization: '중소벤처기업부',
  ),
];

final _mockTopMatches = [
  _AnnouncementSummary(
    id: 'm1',
    title: '2024년 중소기업 기술혁신 R&D 지원사업',
    score: 92,
    deadline: DateTime.now().add(const Duration(days: 15)),
    organization: '중소벤처기업부',
  ),
  _AnnouncementSummary(
    id: 'm2',
    title: '디지털 전환 지원사업 (DX바우처)',
    score: 88,
    deadline: DateTime.now().add(const Duration(days: 20)),
    organization: '과학기술정보통신부',
  ),
  _AnnouncementSummary(
    id: 'm3',
    title: '소재·부품·장비 강소기업 100 육성사업',
    score: 85,
    deadline: DateTime.now().add(const Duration(days: 30)),
    organization: '산업통상자원부',
  ),
];

const String _mockCompanyName = '(주)테크스타트';
const int _mockMatchCount = 12;

/// 홈 대시보드 화면
///
/// - GreetingHeader: 회사명 인사
/// - MatchSummaryCard: 적합 공고 요약
/// - DeadlineList: 마감 임박 공고 3개
/// - TopMatches: 상위 매칭 3개
/// - Pull-to-refresh
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.initialState = HomeScreenState.normal,
  });

  final HomeScreenState initialState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeScreenState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  Future<void> _handleRefresh() async {
    setState(() => _state = HomeScreenState.loading);
    // mock: 1초 뒤 normal 상태로 복귀
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _state = HomeScreenState.normal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'IRIS',
          style: AppTypography.h2.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case HomeScreenState.loading:
        return const Center(child: LoadingIndicator());
      case HomeScreenState.empty:
        return _buildEmptyState();
      case HomeScreenState.normal:
        return _buildNormalState();
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        _GreetingHeader(companyName: _mockCompanyName),
        SizedBox(height: AppSpacing.lg),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  '매칭된 공고가 없습니다.\n기업 정보를 등록하고 AI 매칭을 시작해보세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalState() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _GreetingHeader(companyName: _mockCompanyName),
        ),
        const SizedBox(height: AppSpacing.md),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _MatchSummaryCard(matchCount: _mockMatchCount),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _DeadlineList(items: _mockDeadlineItems),
        const SizedBox(height: AppSpacing.sectionGap),
        _TopMatches(items: _mockTopMatches),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// 인사 헤더: "안녕하세요, {회사명}님!"
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요, $companyName님!',
          style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '오늘도 좋은 사업 기회를 찾아드릴게요.',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// 적합 공고 요약 카드
class _MatchSummaryCard extends StatelessWidget {
  const _MatchSummaryCard({required this.matchCount});

  final int matchCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '적합 공고',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$matchCount',
                        style: AppTypography.h1.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '건',
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'AI가 분석한 최적 공고를 확인하세요',
                  style: AppTypography.label.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.search_outlined,
            color: Colors.white,
            size: 48,
          ),
        ],
      ),
    );
  }
}

/// 마감 임박 공고 리스트 섹션
class _DeadlineList extends StatelessWidget {
  const _DeadlineList({required this.items});

  final List<_AnnouncementSummary> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '마감 임박',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.xs,
            ),
            child: _DeadlineItem(item: item),
          ),
        ),
      ],
    );
  }
}

/// 마감 임박 개별 공고 아이템
class _DeadlineItem extends StatelessWidget {
  const _DeadlineItem({required this.item});

  final _AnnouncementSummary item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          DdayBadge(deadline: item.deadline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.organization,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MatchScoreGauge(score: item.score, size: MatchScoreSize.sm),
        ],
      ),
    );
  }
}

/// 상위 매칭 섹션
class _TopMatches extends StatelessWidget {
  const _TopMatches({required this.items});

  final List<_AnnouncementSummary> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              const Icon(
                Icons.star_outline,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '상위 매칭',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.xs,
            ),
            child: MatchCard(
              title: item.title,
              score: item.score,
              deadline: item.deadline,
              organization: item.organization,
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}
