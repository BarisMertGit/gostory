// path: lib/core/utils/logger.dart

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Centralized logging for GoStory.
///
/// Uses [developer.log] in debug mode.
/// In production, logs will be forwarded to Crashlytics (Phase 6).
///
/// Never log personal data: memory text, exact GPS, photos, UIDs.
abstract final class AppLogger {
  static const String _appName = 'GoStory';

  /// General info log.
  static void info(String message, {String? tag}) {
    _log(message, tag: tag, level: 0);
  }

  /// Warning log.
  static void warning(String message, {String? tag, Object? error}) {
    _log(message, tag: tag, level: 500, error: error);
  }

  /// Error log.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(message, tag: tag, level: 1000, error: error, stackTrace: stackTrace);
  }

  static void _log(
    String message, {
    String? tag,
    int level = 0,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _appName,
        level: level,
        error: error,
        stackTrace: stackTrace,
      );
    }
    // TODO(Phase 6): Forward errors to Crashlytics in production.
  }
}
