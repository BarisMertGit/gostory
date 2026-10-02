import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/preview/presentation/screens/preview_screen.dart';
import 'package:gostory/features/preview/presentation/providers/preview_provider.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:gostory/shared/widgets/location_chip.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets(
      'public choice persists with actual note, photo and selected location',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = (await tester
        .runAsync(() => Directory.systemTemp.createTemp('gostory-preview-')))!;
    addTearDown(() => dir.delete(recursive: true));
    final store = MemoryStore(directory: () async => dir);
    addTearDown(store.dispose);
    final photo = (await tester.runAsync(
      () => File('${dir.path}/source.jpg').writeAsBytes([1, 2, 3]),
    ))!;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memoryStoreProvider.overrideWithValue(store),
          authServiceProvider.overrideWithValue(
            AuthService(
              profileFile: () async => File('${dir.path}/profile.json'),
            ),
          ),
          draftLocationProvider.overrideWith((ref) => const LatLng(41, 29)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PreviewScreen(photoPath: photo.path),
                  ),
                ),
                child: const Text('Önizle'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Önizle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Bugün burada güzel bir anı.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Anıyı paylaş'));
    final container = ProviderScope.containerOf(tester.element(find.byType(PreviewScreen)));
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Anıyı paylaş'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (var attempt = 0; attempt < 50 && container.read(previewProvider(photo.path)).isSubmitting; attempt++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
    await tester.pumpAndSettle();
    final rows = await tester.runAsync(store.read);
    expect(rows!.single.isPublic, isTrue);
    expect(rows.single.latitude, 41);
    expect(rows.single.textNote, 'Bugün burada güzel bir anı.');
    expect(rows.single.syncPending, isTrue);
    expect(
      find.text('Herkese açık paylaşım henüz kullanılamıyor'),
      findsNothing,
    );
  });
}
