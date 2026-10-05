// path: lib/app/router.dart

import 'package:flutter/material.dart';

import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/preview/presentation/screens/preview_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import 'home_screen.dart';
import 'theme/design.dart';

/// App route names.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String splash = '/';
  static const String camera = '/camera';
  static const String preview = '/preview';
  static const String map = '/map';
}

/// Generates routes for the app.
///
/// Phase 1: Splash → Camera → Preview.
/// Phase 2: Map screen added.
Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _buildSplashRoute(settings);
    case AppRoutes.home:
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(),
        settings: settings,
      );
    case AppRoutes.camera:
      return MaterialPageRoute(
        builder: (_) => const CameraScreen(),
        settings: settings,
      );
    case AppRoutes.preview:
      final photoPath = settings.arguments as String;
      return _buildPreviewRoute(photoPath, settings);
    case AppRoutes.map:
      return _buildMapRoute(settings);
    default:
      return MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      );
  }
}

/// Splash screen has no transition — it owns its own animation.
Route<dynamic> _buildSplashRoute(RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, __, ___) => const SplashScreen(),
  );
}

/// A short transition, skipped when the system requests reduced motion.
Route<dynamic> _buildPreviewRoute(
  String photoPath,
  RouteSettings settings,
) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: AppMotion.standard,
    reverseTransitionDuration: AppMotion.standard,
    pageBuilder: (context, animation, secondaryAnimation) {
      return PreviewScreen(photoPath: photoPath);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: child,
      );
    },
  );
}

/// Builds the map route with a slide-from-right transition.
Route<dynamic> _buildMapRoute(RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: AppMotion.standard,
    reverseTransitionDuration: AppMotion.standard,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const MapScreen();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      return SlideTransition(
        position: slideAnimation,
        child: child,
      );
    },
  );
}
