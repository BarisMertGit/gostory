import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/widgets/demo_scene.dart';
import 'package:gostory/features/preview/presentation/screens/preview_screen.dart';
import 'package:gostory/features/profile/presentation/screens/profile_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:gostory/shared/widgets/location_chip.dart';
import 'package:latlong2/latlong.dart';

class _ScreenshotAuth extends AuthService {
  @override
  Future<LocalUser> signIn() async => const LocalUser(
        uid: 'sample',
        username: 'deniz_yolda',
        bio: 'Yolun hikâyesini anılarda saklıyorum.',
      );
}

class _ScreenshotStore extends MemoryStore {
  @override
  Future<List<Memory>> read() async => [
        Memory(
          id: 'sample-memory',
          creatorId: 'sample',
          creatorUsername: 'deniz_yolda',
          photoUrl: 'demo://istanbul',
          textNote: 'Bu manzaraya her dönüşümde yeni bir hikâye buluyorum.',
          latitude: 41.008,
          longitude: 28.978,
          city: 'İstanbul',
          createdAt: DateTime(2026, 9, 30),
        ),
      ];
}

void main() {
  testWidgets('capture actual profile and preview UI with labelled sample data',
      (tester) async {
    await tester.runAsync(() async {
      final bytes = await File('/System/Library/Fonts/Supplemental/Arial.ttf')
          .readAsBytes();
      for (final family in ['Ahem', 'Roboto', 'SF Pro Text', '.SF UI Text']) {
        await (FontLoader(family)
              ..addFont(Future.value(ByteData.sublistView(bytes))))
            .load();
      }
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    final key = GlobalKey();
    Future<void> capture(String path, double scale) async {
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: scale);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }

    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: DemoScene(),
        ),
      ),
    );
    await capture('/private/tmp/gostory-release-scene.png', 1);
    for (final platform in ['ios', 'android']) {
      final logical =
          platform == 'ios' ? const Size(430, 932) : const Size(360, 800);
      tester.view.physicalSize = logical * 3;
      tester.view.devicePixelRatio = 3;
      Future<void> show(Widget screen) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(_ScreenshotAuth()),
              memoryStoreProvider.overrideWithValue(_ScreenshotStore()),
              draftLocationProvider
                  .overrideWith((ref) => const LatLng(41.008, 28.978)),
            ],
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                home: screen,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(const ProfileScreen());
      await capture('docs/release/screenshots/$platform-profile-sample.png', 3);
      await show(
        const PreviewScreen(
          photoPath: '/private/tmp/gostory-release-scene.png',
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        'Bu manzaraya her dönüşümde yeni bir hikâye.',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await capture('docs/release/screenshots/$platform-preview-sample.png', 3);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
