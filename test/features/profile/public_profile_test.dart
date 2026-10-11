import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/app/theme/app_theme.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/widgets/memory_tile.dart';

void main() {
  final memory = Memory(
    id: 'public-memory',
    creatorId: 'author',
    creatorUsername: 'deniz',
    photoUrl: '',
    textNote: 'Paylaşılan hikâye',
    latitude: 41,
    longitude: 29,
    city: 'İstanbul',
    createdAt: DateTime(2026),
    isPublic: true,
  );
  const user = LocalUser(
    uid: 'author',
    username: 'deniz_yolda',
    bio: 'Gezgin biyografisi',
  );

  Future<void> mount(
    WidgetTester tester,
    Future<LocalUser?> Function() load, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicProfileProvider('author').overrideWith((ref) => load()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: PublicProfileScreen(memory: memory),
        ),
      ),
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'public profile retains identity, bio and memory at text scale $scale',
        (tester) async {
      await mount(tester, () async => user, scale: scale);
      await tester.pumpAndSettle();
      expect(find.text('@deniz_yolda'), findsOneWidget);
      expect(find.text('Gezgin biyografisi'), findsOneWidget);
      expect(find.byType(MemoryTile), findsOneWidget);
      expect(
        tester.widget<MemoryTile>(find.byType(MemoryTile)).memory,
        same(memory),
      );
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing profile falls back to the memory author',
      (tester) async {
    await mount(tester, () async => null);
    await tester.pumpAndSettle();
    expect(find.text('@deniz'), findsOneWidget);
    expect(
      find.text('Bu kullanıcı için paylaşılmış profil bilgisi yok.'),
      findsOneWidget,
    );
    expect(find.byType(MemoryTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty bio keeps identity and shared memory visible',
      (tester) async {
    await mount(
      tester,
      () async => const LocalUser(uid: 'author', username: 'deniz'),
    );
    await tester.pumpAndSettle();
    expect(find.text('@deniz'), findsOneWidget);
    expect(
      find.text('Bu kullanıcı için paylaşılmış profil bilgisi yok.'),
      findsNothing,
    );
    expect(find.byType(MemoryTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading resolves into the public profile', (tester) async {
    final completion = Completer<LocalUser?>();
    await mount(tester, () => completion.future);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MemoryTile), findsNothing);
    completion.complete(user);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('@deniz_yolda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed load retries and restores the profile', (tester) async {
    var attempts = 0;
    await mount(tester, () async {
      if (++attempts == 1) throw StateError('Offline');
      return user;
    });
    await tester.pumpAndSettle();
    expect(find.text('Profil yüklenemedi'), findsOneWidget);
    await tester.tap(find.text('Profili yeniden yükle'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('@deniz_yolda'), findsOneWidget);
    expect(find.byType(MemoryTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
