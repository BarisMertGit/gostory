import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import 'cloud_service.dart';

class MemoryComment {
  const MemoryComment({
    required this.username,
    required this.text,
    this.createdAt,
  });
  final String username;
  final String text;
  final DateTime? createdAt;
}

class MemoryInteractions {
  const MemoryInteractions({
    this.views = 0,
    this.likes = 0,
    this.liked = false,
    this.comments = const [],
  });
  final int views;
  final int likes;
  final bool liked;
  final List<MemoryComment> comments;
}

class InteractionsService {
  InteractionsService({this.directory});
  final Future<Directory> Function()? directory;
  Future<void> _pending = Future.value();
  final _changes = StreamController<void>.broadcast();
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<File> _file() async {
    final dir = await (directory?.call() ?? getApplicationSupportDirectory());
    await dir.create(recursive: true);
    return File('${dir.path}/interactions.json');
  }

  Future<Map<String, dynamic>> _read() async {
    final file = await _file();
    return await file.exists()
        ? Map<String, dynamic>.from(
            jsonDecode(await file.readAsString()) as Map,
          )
        : {};
  }

  Future<void> _mutate(String id, void Function(Map<String, dynamic>) change) =>
      _exclusive(() async {
        final all = await _read();
        final row = Map<String, dynamic>.from(all[id] as Map? ?? {});
        change(row);
        all[id] = row;
        final file = await _file();
        final temp = File('${file.path}.tmp');
        await temp.writeAsString(jsonEncode(all), flush: true);
        await temp.rename(file.path);
        _changes.add(null);
      });
  Future<MemoryInteractions> load(String id, String userId) async {
    if (CloudService.ready) {
      final cloud = CloudService();
      final uid = await cloud.authenticate();
      final doc = cloud.db.collection('memories').doc(id);
      final data = (await doc.get()).data() ?? {};
      final liked = (await doc.collection('likes').doc(uid).get()).exists;
      final comments = await doc
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return MemoryInteractions(
        views: (data['viewCount'] as num?)?.toInt() ?? 0,
        likes: (data['likeCount'] as num?)?.toInt() ?? 0,
        liked: liked,
        comments: comments.docs
            .map(
              (d) => MemoryComment(
                username: d.data()['username'] as String,
                text: d.data()['text'] as String,
                createdAt: (d.data()['createdAt'] as Timestamp?)?.toDate(),
              ),
            )
            .toList(),
      );
    }
    return _exclusive(() async {
      final row = (await _read())[id] as Map? ?? {};
      final likes = List<String>.from(row['likes'] as List? ?? []);
      return MemoryInteractions(
        views: (row['views'] as List? ?? []).length,
        likes: likes.length,
        liked: likes.contains(userId),
        comments: (row['comments'] as List? ?? [])
            .reversed
            .take(50)
            .map(
              (r) => MemoryComment(
                username: r['username'] as String,
                text: r['text'] as String,
                createdAt: DateTime.tryParse(r['createdAt'] as String? ?? ''),
              ),
            )
            .toList(),
      );
    });
  }

  Stream<MemoryInteractions> watch(String id, String userId) async* {
    yield await load(id, userId);
    if (CloudService.ready) {
      yield* CloudService()
          .db
          .collection('memories')
          .doc(id)
          .snapshots()
          .asyncMap((_) => load(id, userId));
    } else {
      yield* _changes.stream.asyncMap((_) => load(id, userId));
    }
  }

  Future<void> view(String id, String userId) async {
    if (CloudService.ready) {
      final cloud = CloudService();
      final uid = await cloud.authenticate();
      final doc =
          cloud.db.collection('memories').doc(id).collection('views').doc(uid);
      // Idempotent once per authenticated visitor; no synthetic counts.
      await cloud.db.runTransaction((t) async {
        if (!(await t.get(doc)).exists) {
          t.set(doc, {'createdAt': FieldValue.serverTimestamp()});
        }
      });
      return;
    }
    await _mutate(id, (row) {
      final views = List<String>.from(row['views'] as List? ?? []);
      if (!views.contains(userId)) views.add(userId);
      row['views'] = views;
    });
  }

  Future<void> like(String id, String userId, bool value) async {
    if (CloudService.ready) {
      final cloud = CloudService();
      final uid = await cloud.authenticate();
      final doc =
          cloud.db.collection('memories').doc(id).collection('likes').doc(uid);
      if (value) {
        await doc.set({'createdAt': FieldValue.serverTimestamp()});
      } else {
        await doc.delete();
      }
      return;
    }
    await _mutate(id, (row) {
      final likes = List<String>.from(row['likes'] as List? ?? []);
      likes.remove(userId);
      if (value) likes.add(userId);
      row['likes'] = likes;
    });
  }

  Future<void> comment(
    String id,
    String userId,
    String username,
    String value,
  ) async {
    final text = value.trim();
    if (text.isEmpty || text.length > 500) {
      throw ArgumentError('Yorum 1–500 karakter olmalı.');
    }
    if (CloudService.ready) {
      final cloud = CloudService();
      final uid = await cloud.authenticate();
      await cloud.db.collection('memories').doc(id).collection('comments').add({
        'authorId': uid,
        'profileId': userId,
        'username': username,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await _mutate(id, (row) {
      row['comments'] = [
        ...row['comments'] as List? ?? [],
        {
          'username': username,
          'text': text,
          'authorId': userId,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      ];
    });
  }

  Future<void> dispose() => _changes.close();
}
