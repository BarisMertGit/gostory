import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/cloud_service.dart';
import 'auth_provider.dart';
import 'memories_provider.dart';

final cloudServiceProvider = Provider((ref) => CloudService());
final syncStatusProvider =
    StateProvider<String?>((ref) => CloudService.startupError);

/// Local commit is the optimistic update. Retries never block navigation.
final cloudSyncProvider = Provider<void>((ref) {
  if (!CloudService.ready) return;
  var running = false;
  var disposed = false;
  Future<void> sync() async {
    if (running || disposed) return;
    running = true;
    try {
      final cloud = ref.read(cloudServiceProvider);
      final store = ref.read(memoryStoreProvider);
      await cloud.saveProfile(await ref.read(authServiceProvider).signIn());
      for (final memory in await store.pendingUploads()) {
        if (disposed) break;
        await cloud.upload(memory);
        await store.acknowledge(memory);
      }
      if (!disposed) {
        ref.read(syncStatusProvider.notifier).state = null;
        ref.invalidate(personalMemoriesProvider);
      }
    } catch (_) {
      if (!disposed) {
        ref.read(syncStatusProvider.notifier).state =
            'Yükleme bekliyor. Bağlantı geldiğinde yeniden denenecek.';
      }
    } finally {
      running = false;
    }
  }

  final changes = ref.read(memoryStoreProvider).changes.listen((_) => sync());
  final connectivity =
      Connectivity().onConnectivityChanged.listen((_) => sync());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => sync());
  ref.listen(authStateProvider, (_, __) => sync());
  unawaited(sync());
  ref.onDispose(() {
    disposed = true;
    changes.cancel();
    connectivity.cancel();
    timer.cancel();
  });
});
