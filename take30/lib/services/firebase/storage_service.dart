import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Chemins alignés avec `storage.rules`.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Reference _sceneRef(String uid, String sceneId) =>
      _storage.ref('scenes/$uid/$sceneId.mp4');

  Reference _thumbRef(String uid, String sceneId) =>
      _storage.ref('thumbnails/$uid/$sceneId.jpg');

  Reference _avatarRef(String uid) => _storage.ref('avatars/$uid.jpg');

  Future<String> uploadVideo({
    required String uid,
    required String sceneId,
    required File file,
  }) async {
    final ref = _sceneRef(uid, sceneId);
    final metadata = SettableMetadata(contentType: 'video/mp4');
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  Future<String> uploadVideoBytes({
    required String uid,
    required String sceneId,
    required Uint8List bytes,
  }) async {
    final ref = _sceneRef(uid, sceneId);
    final metadata = SettableMetadata(contentType: 'video/mp4');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<String> uploadThumbnail({
    required String uid,
    required String sceneId,
    required Uint8List bytes,
  }) async {
    final ref = _thumbRef(uid, sceneId);
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _avatarRef(uid);
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<void> deleteScene({required String uid, required String sceneId}) async {
    await Future.wait([
      _sceneRef(uid, sceneId).delete().catchError((_) {}),
      _thumbRef(uid, sceneId).delete().catchError((_) {}),
    ]);
  }
}
