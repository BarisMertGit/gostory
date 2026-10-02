// path: lib/shared/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';

/// Provides a singleton [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Loads the current local user profile.
///
/// This runs once at app startup. If it fails, [authStateProvider]
/// will be null but the app will not crash.
final authStateProvider = FutureProvider<LocalUser>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.signIn();
});
