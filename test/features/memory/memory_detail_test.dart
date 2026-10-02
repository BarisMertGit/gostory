import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/interactions_service.dart';
import 'package:gostory/features/map/presentation/widgets/memory_bottom_sheet.dart';
import 'package:gostory/features/memory/presentation/memory_detail_screen.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/interactions_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';
import 'package:gostory/shared/widgets/memory_photo.dart';

class _DetailAuth extends AuthService {
  @override
  Future<LocalUser> signIn() async =>
      const LocalUser(uid: 'visitor', username: 'gezgin');
}

class _DetailInteractions extends InteractionsService {
  @override
  Future<void> view(String id, String userId) async {}
}

class _DetailStore extends MemoryStore {
  @override
  Future<void> updateLocalViews(String id, int count) async {}
}

void main() {
  final overrides = [
    authServiceProvider.overrideWithValue(_DetailAuth()),
    memoryStoreProvider.overrideWithValue(_DetailStore()),
    interactionsServiceProvider.overrideWithValue(_DetailInteractions()),
    interactionsProvider('demo')
        .overrideWith((ref) => Stream.value(const MemoryInteractions())),
  ];
  final memory = Memory(
    id: 'demo',
    creatorId: 'user',
    creatorUsername: 'deniz',
    photoUrl: 'demo://istanbul',
    textNote: 'Hatırlamak istediğim bir gün.',
    latitude: 41,
    longitude: 29,
    city: 'İstanbul',
    createdAt: DateTime(2026, 9, 29),
  );
  testWidgets('thumbnail opens full note, photo and location details',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MemoryBottomSheet(memory: memory, onDismiss: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.byType(MemoryPhoto), findsOneWidget);
    await tester.tap(find.text('Anıyı aç'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.byType(MemoryDetailScreen), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text(memory.textNote), findsOneWidget);
    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.text('41.00000, 29.00000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing photo keeps detail usable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: MemoryDetailScreen(
            memory: memory.copyWith(photoUrl: ''),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text(memory.textNote), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
