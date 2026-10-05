import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gostory/app/navigation.dart';
import 'package:gostory/core/constants/preview_config.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/location_service.dart';
import 'package:gostory/core/services/permission_service.dart';
import 'package:gostory/features/map/presentation/screens/map_screen.dart';
import 'package:gostory/features/map/presentation/widgets/discovery_map.dart';
import 'package:gostory/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/location_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:latlong2/latlong.dart';

import '../../test_helpers/empty_memory_store.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets(
      'discovery controls, panel and sharing at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final locationService = _GrantedLocationService();
        final container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(_MapAuthService()),
            memoryStoreProvider.overrideWithValue(EmptyMemoryStore()),
            locationServiceProvider.overrideWithValue(locationService),
            locationAccessProvider.overrideWith(
              (ref) => _GrantedLocationNotifier(locationService),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: MapScreen(embedded: true),
                bottomNavigationBar: SizedBox(height: 68),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Yakınındaki anıları keşfet'), findsOneWidget);
        expect(find.text('Bir yer, bin hikâye.'), findsNothing);
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
        final state =
            tester.state<DiscoveryMapState>(find.byType(DiscoveryMap));
        final zoom = state.controller.camera.zoom;
        await tester.tap(find.byTooltip('Yakınlaştır'));
        await tester.pumpAndSettle();
        expect(state.controller.camera.zoom, greaterThan(zoom));
        await tester.tap(find.byTooltip('Konumuma dön'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yeni'));
        await tester.pumpAndSettle();
        var map = tester.widget<DiscoveryMap>(find.byType(DiscoveryMap));
        expect(map.memories.first.id, 'mock-1');
        await tester.ensureVisible(find.text('Popüler'));
        await tester.tap(find.text('Popüler'));
        await tester.pumpAndSettle();
        map = tester.widget<DiscoveryMap>(find.byType(DiscoveryMap));
        expect(map.memories.every((m) => m.viewCount == 0), isTrue);
        await tester.tap(find.textContaining('Bu bölgede'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('map-memory-panel')), findsOneWidget);
        map.onSelect(map.memories.first);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('selected-memory-card')),
          findsOneWidget,
        );
        final author = find.text('@${map.memories.first.creatorUsername}');
        await tester.ensureVisible(author);
        await tester.tap(author);
        await tester.pumpAndSettle();
        expect(find.byType(PublicProfileScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Bu bölgede'));
        await tester.pumpAndSettle();
        for (final label in ['Yakınlaştır', 'Uzaklaştır', 'Konumuma dön']) {
          expect(find.byTooltip(label).hitTestable(), findsOneWidget);
        }
        final before = state.controller.camera.center;
        final mapRect = tester.getRect(find.byType(DiscoveryMap));
        await tester.dragFrom(
          mapRect.centerLeft + const Offset(30, 0),
          const Offset(45, 20),
        );
        await tester.pumpAndSettle();
        expect(state.controller.camera.center, isNot(before));
        state.controller.move(const LatLng(40.7, -74), 13);
        await tester.pumpAndSettle();
        expect(find.text('Bu bölgede 0 anı'), findsOneWidget);
        await tester.tap(find.text('Bu bölgede 0 anı'));
        await tester.pumpAndSettle();
        expect(find.text('Buraya ilk anıyı sen bırak'), findsOneWidget);
        await tester.ensureVisible(find.text('Anı bırak').last);
        await tester.pumpAndSettle();
        expect(find.text('Anı bırak').last.hitTestable(), findsOneWidget);
        await tester.tap(find.text('Anı bırak').last);
        expect(container.read(selectedTabProvider), 1);
        expect(
          find.text('© OpenStreetMap contributors').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
      skip: !PreviewConfig.enabled,
    );
  }
}

class _MapAuthService extends AuthService {
  @override
  LocalUser get currentUser =>
      const LocalUser(uid: 'viewer', username: 'gezgin');
}

class _GrantedLocationService extends LocationService {
  @override
  Future<bool> isServiceEnabled() async => true;
  @override
  Future<AccessStatus> accessStatus() async => AccessStatus.granted;
  @override
  Future<Position> getCurrentLocation() async => Position(
        latitude: 41.0082,
        longitude: 28.9784,
        timestamp: DateTime(2026),
        accuracy: 500,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
}

class _GrantedLocationNotifier extends LocationAccessNotifier {
  _GrantedLocationNotifier(super.service);
  @override
  Future<void> locate({required Future<bool> Function() confirm}) async {
    state = const LocationAccessState(busy: true);
    state = LocationAccessState(position: await service.getCurrentLocation());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}
