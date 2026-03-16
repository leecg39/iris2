// @TASK P2-S3-T1 - 기업 프로필 설정 화면 UI 구현
// @SPEC docs/planning/03-user-flow.md#프로필-설정
// @TEST test/features/profile/profile_edit_test.dart

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../widgets/tag_input.dart';

/// 공공 API에서 가져온 기업 정보 데이터 모델 (읽기 전용)
class ProfileCompanyData {
  const ProfileCompanyData({
    required this.companyName,
    required this.ceoName,
    required this.industry,
    required this.revenue,
    required this.employeeCount,
    required this.address,
  });

  /// 회사명
  final String companyName;

  /// 대표자명
  final String ceoName;

  /// 업종
  final String industry;

  /// 매출액 (원 단위)
  final int revenue;

  /// 직원수
  final int employeeCount;

  /// 주소
  final String address;
}

/// 연구분야 옵션 목록
const _researchFieldOptions = ['ICT', 'BT', 'NT', 'ET', 'ST', '기타'];

/// 매출액을 억원 단위로 포맷
///
/// 예: 5000000000 → "50억원"
String _formatRevenue(int revenue) {
  final eok = revenue ~/ 100000000;
  return '$eok억원';
}

/// 기업 프로필 설정 화면
///
/// - 자동 채움 섹션 (읽기 전용): 회사명, 대표자, 업종, 매출액, 직원수, 주소
/// - 편집 가능 섹션: 연구분야 멀티셀렉트, 기술키워드 TagInput
/// - 하단 고정 저장 버튼
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.companyData,
  });

  /// 공공 API에서 받아온 기업 정보
  final ProfileCompanyData companyData;

  @override
  State<ProfileEditScreen> createState() => ProfileEditScreenState();
}

class ProfileEditScreenState extends State<ProfileEditScreen> {
  bool _isLoading = false;
  final Set<String> _selectedResearchFields = {};
  List<String> _techKeywords = [];

  /// 테스트용: 로딩 상태 직접 설정
  @visibleForTesting
  void setLoadingForTest() {
    setState(() {
      _isLoading = true;
    });
  }

  void _toggleResearchField(String field) {
    setState(() {
      if (_selectedResearchFields.contains(field)) {
        _selectedResearchFields.remove(field);
      } else {
        _selectedResearchFields.add(field);
      }
    });
  }

  Future<void> _onSave() async {
    setState(() {
      _isLoading = true;
    });

    // API 연동은 추후 구현 (현재 mock: 1초 딜레이 후 완료)
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('프로필 설정'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 자동 채움 섹션
                  _AutoFillSection(companyData: widget.companyData),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // 연구분야 섹션
                  const _SectionHeader(title: '연구분야'),
                  const SizedBox(height: AppSpacing.sm),
                  _ResearchFieldChips(
                    selectedFields: _selectedResearchFields,
                    onToggle: _toggleResearchField,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // 기술키워드 섹션
                  const _SectionHeader(title: '기술키워드'),
                  const SizedBox(height: AppSpacing.sm),
                  TagInput(
                    key: const Key('technology-keywords-input'),
                    tags: _techKeywords,
                    onTagsChanged: (tags) {
                      setState(() {
                        _techKeywords = tags;
                      });
                    },
                    placeholder: '키워드 입력 후 Enter',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // 하단 고정 저장 버튼
          _SaveButton(
            isLoading: _isLoading,
            onSave: _onSave,
          ),
        ],
      ),
    );
  }
}

/// 자동 채움 섹션 (읽기 전용 기업 정보)
class _AutoFillSection extends StatelessWidget {
  const _AutoFillSection({required this.companyData});

  final ProfileCompanyData companyData;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            _InfoRow(label: '회사명', value: companyData.companyName),
            _divider(),
            _InfoRow(label: '대표자', value: companyData.ceoName),
            _divider(),
            _InfoRow(label: '업종', value: companyData.industry),
            _divider(),
            _InfoRow(
              label: '매출액',
              value: _formatRevenue(companyData.revenue),
            ),
            _divider(),
            _InfoRow(
              label: '직원수',
              value: '${companyData.employeeCount}명',
            ),
            _divider(),
            _InfoRow(label: '주소', value: companyData.address),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}

/// 정보 행 (라벨 + 값)
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 연구분야 멀티셀렉트 Chip 그룹
class _ResearchFieldChips extends StatelessWidget {
  const _ResearchFieldChips({
    required this.selectedFields,
    required this.onToggle,
  });

  final Set<String> selectedFields;
  final void Function(String field) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _researchFieldOptions.map((field) {
        final isSelected = selectedFields.contains(field);
        return FilterChip(
          label: Text(field),
          selected: isSelected,
          onSelected: (_) => onToggle(field),
          selectedColor: AppColors.primary.withOpacity(0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: AppTypography.label.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }
}

/// 하단 고정 저장 버튼
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isLoading,
    required this.onSave,
  });

  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.12),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            key: const Key('save-button'),
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.primary.withAlpha(77),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  )
                : Text(
                    '저장',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
