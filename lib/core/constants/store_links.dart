abstract final class StoreLinks {
  static const appStore = String.fromEnvironment('APP_STORE_URL');
  static const googlePlay = String.fromEnvironment('GOOGLE_PLAY_URL');

  static Uri? uri(String value, String host) {
    final result = Uri.tryParse(value);
    return result != null &&
            result.scheme == 'https' &&
            result.host == host &&
            result.path.length > 1
        ? result
        : null;
  }
}
