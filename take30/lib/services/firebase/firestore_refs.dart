import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/models.dart';

/// Centralise toutes les `CollectionReference` / `DocumentReference` typées
/// via `.withConverter`. Les repos consomment uniquement ces refs, jamais
/// `FirebaseFirestore.instance` directement — ça simplifie les tests.
class FirestoreRefs {
  FirestoreRefs(this._db);

  final FirebaseFirestore _db;

  // ─── users ─────────────────────────────────────────────────────────────────
  CollectionReference<UserModel> get users => _db.collection('users').withConverter(
        fromFirestore: (snap, _) => UserModel.fromFirestore(snap),
        toFirestore: (u, _) => u.toFirestore(),
      );
  DocumentReference<UserModel> userDoc(String uid) => users.doc(uid);

  CollectionReference<Map<String, dynamic>> userFollowers(String uid) =>
      _db.collection('users').doc(uid).collection('followers');
  CollectionReference<Map<String, dynamic>> userFollowing(String uid) =>
      _db.collection('users').doc(uid).collection('following');

  // ─── scenes ────────────────────────────────────────────────────────────────
  CollectionReference<SceneModel> get scenes =>
      _db.collection('scenes').withConverter(
            fromFirestore: (snap, _) => SceneModel.fromFirestore(snap),
            toFirestore: (s, _) => s.toFirestore(),
          );
  DocumentReference<SceneModel> sceneDoc(String sceneId) => scenes.doc(sceneId);

  CollectionReference<CommentModel> sceneComments(String sceneId) => _db
      .collection('scenes')
      .doc(sceneId)
      .collection('comments')
      .withConverter(
        fromFirestore: (snap, _) =>
            CommentModel.fromFirestore(snap, sceneId: sceneId),
        toFirestore: (c, _) => c.toFirestore(),
      );

  CollectionReference<Map<String, dynamic>> sceneLikes(String sceneId) =>
      _db.collection('scenes').doc(sceneId).collection('likes');

  // ─── notifications ─────────────────────────────────────────────────────────
  CollectionReference<NotificationModel> userNotifications(String uid) => _db
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .withConverter(
        fromFirestore: (snap, _) => NotificationModel.fromFirestore(snap),
        toFirestore: (n, _) => n.toFirestore(),
      );

  // ─── duels ─────────────────────────────────────────────────────────────────
  CollectionReference<DuelModel> get duels =>
      _db.collection('duels').withConverter(
            fromFirestore: (snap, _) => DuelModel.fromFirestore(snap),
            toFirestore: (d, _) => d.toFirestore(),
          );
  CollectionReference<Map<String, dynamic>> duelVotes(String duelId) =>
      _db.collection('duels').doc(duelId).collection('votes');

    // ─── battles ───────────────────────────────────────────────────────────────
    CollectionReference<BattleModel> get battles =>
      _db.collection('battles').withConverter(
        fromFirestore: (snap, _) => BattleModel.fromFirestore(snap),
        toFirestore: (battle, _) => battle.toFirestore(),
        );
    DocumentReference<BattleModel> battleDoc(String battleId) => battles.doc(battleId);
    CollectionReference<Map<String, dynamic>> battleFollowers(String battleId) =>
      _db.collection('battles').doc(battleId).collection('followers');
    CollectionReference<Map<String, dynamic>> battleVotes(String battleId) =>
      _db.collection('battles').doc(battleId).collection('votes');
    CollectionReference<Map<String, dynamic>> battlePredictions(String battleId) =>
      _db.collection('battles').doc(battleId).collection('predictions');

    CollectionReference<BattleRivalryModel> get battleRivalries =>
      _db.collection('battleRivalries').withConverter(
        fromFirestore: (snap, _) => BattleRivalryModel.fromFirestore(snap),
        toFirestore: (rivalry, _) => rivalry.toFirestore(),
        );

    CollectionReference<UserBattleStatsModel> get userBattleStats =>
      _db.collection('userBattleStats').withConverter(
        fromFirestore: (snap, _) => UserBattleStatsModel.fromFirestore(snap),
        toFirestore: (stats, _) => stats.toFirestore(),
        );

  // ─── daily challenges ──────────────────────────────────────────────────────
  CollectionReference<DailyChallengeModel> get dailyChallenges =>
      _db.collection('dailyChallenges').withConverter(
            fromFirestore: (snap, _) => DailyChallengeModel.fromFirestore(snap),
            toFirestore: (c, _) => c.toFirestore(),
          );
  CollectionReference<Map<String, dynamic>> challengeParticipants(
          String dateKey) =>
      _db.collection('dailyChallenges').doc(dateKey).collection('participants');

  // ─── leaderboards ──────────────────────────────────────────────────────────
  CollectionReference<LeaderboardEntry> leaderboardEntries(String period) => _db
      .collection('leaderboards')
      .doc(period)
      .collection('entries')
      .withConverter(
        fromFirestore: (snap, _) => LeaderboardEntry.fromFirestore(snap),
        toFirestore: (e, _) => e.toFirestore(),
      );

  // ─── categories ────────────────────────────────────────────────────────────
  CollectionReference<CategoryModel> get categories =>
      _db.collection('categories').withConverter(
            fromFirestore: (snap, _) => CategoryModel.fromFirestore(snap),
            toFirestore: (c, _) => c.toFirestore(),
          );

  // ─── feed fan-out ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> userFeed(String uid) =>
      _db.collection('feed').doc(uid).collection('items');
}
