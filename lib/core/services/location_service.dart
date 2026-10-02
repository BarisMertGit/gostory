import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../utils/logger.dart';
import 'permission_service.dart';

enum LocationProblem { denied, blocked, servicesDisabled, timeout, unavailable }

class LocationFailure implements Exception {
  const LocationFailure(this.problem);
  final LocationProblem problem;
  String get message => switch (problem) {
        LocationProblem.denied =>
          'Konum izni verilmedi. Haritayı elle gezebilir ve anının yerini haritadan seçebilirsin.',
        LocationProblem.blocked =>
          'Konum izni kapalı. Cihaz ayarlarından erişimi açabilir veya haritayı elle kullanabilirsin.',
        LocationProblem.servicesDisabled =>
          'Cihazın konum servisi kapalı. Konum servislerini açıp tekrar dene.',
        LocationProblem.timeout =>
          'Konum alma işlemi zaman aşımına uğradı. Açık bir alanda tekrar dene.',
        LocationProblem.unavailable =>
          'Konum şu anda alınamıyor. Biraz sonra tekrar dene veya haritadan bir yer seç.',
      };
}

class LocationService {
  LocationService({PermissionService? permissions})
      : permissions = permissions ?? PermissionService();
  final PermissionService permissions;
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();
  Future<LocationPermission> requestPermission() async {
    await permissions.markRequested('location');
    return Geolocator.requestPermission();
  }

  Future<AccessStatus> accessStatus() async {
    final status = await checkPermission();
    if (status == LocationPermission.always ||
        status == LocationPermission.whileInUse) {
      return AccessStatus.granted;
    }
    if (status == LocationPermission.deniedForever) return AccessStatus.blocked;
    return permissions.status('location');
  }

  Future<Position> getCurrentLocation() async {
    try {
      if (!await isServiceEnabled()) {
        throw const LocationFailure(LocationProblem.servicesDisabled);
      }
      if (await accessStatus() != AccessStatus.granted) {
        throw const LocationFailure(LocationProblem.denied);
      }
      // One foreground fix; approximate access is sufficient. No background stream.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure(LocationProblem.timeout);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationProblem.servicesDisabled);
    } on LocationFailure {
      rethrow;
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'location_service',
        error: error.runtimeType,
        stackTrace: stack,
      );
      throw const LocationFailure(LocationProblem.unavailable);
    }
  }

  Future<bool> openAppSettings() => permissions.openSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
