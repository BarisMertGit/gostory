import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gostory/app/router.dart' as router;
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/location_service.dart';
import 'package:gostory/core/services/permission_service.dart';
import 'package:gostory/features/camera/domain/camera_state.dart';
import 'package:gostory/features/camera/presentation/providers/camera_provider.dart';
import 'package:gostory/features/camera/presentation/screens/camera_screen.dart';
import 'package:gostory/features/preview/presentation/providers/preview_provider.dart';
import 'package:gostory/features/preview/presentation/screens/preview_screen.dart';
import 'package:gostory/features/profile/presentation/screens/profile_screen.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/location_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:gostory/shared/widgets/location_chip.dart';

class _CaptureCamera extends CameraNotifier {
  void captured(String path) {
    state = CameraCaptured(photoPath: path);
  }
}

class _CaptureLocation extends LocationService {
  int fixes = 0;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<AccessStatus> accessStatus() async => AccessStatus.granted;

  @override
  Future<Position> getCurrentLocation() async {
    fixes++;
    return Position(
      latitude: 41,
      longitude: 29,
      timestamp: DateTime(2026),
      accuracy: 20,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() => registerCaptureFlow();

void registerCaptureFlow() {
  testWidgets(
      'capture event → preview GPS → durable save → profile after reload',
      (tester) async {
    if (tester.binding is AutomatedTestWidgetsFlutterBinding) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    final dir = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('gostory-flow-')))!;
    addTearDown(() => dir.delete(recursive: true));
    final photo = (await tester.runAsync(
      () => File('${dir.path}/capture.png').writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9WQAAAAASUVORK5CYII=',
        ),
      ),
    ))!;
    final camera = _CaptureCamera();
    final location = _CaptureLocation();
    final store = MemoryStore(
      directory: () async => dir,
      resolveCity: (_, __) async => 'İstanbul',
    );
    addTearDown(store.dispose);
    final auth =
        AuthService(profileFile: () async => File('${dir.path}/profile.json'));
    final container = ProviderContainer(
      overrides: [
        cameraProvider.overrideWith((ref) => camera),
        memoryStoreProvider.overrideWithValue(store),
        authServiceProvider.overrideWithValue(auth),
        locationServiceProvider.overrideWithValue(location),
      ],
    );
    addTearDown(container.dispose);
    final previewSubscription =
        container.listen(previewProvider(photo.path), (_, __) {});
    addTearDown(previewSubscription.close);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const CameraScreen(),
          onGenerateRoute: router.generateRoute,
        ),
      ),
    );
    await tester.pump();
    // Device camera/GPS results are injected; routing, validation and persistence are real.
    camera.captured(photo.path);
    await tester.pumpAndSettle();
    expect(find.byType(PreviewScreen), findsOneWidget);
    expect(location.fixes, 1);
    expect(container.read(draftLocationProvider)?.latitude, 41);
    await tester.enterText(
      find.byType(TextField),
      'Bu anı yarın da hatırlamak istiyorum.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Anıyı paylaş'));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Anıyı paylaş'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    for (var attempt = 0;
        attempt < 30 &&
            container.read(previewProvider(photo.path)).isSubmitting;
        attempt++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
    final previewState = container.read(previewProvider(photo.path));
    expect(
      previewState.isSubmitted,
      isTrue,
      reason:
          '${previewState.validationError}, busy=${previewState.isSubmitting}, valid=${previewState.isValid}',
    );
    expect(find.byType(PreviewScreen), findsNothing);
    final restored = MemoryStore(directory: () async => dir);
    addTearDown(restored.dispose);
    final rows = await tester.runAsync(restored.read);
    expect(rows!.single.city, 'İstanbul');
    expect(rows.single.latitude, 41);
    expect(rows.single.longitude, 29);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
      ),
    );
    for (var attempt = 0; attempt < 12; attempt++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Bu anı yarın da hatırlamak istiyorum.'), findsOneWidget);
    expect(find.text('1 anı'), findsWidgets);
    expect(find.text('1 şehir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
