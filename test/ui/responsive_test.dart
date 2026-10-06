import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/home_screen.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/location_service.dart';
import 'package:gostory/features/map/presentation/widgets/discovery_controls.dart';
import 'package:gostory/features/map/presentation/widgets/discovery_map.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/location_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:latlong2/latlong.dart';

class _LayoutAuth extends AuthService {
  @override
  Future<LocalUser> signIn() async => const LocalUser(
        uid: 'layout-user',
        username: 'uzun_kullanici_adi_123456',
      );
}

class _LayoutStore extends MemoryStore {
  _LayoutStore(this.populated);
  final bool populated;
  @override
  Future<List<Memory>> read() async => populated
      ? [
          Memory(
            id: 'layout-memory',
            creatorId: 'layout-user',
            creatorUsername: 'uzun_kullanici_adi_123456',
            photoUrl: '',
            textNote:
                'Uzun notların farklı ekranlarda okunabilir kaldığı bir test anısı.',
            latitude: 41,
            longitude: 29,
            city: 'İstanbul',
            createdAt: DateTime(2026),
          ),
        ]
      : [];
}

class _DeniedLocation extends LocationAccessNotifier {
  _DeniedLocation() : super(LocationService()) {
    state = const LocationAccessState(
      failure: LocationFailure(LocationProblem.denied),
    );
  }
}

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final height in [640.0, 844.0]) {
        testWidgets(
            'three tabs: width $width, height $height, text scale $scale, permission denied',
            (tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authServiceProvider.overrideWithValue(_LayoutAuth()),
                memoryStoreProvider.overrideWithValue(_LayoutStore(true)),
                locationAccessProvider.overrideWith((ref) => _DeniedLocation()),
              ],
              child: MaterialApp(
                theme: AppTheme.dark,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(top: 44, bottom: 24),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const HomeScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final controls = find.byType(DiscoveryControls);
          if (controls.evaluate().isNotEmpty) {
            final panel = find.byKey(const ValueKey('map-memory-panel'));
            expect(
              tester.getRect(controls).bottom,
              lessThanOrEqualTo(tester.getRect(panel).top),
            );
          }
          final map =
              tester.state<DiscoveryMapState>(find.byType(DiscoveryMap));
          map.controller.move(const LatLng(40.7, -74), 12);
          await tester.pumpAndSettle();
          Future<void> tab(String label) async {
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              ),
            );
            await tester.pumpAndSettle();
          }

          await tab('Paylaş');
          await tester.ensureVisible(find.text('Kamerayı aç'));
          expect(find.text('Kamerayı aç').hitTestable(), findsOneWidget);
          expect(find.byTooltip('Fotoğraf çek'), findsNothing);
          expect(tester.takeException(), isNull);
          await tab('Profil');
          await tester.scrollUntilVisible(
            find.text(
              'Uzun notların farklı ekranlarda okunabilir kaldığı bir test anısı.',
            ),
            250,
          );
          expect(tester.takeException(), isNull);
          await tab('Harita');
          expect(
            tester.state<DiscoveryMapState>(find.byType(DiscoveryMap)),
            same(map),
          );
          expect(map.controller.camera.center.longitude, closeTo(-74, .001));
          expect(
            find.text('© OpenStreetMap contributors').hitTestable(),
            findsOneWidget,
          );
          await tester.tap(find.textContaining('Bu bölgede'));
          await tester.pumpAndSettle();
          expect(
            find.text('© OpenStreetMap contributors').hitTestable(),
            findsOneWidget,
          );
          await tester.drag(
            find.byKey(const ValueKey('map-memory-panel')),
            const Offset(0, 120),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
