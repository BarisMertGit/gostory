import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/design.dart';

/// Keeps the child's native focus, keyboard and button semantics.
class PressFeedback extends StatefulWidget {
  const PressFeedback({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Listener(
          onPointerDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: widget.enabled && _pressed ? .97 : 1,
            duration: AppMotion.duration(context, AppMotion.instant),
            curve: AppMotion.standardCurve,
            child: AnimatedContainer(
              duration: AppMotion.duration(context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: widget.enabled && (_hovered || _pressed)
                    ? const [
                        BoxShadow(color: AppColors.peachGlow, blurRadius: 16),
                      ]
                    : const [],
              ),
              child: widget.child,
            ),
          ),
        ),
      );
}

class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.order = 0,
    this.horizontal = false,
  });
  final Widget child;
  final int order;
  final bool horizontal;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.duration(
          context,
          Duration(milliseconds: 350 + order.clamp(0, 5) * 50),
        ),
        curve: Interval(
          order.clamp(0, 5) * .08,
          1,
          curve: AppMotion.standardCurve,
        ),
        child: child,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: horizontal
                ? Offset(-16 * (1 - value), 0)
                : Offset(0, 16 * (1 - value)),
            child: child,
          ),
        ),
      );
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppRadii.card,
  });
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: .76),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: .08),
              ),
            ),
            child: child,
          ),
        ),
      );
}

class AvatarRing extends StatelessWidget {
  const AvatarRing({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.peachLight,
              AppColors.peach,
              AppColors.surfaceElevated,
            ],
          ),
          boxShadow: [BoxShadow(color: AppColors.peachGlow, blurRadius: 12)],
        ),
        child: Padding(padding: const EdgeInsets.all(2), child: child),
      );
}

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });
  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value $label',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.peach),
              const SizedBox(width: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: AppMotion.duration(context, AppMotion.slow),
                curve: AppMotion.standardCurve,
                builder: (context, count, _) => Text(
                  '${count.round()} $label',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
}

/// One finite, locally bundled illustration; reduced motion shows a static frame.
class JournalIllustration extends StatelessWidget {
  const JournalIllustration({super.key, this.size = 160});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Lottie.asset(
          'assets/animations/journal.json',
          width: size,
          height: size,
          repeat: false,
          animate: !MediaQuery.disableAnimationsOf(context),
          frameRate: FrameRate.max,
          errorBuilder: (_, __, ___) => SizedBox.square(
            dimension: size,
            child: const Icon(
              Icons.auto_stories_outlined,
              color: AppColors.peach,
              size: 64,
            ),
          ),
        ),
      );
}

/// Subtle movement inside a clipped photograph without changing its layout size.
class ParallaxPhoto extends StatelessWidget {
  const ParallaxPhoto({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll == null || MediaQuery.disableAnimationsOf(context)) return child;
    return ClipRect(
      child: AnimatedBuilder(
        animation: scroll,
        child: child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, (scroll.pixels * .12).clamp(0.0, 20.0)),
          child: Transform.scale(scale: 1.14, child: child),
        ),
      ),
    );
  }
}
