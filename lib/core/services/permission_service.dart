import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum AccessStatus { granted, denied, blocked, restricted }

/// Status-only native bridge. OS prompts remain owned by camera/geolocator.
class PermissionService {
  static const channel = MethodChannel('com.gostory/permissions');
  Future<AccessStatus> status(String permission) async {
    final value = await channel.invokeMethod<String>('status', permission);
    return switch (value) {
      'granted' => AccessStatus.granted,
      'denied' => AccessStatus.denied,
      'blocked' => AccessStatus.blocked,
      'restricted' => AccessStatus.restricted,
      _ => throw StateError('İzin durumu okunamadı.'),
    };
  }

  Future<void> markRequested(String permission) =>
      channel.invokeMethod<void>('markRequested', permission);
  Future<bool> openSettings() => Geolocator.openAppSettings();
}

final permissionServiceProvider = Provider((ref) => PermissionService());
