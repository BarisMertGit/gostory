// path: lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/cloud_service.dart';
import '../core/services/notifications_service.dart';
import '../features/memory/presentation/memory_detail_screen.dart';
import '../features/onboarding/onboarding_gate.dart';
import '../shared/models/memory.dart';
import '../shared/providers/cloud_provider.dart';
import 'navigation.dart';
import 'router.dart' as app_router;
import 'theme/app_theme.dart';
import 'theme/colors.dart';

/// The root widget of GoStory.
///
/// Configures theme, status bar style, and routing.
/// Locks orientation to portrait.
final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class GoStoryApp extends ConsumerWidget {
  const GoStoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cloudSyncProvider);
    ref.watch(notificationsServiceProvider);
    Future<void> openNotification(String id) async {
      try {
        final cloud = ref.read(cloudServiceProvider);
        await cloud.authenticate();
        final doc = await cloud.db.collection('memories').doc(id).get();
        final context = _navigatorKey.currentContext;
        if (doc.exists && context != null && context.mounted) {
          openMemoryDetail(
            context,
            Memory.fromJson({...doc.data()!, 'id': doc.id}),
          );
        }
      } catch (_) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Anı artık erişilebilir değil.')),
        );
      }
    }

    if (CloudService.ready) {
      ref.listen(notificationMessageProvider, (_, message) {
        if (message == null) return;
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content:
                Text(message.notification?.title ?? 'Yeni GoStory bildirimi'),
            action: message.data['memoryId'] is String
                ? SnackBarAction(
                    label: 'Anıyı aç',
                    onPressed: () =>
                        openNotification(message.data['memoryId'] as String),
                  )
                : null,
          ),
        );
      });
      ref.listen(notificationOpenProvider, (_, id) {
        if (id != null) openNotification(id);
      });
    }
    // Lock to portrait mode for a consistent camera experience.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Full-screen immersive status bar.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'GoStory',
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      navigatorObservers: [appRouteObserver],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const OnboardingGate(),
      onGenerateRoute: app_router.generateRoute,
    );
  }
}
