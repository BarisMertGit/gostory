import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';

/// Native button semantics and keyboard activation, with a restrained press state.
class ShutterButton extends StatelessWidget {
  const ShutterButton({
    required this.onPressed,
    this.enabled = true,
    super.key,
  });
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Fotoğraf çek',
        child: SizedBox.square(
          dimension: 76,
          child: FilledButton(
            onPressed: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed();
                  }
                : null,
            style: FilledButton.styleFrom(
              animationDuration: AppMotion.duration(context),
              padding: const EdgeInsets.all(5),
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.peach, width: 2),
              ),
            ),
            child: Semantics(
              label: enabled ? 'Fotoğraf çek' : 'Fotoğraf çekiliyor',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? AppColors.peach : AppColors.surfaceVariant,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
}
