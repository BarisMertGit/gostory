// path: lib/shared/models/memory.dart

/// A memory stored in the local archive. JSON uses ISO 8601 dates.
class Memory {
  const Memory({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    required this.photoUrl,
    required this.textNote,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.createdAt,
    this.viewCount = 0,
    this.isPublic = false,
    this.syncPending = false,
    this.isDeleted = false,
    this.revision = 0,
  });

  final String id;
  final String creatorId;
  final String creatorUsername;
  final String photoUrl;
  final String textNote;
  final double latitude;
  final double longitude;
  final String city;
  final DateTime createdAt;
  final int viewCount;
  final bool isPublic;
  final bool syncPending;
  final bool isDeleted;
  final int revision;

  String get locationLabel =>
      city.trim().isNotEmpty ? city : 'Konum kaydedildi';

  Map<String, dynamic> toJson() => {
        'id': id,
        'creatorId': creatorId,
        'creatorUsername': creatorUsername,
        'photoUrl': photoUrl,
        'textNote': textNote,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'viewCount': viewCount,
        'public': isPublic,
        'syncPending': syncPending,
        'isDeleted': isDeleted,
        'revision': revision,
      };

  /// Also accepts the original device archive's field names.
  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        id: json['id'] as String,
        creatorId: json['creatorId'] as String,
        creatorUsername:
            (json['creatorUsername'] ?? json['username'] ?? '') as String,
        photoUrl: (json['photoUrl'] ?? json['photo'] ?? '') as String,
        textNote: (json['textNote'] ?? json['note'] ?? '') as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        city: json['city'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        isPublic: json['public'] as bool? ?? false,
        syncPending: json['syncPending'] as bool? ?? false,
        isDeleted: json['isDeleted'] as bool? ?? false,
        revision: (json['revision'] as num?)?.toInt() ?? 0,
      );

  Memory copyWith({
    String? id,
    String? creatorId,
    String? creatorUsername,
    String? photoUrl,
    String? textNote,
    double? latitude,
    double? longitude,
    String? city,
    DateTime? createdAt,
    int? viewCount,
    bool? isPublic,
    bool? syncPending,
    bool? isDeleted,
    int? revision,
  }) {
    return Memory(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      photoUrl: photoUrl ?? this.photoUrl,
      textNote: textNote ?? this.textNote,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      isPublic: isPublic ?? this.isPublic,
      syncPending: syncPending ?? this.syncPending,
      isDeleted: isDeleted ?? this.isDeleted,
      revision: revision ?? this.revision,
    );
  }

  @override
  String toString() => 'Memory(id: $id, city: $city)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Memory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
