import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Bounded cache keyed by signed-in identity; avoids repeat downloads on rebuild.
class PhotoCache {
  static final _photos = <String, Future<Uint8List?>>{};
  static Future<Uint8List?> load(String path) {
    final key = '${FirebaseAuth.instance.currentUser?.uid}:$path';
    final cached = _photos.remove(key);
    if (cached != null) {
      _photos[key] = cached;
      return cached;
    }
    if (_photos.length >= 12) _photos.remove(_photos.keys.first);
    final result = FirebaseStorage.instance.ref(path).getData(5 * 1024 * 1024);
    _photos[key] = result;
    result.then(
      (_) {},
      onError: (Object _) {
        _photos.remove(key);
      },
    );
    return result;
  }
}
