import '../../models/models.dart';
import 'firestore_refs.dart';

class LeaderboardRepo {
  LeaderboardRepo(this._refs);

  final FirestoreRefs _refs;

  /// Période ∈ `day|week|month|global`. Les entries sont réécrites par la
  /// Cloud Function `computeLeaderboard`, pas en écriture client.
  Stream<List<LeaderboardEntry>> watch(String period, {int limit = 50}) {
    return _refs
        .leaderboardEntries(period)
        .orderBy('rank')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<LeaderboardEntry>> list(String period, {int limit = 50}) async {
    final q = await _refs
        .leaderboardEntries(period)
        .orderBy('rank')
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }
}
