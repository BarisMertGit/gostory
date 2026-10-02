import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'auth_provider.dart';

Future<File> _purposeFile() async => File(
      '${(await getApplicationSupportDirectory()).path}/gallery_purpose.txt',
    );
Future<void> markGalleryPurpose(String purpose) async {
  if (Platform.isAndroid) {
    await (await _purposeFile()).writeAsString(purpose, flush: true);
  }
}

Future<void> clearGalleryPurpose() async {
  if (!Platform.isAndroid) return;
  final file = await _purposeFile();
  if (await file.exists()) await file.delete();
}

/// Restores profile photo selection after Android restarts.
final recoveredProfilePhotoProvider = FutureProvider<String?>((ref) async {
  if (!Platform.isAndroid) return null;
  final response = await ImagePicker().retrieveLostData();
  if (response.isEmpty) return null;
  if (response.exception != null) throw response.exception!;
  final image = response.files?.firstOrNull;
  if (image == null) return null;
  final file = await _purposeFile();
  final purpose = await file.exists() ? await file.readAsString() : '';
  await clearGalleryPurpose();
  if (purpose != 'profile') return null;
  final service = ref.read(authServiceProvider);
  final user = await service.signIn();
  await service.updateProfile(
    username: user.username,
    socialLinks: user.socialLinks,
    newPhotoPath: image.path,
  );
  ref.invalidate(authStateProvider);
  return null;
});
