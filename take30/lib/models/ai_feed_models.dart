import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

enum FeedEventType {
  view,
  complete,
  rewatch,
  like,
  share,
  comment,
  skip,
  follow,
  vote,
}

extension FeedEventTypeX on FeedEventType {
  String get storageValue => name;

  static FeedEventType fromStorage(String? value) {
    return FeedEventType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => FeedEventType.view,
    );
  }
}

class FeedStylePreferences {
  const FeedStylePreferences({
    this.drama = 0,
    this.intense = 0,
    this.funny = 0,
    this.romance = 0,
  });

  final double drama;
  final double intense;
  final double funny;
  final double romance;

  double affinityFor(Iterable<String> styles) {
    var score = 0.0;
    for (final style in styles.map((s) => s.toLowerCase())) {
      if (style.contains('drama') || style.contains('clash')) score += drama;
      if (style.contains('intense') || style.contains('battle')) score += intense;
      if (style.contains('funny') || style.contains('comedy') || style.contains('humour')) score += funny;
      if (style.contains('romance') || style.contains('love')) score += romance;
    }
    return score.clamp(0, 1);
  }

  factory FeedStylePreferences.fromMap(Map<String, dynamic> map) {
    return FeedStylePreferences(
      drama: _readDouble(map['drama']),
      intense: _readDouble(map['intense']),
      funny: _readDouble(map['funny']),
      romance: _readDouble(map['romance']),
    );
  }

  Map<String, dynamic> toMap() => {
        'drama': drama,
        'intense': intense,
        'funny': funny,
        'romance': romance,
      };
}

class UserFeedProfile {
  const UserFeedProfile({
    required this.userId,
    this.preferredStyles = const FeedStylePreferences(),
    this.preferredDurations = const [],
    this.preferredRegions = const [],
    this.creatorAffinity = const {},
    this.skipPatterns = const {},
    this.updatedAt,
  });

  final String userId;
  final FeedStylePreferences preferredStyles;
  final List<int> preferredDurations;
  final List<String> preferredRegions;
  final Map<String, double> creatorAffinity;
  final Map<String, double> skipPatterns;
  final DateTime? updatedAt;

  factory UserFeedProfile.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserFeedProfile(
      userId: id ?? map['userId'] as String? ?? '',
      preferredStyles: FeedStylePreferences.fromMap(_readMap(map['preferredStyles'])),
      preferredDurations: (map['preferredDurations'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      preferredRegions: (map['preferredRegions'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      creatorAffinity: _readDoubleMap(map['creatorAffinity']),
      skipPatterns: _readDoubleMap(map['skipPatterns']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class FeedCandidate {
  const FeedCandidate({
    required this.postId,
    required this.userId,
    required this.videoUrl,
    required this.actorStyles,
    this.qualityScore = 0,
    this.trendingScore = 0,
    this.freshnessScore = 0,
    this.regionScore = 0,
    this.explorationScore = 0,
    this.createdAt,
  });

  final String postId;
  final String userId;
  final String videoUrl;
  final List<String> actorStyles;
  final double qualityScore;
  final double trendingScore;
  final double freshnessScore;
  final double regionScore;
  final double explorationScore;
  final DateTime? createdAt;

  double scoreFor(UserFeedProfile? profile) {
    final styleAffinity = profile?.preferredStyles.affinityFor(actorStyles) ?? 0.35;
    final completionPrediction = (qualityScore * 0.7 + regionScore * 0.3).clamp(0, 1);
    final rewatchPrediction = (qualityScore * 0.6 + trendingScore * 0.4).clamp(0, 1);
    return (styleAffinity * 30) +
        (completionPrediction * 25) +
        (rewatchPrediction * 15) +
        (trendingScore * 15) +
        (freshnessScore * 10) +
        (explorationScore * 5);
  }

  factory FeedCandidate.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FeedCandidate.fromMap(data, id: doc.id);
  }

  factory FeedCandidate.fromMap(Map<String, dynamic> map, {String? id}) {
    return FeedCandidate(
      postId: id ?? map['postId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      actorStyles: (map['actorStyles'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      qualityScore: _readDouble(map['qualityScore']),
      trendingScore: _readDouble(map['trendingScore']),
      freshnessScore: _readDouble(map['freshnessScore']),
      regionScore: _readDouble(map['regionScore']),
      explorationScore: _readDouble(map['explorationScore']),
      createdAt: _readDate(map['createdAt']),
    );
  }
}

class PersonalizedFeedItem {
  const PersonalizedFeedItem({
    required this.scene,
    this.candidate,
    this.feedScore = 0,
    this.reason = 'personalized',
    this.isBattle = false,
    this.battleId,
  });

  final SceneModel scene;
  final FeedCandidate? candidate;
  final double feedScore;
  final String reason;
  final bool isBattle;
  final String? battleId;
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
  return const <String, dynamic>{};
}

Map<String, double> _readDoubleMap(dynamic value) {
  final map = _readMap(value);
  return map.map((key, mapValue) => MapEntry(key, _readDouble(mapValue)));
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble().clamp(0, 1);
  return double.tryParse(value?.toString() ?? '')?.clamp(0, 1).toDouble() ?? 0;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
