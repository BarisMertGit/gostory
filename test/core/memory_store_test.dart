import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gostory/features/preview/domain/memory_draft.dart';
import 'package:gostory/features/preview/presentation/providers/preview_provider.dart';
import 'package:gostory/shared/providers/memories_provider.dart';

void main() {
  test('archive keeps actual photo, note and coordinates after reload',
      () async {
    final dir = await Directory.systemTemp.createTemp('gostory-memories-');
    addTearDown(() => dir.delete(recursive: true));
    final photo = File('${dir.path}/source.jpg');
    await photo.writeAsBytes([1, 2, 3]);
    final store = MemoryStore(directory: () async => dir);
    await store.save(
      MemoryDraft(
        photoPath: photo.path,
        note: 'Bir anı',
        creatorId: 'user',
        creatorUsername: 'deniz',
        latitude: 40.5,
        longitude: 29.1,
      ),
    );
    await photo.delete();
    final rows = await MemoryStore(directory: () async => dir).read();
    expect(rows.single.creatorId, 'user');
    expect(rows.single.latitude, 40.5);
    expect(rows.single.city, isEmpty);
    expect(await File(rows.single.photoUrl).readAsBytes(), [1, 2, 3]);
  });
  test('failed archive write does not report a successful share', () async {
    final notifier = PreviewNotifier(
      photoPath: 'missing',
      saveDraft: (_) async => throw const FileSystemException(),
    );
    addTearDown(notifier.dispose);
    notifier.updateNote('Bir anı bırakıyorum.');
    expect(await notifier.submit(), isFalse);
    expect(notifier.state.isSubmitted, isFalse);
    expect(notifier.state.isSubmitting, isFalse);
    expect(notifier.state.validationError, isNotNull);
  });
}
