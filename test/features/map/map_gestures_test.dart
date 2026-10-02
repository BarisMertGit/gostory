import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/features/map/presentation/widgets/discovery_map.dart';
import 'package:latlong2/latlong.dart';

class BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=',
        ),
      );
}

void main() {
  testWidgets('world map pans beyond Istanbul, zooms and returns to location',
      (tester) async {
    final key = GlobalKey<DiscoveryMapState>();
    var interactions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryMap(
            key: key,
            memories: const [],
            selectedId: null,
            latitude: 41,
            longitude: 29,
            onSelect: (_) {},
            onInteraction: () => interactions++,
            tileProvider: BlankTiles(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final state = key.currentState!;
    final initial = state.controller.camera.center;
    await tester.dragFrom(const Offset(200, 200), const Offset(90, 60));
    await tester.pumpAndSettle();
    expect(state.controller.camera.center, isNot(initial));
    expect(interactions, greaterThan(0));

    state.showWorld();
    await tester.pumpAndSettle();
    expect(state.controller.camera.zoom, 2);
    expect(state.controller.camera.center.longitude, closeTo(0, .01));
    // Camera can reach another continent; it has no local bounds.
    state.controller.move(const LatLng(40.7, -74), 12);
    await tester.pumpAndSettle();
    expect(state.controller.camera.center.longitude, closeTo(-74, .01));
    state.zoomBy(2);
    await tester.pumpAndSettle();
    expect(state.controller.camera.zoom, 13);

    await tester.tapAt(const Offset(300, 300));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();
    expect(state.controller.camera.zoom, greaterThan(13));

    state.resetView();
    await tester.pumpAndSettle();
    expect(state.controller.camera.center.latitude, closeTo(41, .01));
    expect(state.controller.camera.center.longitude, closeTo(29, .01));
    expect(state.controller.camera.zoom, 13);
    expect(tester.takeException(), isNull);
  });
}
