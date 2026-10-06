// path: lib/features/splash/presentation/screens/splash_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart' as app_type;

/// GoStory cinematic splash screen.
///
/// Sequence:
/// 1. Black screen (300ms)
/// 2. Brand icon scales & fades in over 600ms
/// 3. Wordmark fades in over 800ms
/// 4. Tagline fades in over 600ms (staggered 400ms after wordmark)
/// 5. Shimmer sweeps across wordmark
/// 6. Hold for 800ms
/// 7. Navigate to camera (fade out)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _iconController;
  late final AnimationController _wordmarkController;
  late final AnimationController _taglineController;
  late final AnimationController _shimmerController;
  late final AnimationController _exitController;
  late final AnimationController _glowController;

  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _wordmarkOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _shimmerPosition;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Force immersive mode during splash.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _iconOpacity = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut,
    );
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );
    _wordmarkOpacity = CurvedAnimation(
      parent: _wordmarkController,
      curve: Curves.easeOut,
    );
    _wordmarkOffset = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOut),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOut,
    );
    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _glowOpacity = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runSequence();
    });
  }

  Future<void> _runSequence() async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _iconController.value = 1;
      _wordmarkController.value = 1;
      _taglineController.value = 1;
      _glowController.value = 1;
      _shimmerController.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } else {
      _glowController.forward();
      await _iconController.forward();
      if (!mounted) return;
      await _wordmarkController.forward();
      if (!mounted) return;
      _taglineController.forward();
      await _shimmerController.forward();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _exitController.forward();
    }
    if (!mounted) return;
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    _iconController.dispose();
    _wordmarkController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _exitOpacity,
        child: Stack(
          children: [
            // Base gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                ),
              ),
            ),
            // Radial peach glow
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) => Opacity(
                opacity: _glowOpacity.value,
                child: child,
              ),
              child: Center(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.peach.withValues(alpha: 0.12),
                        AppColors.peach.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand icon
                    AnimatedBuilder(
                      animation: _iconController,
                      builder: (context, child) => Transform.scale(
                        scale: _iconScale.value,
                        child: Opacity(
                          opacity: _iconOpacity.value,
                          child: child,
                        ),
                      ),
                      child: SvgPicture.asset(
                        'assets/brand/icon.svg',
                        width: 56,
                        height: 56,
                        colorFilter: const ColorFilter.mode(
                          AppColors.peach,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Wordmark with shimmer
                    AnimatedBuilder(
                      animation: Listenable.merge(
                        [_wordmarkController, _shimmerController],
                      ),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _wordmarkOffset.value),
                          child: Opacity(
                            opacity: _wordmarkOpacity.value,
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                if (!_shimmerController.isAnimating &&
                                    _shimmerController.value == 0) {
                                  return const LinearGradient(
                                    colors: [Colors.white, Colors.white],
                                  ).createShader(bounds);
                                }
                                return LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: const [
                                    Colors.white,
                                    Color(0xFFF5D4B3),
                                    Colors.white,
                                  ],
                                  stops: [
                                    math.max(
                                      0,
                                      _shimmerPosition.value - 0.3,
                                    ),
                                    _shimmerPosition.value.clamp(0.0, 1.0),
                                    math.min(
                                      1,
                                      _shimmerPosition.value + 0.3,
                                    ),
                                  ],
                                ).createShader(bounds);
                              },
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: const _GoStoryWordmark(),
                    ),

                    const SizedBox(height: 16),

                    // Tagline
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: Text(
                        'bırak. unut. bulun.',
                        style: app_type.AppTypography.label.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Animated divider
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: AnimatedBuilder(
                        animation: _taglineController,
                        builder: (context, _) => Container(
                          width: 40 * _taglineOpacity.value,
                          height: 1.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.peach.withValues(alpha: 0.0),
                                AppColors.peach.withValues(alpha: 0.5),
                                AppColors.peach.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The GoStory wordmark — two words styled differently for contrast.
class _GoStoryWordmark extends StatelessWidget {
  const _GoStoryWordmark();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'go',
            style: TextStyle(
              fontFamily: app_type.AppTypography.heading,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 8.0,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: 'story',
            style: TextStyle(
              fontFamily: app_type.AppTypography.heading,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: 4.0,
              color: AppColors.textSecondary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
