import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/identifiers.dart';
import '../utils/logger.dart';

/// Local profile while server authentication is not configured.
class LocalUser {
  const LocalUser({
    required this.uid,
    required this.username,
    this.photoPath,
    this.bio = '',
  });
  final String bio;
  final String? photoPath;
  final String uid;
  final String username;

  static String? validateUsername(String value) {
    if (!RegExp(r'^[a-zA-Z0-9_çğıöşüÇĞİÖŞÜ]{3,24}$').hasMatch(value.trim())) {
      return '3–24 karakter; harf, rakam ve alt çizgi kullan.';
    }
    return null;
  }
}

class AuthService {
  AuthService({Future<File> Function()? profileFile})
      : _resolveFile = profileFile ?? _profileFile;

  final Future<File> Function() _resolveFile;
  LocalUser? _currentUser;
  Future<LocalUser>? _loading;
  LocalUser? get currentUser => _currentUser;
  String? get uid => _currentUser?.uid;
  bool get isSignedIn => _currentUser != null;

  static Future<File> _profileFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/gostory_profile.json');
  }

  Future<LocalUser> signIn() => _loading ??= _loadProfile();

  Future<LocalUser> _loadProfile() async {
    try {
      final file = await _resolveFile();
      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final username = data['username'] as String;
        if (LocalUser.validateUsername(username) != null) {
          throw const FormatException('Invalid username');
        }
        return _currentUser = LocalUser(
          uid: data['uid'] as String,
          username: username,
          bio: data['bio'] as String? ?? '',
          photoPath: data['photo'] is String
              ? p.join(file.parent.path, p.basename(data['photo'] as String))
              : null,
        );
      }
      final user = LocalUser(
        uid: 'local-${newArchiveId()}',
        username: 'gezgin',
      );
      await _save(file, user);
      return _currentUser = user;
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'auth_service',
        error: error.runtimeType,
        stackTrace: stack,
      );
      _loading = null;
      rethrow;
    }
  }

  Future<void> _save(File file, LocalUser user) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'uid': user.uid,
        'username': user.username,
        'bio': user.bio,
        'photo': user.photoPath == null ? null : p.basename(user.photoPath!),
      }),
      flush: true,
    );
  }

  Future<LocalUser> updateUsername(String value) async {
    final username = value.trim();
    final error = LocalUser.validateUsername(username);
    if (error != null) throw ArgumentError(error);
    final current = await signIn();
    final user = LocalUser(
      uid: current.uid,
      username: username,
      bio: current.bio,
      photoPath: current.photoPath,
    );
    await _save(await _resolveFile(), user);
    _currentUser = user;
    _loading = Future.value(user);
    return user;
  }

  Future<LocalUser> updateProfile({
    required String username,
    String? newPhotoPath,
    String? bio,
    bool removePhoto = false,
  }) async {
    final name = username.trim();
    final error = LocalUser.validateUsername(name);
    if (error != null) throw ArgumentError(error);
    final current = await signIn();
    final file = await _resolveFile();
    String? photo = removePhoto ? null : current.photoPath;
    if (newPhotoPath != null) {
      final target = p.join(
        file.parent.path,
        'avatar_${DateTime.now().microsecondsSinceEpoch}${p.extension(newPhotoPath)}',
      );
      await File(newPhotoPath).copy(target);
      photo = target;
    }
    final user = LocalUser(
      uid: current.uid,
      username: name,
      bio: (bio ?? current.bio).trim(),
      photoPath: photo,
    );
    await _save(file, user);
    _currentUser = user;
    _loading = Future.value(user);
    return user;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _loading = null;
  }
}
