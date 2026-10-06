import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/features/map/presentation/widgets/discovery_memory_card.dart';
import 'package:gostory/features/memory/presentation/memory_detail_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/widgets/memory_photo.dart';

void main() {
  final memory = Memory(
    id: 'layout',
    creatorId: 'author',
    creatorUsername: 'deniz',
    photoUrl: 'demo://photo',
    textNote: 'Bu yerde saklamak istediğim uzun bir anının kısa hikâyesi.',
    latitude: 41,
    longitude: 29,
    city: 'İstanbul',
    createdAt: DateTime(2026, 10, 6),
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets('selected preview fits panel at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> show(double available) => tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 360,
                        child: DiscoveryMemoryCard(
                          memory: memory,
                          distance: 250,
                          selected: true,
                          availableHeight: available,
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
      await show(180);
      expect(tester.getSize(find.byType(MemoryPhoto)).width, 96);
      expect(find.text('6 Eki 2026'), findsOneWidget);
      expect(find.text('250 m uzaklıkta'), findsOneWidget);
      await show(650);
      expect(tester.getSize(find.byType(MemoryPhoto)).width, greaterThan(300));
    });
  }
  testWidgets('full photo preserves aspect ratio and supports zoom',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const MemoryPhotoViewer(path: 'demo://photo'),
      ),
    );
    expect(
      tester.widget<MemoryPhoto>(find.byType(MemoryPhoto)).fit,
      BoxFit.contain,
    );
    expect(
      tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).maxScale,
      5,
    );
    expect(tester.takeException(), isNull);
  });
}
