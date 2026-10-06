import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/home_screen.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';

class _ArchiveSnapshot extends MemoryStore {
  _ArchiveSnapshot(this.rows);
  final List<Memory> rows;
  @override
  Future<List<Memory>> read() async => rows;
}

class _ProfileSnapshot extends AuthService {
  _ProfileSnapshot(this.user);
  final LocalUser user;
  @override
  Future<LocalUser> signIn() async => user;
}

void main() {
  testWidgets(
      'capture the three redesigned screens with the existing local archive',
      (tester) async {
    final archivePath = Platform.environment['GOSTORY_ARCHIVE_DIR'] ??
        '${Platform.environment['HOME']}/Library/Containers/com.gostory.gostory/Data/Library/Application Support/com.gostory.gostory';
    late LocalUser user;
    late List<Memory> rows;
    await tester.runAsync(() async {
      final file = File('$archivePath/gostory_profile.json');
      if (!await file.exists()) {
        throw StateError(
          'Set GOSTORY_ARCHIVE_DIR to an existing profile; this capture does not create sample users.',
        );
      }
      user = await AuthService(profileFile: () async => file).signIn();
      final store = MemoryStore(directory: () async => Directory(archivePath));
      rows = await store.read();
      await store.dispose();
      final bytes = await File('/System/Library/Fonts/Supplemental/Arial.ttf')
          .readAsBytes();
      for (final family in ['Ahem', 'Roboto', 'SF Pro Text', '.SF UI Text']) {
        await (FontLoader(family)
              ..addFont(Future.value(ByteData.sublistView(bytes))))
            .load();
      }
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
    });
    BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: '/private/tmp/gostory-design-map-cache',
    );
    final oldHttp = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = oldHttp);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_ProfileSnapshot(user)),
          memoryStoreProvider.overrideWithValue(_ArchiveSnapshot(rows)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          builder: (context, child) => RepaintBoundary(
            key: boundaryKey,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 44, bottom: 24),
              ),
              child: child!,
            ),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(seconds: 4)));
    await tester.pumpAndSettle();
    for (final screen
        in {'map': 'Harita', 'share': 'Paylaş', 'profile': 'Profil'}.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(screen.value),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final file = File('docs/design/${screen.key}-390.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });
}
