import 'package:geocoding/geocoding.dart';

import '../utils/logger.dart';

class GeocodingService {
  final _cache = <String, String>{};

  Future<String> city(double latitude, double longitude) async {
    final key =
        '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';
    if (_cache.containsKey(key)) return _cache[key]!;
    try {
      final places = await placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 5));
      if (places.isEmpty) return '';
      final place = places.first;
      // Turkish locality commonly denotes a district; count provinces as cities.
      final candidates = place.isoCountryCode == 'TR'
          ? [
              place.administrativeArea,
              place.locality,
              place.subAdministrativeArea,
            ]
          : [
              place.locality,
              place.subAdministrativeArea,
              place.administrativeArea,
            ];
      final result = candidates
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .firstOrNull ??
          '';
      if (result.isNotEmpty) _cache[key] = result;
      return result;
    } catch (error, stack) {
      AppLogger.error(
        'Şehir çözümlenemedi; anı konumuyla saklanacak.',
        tag: 'Geocoding',
        error: error.runtimeType,
        stackTrace: stack,
      );
      return '';
    }
  }
}
