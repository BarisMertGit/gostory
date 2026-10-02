// path: lib/features/camera/presentation/widgets/shutter_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';

/// The camera shutter button.
///
/// A circular button with an outer ring and inner fill.
/// Provides haptic feedback on press.
/// Animated press effect — subtle, not flashy.
class ShutterButton extends StatefulWidget {
  const ShutterButton({
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails _) async {
    if (!widget.enabled) return;
    await HapticFeedback.lightImpact();
    _animController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _animController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _ShutterPainter(enabled: widget.enabled),
          ),
        ),
      ),
    );
  }
}

class _ShutterPainter extends CustomPainter {
  _ShutterPainter({required this.enabled});

  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 4.0;
    final fillRadius = innerRadius - 3.0;

    // Outer ring.
    final outerPaint = Paint()
      ..color = enabled ? AppColors.shutterOuter : AppColors.textTertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, outerRadius - 1.5, outerPaint);

    // Inner fill.
    final fillPaint = Paint()
      ..color = enabled ? AppColors.shutterInner : AppColors.textTertiary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, fillRadius, fillPaint);
  }

  @override
  bool shouldRepaint(_ShutterPainter oldDelegate) =>
      enabled != oldDelegate.enabled;
}
