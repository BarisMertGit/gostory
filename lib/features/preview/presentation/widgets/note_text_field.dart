// path: lib/features/preview/presentation/widgets/note_text_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart' as app_type;
import '../../../../core/constants/app_constants.dart';

/// The memory note input field.
///
/// - Max 100 characters
/// - Character counter shown
/// - Multiline support
/// - Minimal styling, blends with dark background
/// - Hint text in Turkish
class NoteTextField extends StatelessWidget {
  const NoteTextField({
    required this.controller,
    required this.onChanged,
    required this.characterCount,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int characterCount;

  @override
  Widget build(BuildContext context) {
    final remaining = AppConstants.maxNoteLength - characterCount;
    final isNearLimit = remaining <= 20;
    final isAtLimit = remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: AppConstants.maxNoteLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          style: app_type.AppTypography.noteInput,
          cursorColor: AppColors.textSecondary,
          cursorWidth: 1.0,
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) =>
              null, // We build our own counter below.
          decoration: const InputDecoration(
            hintText: 'Bir not bırak...',
            hintStyle: app_type.AppTypography.hint,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.noteFieldPadding,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        // Character counter.
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.noteFieldPadding,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: app_type.AppTypography.counter.copyWith(
              color: isAtLimit
                  ? AppColors.error
                  : isNearLimit
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
            ),
            child: Text('$characterCount/${AppConstants.maxNoteLength}'),
          ),
        ),
      ],
    );
  }
}
