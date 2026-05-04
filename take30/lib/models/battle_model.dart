import 'package:cloud_firestore/cloud_firestore.dart';

enum BattleStatus {
  challengeSent,
  declined,
  accepted,
  sceneAssigned,
  inPreparation,
  waitingChallengerSubmission,
  waitingOpponentSubmission,
  readyToPublish,
  published,
  votingOpen,
  ended,
  cancelled,
  forfeit,
}

enum BattleResultReason {
  votes,
  forfeit,
  tieBreakWatchTime,
  tie,
  cancelled,
}

class BattleModel {
  const BattleModel({
    required this.id,
    required this.status,
    required this.challengerId,
    required this.opponentId,
    required this.challengerName,
    required this.opponentName,
    this.challengerPhotoUrl,
    this.opponentPhotoUrl,
    this.challengerRatingAvgAtChallenge = 0,
    this.opponentRatingAvgAtChallenge = 0,
    this.ratingDeltaPercent = 0,
    this.isRatingEligible = false,
    this.themeId,
    this.themeTitle,
    this.sceneId,
    this.sceneTitle,
    this.sceneCategory,
    this.sceneGenre,
    this.sceneDifficulty,
    this.sceneDurationSec,
    this.sceneAdminWorkflow = false,
    required this.createdAt,
    this.acceptedAt,
    this.declinedAt,
    this.sceneAssignedAt,
    this.submissionDeadline,
    this.challengerSubmittedAt,
    this.opponentSubmittedAt,
    this.publishedAt,
    this.votingStartsAt,
    this.votingEndsAt,
    this.endedAt,
    this.cancelledAt,
    this.challengerVideoUrl,
    this.opponentVideoUrl,
    this.challengerRecordingId,
    this.opponentRecordingId,
    this.challengerStoragePath,
    this.opponentStoragePath,
    this.followersCount = 0,
    this.predictionsCount = 0,
    this.commentsCount = 0,
    this.votesChallenger = 0,
    this.votesOpponent = 0,
    this.totalVotes = 0,
    this.watchersCount = 0,
    this.winnerId,
    this.loserId,
    this.resultReason,
    this.isRevengeAvailable = false,
    this.parentBattleId,
    this.rivalryPairKey = '',
    this.isFeatured = false,
    this.featuredUntil,
    this.battleScore = 0,
    this.trendingScore = 0,
    this.visibilityScope = 'public',
    this.regionCode,
    this.countryCode,
    this.shareTitle = '',
    this.shareSubtitle = '',
    this.shareImageUrl,
    this.deepLink,
    this.createdBy = '',
    this.updatedAt,
    this.version = 1,
  });

  final String id;
  final BattleStatus status;
  final String challengerId;
  final String opponentId;
  final String challengerName;
  final String opponentName;
  final String? challengerPhotoUrl;
  final String? opponentPhotoUrl;
  final double challengerRatingAvgAtChallenge;
  final double opponentRatingAvgAtChallenge;
  final double ratingDeltaPercent;
  final bool isRatingEligible;
  final String? themeId;
  final String? themeTitle;
  final String? sceneId;
  final String? sceneTitle;
  final String? sceneCategory;
  final String? sceneGenre;
  final String? sceneDifficulty;
  final int? sceneDurationSec;
  final bool sceneAdminWorkflow;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? sceneAssignedAt;
  final DateTime? submissionDeadline;
  final DateTime? challengerSubmittedAt;
  final DateTime? opponentSubmittedAt;
  final DateTime? publishedAt;
  final DateTime? votingStartsAt;
  final DateTime? votingEndsAt;
  final DateTime? endedAt;
  final DateTime? cancelledAt;
  final String? challengerVideoUrl;
  final String? opponentVideoUrl;
  final String? challengerRecordingId;
  final String? opponentRecordingId;
  final String? challengerStoragePath;
  final String? opponentStoragePath;
  final int followersCount;
  final int predictionsCount;
  final int commentsCount;
  final int votesChallenger;
  final int votesOpponent;
  final int totalVotes;
  final int watchersCount;
  final String? winnerId;
  final String? loserId;
  final BattleResultReason? resultReason;
  final bool isRevengeAvailable;
  final String? parentBattleId;
  final String rivalryPairKey;
  final bool isFeatured;
  final DateTime? featuredUntil;
  final double battleScore;
  final double trendingScore;
  final String visibilityScope;
  final String? regionCode;
  final String? countryCode;
  final String shareTitle;
  final String shareSubtitle;
  final String? shareImageUrl;
  final String? deepLink;
  final String createdBy;
  final DateTime? updatedAt;
  final int version;

