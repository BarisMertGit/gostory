// path: lib/features/map/presentation/providers/map_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/preview_config.dart';
import '../../../../core/services/cloud_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/providers/cloud_provider.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/memories_provider.dart';
import '../../domain/map_state.dart';

/// StateNotifier for the map screen.
///
/// Responsibilities:
/// - Fetch user location via [LocationService]
/// - Load nearby memories (mock data in Phase 1, Firestore in Phase 2)
/// - Manage selected memory (pin tap → bottom sheet)
class MapNotifier extends StateNotifier<MapState> {
  MapNotifier({required this.ref}) : super(const MapLoading()) {
    _init();
  }

  final Ref ref;
  DocumentSnapshot? _cursor;
  bool hasMore = false;
  bool loadingMore = false;

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || state is! MapReady) return;
    loadingMore = true;
    try {
      final page =
          await ref.read(cloudServiceProvider).publicPage(after: _cursor);
      if (!mounted || state is! MapReady) return;
      _cursor = page.cursor;
      hasMore = page.hasMore;
      final current = state as MapReady;
      final ids = current.memories.map((m) => m.id).toSet();
      state = current.copyWith(
        memories: [
          ...current.memories,
          ...page.memories.where((m) => !ids.contains(m.id)),
        ],
      );
    } finally {
      loadingMore = false;
    }
  }

  Future<void> _init() async {
    state = const MapLoading();

    List<Memory> local;
    try {
      local = await ref.read(memoryStoreProvider).read();
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'map_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted) {
        state = const MapError(message: 'Anılar yüklenemedi. Tekrar dene.');
      }
      return;
    }
    if (!mounted) return;
    final position = ref.read(locationAccessProvider).position;
    final lat = position?.latitude ??
        (PreviewConfig.enabled ? 41.0082 : local.firstOrNull?.latitude ?? 20);
    final lng = position?.longitude ??
        (PreviewConfig.enabled ? 28.9784 : local.firstOrNull?.longitude ?? 0);
    var public = <Memory>[];
    if (CloudService.ready) {
      try {
        final page = await ref.read(cloudServiceProvider).publicPage();
        public = page.memories;
        _cursor = page.cursor;
        hasMore = page.hasMore;
      } catch (_) {}
    }
    if (!mounted) return;
    final localIds = local.map((m) => m.id).toSet();
    final memories = [
      ...public.where((m) => !localIds.contains(m.id)),
      ...local,
      if (PreviewConfig.enabled) ..._mockMemories(41.0082, 28.9784),
    ];

    state = MapReady(
      memories: memories,
      userLatitude: lat,
      userLongitude: lng,
      hasUserLocation: position != null,
    );
  }

  Future<void> setLocation(Position? position) async {
    final current = state;
    if (current is! MapReady) return;
    state = current.copyWith(
      userLatitude: position?.latitude,
      userLongitude: position?.longitude,
      hasUserLocation: position != null,
      clearLocation: position == null,
    );
    if (position == null) return;
    // Reload the available archive; no server geo-query is configured yet.
    try {
      final local = await ref.read(memoryStoreProvider).read();
      if (mounted && state is MapReady) {
        state = (state as MapReady).copyWith(
          memories: [
            ...local,
            ...(state as MapReady)
                .memories
                .where((m) => !local.any((l) => l.id == m.id)),
          ],
        );
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'map_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      /* Keep the already loaded map usable; archive retry remains available. */
    }
  }

  /// Called when the user taps a memory pin on the map.
  void selectMemory(Memory memory) {
    final current = state;
    if (current is MapReady) {
      state = current.copyWith(selectedMemory: memory);
    }
  }

  /// Dismisses the selected memory bottom sheet.
  void clearSelection() {
    final current = state;
    if (current is MapReady) {
      state = current.copyWith(clearSelected: true);
    }
  }

  /// Refreshes location + memories.
  Future<void> refresh() => _init();

  // ---------------------------------------------------------------------------
  // Phase 1: Mock memories near the user's position.
  // Phase 2: Replace with a Firestore geo-query.
  // ---------------------------------------------------------------------------
  List<Memory> _mockMemories(double lat, double lng) {
    final now = DateTime.now();
    return [
      Memory(
        id: 'mock-1',
        creatorId: 'demo-user-1',
        creatorUsername: 'deniz',
        photoUrl: 'demo://istanbul',
        textNote:
            'Burada bir şeyler hissettim. Tam olarak ne olduğunu bilmiyorum.',
        latitude: lat + 0.003,
        longitude: lng + 0.005,
        city: 'İstanbul',
        createdAt: now.subtract(const Duration(hours: 2)),
        isPublic: true,
      ),
      Memory(
        id: 'mock-2',
        creatorId: 'demo-user-2',
        creatorUsername: 'elif_yolda',
        photoUrl: 'demo://istanbul',
        textNote: 'Yağmur başlamıştı. Şemsiyem yoktu ama umursamadım.',
        latitude: lat - 0.002,
        longitude: lng + 0.008,
        city: 'İstanbul',
        createdAt: now.subtract(const Duration(hours: 5)),
        isPublic: true,
      ),
      Memory(
        id: 'mock-3',
        creatorId: 'demo-user-3',
        creatorUsername: 'mert',
        photoUrl: 'demo://istanbul',
        textNote: 'Burası çok sessiz. İnsanlar neden buraya gelmiyor?',
        latitude: lat + 0.006,
        longitude: lng - 0.003,
        city: 'İstanbul',
        createdAt: now.subtract(const Duration(days: 1)),
        isPublic: true,
      ),
      Memory(
        id: 'mock-4',
        creatorId: 'demo-user-4',
        creatorUsername: 'zeynep',
        photoUrl: 'demo://istanbul',
        textNote: 'Güneş tam burada batıyordu. Bunu görmek için 3 kez geldim.',
        latitude: lat - 0.005,
        longitude: lng - 0.006,
        city: 'İstanbul',
        createdAt: now.subtract(const Duration(days: 2)),
        isPublic: true,
      ),
      Memory(
        id: 'mock-5',
        creatorId: 'demo-user-5',
        creatorUsername: 'can',
        photoUrl: 'demo://istanbul',
        textNote: 'Bir çocuk ağlıyordu. Annesini bekliyordu. Mutlu son.',
        latitude: lat + 0.001,
        longitude: lng + 0.012,
        city: 'İstanbul',
        createdAt: now.subtract(const Duration(days: 3)),
        isPublic: true,
      ),
    ];
  }
}

/// Global map provider.
final mapProvider = StateNotifierProvider.autoDispose<MapNotifier, MapState>(
  (ref) {
    final notifier = MapNotifier(ref: ref);
    ref.listen(locationAccessProvider, (previous, next) {
      if (previous?.position != next.position) {
        notifier.setLocation(next.position);
      }
    });
    return notifier;
  },
);
