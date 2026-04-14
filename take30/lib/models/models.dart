class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.bio = '',
    this.isVerified = false,
    this.scenesCount = 0,
    this.followersCount = 0,
    this.likesCount = 0,
    this.totalViews = 0,
    this.approvalRate = 0,
    this.sharesCount = 0,
    this.badges = const [],
    this.isFollowing = false,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final bool isVerified;
  final int scenesCount;
  final int followersCount;
  final int likesCount;
  final int totalViews;
  final double approvalRate;
  final int sharesCount;
  final List<BadgeModel> badges;
  final bool isFollowing;

  UserModel copyWith({
    bool? isFollowing,
    int? followersCount,
  }) {
    return UserModel(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      isVerified: isVerified,
      scenesCount: scenesCount,
      followersCount: followersCount ?? this.followersCount,
      likesCount: likesCount,
      totalViews: totalViews,
      approvalRate: approvalRate,
      sharesCount: sharesCount,
      badges: badges,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class SceneModel {
  const SceneModel({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
    this.videoUrl,
    this.durationSeconds = 30,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    required this.author,
    required this.createdAt,
    this.isLiked = false,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String category;
  final String thumbnailUrl;
  final String? videoUrl;
  final int durationSeconds;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final UserModel author;
  final DateTime createdAt;
  final bool isLiked;
  final List<String> tags;

  SceneModel copyWith({
    bool? isLiked,
    int? likesCount,
  }) {
    return SceneModel(
      id: id,
      title: title,
      category: category,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      durationSeconds: durationSeconds,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      viewsCount: viewsCount,
      author: author,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      tags: tags,
    );
  }

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.scenesCount = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final int scenesCount;
}

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.type,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
  final BadgeType type;
}

enum BadgeType { gold, silver, bronze, special }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.score,
    required this.scoreLabel,
  });

  final int rank;
  final UserModel user;
  final double score;
  final String scoreLabel;
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.message,
    required this.subMessage,
    required this.type,
    required this.time,
    this.isRead = false,
    this.avatarUrl,
  });

  final String id;
  final String message;
  final String subMessage;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  final String? avatarUrl;
}

enum NotificationType { like, comment, duel, achievement, system }

class DuelModel {
  const DuelModel({
    required this.id,
    required this.sceneA,
    required this.sceneB,
    this.votesA = 0,
    this.votesB = 0,
    required this.expiresAt,
    this.userVote,
  });

  final String id;
  final SceneModel sceneA;
  final SceneModel sceneB;
  final int votesA;
  final int votesB;
  final DateTime expiresAt;
  final int? userVote;

  DuelModel copyWith({
    int? userVote,
    int? votesA,
    int? votesB,
  }) {
    return DuelModel(
      id: id,
      sceneA: sceneA,
      sceneB: sceneB,
      votesA: votesA ?? this.votesA,
      votesB: votesB ?? this.votesB,
      expiresAt: expiresAt,
      userVote: userVote ?? this.userVote,
    );
  }

  int get totalVotes => votesA + votesB;
  double get percentA => totalVotes == 0 ? 0.5 : votesA / totalVotes;
  double get percentB => totalVotes == 0 ? 0.5 : votesB / totalVotes;
}

class DailyChallengeModel {
  const DailyChallengeModel({
    required this.id,
    required this.sceneTitle,
    required this.quote,
    this.maxSeconds = 30,
    required this.thumbnailUrl,
    this.rules = const [],
    required this.expiresAt,
    this.participantsCount = 0,
  });

  final String id;
  final String sceneTitle;
  final String quote;
  final int maxSeconds;
  final String thumbnailUrl;
  final List<String> rules;
  final DateTime expiresAt;
  final int participantsCount;
}
