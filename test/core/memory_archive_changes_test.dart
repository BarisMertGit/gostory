import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/core/errors/app_exceptions.dart';
import 'package:gostory/features/preview/domain/memory_draft.dart';
import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/memories_provider.dart';

void main() {
  late Directory dir;
  late File photo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('archive-changes-');
    photo = await File('${dir.path}/source.jpg').writeAsBytes([1, 2, 3]);
  });
  tearDown(() => dir.delete(recursive: true));
  MemoryDraft draft() => MemoryDraft(
        photoPath: photo.path,
        note: 'Not',
        creatorId: 'owner',
        creatorUsername: 'deniz',
        latitude: 41,
        longitude: 29,
      );

  test('JSON round trip retains all fields and accepts integer coordinates',
      () {
    final memory = Memory(
      id: '1',
      creatorId: 'owner',
      creatorUsername: 'deniz',
      photoUrl: 'photo.jpg',
      textNote: 'Not',
      latitude: 41,
      longitude: 29,
      city: 'İstanbul',
      createdAt: DateTime.utc(2026),
      viewCount: 12,
    );
    final json = memory.toJson();
    json['latitude'] = 41;
    expect(Memory.fromJson(json).toJson(), memory.toJson());
  });
  test('legacy archive remains readable', () async {
    await File('${dir.path}/memories.json').writeAsString(
      jsonEncode([
        {
          'id': 'old',
          'creatorId': 'owner',
          'username': 'deniz',
          'photo': 'source.jpg',
          'note': 'Eski anı',
          'latitude': 41,
          'longitude': 29,
          'createdAt': '2025-01-01T00:00:00.000Z',
        }
      ]),
    );
    final memory =
        (await MemoryStore(directory: () async => dir).read()).single;
    expect(memory.photoUrl, photo.path);
    expect(memory.textNote, 'Eski anı');
    expect(memory.city, '');
  });
  test('concurrent saves retain both entries and resolved city', () async {
    final store = MemoryStore(
      directory: () async => dir,
      resolveCity: (_, __) async => 'İstanbul',
    );
    await Future.wait([store.save(draft()), store.save(draft())]);
    final memories = await store.read();
    expect(memories.length, 2);
    expect(memories.map((m) => m.id).toSet().length, 2);
    expect(memories.every((m) => m.city == 'İstanbul'), isTrue);
  });
  test('geocoding outage does not prevent local save', () async {
    final store = MemoryStore(
      directory: () async => dir,
      resolveCity: (_, __) async => throw StateError('offline'),
    );
    await store.save(draft());
    expect((await store.read()).single.latitude, 41);
  });
  test('oversized photo leaves no archive or copied photo', () async {
    final handle = await photo.open(mode: FileMode.write);
    await handle.truncate(5 * 1024 * 1024 + 1);
    await handle.close();
    final store = MemoryStore(directory: () async => dir);
    await expectLater(store.save(draft()), throwsA(isA<ValidationException>()));
    expect(await store.read(), isEmpty);
    expect(await dir.list().length, 1);
  });
  test('delete enforces ownership and removes only archived photo', () async {
    final store = MemoryStore(directory: () async => dir);
    await store.save(draft());
    final memory = (await store.read()).single;
    await expectLater(
      store.delete(memory.id, creatorId: 'other'),
      throwsStateError,
    );
    expect(await store.read(), hasLength(1));
    await store.delete(memory.id, creatorId: 'owner');
    expect(await store.read(), isEmpty);
    expect(await File(memory.photoUrl).exists(), isFalse);
    expect(await photo.exists(), isTrue);
  });
}