  factory BattleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BattleModel.fromMap(
      doc.data() ?? const <String, dynamic>{},
      id: doc.id,
    );
  }

  factory BattleModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return BattleModel(
      id: id ?? (data['id'] as String? ?? ''),
      status: BattleStatusX.fromStorage(data['status'] as String?),
      challengerId: data['challengerId'] as String? ?? '',
      opponentId: data['opponentId'] as String? ?? '',
      challengerName: data['challengerName'] as String? ?? '',
      opponentName: data['opponentName'] as String? ?? '',
      challengerPhotoUrl: _readNullableString(data['challengerPhotoUrl']),
      opponentPhotoUrl: _readNullableString(data['opponentPhotoUrl']),
      challengerRatingAvgAtChallenge:
          _readDouble(data['challengerRatingAvgAtChallenge']),
      opponentRatingAvgAtChallenge:
          _readDouble(data['opponentRatingAvgAtChallenge']),
      ratingDeltaPercent: _readDouble(data['ratingDeltaPercent']),
      isRatingEligible: data['isRatingEligible'] as bool? ?? false,
      themeId: _readNullableString(data['themeId']),
      themeTitle: _readNullableString(data['themeTitle']),
      sceneId: _readNullableString(data['sceneId']),
      sceneTitle: _readNullableString(data['sceneTitle']),
      sceneCategory: _readNullableString(data['sceneCategory']),
      sceneGenre: _readNullableString(data['sceneGenre']),
      sceneDifficulty: _readNullableString(data['sceneDifficulty']),
      sceneDurationSec: _readNullableInt(data['sceneDurationSec']),
      sceneAdminWorkflow: data['sceneAdminWorkflow'] as bool? ?? false,
      createdAt: _readRequiredDate(data['createdAt']),
      acceptedAt: _readNullableDate(data['acceptedAt']),
      declinedAt: _readNullableDate(data['declinedAt']),
      sceneAssignedAt: _readNullableDate(data['sceneAssignedAt']),
      submissionDeadline: _readNullableDate(data['submissionDeadline']),
      challengerSubmittedAt:
          _readNullableDate(data['challengerSubmittedAt']),
      opponentSubmittedAt: _readNullableDate(data['opponentSubmittedAt']),
      publishedAt: _readNullableDate(data['publishedAt']),
      votingStartsAt: _readNullableDate(data['votingStartsAt']),
      votingEndsAt: _readNullableDate(data['votingEndsAt']),
      endedAt: _readNullableDate(data['endedAt']),
      cancelledAt: _readNullableDate(data['cancelledAt']),
      challengerVideoUrl: _readNullableString(data['challengerVideoUrl']),
      opponentVideoUrl: _readNullableString(data['opponentVideoUrl']),
      challengerRecordingId:
          _readNullableString(data['challengerRecordingId']),
      opponentRecordingId: _readNullableString(data['opponentRecordingId']),
      challengerStoragePath:
          _readNullableString(data['challengerStoragePath']),
      opponentStoragePath: _readNullableString(data['opponentStoragePath']),
      followersCount: _readInt(data['followersCount']),
      predictionsCount: _readInt(data['predictionsCount']),
      commentsCount: _readInt(data['commentsCount']),
      votesChallenger: _readInt(data['votesChallenger']),
      votesOpponent: _readInt(data['votesOpponent']),
      totalVotes: _readInt(data['totalVotes']),
        watchersCount: _readInt(data['watchersCount']),
      winnerId: _readNullableString(data['winnerId']),
      loserId: _readNullableString(data['loserId']),
      resultReason:
          BattleResultReasonX.fromStorage(data['resultReason'] as String?),
      isRevengeAvailable: data['isRevengeAvailable'] as bool? ?? false,
      parentBattleId: _readNullableString(data['parentBattleId']),
      rivalryPairKey: data['rivalryPairKey'] as String? ?? '',
        isFeatured: data['isFeatured'] as bool? ?? false,
        featuredUntil: _readNullableDate(data['featuredUntil']),
        battleScore: _readDouble(data['battleScore']),
        trendingScore: _readDouble(data['trendingScore']),
        visibilityScope: data['visibilityScope'] as String? ?? 'public',
        regionCode: _readNullableString(data['regionCode']),
        countryCode: _readNullableString(data['countryCode']),
      shareTitle: data['shareTitle'] as String? ?? '',
      shareSubtitle: data['shareSubtitle'] as String? ?? '',
      shareImageUrl: _readNullableString(data['shareImageUrl']),
      deepLink: _readNullableString(data['deepLink']),
      createdBy: data['createdBy'] as String? ?? '',
      updatedAt: _readNullableDate(data['updatedAt']),
      version: _readInt(data['version'], fallback: 1),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'status': status.storageValue,
      'challengerId': challengerId,
      'opponentId': opponentId,
      'challengerName': challengerName,
      'opponentName': opponentName,
      if (_hasValue(challengerPhotoUrl)) 'challengerPhotoUrl': challengerPhotoUrl,
      if (_hasValue(opponentPhotoUrl)) 'opponentPhotoUrl': opponentPhotoUrl,
      'challengerRatingAvgAtChallenge': challengerRatingAvgAtChallenge,
      'opponentRatingAvgAtChallenge': opponentRatingAvgAtChallenge,
      'ratingDeltaPercent': ratingDeltaPercent,
      'isRatingEligible': isRatingEligible,
      if (_hasValue(themeId)) 'themeId': themeId,
      if (_hasValue(themeTitle)) 'themeTitle': themeTitle,
      if (_hasValue(sceneId)) 'sceneId': sceneId,
      if (_hasValue(sceneTitle)) 'sceneTitle': sceneTitle,
      if (_hasValue(sceneCategory)) 'sceneCategory': sceneCategory,
      if (_hasValue(sceneGenre)) 'sceneGenre': sceneGenre,
      if (_hasValue(sceneDifficulty)) 'sceneDifficulty': sceneDifficulty,
      if (sceneDurationSec != null) 'sceneDurationSec': sceneDurationSec,
      'sceneAdminWorkflow': sceneAdminWorkflow,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (declinedAt != null) 'declinedAt': Timestamp.fromDate(declinedAt!),
      if (sceneAssignedAt != null)
        'sceneAssignedAt': Timestamp.fromDate(sceneAssignedAt!),
      if (submissionDeadline != null)
        'submissionDeadline': Timestamp.fromDate(submissionDeadline!),
      if (challengerSubmittedAt != null)
        'challengerSubmittedAt': Timestamp.fromDate(challengerSubmittedAt!),
      if (opponentSubmittedAt != null)
        'opponentSubmittedAt': Timestamp.fromDate(opponentSubmittedAt!),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (votingStartsAt != null)
        'votingStartsAt': Timestamp.fromDate(votingStartsAt!),
      if (votingEndsAt != null)
        'votingEndsAt': Timestamp.fromDate(votingEndsAt!),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (_hasValue(challengerVideoUrl)) 'challengerVideoUrl': challengerVideoUrl,
      if (_hasValue(opponentVideoUrl)) 'opponentVideoUrl': opponentVideoUrl,
      if (_hasValue(challengerRecordingId))
        'challengerRecordingId': challengerRecordingId,
      if (_hasValue(opponentRecordingId))
        'opponentRecordingId': opponentRecordingId,
      if (_hasValue(challengerStoragePath))
        'challengerStoragePath': challengerStoragePath,
      if (_hasValue(opponentStoragePath))
        'opponentStoragePath': opponentStoragePath,
      'followersCount': followersCount,
      'predictionsCount': predictionsCount,
      'commentsCount': commentsCount,
      'votesChallenger': votesChallenger,
      'votesOpponent': votesOpponent,
      'totalVotes': totalVotes,
      'watchersCount': watchersCount,
      if (_hasValue(winnerId)) 'winnerId': winnerId,
      if (_hasValue(loserId)) 'loserId': loserId,
      if (resultReason != null) 'resultReason': resultReason!.storageValue,
      'isRevengeAvailable': isRevengeAvailable,
      if (_hasValue(parentBattleId)) 'parentBattleId': parentBattleId,
      'rivalryPairKey': rivalryPairKey,
      'isFeatured': isFeatured,
      if (featuredUntil != null) 'featuredUntil': Timestamp.fromDate(featuredUntil!),
      'battleScore': battleScore,
      'trendingScore': trendingScore,
      'visibilityScope': visibilityScope,
      if (_hasValue(regionCode)) 'regionCode': regionCode,
      if (_hasValue(countryCode)) 'countryCode': countryCode,
      'shareTitle': shareTitle,
      'shareSubtitle': shareSubtitle,
      if (_hasValue(shareImageUrl)) 'shareImageUrl': shareImageUrl,
      if (_hasValue(deepLink)) 'deepLink': deepLink,
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'version': version,
    };
  }

  BattleModel copyWith({
    String? id,
    BattleStatus? status,
    String? challengerId,
    String? opponentId,
    String? challengerName,
    String? opponentName,
    String? challengerPhotoUrl,
    String? opponentPhotoUrl,
    double? challengerRatingAvgAtChallenge,
    double? opponentRatingAvgAtChallenge,
    double? ratingDeltaPercent,
    bool? isRatingEligible,
    String? themeId,
    String? themeTitle,
    String? sceneId,
    String? sceneTitle,
    String? sceneCategory,
    String? sceneGenre,
    String? sceneDifficulty,
    int? sceneDurationSec,
    bool? sceneAdminWorkflow,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? sceneAssignedAt,
    DateTime? submissionDeadline,
    DateTime? challengerSubmittedAt,
    DateTime? opponentSubmittedAt,
    DateTime? publishedAt,
    DateTime? votingStartsAt,
    DateTime? votingEndsAt,
    DateTime? endedAt,
    DateTime? cancelledAt,
    String? challengerVideoUrl,
    String? opponentVideoUrl,
    String? challengerRecordingId,
    String? opponentRecordingId,
    String? challengerStoragePath,
    String? opponentStoragePath,
    int? followersCount,
    int? predictionsCount,
    int? commentsCount,
    int? votesChallenger,
    int? votesOpponent,
    int? totalVotes,
    int? watchersCount,
    String? winnerId,
    String? loserId,
    BattleResultReason? resultReason,
    bool? isRevengeAvailable,
    String? parentBattleId,
    String? rivalryPairKey,
    bool? isFeatured,
    DateTime? featuredUntil,
    double? battleScore,
    double? trendingScore,
    String? visibilityScope,
    String? regionCode,
    String? countryCode,
    String? shareTitle,
    String? shareSubtitle,
    String? shareImageUrl,
    String? deepLink,
    String? createdBy,
    DateTime? updatedAt,
    int? version,
  }) {
    return BattleModel(
      id: id ?? this.id,
      status: status ?? this.status,
      challengerId: challengerId ?? this.challengerId,
      opponentId: opponentId ?? this.opponentId,
      challengerName: challengerName ?? this.challengerName,
      opponentName: opponentName ?? this.opponentName,
      challengerPhotoUrl: challengerPhotoUrl ?? this.challengerPhotoUrl,
      opponentPhotoUrl: opponentPhotoUrl ?? this.opponentPhotoUrl,
      challengerRatingAvgAtChallenge:
          challengerRatingAvgAtChallenge ?? this.challengerRatingAvgAtChallenge,
      opponentRatingAvgAtChallenge:
          opponentRatingAvgAtChallenge ?? this.opponentRatingAvgAtChallenge,
      ratingDeltaPercent: ratingDeltaPercent ?? this.ratingDeltaPercent,
      isRatingEligible: isRatingEligible ?? this.isRatingEligible,
      themeId: themeId ?? this.themeId,
      themeTitle: themeTitle ?? this.themeTitle,
      sceneId: sceneId ?? this.sceneId,
      sceneTitle: sceneTitle ?? this.sceneTitle,
      sceneCategory: sceneCategory ?? this.sceneCategory,
      sceneGenre: sceneGenre ?? this.sceneGenre,
      sceneDifficulty: sceneDifficulty ?? this.sceneDifficulty,
      sceneDurationSec: sceneDurationSec ?? this.sceneDurationSec,
      sceneAdminWorkflow: sceneAdminWorkflow ?? this.sceneAdminWorkflow,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      sceneAssignedAt: sceneAssignedAt ?? this.sceneAssignedAt,
      submissionDeadline: submissionDeadline ?? this.submissionDeadline,
      challengerSubmittedAt:
          challengerSubmittedAt ?? this.challengerSubmittedAt,
      opponentSubmittedAt: opponentSubmittedAt ?? this.opponentSubmittedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      votingStartsAt: votingStartsAt ?? this.votingStartsAt,
      votingEndsAt: votingEndsAt ?? this.votingEndsAt,
      endedAt: endedAt ?? this.endedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      challengerVideoUrl: challengerVideoUrl ?? this.challengerVideoUrl,
      opponentVideoUrl: opponentVideoUrl ?? this.opponentVideoUrl,
      challengerRecordingId:
          challengerRecordingId ?? this.challengerRecordingId,
      opponentRecordingId: opponentRecordingId ?? this.opponentRecordingId,
      challengerStoragePath:
          challengerStoragePath ?? this.challengerStoragePath,
      opponentStoragePath: opponentStoragePath ?? this.opponentStoragePath,
      followersCount: followersCount ?? this.followersCount,
      predictionsCount: predictionsCount ?? this.predictionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      votesChallenger: votesChallenger ?? this.votesChallenger,
      votesOpponent: votesOpponent ?? this.votesOpponent,
      totalVotes: totalVotes ?? this.totalVotes,
      watchersCount: watchersCount ?? this.watchersCount,
      winnerId: winnerId ?? this.winnerId,
      loserId: loserId ?? this.loserId,
      resultReason: resultReason ?? this.resultReason,
      isRevengeAvailable: isRevengeAvailable ?? this.isRevengeAvailable,
      parentBattleId: parentBattleId ?? this.parentBattleId,
      rivalryPairKey: rivalryPairKey ?? this.rivalryPairKey,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      battleScore: battleScore ?? this.battleScore,
      trendingScore: trendingScore ?? this.trendingScore,
      visibilityScope: visibilityScope ?? this.visibilityScope,
      regionCode: regionCode ?? this.regionCode,
      countryCode: countryCode ?? this.countryCode,
      shareTitle: shareTitle ?? this.shareTitle,
      shareSubtitle: shareSubtitle ?? this.shareSubtitle,
      shareImageUrl: shareImageUrl ?? this.shareImageUrl,
      deepLink: deepLink ?? this.deepLink,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  bool get isPending => status == BattleStatus.challengeSent;
  bool get isAccepted =>
      status == BattleStatus.accepted || status == BattleStatus.sceneAssigned;
  bool get isInPreparation =>
      status == BattleStatus.sceneAssigned ||
      status == BattleStatus.inPreparation ||
      status == BattleStatus.waitingChallengerSubmission ||
      status == BattleStatus.waitingOpponentSubmission ||
      status == BattleStatus.readyToPublish;
  bool get isPublished =>
      status == BattleStatus.published ||
      status == BattleStatus.votingOpen ||
      status == BattleStatus.ended;
  bool get isVotingOpen => status == BattleStatus.votingOpen;
  bool get isEnded =>
      status == BattleStatus.ended ||
      status == BattleStatus.cancelled ||
      status == BattleStatus.forfeit;

  bool canVote(String uid) {
    return isVotingOpen &&
        uid.isNotEmpty &&
        uid != challengerId &&
        uid != opponentId &&
        hasBothVideos;
  }

  bool get hasBothVideos {
    return _hasValue(challengerVideoUrl) && _hasValue(opponentVideoUrl);
  }

  List<String> get participantIds => <String>[challengerId, opponentId];

  String? opponentOf(String uid) {
    if (uid == challengerId) {
      return opponentId;
    }
    if (uid == opponentId) {
      return challengerId;
    }
    return null;
  }

  Duration? get timeRemaining {
    final now = DateTime.now();
    final end = isVotingOpen ? votingEndsAt : submissionDeadline;
    if (end == null) {
      return null;
    }
    final remaining = end.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isCloseResult {
    if (totalVotes <= 0) {
      return false;
    }
    final voteDelta = (votesChallenger - votesOpponent).abs();
    return (voteDelta / totalVotes) * 100 <= 5;
  }
}

extension BattleStatusX on BattleStatus {
  String get storageValue {
    switch (this) {
      case BattleStatus.challengeSent:
        return 'challenge_sent';
      case BattleStatus.declined:
        return 'declined';
      case BattleStatus.accepted:
        return 'accepted';
      case BattleStatus.sceneAssigned:
        return 'scene_assigned';
      case BattleStatus.inPreparation:
        return 'in_preparation';
      case BattleStatus.waitingChallengerSubmission:
        return 'waiting_challenger_submission';
      case BattleStatus.waitingOpponentSubmission:
        return 'waiting_opponent_submission';
      case BattleStatus.readyToPublish:
        return 'ready_to_publish';
      case BattleStatus.published:
        return 'published';
      case BattleStatus.votingOpen:
        return 'voting_open';
      case BattleStatus.ended:
        return 'ended';
      case BattleStatus.cancelled:
        return 'cancelled';
      case BattleStatus.forfeit:
        return 'forfeit';
    }
  }

  static BattleStatus fromStorage(String? raw) {
    switch (raw) {
      case 'challenge_sent':
        return BattleStatus.challengeSent;
      case 'declined':
        return BattleStatus.declined;
      case 'accepted':
        return BattleStatus.accepted;
      case 'scene_assigned':
        return BattleStatus.sceneAssigned;
      case 'in_preparation':
        return BattleStatus.inPreparation;
      case 'waiting_challenger_submission':
        return BattleStatus.waitingChallengerSubmission;
      case 'waiting_opponent_submission':
        return BattleStatus.waitingOpponentSubmission;
      case 'ready_to_publish':
        return BattleStatus.readyToPublish;
      case 'published':
        return BattleStatus.published;
      case 'voting_open':
        return BattleStatus.votingOpen;
      case 'ended':
        return BattleStatus.ended;
      case 'cancelled':
        return BattleStatus.cancelled;
      case 'forfeit':
        return BattleStatus.forfeit;
      default:
        return BattleStatus.challengeSent;
    }
  }
}

extension BattleResultReasonX on BattleResultReason {
  String get storageValue {
    switch (this) {
      case BattleResultReason.votes:
        return 'votes';
      case BattleResultReason.forfeit:
        return 'forfeit';
      case BattleResultReason.tieBreakWatchTime:
        return 'tie_break_watch_time';
      case BattleResultReason.tie:
        return 'tie';
      case BattleResultReason.cancelled:
        return 'cancelled';
    }
  }

  static BattleResultReason? fromStorage(String? raw) {
    switch (raw) {
      case 'votes':
        return BattleResultReason.votes;
      case 'forfeit':
        return BattleResultReason.forfeit;
      case 'tie_break_watch_time':
        return BattleResultReason.tieBreakWatchTime;
      case 'tie':
        return BattleResultReason.tie;
      case 'cancelled':
        return BattleResultReason.cancelled;
      default:
        return null;
    }
  }
}

DateTime _readRequiredDate(dynamic raw) {
  return _readNullableDate(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDate(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is Timestamp) {
    return raw.toDate();
  }
  if (raw is DateTime) {
    return raw;
  }
  if (raw is String) {
    return DateTime.tryParse(raw);
  }
  return null;
}

double _readDouble(dynamic raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw) ?? 0;
  }
  return 0;
}

int _readInt(dynamic raw, {int fallback = 0}) {
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw) ?? fallback;
  }
  return fallback;
}

int? _readNullableInt(dynamic raw) {
  if (raw == null) {
    return null;
  }
  return _readInt(raw);
}

String? _readNullableString(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

bool _hasValue(String? raw) => raw != null && raw.trim().isNotEmpty;