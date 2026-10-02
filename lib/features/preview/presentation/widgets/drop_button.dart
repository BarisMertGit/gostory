// path: lib/features/preview/presentation/widgets/drop_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart' as app_type;
import '../../../../core/constants/app_constants.dart';

/// The "BIRAK" (drop) button.
///
/// Appears on the preview screen to submit a memory.
/// Full-width, dark, cinematic. Subtle shimmer on enabled state.
/// Shows a loading indicator during submission.
class DropButton extends StatefulWidget {
  const DropButton({
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  State<DropButton> createState() => _DropButtonState();
}

class _DropButtonState extends State<DropButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.enabled || widget.isLoading) return;
          _pressController.forward();
        },
        onTapUp: (_) {
          if (!widget.enabled || widget.isLoading) return;
          _pressController.reverse();
          HapticFeedback.mediumImpact();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (context, child) {
            return Transform.scale(scale: _pressScale.value, child: child);
          },
          child: AnimatedContainer(
            duration: AppConstants.animNormal,
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.enabled && !widget.isLoading
                  ? AppColors.surfaceVariant
                  : Colors.transparent,
              border: Border.all(
                color: widget.enabled
                    ? AppColors.textTertiary.withValues(alpha: 0.6)
                    : AppColors.divider,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : AnimatedDefaultTextStyle(
                      duration: AppConstants.animNormal,
                      style: app_type.AppTypography.button.copyWith(
                        fontSize: 13,
                        letterSpacing: 3.0,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                      child: const Text('B I R A K'),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
