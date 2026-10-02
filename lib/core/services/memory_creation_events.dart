import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

enum MemoryCreationPhase { started, saved, failed }

/// Creation lifecycle events deliberately omit notes, photos, coordinates and IDs.
class MemoryCreationEvent {
  MemoryCreationEvent({
    required this.phase,
    required this.isPublic,
    this.reason,
  }) : occurredAt = DateTime.now().toUtc();
  final MemoryCreationPhase phase;
  final bool isPublic;
  final String? reason;
  final DateTime occurredAt;
  String get name => switch (phase) {
        MemoryCreationPhase.started => 'memory_creation_started',
        MemoryCreationPhase.saved => 'memory_created_local',
        MemoryCreationPhase.failed => 'memory_creation_failed',
      };
}

class MemoryCreationEvents {
  final _events = StreamController<MemoryCreationEvent>.broadcast();
  Stream<MemoryCreationEvent> get stream => _events.stream;
  void emit(MemoryCreationEvent event) {
    if (_events.isClosed) return;
    AppLogger.info(event.name, tag: 'memory_creation');
    _events.add(event);
  }

  Future<void> dispose() => _events.close();
}

final memoryCreationEventsProvider = Provider((ref) {
  final events = MemoryCreationEvents();
  ref.onDispose(events.dispose);
  return events;
});
