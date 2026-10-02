import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gostory/core/services/location_service.dart';
import 'package:gostory/core/services/permission_service.dart';
import 'package:gostory/shared/providers/location_provider.dart';

class FakeLocation extends LocationService {
  AccessStatus access = AccessStatus.denied;
  AccessStatus afterRequest = AccessStatus.granted;
  bool enabled = true;
  LocationFailure? failure;
  int checks = 0, requests = 0, fixes = 0, settings = 0;
  @override
  Future<bool> isServiceEnabled() async => enabled;
  @override
  Future<AccessStatus> accessStatus() async {
    checks++;
    return access;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    access = afterRequest;
    return access == AccessStatus.granted
        ? LocationPermission.whileInUse
        : access == AccessStatus.blocked
            ? LocationPermission.deniedForever
            : LocationPermission.denied;
  }

  @override
  Future<Position> getCurrentLocation() async {
    fixes++;
    if (!enabled) throw const LocationFailure(LocationProblem.servicesDisabled);
    if (failure != null) throw failure!;
    return Position(
      latitude: 38.42,
      longitude: 27.14,
      timestamp: DateTime(2026),
      accuracy: 1500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    settings++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    settings++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeLocation service;
  late LocationAccessNotifier notifier;
  setUp(() {
    service = FakeLocation();
    notifier = LocationAccessNotifier(service);
  });
  tearDown(() => notifier.dispose());

  test('startup and passive resume never request or read a position', () async {
    await notifier.recheckOnResume();
    expect(service.checks, 0);
    expect(service.requests, 0);
    expect(service.fixes, 0);
  });
  test(
      'not now avoids OS request; approximate permission yields actual coordinates',
      () async {
    await notifier.locate(confirm: () async => false);
    expect(service.requests, 0);
    expect(service.fixes, 0);
    await notifier.locate(confirm: () async => true);
    expect(service.requests, 1);
    expect(notifier.state.position!.latitude, 38.42);
    expect(notifier.state.position!.accuracy, 1500);
    await notifier.locate(
      confirm: () async => fail('Already granted; do not explain again'),
    );
    expect(service.requests, 1);
    expect(service.fixes, 2);
  });
  test('ordinary denial stays usable and resume never requests again',
      () async {
    service.afterRequest = AccessStatus.denied;
    await notifier.locate(confirm: () async => true);
    expect(notifier.state.failure!.problem, LocationProblem.denied);
    await notifier.recheckOnResume();
    expect(service.requests, 1);
    expect(service.fixes, 0);
  });
  test('blocked permission does not prompt; settings return checks and locates',
      () async {
    service.access = AccessStatus.blocked;
    await notifier.locate(
      confirm: () async => fail('Blocked permissions must use settings'),
    );
    expect(notifier.state.failure!.problem, LocationProblem.blocked);
    expect(service.requests, 0);
    await notifier.openSettings();
    service.access = AccessStatus.granted;
    await notifier.recheckOnResume();
    expect(service.settings, 1);
    expect(service.requests, 0);
    expect(notifier.state.position!.longitude, 27.14);
    service.access = AccessStatus.blocked;
    await notifier.recheckOnResume();
    expect(notifier.state.position, isNull);
  });
  test('services disabled, timeout and unavailable remain distinct', () async {
    service.enabled = false;
    await notifier.locate(
      confirm: () async => fail('Do not prompt with services off'),
    );
    expect(notifier.state.failure!.problem, LocationProblem.servicesDisabled);
    expect(service.requests, 0);
    service.enabled = true;
    service.access = AccessStatus.granted;
    for (final issue in [
      LocationProblem.timeout,
      LocationProblem.unavailable,
    ]) {
      service.failure = LocationFailure(issue);
      await notifier.locate(confirm: () async => true);
      expect(notifier.state.failure!.problem, issue);
      expect(notifier.state.busy, isFalse);
    }
    service.failure = null;
    await notifier.locate(confirm: () async => true);
    expect(notifier.state.position, isNotNull);
  });
  test('no background location read', () async {
    notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    service.access = AccessStatus.granted;
    await notifier.locate(confirm: () async => true);
    expect(service.fixes, 0);
  });
}
