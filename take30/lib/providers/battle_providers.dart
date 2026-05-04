import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/battle_service.dart';
import 'providers.dart';

final battleServiceProvider = Provider<BattleService>((ref) => BattleService());

final homePublishedBattlesProvider =
    StreamProvider.autoDispose<List<BattleModel>>(
  (ref) => ref.watch(battleServiceProvider).watchHomePublishedBattles(),
);

final homePreparingBattlesProvider =
    StreamProvider.autoDispose<List<BattleModel>>(
  (ref) => ref.watch(battleServiceProvider).watchHomePreparingBattles(),
);

final mostExpectedBattlesProvider =
    StreamProvider.autoDispose<List<BattleModel>>(
  (ref) => ref.watch(battleServiceProvider).watchMostExpectedBattles(),
);

final followedCandidatesBattlesProvider =
    StreamProvider.autoDispose<List<BattleModel>>((ref) {
  final uid = ref.watch(authProvider).user?.id ?? '';
  return ref.watch(battleServiceProvider).watchBattlesForFollowedCandidates(uid);
});

final battleByIdProvider =
    StreamProvider.autoDispose.family<BattleModel?, String>((ref, battleId) {
  return ref.watch(battleServiceProvider).watchBattle(battleId);
});

final userBattleStatsProvider =
    StreamProvider.autoDispose.family<UserBattleStatsModel?, String>((ref, uid) {
  return ref.watch(battleServiceProvider).watchUserBattleStats(uid);
});

final candidateFollowersProvider =
    StreamProvider.autoDispose.family<int, String>((ref, uid) {
  return ref.watch(battleServiceProvider).watchCandidateFollowersCount(uid);
});

final battleVoteEligibilityProvider =
    Provider.autoDispose.family<bool, BattleModel>((ref, battle) {
  final uid = ref.watch(authProvider).user?.id ?? '';
  return battle.canVote(uid);
});

final battleCountdownProvider =
    StreamProvider.autoDispose.family<Duration?, String>((ref, battleId) {
  return ref.watch(battleServiceProvider).watchBattleCountdown(battleId);
});

final battleRivalryProvider =
    StreamProvider.autoDispose.family<BattleRivalryModel?, String>((ref, pairKey) {
  return ref.watch(battleServiceProvider).watchBattleRivalry(pairKey);
});

final battleChallengeEligibilityProvider =
    Provider.autoDispose.family<bool, String>((ref, opponentUid) {
  final challengerUid = ref.watch(authProvider).user?.id ?? '';
  if (challengerUid.isEmpty || opponentUid.isEmpty || challengerUid == opponentUid) {
    return false;
  }

  final challengerStats = ref.watch(userBattleStatsProvider(challengerUid));
  final opponentStats = ref.watch(userBattleStatsProvider(opponentUid));
  final challengerValue = challengerStats.valueOrNull;
  final opponentValue = opponentStats.valueOrNull;
  if (challengerValue == null || opponentValue == null) {
    return false;
  }

  return BattleService.isBattleEligible(
    challengerStats: challengerValue,
    opponentStats: opponentValue,
  );
});

final battleChallengeLabelProvider =
    Provider.autoDispose.family<String, String>((ref, opponentUid) {
  final theme = ref.watch(themeModeProvider);
  final eligible = ref.watch(battleChallengeEligibilityProvider(opponentUid));
  if (eligible) {
    return 'Provoquer en duel';
  }
  return theme == ThemeMode.dark
      ? 'Niveau Battle indisponible'
      : 'Ce candidat n\'est pas dans ton niveau Battle';
});