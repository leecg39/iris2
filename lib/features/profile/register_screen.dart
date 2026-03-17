// @TASK P2-S2-T1 - 사업자번호 입력 화면 UI 구현
// @SPEC docs/planning/03-user-flow.md#사업자번호-입력
// @TEST test/features/profile/register_test.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
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
/// 사업자번호(10자리)를 입력하면 자동 하이픈 포맷(000-00-00000)으로
/// 표시하고, "조회하기" 버튼으로 공공데이터 API를 통해 기업 정보를 조회합니다.
/// 조회 성공 시 법인명, 대표자, 주소를 화면에 표시하고
/// "다음" 버튼으로 /profile/edit 화면으로 이동합니다.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.apiClient});

  /// 테스트용 API 클라이언트 주입
  final ApiClient? apiClient;

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  RegisterStatus _status = RegisterStatus.initial;
  String _errorMessage = '';

  /// 조회된 기업 정보
  Map<String, dynamic>? _companyData;

  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
  }

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
      _companyData = {
        'company_name': '테스트기업',
        'ceo_name': '홍길동',
        'address': '서울시 강남구',
      };
    });
    context.go('/profile/edit', extra: _companyData);
  }

  /// 사업자번호 입력값을 000-00-00000 형식으로 변환
  String _formatBusinessNumber(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 5) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 5)}-${digits.substring(5)}';
  }

  /// 조회하기 버튼 핸들러 - 백엔드 API 호출
  Future<void> _onLookup() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _status = RegisterStatus.loading;
      _errorMessage = '';
      _companyData = null;
    });

    try {
      final data = await _apiClient.lookupCompany(_rawDigits);

      if (!mounted) return;

      setState(() {
        _status = RegisterStatus.success;
        _companyData = data;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      String message;
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final detail = e.response!.data is Map
            ? e.response!.data['detail'] ?? ''
            : '';

        if (statusCode == 400) {
          message = '잘못된 사업자번호입니다';
        } else if (statusCode == 404) {
          message = detail.isNotEmpty
              ? detail.toString()
              : '해당 사업자번호의 기업을 찾을 수 없습니다';
        } else {
          message = '서버 오류가 발생했습니다 ($statusCode)';
        }
      } else {
        message = '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.';
      }

      setState(() {
        _status = RegisterStatus.error;
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = RegisterStatus.error;
        _errorMessage = '알 수 없는 오류가 발생했습니다';
      });
    }
  }

  /// "다음" 버튼 - profile/edit로 이동
  void _onNext() {
    if (_companyData == null) return;
    context.go('/profile/edit', extra: _companyData);
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
    final hasResult = _status == RegisterStatus.success && _companyData != null;

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
                onChanged: (_) => setState(() {
                  // 입력 변경 시 이전 결과 초기화
                  if (_status == RegisterStatus.success) {
                    _status = RegisterStatus.initial;
                    _companyData = null;
                  }
                }),
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
                  onPressed: _isButtonEnabled && !isLoading && !hasResult
                      ? _onLookup
                      : null,
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

              // 조회 결과 카드
              if (hasResult) ...[
                const SizedBox(height: AppSpacing.xl),
                _CompanyInfoCard(companyData: _companyData!),
                const Spacer(),
                // 다음 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('next-button'),
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '다음',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 조회된 기업 정보 카드
class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard({required this.companyData});

  final Map<String, dynamic> companyData;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('company-info-card'),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withAlpha(51)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '기업 정보 조회 완료',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // 법인명
            _InfoRow(
              label: '법인명',
              value: companyData['company_name']?.toString() ?? '-',
            ),
            const SizedBox(height: AppSpacing.sm),

            // 대표자
            _InfoRow(
              label: '대표자',
              value: companyData['ceo_name']?.toString() ?? '-',
            ),
            const SizedBox(height: AppSpacing.sm),

            // 주소
            _InfoRow(
              label: '주소',
              value: companyData['address']?.toString() ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}

/// 정보 행 (라벨 + 값)
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
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
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
