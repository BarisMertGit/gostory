// path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/cloud_service.dart';
import 'core/utils/logger.dart';

/// GoStory entry point.
///
/// Configures bounded map caching and optional Firebase before rendering.
/// Local profile loading remains lazy and does not block app startup.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BuiltInMapCachingProvider.getOrCreateInstance(
    maxCacheSize: 128 * 1024 * 1024,
  );
  await CloudService.initialize();
  AppLogger.info('App starting.', tag: 'Main');

  runApp(
    const ProviderScope(
      child: GoStoryApp(),
    ),
  );
}
