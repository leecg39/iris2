// @TASK P2-S2-T1 - 사업자번호 입력 화면 UI 구현
// @SPEC docs/planning/03-user-flow.md#사업자번호-입력
// @TEST test/features/profile/register_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';

/// 사업자번호 입력 화면 상태 enum
enum RegisterStatus {
  initial,
  loading,
  error,
  success,
}

/// 사업자번호 입력 화면
///
/// 사용자가 사업자번호(10자리)를 입력하면 자동 하이픈 포맷(000-00-00000)으로
/// 표시하고, "조회하기" 버튼으로 기업 정보를 조회합니다.
/// 조회 성공 시 /profile/edit 화면으로 이동합니다.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  RegisterStatus _status = RegisterStatus.initial;
  String _errorMessage = '';

  /// 순수 숫자만 추출 (하이픈 제외)
  String get _rawDigits => _controller.text.replaceAll('-', '');

  /// 버튼 활성화 여부: 숫자 10자리 완성 시
  bool get _isButtonEnabled => _rawDigits.length == 10;

  /// 테스트용: 로딩 상태 직접 설정
  @visibleForTesting
  void setLoadingForTest() {
    setState(() {
      _status = RegisterStatus.loading;
    });
  }

  /// 테스트용: 에러 상태 직접 설정
  @visibleForTesting
  void setErrorForTest(String message) {
    setState(() {
      _status = RegisterStatus.error;
      _errorMessage = message;
    });
  }

  /// 테스트용: 성공 상태 직접 트리거 (라우팅 포함)
  @visibleForTesting
  void simulateSuccessForTest() {
    setState(() {
      _status = RegisterStatus.success;
    });
    context.go('/profile/edit');
  }

  /// 사업자번호 입력값을 000-00-00000 형식으로 변환
  String _formatBusinessNumber(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 5)}-${digits.substring(5)}';
  }

  /// 조회하기 버튼 핸들러 (mock 구현)
  Future<void> _onLookup() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _status = RegisterStatus.loading;
      _errorMessage = '';
    });

    // API 연동은 추후 구현 (현재 mock: 1초 딜레이 후 성공)
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // 성공 처리 → /profile/edit 이동
    setState(() {
      _status = RegisterStatus.success;
    });
    context.go('/profile/edit');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _status == RegisterStatus.loading;
    final hasError = _status == RegisterStatus.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '사업자번호 입력',
                style: AppTypography.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 설명 텍스트
              Text(
                '사업자번호를 입력하면 기업 정보를 자동으로 가져옵니다',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 사업자번호 입력 필드
              _BusinessNumberField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
                formatNumber: _formatBusinessNumber,
              ),

              // 에러 메시지
              if (hasError) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  key: const Key('error-message'),
                  _errorMessage,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // 조회하기 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('lookup-button'),
                  onPressed: _isButtonEnabled && !isLoading ? _onLookup : null,
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
                          '조회하기',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사업자번호 입력 필드 위젯
///
/// 숫자만 입력 가능하며 자동으로 000-00-00000 포맷을 적용합니다.
/// 최대 입력 길이는 포맷 적용 후 12자(숫자 10 + 하이픈 2)입니다.
class _BusinessNumberField extends StatelessWidget {
  const _BusinessNumberField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.formatNumber,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String Function(String digits) formatNumber;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('business-number-field'),
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      enabled: enabled,
      maxLength: 12, // 숫자 10 + 하이픈 2
      inputFormatters: [
        _BusinessNumberFormatter(formatNumber),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '000-00-00000',
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textSecondary.withAlpha(128),
        ),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withAlpha(77),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      style: AppTypography.body.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// 사업자번호 자동 포맷 TextInputFormatter
///
/// 숫자만 허용하고 000-00-00000 형식으로 자동 포맷합니다.
class _BusinessNumberFormatter extends TextInputFormatter {
  const _BusinessNumberFormatter(this.formatNumber);

  final String Function(String digits) formatNumber;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 추출
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 최대 10자리
    final limitedDigits = digits.length > 10 ? digits.substring(0, 10) : digits;

    // 포맷 적용
    final formatted = formatNumber(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
