import 'package:cloud_firestore/cloud_firestore.dart';

import 'take60_guided_flow.dart';

export 'battle_model.dart';
export 'battle_follower_model.dart';
export 'battle_prediction_model.dart';
export 'battle_rivalry_model.dart';
export 'battle_vote_model.dart';
export 'take60_guided_flow.dart';
export 'user_battle_stats_model.dart';

// ─── Converters helpers ──────────────────────────────────────────────────────
DateTime _readDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

Timestamp _writeDate(DateTime d) => Timestamp.fromDate(d);

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.map((item) => _readMap(item)).toList();
}

T _enumFromString<T>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  return values.firstWhere(
    (e) => e.toString().split('.').last == name,
    orElse: () => fallback,
  );
}

String _enumToString(Object e) => e.toString().split('.').last;

// ─── UserModel ───────────────────────────────────────────────────────────────
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.email,
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
    this.isAdmin = false,
    this.createdAt,
    this.lastActiveAt,
    this.fcmTokens = const [],
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String? email;
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
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final List<String> fcmTokens;

  UserModel copyWith({
    bool? isFollowing,
    int? followersCount,
  }) {
    return UserModel(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
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
      isAdmin: isAdmin,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      fcmTokens: fcmTokens,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return UserModel(
      id: doc.id,
      username: d['username'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? '',
      email: d['email'] as String?,
      bio: d['bio'] as String? ?? '',
      isVerified: d['isVerified'] as bool? ?? false,
      scenesCount: (d['scenesCount'] as num?)?.toInt() ?? 0,
      followersCount: (d['followersCount'] as num?)?.toInt() ?? 0,
      likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
      totalViews: (d['totalViews'] as num?)?.toInt() ?? 0,
      approvalRate: (d['approvalRate'] as num?)?.toDouble() ?? 0,
      sharesCount: (d['sharesCount'] as num?)?.toInt() ?? 0,
        isAdmin: d['isAdmin'] as bool? ?? false,
      createdAt: d['createdAt'] == null ? null : _readDate(d['createdAt']),
      lastActiveAt:
          d['lastActiveAt'] == null ? null : _readDate(d['lastActiveAt']),
      fcmTokens: (d['fcmTokens'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
      if (email != null && email!.isNotEmpty) 'email': email,
        'bio': bio,
        'isVerified': isVerified,
        'scenesCount': scenesCount,
        'followersCount': followersCount,
        'likesCount': likesCount,
        'totalViews': totalViews,
        'approvalRate': approvalRate,
        'sharesCount': sharesCount,
        'isAdmin': isAdmin,
        if (createdAt != null) 'createdAt': _writeDate(createdAt!),
        if (lastActiveAt != null) 'lastActiveAt': _writeDate(lastActiveAt!),
        'fcmTokens': fcmTokens,
      };

  UserStub toStub() => UserStub(
        id: id,
        username: username,
        avatarUrl: avatarUrl,
        isVerified: isVerified,
      );
}

/// Version légère utilisée pour dénormaliser l'auteur dans scenes/comments/notifs.
class UserStub {
  const UserStub({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final bool isVerified;

  factory UserStub.fromMap(Map<String, dynamic> m) => UserStub(
        id: m['id'] as String? ?? '',
        username: m['username'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String? ?? '',
        isVerified: m['isVerified'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatarUrl': avatarUrl,
        'isVerified': isVerified,
      };
}

// ─── SceneModel ──────────────────────────────────────────────────────────────
class SceneModel {
  const SceneModel({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
    this.sceneType = '',
    this.videoUrl,
    this.description = '',
    this.dialogueText = '',
    this.difficulty = '',
    this.durationSeconds = 60,
    this.editingMode = 'dialogue_auto_cut',
    this.ambiance = '',
    this.characterToPlay = '',
    this.context = '',
    this.emotionalObjective = '',
    this.mainObstacle = '',
    this.dominantEmotion = '',
    this.directorInstructions = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    required this.author,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.veoPrompt = '',
    this.veoStatus = 'none',
    this.veoOperationId,
    this.veoError,
    this.isLiked = false,
    this.tags = const [],
    this.status = 'published',
    this.adminWorkflow = false,
    this.audioRules = const Take60AudioRules(),
    this.markers = const [],
  });

  final String id;
  final String title;
  final String category;
  final String thumbnailUrl;
  final String sceneType;
  final String? videoUrl;
  final String description;
  final String dialogueText;
  final String difficulty;
  final int durationSeconds;
  final String editingMode;
  final String ambiance;
  final String characterToPlay;
  final String context;
  final String emotionalObjective;
  final String mainObstacle;
  final String dominantEmotion;
  final String directorInstructions;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final UserModel author;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String veoPrompt;
  final String veoStatus;
  final String? veoOperationId;
  final String? veoError;
  final bool isLiked;
  final List<String> tags;
  final String status;
  final bool adminWorkflow;
  final Take60AudioRules audioRules;
  final List<Take60SceneMarker> markers;

  String get authorId => author.id;
  int get userPlanCount =>
      markers.where((marker) => marker.requiresUserRecording).length;
  bool get isGuidedRecordingReady =>
      adminWorkflow ||
      markers.isNotEmpty ||
      sceneType.trim().isNotEmpty ||
      characterToPlay.trim().isNotEmpty ||
      context.trim().isNotEmpty;

  SceneModel copyWith({
    bool? isLiked,
    int? likesCount,
  }) {
    return SceneModel(
      id: id,
      title: title,
      category: category,
      thumbnailUrl: thumbnailUrl,
      sceneType: sceneType,
      videoUrl: videoUrl,
      description: description,
      dialogueText: dialogueText,
      difficulty: difficulty,
      durationSeconds: durationSeconds,
      editingMode: editingMode,
      ambiance: ambiance,
      characterToPlay: characterToPlay,
      context: context,
      emotionalObjective: emotionalObjective,
      mainObstacle: mainObstacle,
      dominantEmotion: dominantEmotion,
      directorInstructions: directorInstructions,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      viewsCount: viewsCount,
      author: author,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      veoPrompt: veoPrompt,
      veoStatus: veoStatus,
      veoOperationId: veoOperationId,
      veoError: veoError,
      isLiked: isLiked ?? this.isLiked,
      tags: tags,
      status: status,
      adminWorkflow: adminWorkflow,
      audioRules: audioRules,
      markers: markers,
    );
  }

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory SceneModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final authorMap = _readMap(d['authorDenorm']);
    final actorSheet = _readMap(d['actorSheet']);
    final aiIntroVideo = _readMap(d['aiIntroVideo']);
    final rawMarkers = _readMapList(d['markers'] ?? d['guidedMarkers']);
    final isAdminWorkflow = d['adminWorkflow'] as bool? ?? false;
    final rawCategory = d['category'] as String? ?? '';
    final rawGenre = d['genre'] as String? ?? '';
    return SceneModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      category: isAdminWorkflow && rawGenre.trim().isNotEmpty
          ? rawGenre
          : rawCategory,
      thumbnailUrl: d['thumbnailUrl'] as String? ?? '',
      sceneType:
          d['type'] as String? ??
          d['sceneType'] as String? ??
          (isAdminWorkflow ? rawCategory : ''),
      videoUrl:
        d['videoUrl'] as String? ?? aiIntroVideo['videoUrl'] as String?,
      description: d['description'] as String? ?? d['contextSummary'] as String? ?? '',
      dialogueText: d['dialogueText'] as String? ?? '',
      difficulty: d['difficulty'] as String? ?? d['level'] as String? ?? '',
      durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 60,
      editingMode: d['editingMode'] as String? ?? 'dialogue_auto_cut',
      ambiance: d['ambiance'] as String? ??
        d['dominantEmotion'] as String? ??
        actorSheet['mainEmotion'] as String? ??
        '',
      characterToPlay: d['characterToPlay'] as String? ??
        actorSheet['characterName'] as String? ??
        '',
      context: d['context'] as String? ??
        d['contextSummary'] as String? ??
        d['description'] as String? ??
        '',
      emotionalObjective: d['emotionalObjective'] as String? ??
        d['mainObjective'] as String? ??
        actorSheet['characterIntention'] as String? ??
        '',
      mainObstacle: d['mainObstacle'] as String? ??
        actorSheet['sceneObjective'] as String? ??
        '',
      dominantEmotion: d['dominantEmotion'] as String? ??
        actorSheet['mainEmotion'] as String? ??
        '',
      directorInstructions: d['directorInstructions'] as String? ??
        d['director'] as String? ??
        actorSheet['stagingInstructions'] as String? ??
        '',
      likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (d['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (d['sharesCount'] as num?)?.toInt() ?? 0,
      viewsCount: (d['viewsCount'] as num?)?.toInt() ?? 0,
      author: UserModel(
        id: d['authorId'] as String? ?? (authorMap['id'] as String? ?? ''),
        username: authorMap['username'] as String? ?? '',
        displayName: authorMap['username'] as String? ?? '',
        avatarUrl: authorMap['avatarUrl'] as String? ?? '',
        isVerified: authorMap['isVerified'] as bool? ?? false,
      ),
      createdAt: _readDate(d['createdAt']),
      updatedAt: d['updatedAt'] == null ? null : _readDate(d['updatedAt']),
      createdBy: d['createdBy'] as String?,
      veoPrompt: d['veoPrompt'] as String? ?? '',
      veoStatus: d['veoStatus'] as String? ?? 'none',
      veoOperationId: d['veoOperationId'] as String?,
      veoError: d['veoError'] as String?,
      tags: (d['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: d['status'] as String? ?? 'published',
      adminWorkflow: isAdminWorkflow,
      audioRules: Take60AudioRules.fromMap(_readMap(d['audioRules'])),
      markers: rawMarkers
          .map(Take60SceneMarker.fromMap)
          .toList()
        ..sort((left, right) => left.order.compareTo(right.order)),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'category': category,
        'thumbnailUrl': thumbnailUrl,
        'type': sceneType,
        'videoUrl': videoUrl,
        'description': description,
        'dialogueText': dialogueText,
        'difficulty': difficulty,
        'durationSeconds': durationSeconds,
        'editingMode': editingMode,
        'ambiance': ambiance,
        'characterToPlay': characterToPlay,
        'context': context,
        'emotionalObjective': emotionalObjective,
        'mainObstacle': mainObstacle,
        'dominantEmotion': dominantEmotion,
        'directorInstructions': directorInstructions,
        'authorId': author.id,
        'authorDenorm': author.toStub().toMap(),
        'createdBy': createdBy ?? author.id,
        'veoPrompt': veoPrompt,
        'veoStatus': veoStatus,
        'veoOperationId': veoOperationId,
        'veoError': veoError,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'viewsCount': viewsCount,
        'tags': tags,
        'status': status,
        'adminWorkflow': adminWorkflow,
        'audioRules': audioRules.toMap(),
        'markers': markers.map((marker) => marker.toMap()).toList(),
        'createdAt': _writeDate(createdAt),
        'updatedAt': _writeDate(updatedAt ?? createdAt),
      };
}

// ─── CategoryModel ───────────────────────────────────────────────────────────
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

  factory CategoryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '',
      scenesCount: (d['scenesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'emoji': emoji,
        'scenesCount': scenesCount,
      };
}

// ─── BadgeModel ──────────────────────────────────────────────────────────────
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

  factory BadgeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return BadgeModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '',
      description: d['description'] as String? ?? '',
      type: _enumFromString(
          BadgeType.values, d['type'] as String?, BadgeType.bronze),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'emoji': emoji,
        'description': description,
        'type': _enumToString(type),
      };
}

enum BadgeType { gold, silver, bronze, special }

// ─── LeaderboardEntry ────────────────────────────────────────────────────────
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

  factory LeaderboardEntry.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final u = d['userDenorm'] as Map<String, dynamic>? ?? const {};
    return LeaderboardEntry(
      rank: (d['rank'] as num?)?.toInt() ?? 0,
      user: UserModel(
        id: d['userId'] as String? ?? (u['id'] as String? ?? ''),
        username: u['username'] as String? ?? '',
        displayName: u['username'] as String? ?? '',
        avatarUrl: u['avatarUrl'] as String? ?? '',
        isVerified: u['isVerified'] as bool? ?? false,
        followersCount: (u['followersCount'] as num?)?.toInt() ?? 0,
      ),
      score: (d['score'] as num?)?.toDouble() ?? 0,
      scoreLabel: d['scoreLabel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'rank': rank,
        'userId': user.id,
        'userDenorm': {
          ...user.toStub().toMap(),
          'followersCount': user.followersCount,
        },
        'score': score,
        'scoreLabel': scoreLabel,
      };
}

// ─── NotificationModel ───────────────────────────────────────────────────────
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.message,
    required this.subMessage,
    required this.type,
    required this.time,
    this.isRead = false,
    this.avatarUrl,
    this.sceneId,
    this.userId,
  });

  final String id;
  final String message;
  final String subMessage;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  final String? avatarUrl;
  final String? sceneId;
  final String? userId;

  factory NotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final actor = d['actorDenorm'] as Map<String, dynamic>? ?? const {};
    final type = _enumFromString(
      NotificationType.values,
      d['type'] as String?,
      NotificationType.system,
    );
    return NotificationModel(
      id: doc.id,
      message: d['message'] as String? ?? d['text'] as String? ?? '',
      subMessage: d['subMessage'] as String? ??
          _notificationFallbackSubMessage(type),
      type: type,
      time: _readDate(d['time']),
      isRead: d['isRead'] as bool? ?? false,
      avatarUrl: d['avatarUrl'] as String? ?? actor['avatarUrl'] as String?,
      sceneId: d['sceneId'] as String?,
      userId: d['userId'] as String? ?? actor['id'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'message': message,
        'subMessage': subMessage,
        'type': _enumToString(type),
        'time': _writeDate(time),
        'isRead': isRead,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (sceneId != null) 'sceneId': sceneId,
        if (userId != null) 'userId': userId,
      };
}

String _notificationFallbackSubMessage(NotificationType type) {
  switch (type) {
    case NotificationType.like:
      return 'Ouvre la vidéo pour voir qui a réagi.';
    case NotificationType.comment:
      return 'Lis le commentaire et réponds si besoin.';
    case NotificationType.duel:
      return 'Va voir la battle en cours.';
    case NotificationType.achievement:
      return 'Un nouveau badge ou palier t’attend.';
    case NotificationType.follow:
      return 'Découvre son profil ou rends-lui la pareille.';
    case NotificationType.system:
      return 'Consulte cette mise à jour.';
  }
}

enum NotificationType { like, comment, duel, achievement, follow, system }

// ─── DuelModel ───────────────────────────────────────────────────────────────
class DuelModel {
  const DuelModel({
    required this.id,
    required this.sceneA,
    required this.sceneB,
    this.votesA = 0,
    this.votesB = 0,
    required this.expiresAt,
    this.userVote,
    this.status = 'active',
  });

  final String id;
  final SceneModel sceneA;
  final SceneModel sceneB;
  final int votesA;
  final int votesB;
  final DateTime expiresAt;
  final int? userVote;
  final String status;

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
      status: status,
    );
  }

  int get totalVotes => votesA + votesB;
  double get percentA => totalVotes == 0 ? 0.5 : votesA / totalVotes;
  double get percentB => totalVotes == 0 ? 0.5 : votesB / totalVotes;

  factory DuelModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    SceneModel stubToScene(Map<String, dynamic> m) {
      final authorMap = m['authorDenorm'] as Map<String, dynamic>? ?? const {};
      return SceneModel(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        category: m['category'] as String? ?? '',
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        author: UserModel(
          id: authorMap['id'] as String? ?? '',
          username: authorMap['username'] as String? ?? '',
          displayName: authorMap['username'] as String? ?? '',
          avatarUrl: authorMap['avatarUrl'] as String? ?? '',
          isVerified: authorMap['isVerified'] as bool? ?? false,
        ),
        createdAt: DateTime.now(),
      );
    }

    return DuelModel(
      id: doc.id,
      sceneA: stubToScene(d['sceneA'] as Map<String, dynamic>? ?? const {}),
      sceneB: stubToScene(d['sceneB'] as Map<String, dynamic>? ?? const {}),
      votesA: (d['votesA'] as num?)?.toInt() ?? 0,
      votesB: (d['votesB'] as num?)?.toInt() ?? 0,
      expiresAt: _readDate(d['expiresAt']),
      status: d['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> sceneStub(SceneModel s) => {
          'id': s.id,
          'title': s.title,
          'category': s.category,
          'thumbnailUrl': s.thumbnailUrl,
          'authorDenorm': s.author.toStub().toMap(),
        };
    return {
      'sceneA': sceneStub(sceneA),
      'sceneB': sceneStub(sceneB),
      'votesA': votesA,
      'votesB': votesB,
      'expiresAt': _writeDate(expiresAt),
      'status': status,
    };
  }
}

// ─── DailyChallengeModel ─────────────────────────────────────────────────────
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

  factory DailyChallengeModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return DailyChallengeModel(
      id: doc.id,
      sceneTitle: d['sceneTitle'] as String? ?? '',
      quote: d['quote'] as String? ?? '',
      maxSeconds: (d['maxSeconds'] as num?)?.toInt() ?? 30,
      thumbnailUrl: d['thumbnailUrl'] as String? ?? '',
      rules: (d['rules'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      expiresAt: _readDate(d['expiresAt']),
      participantsCount: (d['participantsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'sceneTitle': sceneTitle,
        'quote': quote,
        'maxSeconds': maxSeconds,
        'thumbnailUrl': thumbnailUrl,
        'rules': rules,
        'expiresAt': _writeDate(expiresAt),
        'participantsCount': participantsCount,
      };
}

// ─── CommentModel ────────────────────────────────────────────────────────────
class CommentModel {
  const CommentModel({
    required this.id,
    required this.sceneId,
    required this.authorId,
    required this.authorDenorm,
    required this.text,
    required this.createdAt,
    this.likesCount = 0,
  });

  final String id;
  final String sceneId;
  final String authorId;
  final UserStub authorDenorm;
  final String text;
  final DateTime createdAt;
  final int likesCount;

  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String sceneId,
  }) {
    final d = doc.data() ?? const <String, dynamic>{};
    return CommentModel(
      id: doc.id,
      sceneId: sceneId,
      authorId: d['authorId'] as String? ?? '',
      authorDenorm: UserStub.fromMap(
          d['authorDenorm'] as Map<String, dynamic>? ?? const {}),
      text: d['text'] as String? ?? '',
      createdAt: _readDate(d['createdAt']),
      likesCount: (d['likesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorDenorm': authorDenorm.toMap(),
        'text': text,
        'createdAt': _writeDate(createdAt),
        'likesCount': likesCount,
      };
}

// ─── Edges / records ─────────────────────────────────────────────────────────
class FollowEdge {
  const FollowEdge({
    required this.userId,
    required this.createdAt,
  });

  final String userId;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'createdAt': _writeDate(createdAt),
      };
}

class LikeRecord {
  const LikeRecord({required this.userId, required this.createdAt});

  final String userId;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'createdAt': _writeDate(createdAt),
      };
}

class VoteRecord {
  const VoteRecord({
    required this.userId,
    required this.choice,
    required this.createdAt,
  });

  final String userId;
  final String choice; // 'A' | 'B'
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'choice': choice,
        'createdAt': _writeDate(createdAt),
      };
}
