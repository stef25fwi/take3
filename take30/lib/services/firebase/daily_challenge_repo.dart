import '../../models/models.dart';
import 'firestore_refs.dart';

class DailyChallengeRepo {
  DailyChallengeRepo(this._refs);

  final FirestoreRefs _refs;

  static String todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Stream<DailyChallengeModel?> watchToday() {
    return _refs.dailyChallenges
        .doc(todayKey())
        .snapshots()
        .map((s) => s.exists ? s.data() : null);
  }

  Future<DailyChallengeModel?> getToday() async {
    final snap = await _refs.dailyChallenges.doc(todayKey()).get();
    return snap.exists ? snap.data() : null;
  }

  Future<void> join({required String uid, required String sceneId}) async {
    await _refs.challengeParticipants(todayKey()).doc(uid).set({
      'userId': uid,
      'sceneId': sceneId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
