import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/features/map/presentation/widgets/discovery_map.dart';
import 'package:gostory/shared/models/memory.dart';

import 'map_gestures_test.dart' show BlankTiles;

void main() {
  testWidgets(
      'coincident memories expose the full count and open the actual group',
      (tester) async {
    final memories = List.generate(
      125,
      (index) => Memory(
        id: 'cluster-$index',
        creatorId: 'owner',
        creatorUsername: 'owner',
        photoUrl: '',
        textNote: 'Anı $index',
        latitude: 41,
        longitude: 29,
        createdAt: DateTime(2026),
        city: 'İstanbul',
      ),
    );
    List<Memory>? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: DiscoveryMap(
              memories: memories,
              selectedId: null,
              latitude: 41,
              longitude: 29,
              hasUserLocation: false,
              tileProvider: BlankTiles(),
              onSelect: (_) {},
              onCluster: (group) => opened = group,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('125'), findsOneWidget);
    expect(find.byTooltip('125 anı, kümeyi aç'), findsOneWidget);
    await tester.tap(find.byTooltip('125 anı, kümeyi aç'));
    expect(opened, orderedEquals(memories));
    expect(tester.takeException(), isNull);
  });
}
