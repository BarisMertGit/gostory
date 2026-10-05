import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../shared/widgets/app_components.dart';

class LeaveMemoryButton extends StatelessWidget {
  const LeaveMemoryButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PrimaryAction(
        onPressed: onPressed,
        icon: Icons.add,
        label: 'Anı bırak',
      );
}

class DiscoveryControls extends StatelessWidget {
  const DiscoveryControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocate,
    this.compact = false,
  });
  final VoidCallback onZoomIn, onZoomOut, onLocate;
  final bool compact;

  Widget _button(IconData icon, String label, VoidCallback action) =>
      IconButton(
        tooltip: label,
        onPressed: action,
        icon: Icon(icon, size: 21),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.touchTarget),
          foregroundColor: AppColors.textPrimary,
        ),
      );

  Widget _surface(Widget child) => Material(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: const BorderSide(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final zoomIn = _button(Icons.add, 'Yakınlaştır', onZoomIn);
    final zoomOut = _button(Icons.remove, 'Uzaklaştır', onZoomOut);
    final locate = _button(Icons.my_location, 'Konumuma dön', onLocate);
    return compact
        ? _surface(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [zoomIn, zoomOut, locate],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _surface(
                Column(
                  children: [
                    zoomIn,
                    const SizedBox(width: 24, child: Divider(height: 1)),
                    zoomOut,
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _surface(locate),
            ],
          );
  }
}
