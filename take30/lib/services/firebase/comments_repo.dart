import '../../models/models.dart';
import 'firestore_refs.dart';

class CommentsRepo {
  CommentsRepo(this._refs);

  final FirestoreRefs _refs;

  Stream<List<CommentModel>> watch(String sceneId, {int limit = 50}) {
    return _refs
        .sceneComments(sceneId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<CommentModel>> list(String sceneId, {int limit = 50}) async {
    final q = await _refs
        .sceneComments(sceneId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Future<String> add({
    required String sceneId,
    required UserModel author,
    required String text,
  }) async {
    final ref = await _refs.sceneComments(sceneId).add(
          CommentModel(
            id: '',
            sceneId: sceneId,
            authorId: author.id,
            authorDenorm: author.toStub(),
            text: text,
            createdAt: DateTime.now(),
          ),
        );
    return ref.id;
  }

  Future<void> delete(String sceneId, String commentId) async {
    await _refs.sceneComments(sceneId).doc(commentId).delete();
  }
}
