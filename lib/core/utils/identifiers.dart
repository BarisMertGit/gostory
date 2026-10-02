import 'dart:math';

/// Opaque 128-bit IDs avoid collisions when device archives join the cloud.
String newArchiveId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
