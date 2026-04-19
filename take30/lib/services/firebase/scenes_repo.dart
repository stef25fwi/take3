import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/models.dart';
import 'firestore_refs.dart';

class ScenesRepo {
  ScenesRepo(this._refs, this._functions);

  final FirestoreRefs _refs;
  final FirebaseFunctions _functions;

  /// Feed global : dernières scènes publiées.
  Stream<List<SceneModel>> watchFeed({int limit = 20}) {
    return _refs.scenes
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<SceneModel>> getFeed({int limit = 20}) async {
    final q = await _refs.scenes
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  /// Populaires : tri par likesCount.
  Future<List<SceneModel>> getPopular({String? category, int limit = 20}) async {
    Query<SceneModel> q = _refs.scenes.where('status', isEqualTo: 'published');
    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }
    final snap = await q.orderBy('likesCount', descending: true).limit(limit).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<List<SceneModel>> getByAuthor(String authorId, {int limit = 30}) async {
    final q = await _refs.scenes
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Future<SceneModel?> getById(String sceneId) async {
    final snap = await _refs.sceneDoc(sceneId).get();
    return snap.exists ? snap.data() : null;
  }

  Stream<SceneModel?> watchById(String sceneId) {
    return _refs
        .sceneDoc(sceneId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  /// Crée le doc (compteurs à 0, status published par défaut).
  Future<String> create(SceneModel scene) async {
    final ref = await _refs.scenes.add(scene);
    return ref.id;
  }

  Future<void> delete(String sceneId) async {
    await _refs.sceneDoc(sceneId).delete();
  }

  /// Toggle like : l'existence du sous-doc détermine l'état ; la Function
  /// `onLikeWrite` met à jour le compteur côté scène et côté auteur.
  Future<bool> toggleLike(String sceneId, String uid) async {
    final likeRef = _refs.sceneLikes(sceneId).doc(uid);
    final exists = (await likeRef.get()).exists;
    if (exists) {
      await likeRef.delete();
      return false;
    }
    await likeRef.set(
      LikeRecord(userId: uid, createdAt: DateTime.now()).toFirestore(),
    );
    return true;
  }

  Future<bool> isLikedBy(String sceneId, String uid) async {
    final snap = await _refs.sceneLikes(sceneId).doc(uid).get();
    return snap.exists;
  }

  /// Throttled côté Function (IP + uid).
  Future<void> pingView(String sceneId) async {
    await _functions.httpsCallable('pingSceneView').call({'sceneId': sceneId});
  }
}
