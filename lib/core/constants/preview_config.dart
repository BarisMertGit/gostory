/// Enabled by the simulator launch configuration; hardware builds stay unchanged.
abstract final class PreviewConfig {
  static const enabled = bool.fromEnvironment('SIMULATOR_PREVIEW');
  static const photoPath = 'demo://istanbul';
}
