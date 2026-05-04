import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

class BattleServiceException implements Exception {
  const BattleServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BattleService {
  BattleService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    fa.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _auth = auth ?? fa.FirebaseAuth.instance;

  static const int defaultSubmissionHours = 72;
  static const int defaultVotingHours = 48;
  static const int minRatedTakesForBattleEligibility = 3;
  static const int maxActiveBattles = 2;
  static const int maxWeeklyChallenges = 3;
  static const double closeResultThresholdPercent = 5;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final fa.FirebaseAuth _auth;

  CollectionReference<BattleModel> get _battles =>
      _firestore.collection('battles').withConverter(
            fromFirestore: (snap, _) => BattleModel.fromFirestore(snap),
            toFirestore: (battle, _) => battle.toFirestore(),
          );

  CollectionReference<UserBattleStatsModel> get _userBattleStats =>
      _firestore.collection('userBattleStats').withConverter(
            fromFirestore: (snap, _) => UserBattleStatsModel.fromFirestore(snap),
            toFirestore: (stats, _) => stats.toFirestore(),
          );

  CollectionReference<BattleRivalryModel> get _battleRivalries =>
      _firestore.collection('battleRivalries').withConverter(
            fromFirestore: (snap, _) => BattleRivalryModel.fromFirestore(snap),
            toFirestore: (rivalry, _) => rivalry.toFirestore(),
          );

  Stream<List<BattleModel>> watchHomePublishedBattles() {
    return _battles
        .where('status', whereIn: const ['published', 'voting_open'])
        .orderBy('publishedAt', descending: true)
        .limit(12)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<BattleModel>> watchHomePreparingBattles() {
    return _battles
        .where(
          'status',
          whereIn: const [
            'accepted',
            'scene_assigned',
            'in_preparation',
            'waiting_challenger_submission',
            'waiting_opponent_submission',
            'ready_to_publish',
          ],
        )
        .orderBy('submissionDeadline')
        .limit(12)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<BattleModel>> watchMostExpectedBattles() {
    return _battles
        .where(
          'status',
          whereIn: const [
            'challenge_sent',
            'accepted',
            'scene_assigned',
            'in_preparation',
            'ready_to_publish',
            'published',
            'voting_open',
          ],
        )
        .orderBy('followersCount', descending: true)
        .limit(12)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<BattleModel>> watchBattlesForFollowedCandidates(String uid) {
    if (uid.isEmpty) {
      return Stream.value(const <BattleModel>[]);
    }

    final controller = StreamController<List<BattleModel>>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? followingSub;
    StreamSubscription<QuerySnapshot<BattleModel>>? battlesSub;
    Set<String> followedIds = <String>{};
    List<BattleModel> latestBattles = const <BattleModel>[];

    void emit() {
      final filtered = latestBattles.where((battle) {
        return followedIds.contains(battle.challengerId) ||
            followedIds.contains(battle.opponentId);
      }).toList();
      if (!controller.isClosed) {
        controller.add(filtered);
      }
    }

    followingSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .listen(
      (snapshot) {
        followedIds = snapshot.docs.map((doc) => doc.id).toSet();
        emit();
      },
      onError: controller.addError,
    );

    battlesSub = _battles
        .where(
          'status',
          whereIn: const [
            'in_preparation',
            'waiting_challenger_submission',
            'waiting_opponent_submission',
            'published',
            'voting_open',
            'ended',
          ],
        )
        .orderBy('updatedAt', descending: true)
        .limit(48)
        .snapshots()
        .listen(
      (snapshot) {
        latestBattles = snapshot.docs.map((doc) => doc.data()).toList();
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await followingSub?.cancel();
      await battlesSub?.cancel();
    };

    return controller.stream;
  }

  Stream<BattleModel?> watchBattle(String battleId) {
    if (battleId.isEmpty) {
      return Stream.value(null);
    }
    return _battles.doc(battleId).snapshots().map(
          (snapshot) => snapshot.exists ? snapshot.data() : null,
        );
  }

  Stream<UserBattleStatsModel?> watchUserBattleStats(String uid) {
    if (uid.isEmpty) {
      return Stream.value(null);
    }
    return _userBattleStats.doc(uid).snapshots().map(
          (snapshot) => snapshot.exists ? snapshot.data() : null,
        );
  }

  Stream<BattleRivalryModel?> watchBattleRivalry(String pairKey) {
    if (pairKey.isEmpty) {
      return Stream.value(null);
    }
    return _battleRivalries.doc(pairKey).snapshots().map(
          (snapshot) => snapshot.exists ? snapshot.data() : null,
        );
  }

  Stream<int> watchCandidateFollowersCount(String uid) {
    if (uid.isEmpty) {
      return Stream.value(0);
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<Duration?> watchBattleCountdown(String battleId) {
    final controller = StreamController<Duration?>();
    StreamSubscription<BattleModel?>? battleSub;
    Timer? timer;
    BattleModel? currentBattle;

    void pushCountdown() {
      if (controller.isClosed) {
        return;
      }
      controller.add(currentBattle?.timeRemaining);
    }

    battleSub = watchBattle(battleId).listen(
      (battle) {
        currentBattle = battle;
        timer?.cancel();
        pushCountdown();
        if (battle != null && battle.timeRemaining != null) {
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            pushCountdown();
          });
        }
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      timer?.cancel();
      await battleSub?.cancel();
    };

    return controller.stream;
  }

  Future<void> challengeUser({
    required String opponentId,
    String? sourceTakeId,
  }) async {
    await _callVoid('createBattleChallenge', {
      'opponentId': opponentId,
      if (_hasValue(sourceTakeId)) 'sourceTakeId': sourceTakeId,
    });
  }

  Future<void> respondToChallenge({
    required String battleId,
    required bool accept,
  }) async {
    await _callVoid('respondBattleChallenge', {
      'battleId': battleId,
      'accept': accept,
    });
  }

  Future<void> followBattle(String battleId) async {
    await _callVoid('followBattle', {'battleId': battleId});
  }

  Future<void> unfollowBattle(String battleId) async {
    await _callVoid('unfollowBattle', {'battleId': battleId});
  }

  Future<void> followCandidate(String candidateId) async {
    await _callVoid('followCandidate', {'candidateId': candidateId});
  }

  Future<void> unfollowCandidate(String candidateId) async {
    await _callVoid('unfollowCandidate', {'candidateId': candidateId});
  }

  Future<void> submitBattlePerformance({
    required String battleId,
    required String recordingId,
    required String videoUrl,
    required String storagePath,
  }) async {
    await _callVoid('submitBattlePerformance', {
      'battleId': battleId,
      'recordingId': recordingId,
      'videoUrl': videoUrl,
      'storagePath': storagePath,
    });
  }

  Future<void> voteBattle({
    required String battleId,
    required String votedForUserId,
    required double watchProgressChallenger,
    required double watchProgressOpponent,
  }) async {
    await _callVoid('castBattleVote', {
      'battleId': battleId,
      'votedForUserId': votedForUserId,
      'watchProgressChallenger': watchProgressChallenger,
      'watchProgressOpponent': watchProgressOpponent,
    });
  }

  Future<void> predictBattleWinner({
    required String battleId,
    required String predictedWinnerId,
  }) async {
    await _callVoid('createBattlePrediction', {
      'battleId': battleId,
      'predictedWinnerId': predictedWinnerId,
    });
  }

  Future<void> requestRevenge(String battleId) async {
    await _callVoid('requestBattleRevenge', {'battleId': battleId});
  }

  Future<void> reportBattle({
    required String battleId,
    required String reason,
    String? details,
  }) async {
    await _callVoid('reportBattle', {
      'battleId': battleId,
      'reason': reason,
      if (_hasValue(details)) 'details': details,
    });
  }

  Future<void> shareBattle(BattleModel battle) async {
    final deepLink = battle.deepLink ?? _defaultBattleUrl(battle.id);
    final title = battle.shareTitle.isNotEmpty
        ? battle.shareTitle
        : '${battle.challengerName} vs ${battle.opponentName}';
    final subtitle = battle.shareSubtitle.isNotEmpty
        ? battle.shareSubtitle
        : 'Meme scene. Meme delai. Deux interpretations. Un seul gagnant.';

    await SharePlus.instance.share(
      ShareParams(
        text: '$title\n\n$subtitle\n\n$deepLink',
        subject: title,
      ),
    );
  }

  Future<void> _callVoid(String name, Map<String, dynamic> payload) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const BattleServiceException('Connexion requise pour cette action.');
    }

    try {
      final callable = _functions.httpsCallable(name);
      await callable.call<Map<String, dynamic>>(payload);
    } on FirebaseFunctionsException catch (error) {
      if (kDebugMode) {
        debugPrint('Battle callable $name failed: ${error.code} ${error.message}');
      }
      throw BattleServiceException(_mapFunctionsMessage(error));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Battle callable $name failed: $error');
      }
      throw const BattleServiceException(
        'Une erreur est survenue. Reessaie dans un instant.',
      );
    }
  }

  String _mapFunctionsMessage(FirebaseFunctionsException error) {
    final backendMessage = error.message?.trim();
    if (_hasValue(backendMessage)) {
      return backendMessage!;
    }

    switch (error.code) {
      case 'failed-precondition':
        return 'Ce duel n\'est plus disponible.';
      case 'already-exists':
        return 'Tu as deja vote ou suivi cette battle.';
      case 'deadline-exceeded':
        return 'Le delai est depasse.';
      case 'permission-denied':
        return 'Action non autorisee.';
      case 'invalid-argument':
        return 'Les donnees envoyees sont invalides.';
      case 'unauthenticated':
        return 'Connexion requise pour cette action.';
      default:
        return 'Une erreur est survenue. Reessaie dans un instant.';
    }
  }

  String _defaultBattleUrl(String battleId) {
    if (kIsWeb) {
      final base = Uri.base;
      final firstSegment = base.pathSegments.isEmpty ? '' : base.pathSegments.first;
      final pathPrefix = firstSegment == 'take3' ? '/take3' : '';
      return '${base.origin}$pathPrefix/battle/$battleId';
    }
    return 'take60://battle/$battleId';
  }

  static bool isBattleEligible({
    required UserBattleStatsModel challengerStats,
    required UserBattleStatsModel opponentStats,
  }) {
    return challengerStats.isCompatibleWith(opponentStats) &&
        challengerStats.activeBattlesCount < maxActiveBattles &&
        opponentStats.activeBattlesCount < maxActiveBattles &&
        challengerStats.challengesSentThisWeek < maxWeeklyChallenges;
  }
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;