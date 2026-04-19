import '../../models/models.dart';
import 'firestore_refs.dart';

class DuelsRepo {
  DuelsRepo(this._refs);

  final FirestoreRefs _refs;

  /// Duel actif courant : le plus récent avec `status == 'active'`.
  Stream<DuelModel?> watchCurrent() {
    return _refs.duels
        .where('status', isEqualTo: 'active')
        .orderBy('expiresAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : s.docs.first.data());
  }

  Future<DuelModel?> getCurrent() async {
    final q = await _refs.duels
        .where('status', isEqualTo: 'active')
        .orderBy('expiresAt', descending: true)
        .limit(1)
        .get();
    return q.docs.isEmpty ? null : q.docs.first.data();
  }

  Future<DuelModel?> getById(String duelId) async {
    final snap = await _refs.duels.doc(duelId).get();
    return snap.exists ? snap.data() : null;
  }

  /// Vote : écriture sous-doc `duels/{id}/votes/{uid}` avec choice 'A'|'B'.
  /// Les rules bloquent les doublons. Function `onDuelVote` met à jour les
  /// compteurs.
  Future<void> vote({
    required String duelId,
    required String uid,
    required int choice,
  }) async {
    await _refs.duelVotes(duelId).doc(uid).set(
          VoteRecord(
            userId: uid,
            choice: choice == 0 ? 'A' : 'B',
            createdAt: DateTime.now(),
          ).toFirestore(),
        );
  }

  Future<bool> hasVoted(String duelId, String uid) async {
    final snap = await _refs.duelVotes(duelId).doc(uid).get();
    return snap.exists;
  }
}
