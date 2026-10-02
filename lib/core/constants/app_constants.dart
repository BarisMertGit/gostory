// path: lib/core/constants/app_constants.dart

/// Application-wide constants.
abstract final class AppConstants {
  // ── Memory note ──
  static const int maxNoteLength = 100;
  static const int minNoteLength = 1;

  // ── Photo ──
  static const double maxPhotoSizeMB = 5.0;
  static const int photoQuality = 85;
  static const double photoMaxWidth = 1920;
  static const double photoMaxHeight = 1920;

  // ── Camera ──
  static const Duration cameraInitTimeout = Duration(seconds: 10);

  // ── Animation ──
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 800);
  static const Duration animVerySlow = Duration(milliseconds: 1200);

  // ── Firestore collections (prepared for Phase 2) ──
  static const String memoriesCollection = 'memories';
  static const String cityLimitsCollection = 'city_limits';

  // ── Storage paths (prepared for Phase 2) ──
  static const String memoriesStoragePath = 'memories';
}
