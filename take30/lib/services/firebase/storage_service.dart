import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageUploadResult {
  const StorageUploadResult({
    required this.storagePath,
    required this.downloadUrl,
  });

  final String storagePath;
  final String downloadUrl;
}

/// Chemins alignés avec `storage.rules`.
class StorageService {
  StorageService(this._storage);

  static const int maxBattleRenderBytes = 350 * 1024 * 1024;

  final FirebaseStorage _storage;

  Reference _sceneRef(String uid, String sceneId) =>
      _storage.ref('scenes/$uid/$sceneId.mp4');

  Reference _pathRef(String storagePath) => _storage.ref(storagePath);

  Reference _thumbRef(String uid, String sceneId) =>
      _storage.ref('thumbnails/$uid/$sceneId.jpg');

  Reference _avatarRef(String uid) => _storage.ref('avatars/$uid.jpg');

  static String buildGuidedSegmentPath({
    required String uid,
    required String projectId,
    required String markerId,
    required int timestampMillis,
  }) {
    return 'take60_user_recordings/$uid/$projectId/${markerId}_$timestampMillis.mp4';
  }

  static String buildBattleRenderPath({
    required String battleId,
    required String uid,
    required String participantRole,
    required String projectId,
  }) {
    return 'battles/$battleId/$uid/${participantRole}_$projectId.mp4';
  }

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

  /// Upload one user-recorded segment of a guided scene.
  /// Path: `take60_user_recordings/{uid}/{projectId}/{markerId}_{timestamp}.mp4`.
  Future<StorageUploadResult> uploadGuidedSegment({
    required String storagePath,
    required File file,
  }) async {
    final ref = _pathRef(storagePath);
    final metadata = SettableMetadata(contentType: 'video/mp4');
    await ref.putFile(file, metadata);
    return StorageUploadResult(
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
    );
  }

  Future<StorageUploadResult> uploadGuidedSegmentBytes({
    required String storagePath,
    required Uint8List bytes,
  }) async {
    final ref = _pathRef(storagePath);
    final metadata = SettableMetadata(contentType: 'video/mp4');
    await ref.putData(bytes, metadata);
    return StorageUploadResult(
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
    );
  }

  Future<String> resolveDownloadUrl(String storagePath) {
    return _pathRef(storagePath).getDownloadURL();
  }

  Future<StorageUploadResult> mirrorRemoteVideo({
    required String sourceUrl,
    required String storagePath,
    int maxBytes = maxBattleRenderBytes,
  }) async {
    final sourceRef = _storage.refFromURL(sourceUrl);
    final bytes = await sourceRef.getData(maxBytes);
    if (bytes == null || bytes.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'battle-render-empty',
        message: 'Impossible de lire la vidéo source pour la Battle.',
      );
    }

    final ref = _pathRef(storagePath);
    final metadata = SettableMetadata(contentType: 'video/mp4');
    await ref.putData(bytes, metadata);
    return StorageUploadResult(
      storagePath: storagePath,
      downloadUrl: await ref.getDownloadURL(),
    );
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
