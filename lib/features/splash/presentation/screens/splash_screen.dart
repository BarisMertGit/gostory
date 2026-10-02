// path: lib/features/splash/presentation/screens/splash_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/typography.dart' as app_type;

/// GoStory cinematic splash screen.
///
/// Sequence:
/// 1. Black screen (300ms)
/// 2. Wordmark fades in over 800ms
/// 3. Tagline fades in over 600ms (staggered 400ms after wordmark)
/// 4. Hold for 800ms
/// 5. Navigate to camera (fade out)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _wordmarkController;
  late final AnimationController _taglineController;
  late final AnimationController _exitController;

  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _wordmarkOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // Force immersive mode during splash.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Brief black pause
    await Future<void>.delayed(const Duration(milliseconds: 350));

    // 2. Wordmark fades in
    await _wordmarkController.forward();

    // 3. Tagline fades in (staggered)
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _taglineController.forward();

    // 4. Hold
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // 5. Fade out and navigate
    if (!mounted) return;
    await _exitController.forward();

    if (!mounted) return;
    // Restore system UI before navigating.
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _wordmarkController.dispose();
    _taglineController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _exitOpacity,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.splashGradientTop,
                AppColors.splashGradientBottom,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wordmark
                AnimatedBuilder(
                  animation: _wordmarkController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _wordmarkOffset.value),
                      child: Opacity(
                        opacity: _wordmarkOpacity.value,
                        child: child,
                      ),
                    );
                  },
                  child: const _GoStoryWordmark(),
                ),

                const SizedBox(height: 20),

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
              ],
            ),
          ),
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
              fontSize: 36,
              fontWeight: FontWeight.w200,
              letterSpacing: 8.0,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: 'story',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w500,
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
