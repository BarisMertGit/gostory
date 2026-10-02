// path: lib/core/errors/app_exceptions.dart

/// Base exception for all GoStory errors.
sealed class AppException implements Exception {
  const AppException(this.message, [this.originalError]);

  final String message;
  final Object? originalError;

  @override
  String toString() => 'AppException: $message';
}

/// Camera-related errors.
class CameraException extends AppException {
  const CameraException(super.message, [super.originalError]);

  @override
  String toString() => 'CameraException: $message';
}

/// Authentication errors.
class AuthException extends AppException {
  const AuthException(super.message, [super.originalError]);

  @override
  String toString() => 'AuthException: $message';
}

/// Location/permission errors.
class LocationException extends AppException {
  const LocationException(super.message, [super.originalError]);

  @override
  String toString() => 'LocationException: $message';
}

/// Validation errors (note length, empty input, etc.).
class ValidationException extends AppException {
  const ValidationException(super.message, [super.originalError]);

  @override
  String toString() => 'ValidationException: $message';
}

/// Storage/upload errors (prepared for Phase 2).
class StorageException extends AppException {
  const StorageException(super.message, [super.originalError]);

  @override
  String toString() => 'StorageException: $message';
}
