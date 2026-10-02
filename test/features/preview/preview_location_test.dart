import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gostory/core/services/location_service.dart';
import 'package:gostory/core/services/permission_service.dart';
import 'package:gostory/features/preview/presentation/screens/preview_screen.dart';
import 'package:gostory/shared/providers/location_provider.dart';
import 'package:gostory/shared/widgets/location_chip.dart';
import 'package:latlong2/latlong.dart';

class _PendingLocation extends LocationService {
  var result = Completer<Position>();
  AccessStatus access = AccessStatus.granted;
  int fixes = 0;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<AccessStatus> accessStatus() async => access;

  @override
  Future<Position> getCurrentLocation() {
    fixes++;
    return result.future;
  }

  void complete() => result.complete(
        Position(
          latitude: 38.42,
          longitude: 27.14,
          timestamp: DateTime(2026),
          accuracy: 20,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
}

void main() {
  Future<ProviderContainer> showPreview(
    WidgetTester tester,
    _PendingLocation service, {
    LatLng? initial,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(service),
        draftLocationProvider.overrideWith((ref) => initial),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PreviewScreen(photoPath: '/missing-preview.jpg'),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('preview requests GPS once and enables sharing after a fix',
      (tester) async {
    final service = _PendingLocation();
    final container = await showPreview(tester, service);
    expect(service.fixes, 1);
    expect(find.text('Konum alınıyor…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Bugün burada güzel bir anı.',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Anıyı paylaş'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Anıyı paylaş'))
          .onPressed,
      isNull,
    );
    service.complete();
    await tester.pumpAndSettle();
    expect(container.read(draftLocationProvider), const LatLng(38.42, 27.14));
    expect(find.textContaining('Konumu değiştir'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Anıyı paylaş'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(service.fixes, 1);
  });

  testWidgets('an existing draft location avoids automatic GPS',
      (tester) async {
    final service = _PendingLocation();
    final container = await showPreview(
      tester,
      service,
      initial: const LatLng(41, 29),
    );
    await tester.pumpAndSettle();
    expect(service.fixes, 0);
    expect(container.read(draftLocationProvider), const LatLng(41, 29));
    expect(find.textContaining('Konumu değiştir'), findsOneWidget);
  });

  testWidgets('a late GPS fix preserves a location chosen on the map',
      (tester) async {
    final service = _PendingLocation();
    final container = await showPreview(tester, service);
    await tester.tap(find.text('Konum alınıyor…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(LocationPicker), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Bu konumu seç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final manual = container.read(draftLocationProvider);
    expect(manual, isNotNull);
    service.complete();
    await tester.pumpAndSettle();
    expect(container.read(draftLocationProvider), manual);
    expect(tester.takeException(), isNull);
  });

  testWidgets('declining location leaves manual selection available',
      (tester) async {
    final service = _PendingLocation()..access = AccessStatus.denied;
    final container = await showPreview(tester, service);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Şimdi değil'));
    await tester.pumpAndSettle();
    expect(service.fixes, 0);
    expect(container.read(draftLocationProvider), isNull);
    expect(find.text('Konum ekle').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Konum ekle'));
    await tester.pumpAndSettle();
    expect(find.byType(LocationPicker), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker follows GPS already requested by preview',
      (tester) async {
    final service = _PendingLocation();
    await showPreview(tester, service);
    await tester.tap(find.text('Konum alınıyor…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    service.complete();
    await tester.pumpAndSettle();
    final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(marker.markers.single.point, const LatLng(38.42, 27.14));
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center, const LatLng(38.42, 27.14));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Bu konumu seç'),
          )
          .onPressed,
      isNotNull,
    );
    expect(service.fixes, 1);
  });

  testWidgets('retry after GPS failure updates the picker and the draft',
      (tester) async {
    final service = _PendingLocation();
    final container = await showPreview(tester, service);
    service.result
        .completeError(const LocationFailure(LocationProblem.timeout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konum ekle'));
    await tester.pumpAndSettle();
    service.result = Completer<Position>();
    await tester.tap(find.text('Tekrar dene').hitTestable());
    await tester.pump();
    service.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MarkerLayer), findsOneWidget);
    await tester.tap(find.text('Bu konumu seç'));
    await tester.pumpAndSettle();
    expect(find.byType(LocationPicker), findsNothing);
    expect(container.read(draftLocationProvider), const LatLng(38.42, 27.14));
    expect(service.fixes, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GPS does not move a pin manually placed while the picker is open',
      (tester) async {
    final service = _PendingLocation();
    final container = await showPreview(tester, service);
    await tester.tap(find.text('Konum alınıyor…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
    await tester.pump(const Duration(milliseconds: 400));
    final manual = tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers
        .single
        .point;
    service.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single.point,
      manual,
    );
    await tester.tap(find.text('Bu konumu seç'));
    await tester.pumpAndSettle();
    expect(container.read(draftLocationProvider), manual);
    expect(tester.takeException(), isNull);
  });
}
