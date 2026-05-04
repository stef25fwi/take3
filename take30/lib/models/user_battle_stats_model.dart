import 'package:cloud_firestore/cloud_firestore.dart';

class UserBattleStatsModel {
  const UserBattleStatsModel({
    required this.uid,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.battleRatingTier = 'rookie',
    this.battlesPlayed = 0,
    this.battlesWon = 0,
    this.battlesLost = 0,
    this.battlesDraw = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
    this.activeBattlesCount = 0,
    this.pendingChallengesCount = 0,
    this.challengesSentThisWeek = 0,
    this.battlesCreatedThisWeek = 0,
    this.followersGainedFromBattles = 0,
    this.lastBattleAt,
    this.updatedAt,
    this.badges = const <String>[],
    this.bestCategory,
  });

  static const int minRatedTakesForBattleEligibility = 3;
  static const int maxActiveBattles = 2;
  static const int maxWeeklyChallenges = 3;

  final String uid;
  final double ratingAvg;
  final int ratingCount;
  final String battleRatingTier;
  final int battlesPlayed;
  final int battlesWon;
  final int battlesLost;
  final int battlesDraw;
  final int winStreak;
  final int bestWinStreak;
  final int activeBattlesCount;
  final int pendingChallengesCount;
  final int challengesSentThisWeek;
  final int battlesCreatedThisWeek;
  final int followersGainedFromBattles;
  final DateTime? lastBattleAt;
  final DateTime? updatedAt;
  final List<String> badges;
  final String? bestCategory;

  factory UserBattleStatsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UserBattleStatsModel.fromMap(
      doc.data() ?? const <String, dynamic>{},
      uid: doc.id,
    );
  }

  factory UserBattleStatsModel.fromMap(
    Map<String, dynamic> data, {
    String? uid,
  }) {
    return UserBattleStatsModel(
      uid: uid ?? (data['uid'] as String? ?? ''),
      ratingAvg: _readDouble(data['ratingAvg']),
      ratingCount: _readInt(data['ratingCount']),
      battleRatingTier: data['battleRatingTier'] as String? ?? 'rookie',
      battlesPlayed: _readInt(data['battlesPlayed']),
      battlesWon: _readInt(data['battlesWon']),
      battlesLost: _readInt(data['battlesLost']),
      battlesDraw: _readInt(data['battlesDraw']),
      winStreak: _readInt(data['winStreak']),
      bestWinStreak: _readInt(data['bestWinStreak']),
      activeBattlesCount: _readInt(data['activeBattlesCount']),
      pendingChallengesCount: _readInt(data['pendingChallengesCount']),
      challengesSentThisWeek: _readInt(data['challengesSentThisWeek']),
      battlesCreatedThisWeek: _readInt(data['battlesCreatedThisWeek']),
      followersGainedFromBattles:
          _readInt(data['followersGainedFromBattles']),
      lastBattleAt: _readNullableDate(data['lastBattleAt']),
      updatedAt: _readNullableDate(data['updatedAt']),
      badges: _readStringList(data['badges']),
      bestCategory: _readNullableString(data['bestCategory']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'battleRatingTier': battleRatingTier,
      'battlesPlayed': battlesPlayed,
      'battlesWon': battlesWon,
      'battlesLost': battlesLost,
      'battlesDraw': battlesDraw,
      'winStreak': winStreak,
      'bestWinStreak': bestWinStreak,
      'activeBattlesCount': activeBattlesCount,
      'pendingChallengesCount': pendingChallengesCount,
      'challengesSentThisWeek': challengesSentThisWeek,
      'battlesCreatedThisWeek': battlesCreatedThisWeek,
      'followersGainedFromBattles': followersGainedFromBattles,
      if (lastBattleAt != null) 'lastBattleAt': Timestamp.fromDate(lastBattleAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (badges.isNotEmpty) 'badges': badges,
      if (_hasValue(bestCategory)) 'bestCategory': bestCategory,
    };
  }

  bool get hasEnoughRatings =>
      ratingCount >= minRatedTakesForBattleEligibility && ratingAvg > 0;

  bool get canOpenNewBattle =>
      hasEnoughRatings &&
      activeBattlesCount < maxActiveBattles &&
      challengesSentThisWeek < maxWeeklyChallenges;

  double get minOpponentRating => ratingAvg * 0.9;
  double get maxOpponentRating => ratingAvg * 1.1;

  bool isCompatibleWith(UserBattleStatsModel other) {
    if (!canOpenNewBattle || !other.canOpenNewBattle) {
      return false;
    }
    return other.ratingAvg >= minOpponentRating &&
        other.ratingAvg <= maxOpponentRating;
  }
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _readNullableDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((item) => item.toString()).toList();
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;