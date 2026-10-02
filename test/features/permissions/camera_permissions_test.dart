import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/navigation.dart';
import 'package:gostory/core/services/permission_service.dart';
import 'package:gostory/core/widgets/permission_explanation.dart';
import 'package:gostory/features/camera/presentation/providers/camera_provider.dart';
import 'package:gostory/features/camera/presentation/screens/camera_screen.dart';

class FakePermissions extends PermissionService {
  AccessStatus access = AccessStatus.denied;
  int checks = 0, marks = 0, settings = 0;
  @override
  Future<AccessStatus> status(String permission) async {
    checks++;
    return access;
  }

  @override
  Future<void> markRequested(String permission) async {
    marks++;
  }

  @override
  Future<bool> openSettings() async {
    settings++;
    return true;
  }
}

class FakeCamera extends CameraNotifier {
  int starts = 0, releases = 0;
  VoidCallback? onStart;
  @override
  Future<void> initialize(List<cam.CameraDescription> cameras) async {
    starts++;
    onStart?.call();
    permissionDenied();
  }

  @override
  Future<void> release() async {
    releases++;
    await super.release();
  }
}

void main() {
  late FakePermissions permissions;
  late FakeCamera camera;
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(permissions),
          cameraProvider.overrideWith((ref) => camera),
          availableCamerasProvider.overrideWith(
            (ref) async => [
              const cam.CameraDescription(
                name: 'back',
                lensDirection: cam.CameraLensDirection.back,
                sensorOrientation: 90,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [appRouteObserver],
          home: const CameraScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    permissions = FakePermissions();
    camera = FakeCamera();
  });
  testWidgets('screen entry and not now do not initialize or ask the OS',
      (tester) async {
    await pump(tester);
    expect(permissions.checks, 0);
    expect(camera.starts, 0);
    await tester.tap(find.text('Kamerayı aç'));
    await tester.pumpAndSettle();
    expect(find.text(cameraExplanation), findsOneWidget);
    expect(camera.starts, 0);
    await tester.tap(find.text('Şimdi değil'));
    await tester.pumpAndSettle();
    expect(camera.starts, 0);
    expect(permissions.marks, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 0);
  });
  testWidgets(
      'continue initializes; denial never triggers a second automatic prompt',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Kamerayı aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(permissions.marks, 1);
    expect(find.byTooltip('Galeriden ekle'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(permissions.marks, 1);
    expect(find.text(cameraExplanation), findsNothing);
  });
  testWidgets(
      'blocked opens settings; returning granted checks without prompting',
      (tester) async {
    permissions.access = AccessStatus.blocked;
    await pump(tester);
    await tester.tap(find.text('Kamerayı aç'));
    await tester.pumpAndSettle();
    expect(find.text('Şimdi değil'), findsOneWidget);
    expect(camera.starts, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Ayarları aç').last);
    await tester.pumpAndSettle();
    expect(permissions.settings, 1);
    permissions.access = AccessStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(permissions.marks, 0);
    expect(find.text(cameraExplanation), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(camera.releases, greaterThan(0));
  });
  testWidgets(
      'existing grant skips explanation and camera releases under another page',
      (tester) async {
    permissions.access = AccessStatus.granted;
    await pump(tester);
    await tester.tap(find.text('Kamerayı aç'));
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(permissions.marks, 0);
    final context = tester.element(find.byType(CameraScreen));
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other')),
      ),
    );
    await tester.pumpAndSettle();
    expect(camera.releases, greaterThan(0));
    final starts = camera.starts;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, starts);
  });
}
