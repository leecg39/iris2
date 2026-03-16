// @TASK P4-S3-T1 - 설정 화면
// @SPEC docs/planning/03-user-flow.md#설정
// @TEST test/features/settings/settings_test.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

/// 검색 주기 옵션
enum SearchInterval {
  daily('매일'),
  twiceAWeek('주 2회'),
  weekly('매주');

  const SearchInterval(this.label);
  final String label;
}

/// 설정 화면
///
/// - ProfileSection: 기업 프로필 요약 + "편집" 버튼 → /profile/edit
/// - NotificationToggle: 알림 ON/OFF SwitchListTile
/// - SearchInterval: 검색 주기 DropdownButton
/// - AppInfo: 앱 버전 정보
/// - ResetButton: "데이터 초기화" 위험 버튼 (빨간색, 확인 다이얼로그)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  SearchInterval _searchInterval = SearchInterval.daily;

  void _toggleNotification(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
  }

  void _onIntervalChanged(SearchInterval? value) {
    if (value == null) return;
    setState(() {
      _searchInterval = value;
    });
  }

  Future<void> _onResetPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text(
          '모든 데이터를 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 초기화 로직 placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터가 초기화되었습니다.')),
      );
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
          '설정',
          style: AppTypography.h2.copyWith(color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // 프로필 섹션
          _ProfileSection(),
          const SizedBox(height: AppSpacing.sm),

          // 알림 설정 섹션
          _SectionCard(
            children: [
              _NotificationToggle(
                value: _notificationsEnabled,
                onChanged: _toggleNotification,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 검색 주기 섹션
          _SectionCard(
            children: [
              _SearchIntervalTile(
                value: _searchInterval,
                onChanged: _onIntervalChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 앱 정보 섹션
          const _SectionCard(
            children: [_AppInfoTile()],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 데이터 초기화 버튼
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _ResetButton(onPressed: _onResetPressed),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// 섹션 카드 컨테이너
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

/// 기업 프로필 요약 섹션
class _ProfileSection extends StatelessWidget {
  // mock 데이터
  static const _companyName = '(주)테크스타트';
  static const _businessNumber = '123-45-67890';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 기업 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 회사명 + 사업자번호
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyName,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _businessNumber,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 편집 버튼
          TextButton(
            key: const Key('profile-edit-button'),
            onPressed: () => context.go('/profile/edit'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
            child: Text(
              '편집',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 알림 ON/OFF 토글
class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: const Key('notification-toggle'),
      title: Text(
        '새 공고 알림',
        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        '적합한 공고가 등록되면 알림을 보내드립니다',
        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

/// 검색 주기 드롭다운 타일
class _SearchIntervalTile extends StatelessWidget {
  const _SearchIntervalTile({
    required this.value,
    required this.onChanged,
  });

  final SearchInterval value;
  final ValueChanged<SearchInterval?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '검색 주기',
        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      ),
      trailing: DropdownButton<SearchInterval>(
        key: const Key('search-interval-dropdown'),
        value: value,
        underline: const SizedBox.shrink(),
        items: SearchInterval.values
            .map(
              (interval) => DropdownMenuItem<SearchInterval>(
                value: interval,
                child: Text(
                  interval.label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// 앱 버전 정보 타일
class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile();

  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '앱 버전',
        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      ),
      trailing: Text(
        'v$_appVersion',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// 데이터 초기화 버튼 (빨간색 위험 버튼)
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        key: const Key('reset-button'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '데이터 초기화',
          style: AppTypography.body.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
