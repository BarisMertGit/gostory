// path: lib/features/preview/domain/memory_draft.dart

/// A photo/note draft committed locally before optional cloud upload.
class MemoryDraft {
  const MemoryDraft({
    required this.photoPath,
    required this.note,
    this.creatorId,
    this.creatorUsername,
    this.latitude,
    this.longitude,
    this.isPublic = false,
  });

  /// Local file path of the captured photo.
  final String photoPath;

  /// The user's note text (trimmed, max 100 chars).
  final String note;
  final bool isPublic;

  final String? creatorId;
  final String? creatorUsername;

  /// Latitude of the memory location.
  final double? latitude;

  /// Longitude of the memory location.
  final double? longitude;

  @override
  String toString() => 'MemoryDraft(note: ${note.length} chars)';
}
