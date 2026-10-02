import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/utils/logger.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(permissions: ref.watch(permissionServiceProvider)),
);

class LocationAccessState {
  const LocationAccessState({this.position, this.busy = false, this.failure});
  final Position? position;
  final bool busy;
  final LocationFailure? failure;
}

final locationAccessProvider =
    StateNotifierProvider<LocationAccessNotifier, LocationAccessState>(
  (ref) => LocationAccessNotifier(ref.watch(locationServiceProvider)),
);

class LocationAccessNotifier extends StateNotifier<LocationAccessState>
    with WidgetsBindingObserver {
  LocationAccessNotifier(this.service) : super(const LocationAccessState()) {
    WidgetsBinding.instance.addObserver(this);
  }
  final LocationService service;
  bool _activated = false;
  bool _settingsPending = false;
  bool _foreground = true;

  Future<void> locate({required Future<bool> Function() confirm}) async {
    if (state.busy) return;
    _activated = true;
    state = const LocationAccessState(busy: true);
    try {
      if (!await service.isServiceEnabled()) {
        throw const LocationFailure(LocationProblem.servicesDisabled);
      }
      var access = await service.accessStatus();
      if (access == AccessStatus.blocked || access == AccessStatus.restricted) {
        throw const LocationFailure(LocationProblem.blocked);
      }
      if (access != AccessStatus.granted) {
        if (!await confirm()) {
          if (mounted) state = const LocationAccessState();
          return;
        }
        if (!mounted || !_foreground) return;
        final permission = await service.requestPermission();
        access = permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always
            ? AccessStatus.granted
            : await service.accessStatus();
        if (access != AccessStatus.granted) {
          throw LocationFailure(
            access == AccessStatus.blocked || access == AccessStatus.restricted
                ? LocationProblem.blocked
                : LocationProblem.denied,
          );
        }
      }
      await _readPosition();
    } on LocationFailure catch (failure) {
      if (mounted) state = LocationAccessState(failure: failure);
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'location_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted) {
        state = const LocationAccessState(
          failure: LocationFailure(LocationProblem.unavailable),
        );
      }
    } finally {
      if (mounted && state.busy) state = const LocationAccessState();
    }
  }

  Future<void> _readPosition() async {
    if (!_foreground || !mounted) return;
    final position = await service.getCurrentLocation();
    if (mounted && _foreground) state = LocationAccessState(position: position);
  }

  Future<void> openSettings({bool locationService = false}) async {
    _settingsPending = true;
    final opened = locationService
        ? await service.openLocationSettings()
        : await service.openAppSettings();
    if (!opened) {
      _settingsPending = false;
      if (mounted) {
        state = const LocationAccessState(
          failure: LocationFailure(LocationProblem.unavailable),
        );
      }
    }
  }

  Future<void> recheckOnResume() async {
    if (!_activated || state.busy) return;
    try {
      final access = await service.accessStatus();
      if (!mounted) return;
      if (access != AccessStatus.granted) {
        state = LocationAccessState(
          failure: LocationFailure(
            access == AccessStatus.blocked || access == AccessStatus.restricted
                ? LocationProblem.blocked
                : LocationProblem.denied,
          ),
        );
      } else if (_settingsPending) {
        state = const LocationAccessState(busy: true);
        await _readPosition();
      }
    } on LocationFailure catch (failure) {
      if (mounted) state = LocationAccessState(failure: failure);
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'location_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted) {
        state = const LocationAccessState(
          failure: LocationFailure(LocationProblem.unavailable),
        );
      }
    } finally {
      _settingsPending = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs can briefly make the app inactive; only paused/hidden stop work.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _foreground = false;
    }
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      recheckOnResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
