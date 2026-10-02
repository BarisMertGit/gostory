// path: lib/features/camera/domain/camera_state.dart

/// Represents the current state of the camera feature.
///
/// Uses a sealed class for exhaustive pattern matching.
sealed class CameraState {
  const CameraState();
}

class CameraIdle extends CameraState {
  const CameraIdle();
}

/// Camera is initializing (loading cameras, setting up controller).
class CameraLoading extends CameraState {
  const CameraLoading();
}

/// Camera is ready and showing the viewfinder.
class CameraReady extends CameraState {
  const CameraReady();
}

/// A photo has been captured and saved to a temporary path.
class CameraCaptured extends CameraState {
  const CameraCaptured({required this.photoPath});

  /// The local file path to the captured photo.
  final String photoPath;
}

/// Camera encountered an error.
class CameraError extends CameraState {
  const CameraError({required this.message});

  final String message;
}

/// Camera permission was denied.
class CameraPermissionDenied extends CameraState {
  const CameraPermissionDenied({this.permanentlyDenied = false});
  final bool permanentlyDenied;
}
