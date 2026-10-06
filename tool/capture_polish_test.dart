import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/home_screen.dart';
import 'package:gostory/app/navigation.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/interactions_service.dart';
import 'package:gostory/core/services/location_service.dart';
import 'package:gostory/features/memory/presentation/memory_detail_screen.dart';
import 'package:gostory/features/preview/presentation/screens/preview_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/interactions_provider.dart';
import 'package:gostory/shared/providers/location_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:gostory/shared/widgets/location_chip.dart';
import 'package:latlong2/latlong.dart';

// Visual fixtures only: no real profiles, archives or cloud mutations.
class _Auth extends AuthService {
  @override
  Future<LocalUser> signIn() async => const LocalUser(
        uid: 'visual',
        username: 'deniz_yolda',
        bio: 'Yolun hikâyesini anılarda saklıyorum.',
      );
}

final _rows = List.generate(
  5,
  (index) => Memory(
    id: 'visual-$index',
    creatorId: 'visual',
    creatorUsername: 'deniz_yolda',
    photoUrl: 'demo://photo-$index',
    textNote: [
      'Akşamın son ışığı, şehrin en sevdiğim köşesinde.',
      'Bir kahve, uzun bir yürüyüş ve dönüp hatırlamak istediğim küçük bir an.',
      'Bugünden kalan.',
    ][index % 3],
    latitude: 41,
    longitude: 29,
    city: 'İstanbul',
    createdAt: DateTime(2026, 10, 6 - index),
    syncPending: index == 1,
  ),
);

class _Archive extends MemoryStore {
  @override
  Future<List<Memory>> read() async => _rows;
  @override
  Future<void> updateLocalViews(String id, int count) async {}
}

class _Location extends LocationAccessNotifier {
  _Location() : super(LocationService()) {
    state = const LocationAccessState(
      failure: LocationFailure(LocationProblem.denied),
    );
  }
}

class _Interactions extends InteractionsService {
  @override
  Future<void> view(String id, String userId) async {}
  @override
  Stream<MemoryInteractions> watch(String id, String userId) async* {
    yield MemoryInteractions(
      views: 12,
      likes: 3,
      comments: [
        MemoryComment(
          username: 'gezgin',
          text: 'Bu ışık çok güzel.',
          createdAt: DateTime(2026, 10, 6),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('capture polished UI with labelled visual fixtures',
      (tester) async {
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: '/private/tmp/gostory-polish-map-cache',
    );
    try {
      addTearDown(() => debugDisableShadows = shadows);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        for (final family in ['Inter', 'PlusJakartaSans']) {
          await (FontLoader(family)
                ..addFont(rootBundle.load('assets/fonts/$family.ttf')))
              .load();
        }
        await (FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
            .load();
      });
      final boundary = GlobalKey();
      final interactions = _Interactions();
      addTearDown(interactions.dispose);
      Future<void> show(Widget screen, {int tab = 0}) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(_Auth()),
              memoryStoreProvider.overrideWithValue(_Archive()),
              interactionsServiceProvider.overrideWithValue(interactions),
              locationAccessProvider.overrideWith((_) => _Location()),
              draftLocationProvider.overrideWith((_) => const LatLng(41, 29)),
              selectedTabProvider.overrideWith((_) => tab),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              builder: (context, child) => RepaintBoundary(
                key: boundary,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(top: 44, bottom: 24),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
              ),
              home: screen,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final data =
              (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final file = File('docs/design/polish/$name-sample.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data.buffer.asUint8List());
          image.dispose();
        });
      }

      await show(const HomeScreen(), tab: 2);
      await capture('profile');
      await show(const HomeScreen(), tab: 1);
      await capture('camera-starter');
      await show(const PreviewScreen(photoPath: 'demo://preview'));
      await capture('preview');
      await show(MemoryDetailScreen(memory: _rows.first));
      await capture('memory');
      await tester.drag(
        find.byKey(const ValueKey('memory-detail-scroll')),
        const Offset(0, -480),
      );
      await tester.pumpAndSettle();
      await capture('comments');
    } finally {
      debugDisableShadows = shadows;
    }
  });
}
