// @TASK P1-S0-T3 - 태그 입력 위젯
// @SPEC docs/planning/05-design-system.md#공통-위젯
// @TEST test/widgets/tag_input_test.dart

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing.dart';

/// Chip 형태 태그 입력 위젯
///
/// - 기존 태그를 Chip으로 표시 + 삭제(X) 버튼
/// - TextField로 새 태그 추가 (Enter/완료로 확정)
/// - 빈 문자열은 태그로 추가되지 않음
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.placeholder,
  });

  /// 현재 태그 목록
  final List<String> tags;

  /// 태그 목록 변경 시 콜백
  final void Function(List<String> tags) onTagsChanged;

  /// TextField 힌트 텍스트 (optional)
  final String? placeholder;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (widget.tags.contains(trimmed)) {
      _controller.clear();
      return;
    }
    final newTags = List<String>.from(widget.tags)..add(trimmed);
    widget.onTagsChanged(newTags);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        // 기존 태그 Chip 목록
        ...widget.tags.map(
          (tag) => Chip(
            label: Text(
              tag,
              style: AppTypography.label.copyWith(
                color: AppColors.primary,
              ),
            ),
            backgroundColor: AppColors.primary.withOpacity(0.08),
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            deleteIcon: const Icon(
              Icons.close,
              size: 16.0,
            ),
            onDeleted: () => _removeTag(tag),
          ),
        ),
        // 새 태그 입력 TextField
        SizedBox(
          width: 160.0,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            style: AppTypography.caption,
            textInputAction: TextInputAction.done,
            onSubmitted: _addTag,
          ),
        ),
      ],
    );
  }
}
