// path: lib/features/map/domain/map_state.dart

import '../../../shared/models/memory.dart';

/// Sealed states for the map screen.
sealed class MapState {
  const MapState();
}

/// Initial / loading: fetching location + memories.
final class MapLoading extends MapState {
  const MapLoading();
}

/// Map is ready with data.
final class MapReady extends MapState {
  const MapReady({
    required this.memories,
    required this.userLatitude,
    required this.userLongitude,
    this.selectedMemory,
    this.hasUserLocation = false,
  });

  final List<Memory> memories;
  final double userLatitude;
  final double userLongitude;
  final Memory? selectedMemory;
  final bool hasUserLocation;

  MapReady copyWith({
    List<Memory>? memories,
    double? userLatitude,
    double? userLongitude,
    Memory? selectedMemory,
    bool clearSelected = false,
    bool? hasUserLocation,
    bool clearLocation = false,
  }) {
    return MapReady(
      memories: memories ?? this.memories,
      hasUserLocation: hasUserLocation ?? this.hasUserLocation,
      userLatitude: clearLocation ? 20 : userLatitude ?? this.userLatitude,
      userLongitude: clearLocation ? 0 : userLongitude ?? this.userLongitude,
      selectedMemory:
          clearSelected ? null : selectedMemory ?? this.selectedMemory,
    );
  }
}

/// Error state (location denied, network failure etc.).
final class MapError extends MapState {
  const MapError({required this.message});

  final String message;
}
