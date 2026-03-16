// @TASK P4-S2-T1 - 전문가 상담 폼 화면
// @SPEC docs/planning/03-user-flow.md#전문가-상담
// @TEST test/features/consultation/consult_form_test.dart

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

/// 자동채움 정보 (공고 기반 read-only 데이터)
class _ConsultAutoFillData {
  const _ConsultAutoFillData({
    required this.companyName,
    required this.businessNumber,
    required this.announcementTitle,
    required this.score,
  });

  final String companyName;
  final String businessNumber;
  final String announcementTitle;
  final int score;
}

/// mock 자동채움 데이터
const _mockAutoFill = _ConsultAutoFillData(
  companyName: '(주)테크스타트',
  businessNumber: '123-45-67890',
  announcementTitle: '2024년 중소기업 기술혁신 R&D 지원사업',
  score: 92,
);

/// 전문가 상담 폼 화면
///
/// - AutoFilledInfo: 자동채움 섹션 (회사명, 사업자번호, 공고명, 적합도) - 읽기전용
/// - ConsultForm: 이름 / 이메일 / 연락처 / 문의내용 입력 폼
/// - SubmitButton: "상담 신청" ElevatedButton
/// - SuccessDialog: 신청 완료 다이얼로그
class ConsultFormScreen extends StatefulWidget {
  const ConsultFormScreen({
    super.key,
    required this.announcementId,
  });

  final String announcementId;

  @override
  State<ConsultFormScreen> createState() => ConsultFormScreenState();
}

class ConsultFormScreenState extends State<ConsultFormScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isSubmitEnabled =>
      _nameController.text.trim().isNotEmpty && !_isSubmitting;

  // ── 테스트 전용 헬퍼 ──────────────────────────────────────

  /// 테스트용: submitting 상태 직접 설정
  @visibleForTesting
  void setSubmittingForTest() {
    setState(() {
      _isSubmitting = true;
    });
  }

  /// 테스트용: 에러 상태 직접 설정
  @visibleForTesting
  void setErrorForTest(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  /// 테스트용: SuccessDialog 직접 표시
  @visibleForTesting
  Future<void> showSuccessDialogForTest(BuildContext ctx) async {
    await _showSuccessDialog(ctx);
  }

  // ── 내부 메서드 ───────────────────────────────────────────

  Future<void> _showSuccessDialog(BuildContext ctx) async {
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('신청 완료'),
        content: const Text(
          '신청이 접수되었습니다. 확인 이메일을 보내드렸습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // API 연동 placeholder: 1초 딜레이 후 성공 처리
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    await _showSuccessDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          '전문가 상담 신청',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 자동채움 섹션
                  const _AutoFilledInfo(data: _mockAutoFill),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // 입력 폼
                  _ConsultForm(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    messageController: _messageController,
                    onChanged: () => setState(() {}),
                  ),

                  // 에러 메시지
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.label.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // 하단 고정 제출 버튼
          _SubmitButton(
            isSubmitting: _isSubmitting,
            isEnabled: _isSubmitEnabled,
            onSubmit: _onSubmit,
          ),
        ],
      ),
    );
  }
}

/// 자동채움 정보 섹션 (읽기전용 카드)
class _AutoFilledInfo extends StatelessWidget {
  const _AutoFilledInfo({required this.data});

  final _ConsultAutoFillData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '신청 정보',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.15)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _InfoRow(label: '회사명', value: data.companyName),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(label: '사업자번호', value: data.businessNumber),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(label: '공고명', value: data.announcementTitle),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _InfoRow(label: '적합도', value: '${data.score}점'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 라벨 + 값 행
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
            width: 64,
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

/// 사용자 입력 폼
class _ConsultForm extends StatelessWidget {
  const _ConsultForm({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.messageController,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '연락처 정보',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 이름
        TextField(
          key: const Key('consult-name-field'),
          controller: nameController,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: '이름 *',
            hintText: '이름을 입력하세요',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),

        // 이메일
        TextField(
          key: const Key('consult-email-field'),
          controller: emailController,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'example@company.com',
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),

        // 연락처
        TextField(
          key: const Key('consult-phone-field'),
          controller: phoneController,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: '연락처',
            hintText: '010-0000-0000',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),

        // 문의내용
        TextField(
          key: const Key('consult-message-field'),
          controller: messageController,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: '문의 내용',
            hintText: '문의하실 내용을 자유롭게 작성해 주세요',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          maxLength: 1000,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

/// 하단 고정 제출 버튼
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.isEnabled,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final bool isEnabled;
  final VoidCallback onSubmit;

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
            key: const Key('consult-submit-button'),
            onPressed: isEnabled ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.primary.withAlpha(77),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSubmitting
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
                    '상담 신청',
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
