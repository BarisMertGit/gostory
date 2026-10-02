import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/memory.dart';
import 'auth_service.dart';

/// Opt in only after platform Firebase files and server rules are installed.
class PublicMemoryPage {
  const PublicMemoryPage(this.memories, this.cursor, this.hasMore);
  final List<Memory> memories;
  final DocumentSnapshot? cursor;
  final bool hasMore;
}

class CloudService {
  static const enabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static bool ready = false;
  static String? startupError;
  static Future<void> initialize() async {
    if (!enabled) return;
    try {
      await Firebase.initializeApp();
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      ready = true;
    } catch (_) {
      startupError =
          'Bulut bağlantısı başlatılamadı. Anıların cihazda saklanıyor.';
    }
  }

  FirebaseFirestore get db => FirebaseFirestore.instance;
  static Future<String>? _authentication;
  Future<String> authenticate() {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return Future.value(current.uid);
    return _authentication ??= _signIn();
  }

  Future<String> _signIn() async {
    try {
      return (await FirebaseAuth.instance.signInAnonymously()).user!.uid;
    } finally {
      _authentication = null;
    }
  }

  Future<void> saveProfile(LocalUser user) async {
    final owner = await authenticate();
    // Local avatar paths are never published.
    await db.collection('profiles').doc(user.uid).set({
      'ownerId': owner,
      'username': user.username,
      'bio': user.bio,
      'socialLinks': user.socialLinks,
    });
  }

  Future<void> upload(Memory memory) async {
    final owner = await authenticate();
    final doc = db.collection('memories').doc(memory.id);
    final photo = FirebaseStorage.instance.ref('photos/$owner/${memory.id}');
    if (memory.isDeleted) {
      await doc.delete();
      try {
        await photo.delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
      return;
    }
    final profile =
        (await db.collection('profiles').doc(memory.creatorId).get()).data();
    if (profile == null || profile['ownerId'] != owner) {
      throw StateError('Profil sahipliği doğrulanamadı.');
    }
    final previous = await doc.get();
    if (!previous.exists) {
      final extension = memory.photoUrl.split('.').last.toLowerCase();
      final type = {
            'png': 'image/png',
            'webp': 'image/webp',
            'heic': 'image/heic',
          }[extension] ??
          'image/jpeg';
      await photo.putFile(
        File(memory.photoUrl),
        SettableMetadata(contentType: type),
      );
    }
    // Store a guarded Storage path rather than a permanent public download token.
    final data =
        memory.copyWith(photoUrl: 'storage://${photo.fullPath}').toJson();
    data.remove('syncPending');
    data.remove('isDeleted');
    data.remove('viewCount');
    data['ownerId'] = owner;
    data['creatorUsername'] = profile['username'];
    if (!previous.exists) {
      data.addAll({'viewCount': 0, 'likeCount': 0, 'commentCount': 0});
    }
    await doc.set(data, SetOptions(merge: true));
  }

  Future<PublicMemoryPage> publicPage({
    DocumentSnapshot? after,
    int limit = 40,
  }) async {
    await authenticate().timeout(const Duration(seconds: 5));
    Query<Map<String, dynamic>> query = db
        .collection('memories')
        .where('public', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (after != null) query = query.startAfterDocument(after);
    final result = await query.get().timeout(const Duration(seconds: 5));
    return PublicMemoryPage(
      result.docs
          .map((d) => Memory.fromJson({...d.data(), 'id': d.id}))
          .toList(),
      result.docs.lastOrNull,
      result.docs.length == limit,
    );
  }
}
