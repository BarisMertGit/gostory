import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/services/auth_service.dart';
import 'package:gostory/core/services/interactions_service.dart';
import 'package:gostory/core/services/memory_creation_events.dart';
import 'package:gostory/features/preview/domain/memory_draft.dart';
import 'package:gostory/features/preview/presentation/providers/preview_provider.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/auth_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';

void main() {
  late Directory dir;
  late MemoryStore store;
  late File photo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('gostory-social-');
    store = MemoryStore(directory: () async => dir);
    photo = await File('${dir.path}/source.jpg').writeAsBytes([1, 2, 3]);
    addTearDown(store.dispose);
    addTearDown(() => dir.delete(recursive: true));
  });
  MemoryDraft draft({bool public = false}) => MemoryDraft(
        photoPath: photo.path,
        note: 'Bir anı',
        creatorId: 'author',
        creatorUsername: 'deniz',
        latitude: 41,
        longitude: 29,
        isPublic: public,
      );

  test(
      'public flag and upload queue survive restart; personal provider returns saved entry',
      () async {
    await store.save(draft(public: true));
    final container = ProviderContainer(
      overrides: [memoryStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(personalMemoriesProvider.future)).single.isPublic,
      isTrue,
    );
    final restored = MemoryStore(directory: () async => dir);
    addTearDown(restored.dispose);
    expect((await restored.pendingUploads()).single.isPublic, isTrue);
  });
  test('older JSON is private with zero real views', () {
    final json = Memory(
      id: 'id',
      creatorId: 'uid',
      creatorUsername: 'deniz',
      photoUrl: '',
      textNote: 'anı',
      latitude: 41,
      longitude: 29,
      city: '',
      createdAt: DateTime(2026),
    ).toJson();
    json.remove('public');
    json.remove('syncPending');
    expect(Memory.fromJson(json).isPublic, isFalse);
    expect(Memory.fromJson(json).viewCount, 0);
  });
  test(
      'upload acknowledgement cannot lose a concurrent visibility change or deletion',
      () async {
    await store.save(draft(public: true));
    final uploading = (await store.pendingUploads()).single;
    await store.setPublic(uploading.id, creatorId: 'author', value: false);
    await store.acknowledge(uploading);
    expect((await store.pendingUploads()).single.isPublic, isFalse);
    final nextUpload = (await store.pendingUploads()).single;
    await store.delete(uploading.id, creatorId: 'author');
    await store.acknowledge(nextUpload);
    expect(await store.read(), isEmpty);
    final tombstone = (await store.pendingUploads()).single;
    expect(tombstone.isDeleted, isTrue);
    await store.acknowledge(tombstone);
    expect(await store.pendingUploads(), isEmpty);
  });
  test('visibility change rejects another author', () async {
    await store.save(draft());
    final memory = (await store.read()).single;
    await expectLater(
      store.setPublic(memory.id, creatorId: 'other', value: true),
      throwsStateError,
    );
    expect((await store.read()).single.isPublic, isFalse);
  });
  test('auth provider retains identity and refreshes profile after edit',
      () async {
    final auth =
        AuthService(profileFile: () async => File('${dir.path}/profile.json'));
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    final first = await container.read(authStateProvider.future);
    await auth.updateUsername('deniz_yolda');
    container.invalidate(authStateProvider);
    final next = await container.read(authStateProvider.future);
    expect(next.uid, first.uid);
    expect(next.username, 'deniz_yolda');
  });
  test('auth provider exposes corruption and permits retry after repair',
      () async {
    final file = await File('${dir.path}/profile.json').writeAsString('{');
    final auth = AuthService(profileFile: () async => file);
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(authStateProvider.future),
      throwsFormatException,
    );
    await file
        .writeAsString(jsonEncode({'uid': 'stable', 'username': 'deniz'}));
    container.invalidate(authStateProvider);
    expect((await container.read(authStateProvider.future)).uid, 'stable');
  });
  test('visits and likes are idempotent; concurrent comments survive reload',
      () async {
    final service = InteractionsService(directory: () async => dir);
    addTearDown(service.dispose);
    await Future.wait([
      service.view('m', 'a'),
      service.view('m', 'a'),
      service.view('m', 'b'),
    ]);
    await service.like('m', 'a', true);
    await service.like('m', 'a', true);
    await Future.wait([
      service.comment('m', 'a', 'deniz', 'Birinci'),
      service.comment('m', 'b', 'elif', 'İkinci'),
    ]);
    final restored = InteractionsService(directory: () async => dir);
    addTearDown(restored.dispose);
    final stats = await restored.load('m', 'a');
    expect(stats.views, 2);
    expect(stats.likes, 1);
    expect(stats.comments.length, 2);
    expect(
      stats.comments.every((comment) => comment.createdAt != null),
      isTrue,
    );
    await restored.like('m', 'a', false);
    expect((await restored.load('m', 'a')).likes, 0);
    await expectLater(
      restored.comment('m', 'a', 'deniz', ' '),
      throwsArgumentError,
    );
  });
  test(
      'creation events distinguish local commit from failure and ignore duplicate submit',
      () async {
    final events = <MemoryCreationEvent>[];
    final preview = PreviewNotifier(
      photoPath: 'photo',
      saveDraft: (_) async {},
      onCreationEvent: events.add,
    );
    addTearDown(preview.dispose);
    preview.updateNote('Bir anı');
    preview.setPublic(true);
    expect(await preview.submit(), isTrue);
    expect(await preview.submit(), isFalse);
    expect(
      events.map((e) => e.phase),
      [MemoryCreationPhase.started, MemoryCreationPhase.saved],
    );
    expect(events.every((e) => e.isPublic), isTrue);
    events.clear();
    final failed = PreviewNotifier(
      photoPath: 'photo',
      saveDraft: (_) async => throw StateError('failed'),
      onCreationEvent: events.add,
    );
    addTearDown(failed.dispose);
    failed.updateNote('Bir anı');
    expect(await failed.submit(), isFalse);
    expect(events.last.phase, MemoryCreationPhase.failed);
    expect(events.last.reason, 'local_save_failed');
  });
}
