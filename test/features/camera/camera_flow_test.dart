import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/features/camera/presentation/providers/camera_provider.dart';
import 'package:gostory/features/camera/presentation/screens/camera_screen.dart';

void main() {
  testWidgets(
      'small screen keeps camera controls usable without a gallery shortcut',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [availableCamerasProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(
          home: Scaffold(
            body: CameraScreen(embedded: true),
            bottomNavigationBar: SizedBox(height: 68),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bir fotoğrafla başla'), findsOneWidget);
    await tester.ensureVisible(find.text('Kamerayı aç'));
    expect(find.text('Kamerayı aç').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Galeriden ekle'), findsNothing);
    expect(find.byTooltip('Kamerayı çevir'), findsNothing);
    expect(find.byTooltip('Fotoğraf çek'), findsNothing);
    expect(find.text('DEMO'), findsNothing);
    expect(find.text('İstanbul'), findsNothing);
    expect(find.text('Konum ekle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
