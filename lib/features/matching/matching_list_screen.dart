// @TASK P3-S2-T1 - 매칭 목록 화면
// @SPEC docs/planning/03-user-flow.md#매칭-목록
// @TEST test/features/matching/matching_list_test.dart

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../widgets/match_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

/// 매칭 목록 화면의 상태
enum MatchingListState {
  /// 로딩 중
  loading,

  /// 데이터 없음 (검색 결과 없음 포함)
  empty,

  /// 데이터 있음
  normal,

  /// 필터 적용됨
  filtered,
}

/// 필터 옵션
enum _FilterOption {
  all('전체'),
  active('진행중'),
  closed('마감');

  const _FilterOption(this.label);
  final String label;
}

/// 정렬 옵션
enum _SortOption {
  score('적합도순'),
  deadline('마감일순'),
  latest('최신순');

  const _SortOption(this.label);
  final String label;
}

/// 공고 데이터 모델 (mock)
class _Announcement {
  const _Announcement({
    required this.id,
    required this.title,
    required this.score,
    required this.deadline,
    required this.organization,
    this.isActive = true,
  });

  final String id;
  final String title;
  final int score;
  final DateTime deadline;
  final String organization;
  final bool isActive;
}

/// 샘플 목록 데이터
final _mockAnnouncements = [
  _Announcement(
    id: '1',
    title: '2024년 중소기업 기술혁신 R&D 지원사업',
    score: 92,
    deadline: DateTime.now().add(const Duration(days: 15)),
    organization: '중소벤처기업부',
  ),
  _Announcement(
    id: '2',
    title: '디지털 전환 지원사업 (DX바우처)',
    score: 88,
    deadline: DateTime.now().add(const Duration(days: 20)),
    organization: '과학기술정보통신부',
  ),
  _Announcement(
    id: '3',
    title: '소재·부품·장비 강소기업 100 육성사업',
    score: 85,
    deadline: DateTime.now().add(const Duration(days: 30)),
    organization: '산업통상자원부',
  ),
  _Announcement(
    id: '4',
    title: '스마트제조 혁신 바우처 지원사업',
    score: 78,
    deadline: DateTime.now().add(const Duration(days: 5)),
    organization: '산업통상자원부',
  ),
  _Announcement(
    id: '5',
    title: '창업성장 기술개발 사업',
    score: 65,
    deadline: DateTime.now().subtract(const Duration(days: 3)),
    organization: '중소벤처기업부',
    isActive: false,
  ),
  _Announcement(
    id: '6',
    title: 'AI·빅데이터 활용 제조혁신 지원사업',
    score: 82,
    deadline: DateTime.now().add(const Duration(days: 45)),
    organization: '과학기술정보통신부',
  ),
];

/// 매칭 목록 화면
///
/// - SearchFilterBar: 검색 TextField + 필터 칩
/// - MatchCardList: MatchCard 리스트
/// - EmptyState: 검색 결과 없음
/// - 정렬: 적합도순/마감일순/최신순
class MatchingListScreen extends StatefulWidget {
  const MatchingListScreen({
    super.key,
    this.initialState = MatchingListState.normal,
  });

  final MatchingListState initialState;

  @override
  State<MatchingListScreen> createState() => _MatchingListScreenState();
}

class _MatchingListScreenState extends State<MatchingListScreen> {
  late MatchingListState _state;
  final TextEditingController _searchController = TextEditingController();
  _FilterOption _selectedFilter = _FilterOption.all;
  _SortOption _selectedSort = _SortOption.score;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<_Announcement> get _filteredAnnouncements {
    var items = List<_Announcement>.from(_mockAnnouncements);

    // 필터 적용
    if (_selectedFilter == _FilterOption.active) {
      items = items.where((e) => e.isActive).toList();
    } else if (_selectedFilter == _FilterOption.closed) {
      items = items.where((e) => !e.isActive).toList();
    }

    // 검색어 적용
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items
          .where(
            (e) =>
                e.title.toLowerCase().contains(query) ||
                e.organization.toLowerCase().contains(query),
          )
          .toList();
    }

    // 정렬 적용
    switch (_selectedSort) {
      case _SortOption.score:
        items.sort((a, b) => b.score.compareTo(a.score));
      case _SortOption.deadline:
        items.sort((a, b) => a.deadline.compareTo(b.deadline));
      case _SortOption.latest:
        items.sort((a, b) => b.id.compareTo(a.id));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'AI 공고 매칭',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_state == MatchingListState.loading) {
      return const Center(child: LoadingIndicator());
    }

    if (_state == MatchingListState.empty) {
      return Column(
        children: [
          _SearchFilterBar(
            controller: _searchController,
            selectedFilter: _selectedFilter,
            selectedSort: _selectedSort,
            onFilterChanged: (filter) =>
                setState(() => _selectedFilter = filter),
            onSortChanged: (sort) => setState(() => _selectedSort = sort),
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.search_off_outlined,
              message: '검색 결과가 없습니다.\n다른 검색어나 필터를 사용해보세요.',
            ),
          ),
        ],
      );
    }

    final items = _filteredAnnouncements;

    return Column(
      children: [
        _SearchFilterBar(
          controller: _searchController,
          selectedFilter: _selectedFilter,
          selectedSort: _selectedSort,
          onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
          onSortChanged: (sort) => setState(() => _selectedSort = sort),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_outlined,
                  message: '검색 결과가 없습니다.\n다른 검색어나 필터를 사용해보세요.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: MatchCard(
                        title: item.title,
                        score: item.score,
                        deadline: item.deadline,
                        organization: item.organization,
                        onTap: () {},
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// 검색 + 필터 바
class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar({
    required this.controller,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final _FilterOption selectedFilter;
  final _SortOption selectedSort;
  final ValueChanged<_FilterOption> onFilterChanged;
  final ValueChanged<_SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // 검색 TextField
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '공고명 또는 기관명 검색',
              hintStyle: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 필터 칩 + 정렬
          Row(
            children: [
              // 필터 칩
              ..._FilterOption.values.map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _FilterChip(
                    label: filter.label,
                    isSelected: selectedFilter == filter,
                    onTap: () => onFilterChanged(filter),
                  ),
                ),
              ),
              const Spacer(),
              // 정렬 드롭다운
              _SortDropdown(
                selected: selectedSort,
                onChanged: onSortChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 필터 칩 위젯
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 정렬 드롭다운
class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.selected,
    required this.onChanged,
  });

  final _SortOption selected;
  final ValueChanged<_SortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<_SortOption>(
        value: selected,
        isDense: true,
        style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        items: _SortOption.values.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option.label),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
