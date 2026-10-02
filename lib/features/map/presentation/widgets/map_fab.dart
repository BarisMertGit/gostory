// path: lib/features/map/presentation/widgets/map_fab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Floating action button row on the map screen.
///
/// Contains:
/// - Back to camera button (left)
/// - Refresh/locate button (right)
///
/// Both buttons use a glassmorphism circle style.
class MapActionBar extends StatelessWidget {
  const MapActionBar({
    required this.onCameraPressed,
    required this.onRefreshPressed,
    super.key,
  });

  final VoidCallback onCameraPressed;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _GlassCircleButton(
          icon: Icons.arrow_back_ios_new,
          tooltip: 'Kameraya dön',
          onPressed: onCameraPressed,
        ),
        _GlassCircleButton(
          icon: Icons.my_location_outlined,
          tooltip: 'Konumumu bul',
          onPressed: onRefreshPressed,
        ),
      ],
    );
  }
}

/// A circular glassmorphism icon button for the map screen.
class _GlassCircleButton extends StatefulWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_GlassCircleButton> createState() => _GlassCircleButtonState();
}

class _GlassCircleButtonState extends State<_GlassCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          curve: Curves.easeOut,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceVariant.withValues(alpha: 0.92)
                : AppColors.surface.withValues(alpha: 0.78),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.7),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: _pressed ? AppColors.textPrimary : AppColors.textSecondary,
            size: 17,
          ),
        ),
      ),
    );
  }
}
