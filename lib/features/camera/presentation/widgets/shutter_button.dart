import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../shared/widgets/motion_widgets.dart';

class ShutterButton extends StatefulWidget {
  const ShutterButton(
      {required this.onPressed, this.enabled = true, super.key,});
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with SingleTickerProviderStateMixin {
  late final _breath =
      AnimationController(vsync: this, duration: AppMotion.entrance);
  bool _introduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
      _breath.value = 0;
    } else if (!_introduced && widget.enabled) {
      _introduced = true;
      _breathe();
    }
  }

  Future<void> _breathe() async {
    await _breath.forward();
    if (mounted) await _breath.reverse();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Fotoğraf çek',
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) =>
              Transform.scale(scale: 1 + _breath.value * .025, child: child),
          child: PressFeedback(
            enabled: widget.enabled,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.peachLight,
                  AppColors.textPrimary,
                  AppColors.peach,
                ],),
                boxShadow: [
                  BoxShadow(color: AppColors.peachGlow, blurRadius: 16),
                ],
              ),
              child: FilledButton(
                onPressed: widget.enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onPressed();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  animationDuration: AppMotion.duration(context),
                  padding: const EdgeInsets.all(5),
                  backgroundColor: AppColors.surface,
                  shape: const CircleBorder(),
                ),
                child: Semantics(
                  label: widget.enabled ? 'Fotoğraf çek' : 'Fotoğraf çekiliyor',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.enabled
                          ? AppColors.peach
                          : AppColors.surfaceVariant,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
