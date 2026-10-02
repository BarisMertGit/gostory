import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/utils/identifiers.dart';
import '../../core/utils/logger.dart';
import '../../features/preview/domain/memory_draft.dart';
import '../models/memory.dart';

final memoryStoreProvider = Provider((ref) {
  final store = MemoryStore(resolveCity: GeocodingService().city);
  ref.onDispose(store.dispose);
  return store;
});
final personalMemoriesProvider =
    FutureProvider((ref) => ref.watch(memoryStoreProvider).read());

/// Device-local archive; mutations are serialized to prevent lost updates.
class MemoryStore {
  MemoryStore({this.directory, this.resolveCity});
  final Future<Directory> Function()? directory;
  final Future<String> Function(double, double)? resolveCity;
  Future<void> _pending = Future.value();
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  Future<void> dispose() => _changes.close();

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<Directory> _directory() async =>
      directory != null ? directory!() : getApplicationSupportDirectory();

  Future<List<Memory>> _read(Directory dir) async {
    final file = File(p.join(dir.path, 'memories.json'));
    if (!await file.exists()) return [];
    final rows = jsonDecode(await file.readAsString()) as List;
    return rows.map((row) {
      final memory = Memory.fromJson(Map<String, dynamic>.from(row as Map));
      return memory.copyWith(
        photoUrl: memory.photoUrl.isEmpty ||
                p.isAbsolute(memory.photoUrl) ||
                memory.photoUrl.startsWith('https://')
            ? memory.photoUrl
            : p.join(dir.path, memory.photoUrl),
      );
    }).toList();
  }

  Future<List<Memory>> read() => _exclusive(
        () async => (await _read(await _directory()))
            .where((m) => !m.isDeleted)
            .toList(),
      );

  Future<void> _write(Directory dir, List<Memory> memories) async {
    final rows = memories
        .map(
          (memory) => memory
              .copyWith(
                photoUrl: p.isWithin(dir.path, memory.photoUrl)
                    ? p.relative(memory.photoUrl, from: dir.path)
                    : memory.photoUrl,
              )
              .toJson(),
        )
        .toList();
    final file = File(p.join(dir.path, 'memories.json'));
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(rows), flush: true);
    await temp.rename(file.path);
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> save(MemoryDraft draft) => _exclusive(() async {
        if (draft.latitude == null ||
            draft.longitude == null ||
            draft.creatorId == null) {
          throw StateError('Konum ve profil gerekli.');
        }
        final source = File(draft.photoPath);
        if (await source.length() > AppConstants.maxPhotoSizeMB * 1024 * 1024) {
          throw const ValidationException(
            'Fotoğraf en fazla 5 MB olabilir. Daha küçük bir fotoğraf seç.',
          );
        }
        final dir = await _directory();
        await dir.create(recursive: true);
        final memories = await _read(dir);
        final id = newArchiveId();
        final photo =
            File(p.join(dir.path, 'memory_$id${p.extension(draft.photoPath)}'));
        var city = '';
        try {
          city = await resolveCity
                  ?.call(draft.latitude!, draft.longitude!)
                  .timeout(const Duration(seconds: 3)) ??
              '';
        } catch (error, stack) {
          AppLogger.error(
            'Şehir çözümlenemedi.',
            error: error.runtimeType,
            stackTrace: stack,
          );
        }
        await source.copy(photo.path);
        memories.insert(
          0,
          Memory(
            id: id,
            creatorId: draft.creatorId!,
            creatorUsername: draft.creatorUsername ?? '',
            photoUrl: photo.path,
            textNote: draft.note,
            latitude: draft.latitude!,
            longitude: draft.longitude!,
            city: city,
            createdAt: DateTime.now(),
            isPublic: draft.isPublic,
            syncPending: true,
          ),
        );
        try {
          await _write(dir, memories);
        } catch (error, stack) {
          AppLogger.error(
            'İşlem başarısız.',
            tag: 'memories_provider',
            error: error.runtimeType,
            stackTrace: stack,
          );
          await photo.delete();
          rethrow;
        }
      });

  Future<List<Memory>> pendingUploads() => _exclusive(
        () async => (await _read(await _directory()))
            .where((m) => m.syncPending)
            .toList(),
      );

  // Acknowledge only the uploaded revision; a concurrent delete stays queued.
  Future<void> acknowledge(Memory uploaded) => _exclusive(() async {
        final dir = await _directory();
        final rows = await _read(dir);
        final index = rows.indexWhere((m) => m.id == uploaded.id);
        if (index < 0 || rows[index].revision != uploaded.revision) return;
        if (uploaded.isDeleted) {
          rows.removeAt(index);
        } else {
          rows[index] = rows[index].copyWith(syncPending: false);
        }
        await _write(dir, rows);
      });

  Future<void> updateLocalViews(String id, int count) => _exclusive(() async {
        final dir = await _directory();
        final rows = await _read(dir);
        final index = rows.indexWhere((m) => m.id == id && !m.isDeleted);
        if (index < 0 || rows[index].viewCount == count) return;
        rows[index] = rows[index].copyWith(viewCount: count);
        await _write(dir, rows);
      });

  Future<void> setPublic(
    String id, {
    required String creatorId,
    required bool value,
  }) =>
      _exclusive(() async {
        final dir = await _directory();
        final rows = await _read(dir);
        final index = rows.indexWhere((m) => m.id == id && !m.isDeleted);
        if (index < 0) throw StateError('Anı bulunamadı.');
        final memory = rows[index];
        if (memory.creatorId != creatorId) {
          throw StateError('Bu anıyı değiştiremezsin.');
        }
        rows[index] = memory.copyWith(
          isPublic: value,
          syncPending: true,
          revision: memory.revision + 1,
        );
        await _write(dir, rows);
      });

  Future<void> delete(String id, {required String creatorId}) =>
      _exclusive(() async {
        final dir = await _directory();
        final memories = await _read(dir);
        final memory = memories.where((m) => m.id == id).firstOrNull;
        if (memory == null) return;
        if (memory.creatorId != creatorId) {
          throw StateError('Bu anıyı silemezsin.');
        }
        memories[memories.indexOf(memory)] = memory.copyWith(
          isDeleted: true,
          syncPending: true,
          revision: memory.revision + 1,
        );
        await _write(dir, memories);
        // Only remove photos owned by the archive, after committing the index.
        if (p.isWithin(dir.path, memory.photoUrl) &&
            p.basename(memory.photoUrl).startsWith('memory_')) {
          try {
            final photo = File(memory.photoUrl);
            if (await photo.exists()) await photo.delete();
          } catch (error, stack) {
            AppLogger.error(
              'Silinen anının fotoğrafı temizlenemedi.',
              error: error.runtimeType,
              stackTrace: stack,
            );
          }
        }
      });
}
