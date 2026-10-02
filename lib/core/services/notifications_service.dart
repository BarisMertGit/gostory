import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/cloud_provider.dart';
import '../../shared/providers/location_provider.dart';
import 'cloud_service.dart';

final notificationOpenProvider = StateProvider<String?>((ref) => null);
final notificationMessageProvider =
    StateProvider<RemoteMessage?>((ref) => null);
final notificationsServiceProvider = Provider((ref) {
  final service = NotificationsService(ref);
  unawaited(service.resume());
  ref.onDispose(service.dispose);
  ref.listen(locationAccessProvider, (_, next) {
    if (next.position != null) unawaited(service.updateLocation());
  });
  return service;
});

class NotificationsService {
  NotificationsService(this.ref);
  final Ref ref;
  Future<File> _file() async => File(
        '${(await getApplicationSupportDirectory()).path}/notifications.json',
      );
  Future<Map<String, dynamic>> preferences() async {
    final file = await _file();
    return await file.exists()
        ? Map<String, dynamic>.from(
            jsonDecode(await file.readAsString()) as Map,
          )
        : {};
  }

  Future<void> resume() async {
    if (!CloudService.ready) return;
    try {
      final prefs = await preferences();
      if (prefs['enabled'] == true) {
        await enable(nearby: prefs['nearby'] == true);
      }
    } catch (_) {}
  }

  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _messages;
  StreamSubscription<RemoteMessage>? _opened;
  Future<void> _store(String token, {required bool nearby}) async {
    final user = await ref.read(authServiceProvider).signIn();
    final cloud = ref.read(cloudServiceProvider);
    final owner = await cloud.authenticate();
    await cloud.saveProfile(user);
    final position = ref.read(locationAccessProvider).position;
    final existing =
        (await cloud.db.collection('notificationDevices').doc(token).get())
            .data();
    final lat = position?.latitude ?? existing?['latitude'];
    final lng = position?.longitude ?? existing?['longitude'];
    final locationUpdatedAt = position != null
        ? FieldValue.serverTimestamp()
        : existing?['locationUpdatedAt'];
    await cloud.db.collection('notificationDevices').doc(token).set({
      'ownerId': owner,
      'profileId': user.uid,
      'token': token,
      'replies': true,
      'nearby':
          nearby && lat != null && lng != null && locationUpdatedAt != null,
      if (nearby && lat != null) 'latitude': lat,
      if (nearby && lng != null) 'longitude': lng,
      if (nearby && locationUpdatedAt != null)
        'locationUpdatedAt': locationUpdatedAt,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLocation() async {
    if (!CloudService.ready) return;
    try {
      final prefs = await preferences();
      if (prefs['enabled'] != true || prefs['nearby'] != true) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _store(token, nearby: true);
    } catch (_) {}
  }

  Future<bool> enable({bool nearby = false}) async {
    if (!CloudService.ready) {
      throw StateError('Firebase yapılandırması gerekli.');
    }
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    // APNs registration must complete before requesting an FCM token on iOS.
    if (Platform.isIOS && await messaging.getAPNSToken() == null) {
      throw StateError('APNs kaydı henüz hazır değil. Tekrar dene.');
    }
    final token = await messaging.getToken();
    if (token == null) {
      throw StateError('Bildirim kaydı henüz hazır değil. Tekrar dene.');
    }
    await _store(token, nearby: nearby);
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'enabled': true, 'nearby': nearby}),
      flush: true,
    );
    await _tokens?.cancel();
    _tokens = messaging.onTokenRefresh.listen((token) async {
      try {
        await _store(token, nearby: nearby);
      } catch (_) {}
    });
    _messages ??= FirebaseMessaging.onMessage.listen(
      (message) =>
          ref.read(notificationMessageProvider.notifier).state = message,
    );
    _opened ??= FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => ref.read(notificationOpenProvider.notifier).state =
          message.data['memoryId'] as String?,
    );
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      ref.read(notificationOpenProvider.notifier).state =
          initial.data['memoryId'] as String?;
    }
    return true;
  }

  Future<void> disable() async {
    if (!CloudService.ready) return;
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await ref
          .read(cloudServiceProvider)
          .db
          .collection('notificationDevices')
          .doc(token)
          .delete();
    }
    await FirebaseMessaging.instance.deleteToken();
    await (await _file()).writeAsString(
      jsonEncode({'enabled': false, 'nearby': false}),
      flush: true,
    );
    await _tokens?.cancel();
    _tokens = null;
  }

  void dispose() {
    _tokens?.cancel();
    _messages?.cancel();
    _opened?.cancel();
  }
}
