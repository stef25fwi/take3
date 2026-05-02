import '../../../models/models.dart';

class ProfileViewedSceneHistoryItem {
  const ProfileViewedSceneHistoryItem({
    required this.sceneId,
    required this.title,
    required this.thumbnailUrl,
    required this.authorDisplayName,
    required this.viewedAt,
  });

  final String sceneId;
  final String title;
  final String thumbnailUrl;
  final String authorDisplayName;
  final DateTime viewedAt;

  factory ProfileViewedSceneHistoryItem.fromScene(
    SceneModel scene, {
    DateTime? viewedAt,
  }) {
    return ProfileViewedSceneHistoryItem(
      sceneId: scene.id,
      title: scene.title,
      thumbnailUrl: scene.thumbnailUrl,
      authorDisplayName: scene.author.displayName,
      viewedAt: viewedAt ?? DateTime.now(),
    );
  }

  factory ProfileViewedSceneHistoryItem.fromMap(Map<String, dynamic> map) {
    return ProfileViewedSceneHistoryItem(
      sceneId: map['sceneId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      authorDisplayName: map['authorDisplayName'] as String? ?? '',
      viewedAt: DateTime.tryParse(map['viewedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sceneId': sceneId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'authorDisplayName': authorDisplayName,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
}

class ProfileDuelVoteHistoryItem {
  const ProfileDuelVoteHistoryItem({
    required this.duelId,
    required this.selectedSceneTitle,
    required this.otherSceneTitle,
    required this.selectedThumbnailUrl,
    required this.otherThumbnailUrl,
    required this.selectedAuthorName,
    required this.otherAuthorName,
    required this.choice,
    required this.votedAt,
  });

  final String duelId;
  final String selectedSceneTitle;
  final String otherSceneTitle;
  final String selectedThumbnailUrl;
  final String otherThumbnailUrl;
  final String selectedAuthorName;
  final String otherAuthorName;
  final int choice;
  final DateTime votedAt;

  String get votedForLabel => '$selectedAuthorName • $selectedSceneTitle';

  factory ProfileDuelVoteHistoryItem.fromDuel(
    DuelModel duel,
    int choice, {
    DateTime? votedAt,
  }) {
    final selectedScene = choice == 0 ? duel.sceneA : duel.sceneB;
    final otherScene = choice == 0 ? duel.sceneB : duel.sceneA;
    return ProfileDuelVoteHistoryItem(
      duelId: duel.id,
      selectedSceneTitle: selectedScene.title,
      otherSceneTitle: otherScene.title,
      selectedThumbnailUrl: selectedScene.thumbnailUrl,
      otherThumbnailUrl: otherScene.thumbnailUrl,
      selectedAuthorName: selectedScene.author.displayName,
      otherAuthorName: otherScene.author.displayName,
      choice: choice,
      votedAt: votedAt ?? DateTime.now(),
    );
  }

  factory ProfileDuelVoteHistoryItem.fromMap(Map<String, dynamic> map) {
    return ProfileDuelVoteHistoryItem(
      duelId: map['duelId'] as String? ?? '',
      selectedSceneTitle: map['selectedSceneTitle'] as String? ?? '',
      otherSceneTitle: map['otherSceneTitle'] as String? ?? '',
      selectedThumbnailUrl: map['selectedThumbnailUrl'] as String? ?? '',
      otherThumbnailUrl: map['otherThumbnailUrl'] as String? ?? '',
      selectedAuthorName: map['selectedAuthorName'] as String? ?? '',
      otherAuthorName: map['otherAuthorName'] as String? ?? '',
      choice: (map['choice'] as num?)?.toInt() ?? 0,
      votedAt: DateTime.tryParse(map['votedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'duelId': duelId,
      'selectedSceneTitle': selectedSceneTitle,
      'otherSceneTitle': otherSceneTitle,
      'selectedThumbnailUrl': selectedThumbnailUrl,
      'otherThumbnailUrl': otherThumbnailUrl,
      'selectedAuthorName': selectedAuthorName,
      'otherAuthorName': otherAuthorName,
      'choice': choice,
      'votedAt': votedAt.toIso8601String(),
    };
  }
}