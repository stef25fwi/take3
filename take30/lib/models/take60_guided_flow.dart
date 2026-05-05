import 'battle_model.dart';

enum SceneRecordingStatus {
  notStarted,
  directorSheetViewed,
  aiIntroPlaying,
  waitingCameraPreparation,
  countdown,
  recordingUserPlan,
  previewUserPlan,
  userPlanValidated,
  renderingFinalVideo,
  finalPreviewReady,
  draftSaved,
  published,
}

class Take60BattleRecordingContext {
  const Take60BattleRecordingContext({
    required this.battleId,
    required this.sceneId,
    required this.participantRole,
  });

  final String battleId;
  final String sceneId;
  final String participantRole;

  factory Take60BattleRecordingContext.fromBattle(BattleModel battle) {
    return Take60BattleRecordingContext(
      battleId: battle.id,
      sceneId: battle.sceneId ?? '',
      participantRole: battle.challengerSubmittedAt == null
          ? 'challenger'
          : 'opponent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'battleId': battleId,
      'battleSceneId': sceneId,
      'battleRole': participantRole,
      'isBattleSubmission': true,
    };
  }
}

SceneRecordingStatus sceneRecordingStatusFromString(String? value) {
  switch (_normalizeTake60Key(value)) {
    case 'director_sheet_viewed':
      return SceneRecordingStatus.directorSheetViewed;
    case 'ai_intro_playing':
      return SceneRecordingStatus.aiIntroPlaying;
    case 'waiting_camera_preparation':
      return SceneRecordingStatus.waitingCameraPreparation;
    case 'countdown':
      return SceneRecordingStatus.countdown;
    case 'recording_user_plan':
      return SceneRecordingStatus.recordingUserPlan;
    case 'preview_user_plan':
      return SceneRecordingStatus.previewUserPlan;
    case 'user_plan_validated':
      return SceneRecordingStatus.userPlanValidated;
    case 'rendering_final_video':
      return SceneRecordingStatus.renderingFinalVideo;
    case 'final_preview_ready':
      return SceneRecordingStatus.finalPreviewReady;
    case 'draft_saved':
      return SceneRecordingStatus.draftSaved;
    case 'published':
      return SceneRecordingStatus.published;
    default:
      return SceneRecordingStatus.notStarted;
  }
}

extension SceneRecordingStatusX on SceneRecordingStatus {
  String get value {
    switch (this) {
      case SceneRecordingStatus.notStarted:
        return 'not_started';
      case SceneRecordingStatus.directorSheetViewed:
        return 'director_sheet_viewed';
      case SceneRecordingStatus.aiIntroPlaying:
        return 'ai_intro_playing';
      case SceneRecordingStatus.waitingCameraPreparation:
        return 'waiting_camera_preparation';
      case SceneRecordingStatus.countdown:
        return 'countdown';
      case SceneRecordingStatus.recordingUserPlan:
        return 'recording_user_plan';
      case SceneRecordingStatus.previewUserPlan:
        return 'preview_user_plan';
      case SceneRecordingStatus.userPlanValidated:
        return 'user_plan_validated';
      case SceneRecordingStatus.renderingFinalVideo:
        return 'rendering_final_video';
      case SceneRecordingStatus.finalPreviewReady:
        return 'final_preview_ready';
      case SceneRecordingStatus.draftSaved:
        return 'draft_saved';
      case SceneRecordingStatus.published:
        return 'published';
    }
  }
}

enum UserPlanStatus {
  pending,
  recording,
  recorded,
  previewed,
  validated,
  retakeRequested,
}

UserPlanStatus userPlanStatusFromString(String? value) {
  switch (_normalizeTake60Key(value)) {
    case 'recording':
      return UserPlanStatus.recording;
    case 'recorded':
      return UserPlanStatus.recorded;
    case 'previewed':
      return UserPlanStatus.previewed;
    case 'validated':
      return UserPlanStatus.validated;
    case 'retake_requested':
      return UserPlanStatus.retakeRequested;
    default:
      return UserPlanStatus.pending;
  }
}

extension UserPlanStatusX on UserPlanStatus {
  String get value {
    switch (this) {
      case UserPlanStatus.pending:
        return 'pending';
      case UserPlanStatus.recording:
        return 'recording';
      case UserPlanStatus.recorded:
        return 'recorded';
      case UserPlanStatus.previewed:
        return 'previewed';
      case UserPlanStatus.validated:
        return 'validated';
      case UserPlanStatus.retakeRequested:
        return 'retake_requested';
    }
  }
}

enum GuidedMarkerType {
  introAiVideo,
  aiSequence,
  userSequence,
  finalSequence,
  aiPlan,
  userPlan,
  reactionShot,
  transition,
  introCinema,
  finalShot,
  userReply,
  aiReply,
}

GuidedMarkerType guidedMarkerTypeFromString(String? value) {
  switch (_normalizeTake60Key(value)) {
    case 'intro_ai_video':
      return GuidedMarkerType.introAiVideo;
    case 'ai_sequence':
      return GuidedMarkerType.aiSequence;
    case 'user_sequence':
      return GuidedMarkerType.userSequence;
    case 'final_sequence':
      return GuidedMarkerType.finalSequence;
    case 'user_plan':
      return GuidedMarkerType.userPlan;
    case 'reaction_shot':
      return GuidedMarkerType.reactionShot;
    case 'transition':
      return GuidedMarkerType.transition;
    case 'intro_cinema':
      return GuidedMarkerType.introCinema;
    case 'final_shot':
      return GuidedMarkerType.finalShot;
    case 'user_reply':
      return GuidedMarkerType.userReply;
    case 'ai_reply':
      return GuidedMarkerType.aiReply;
    default:
      return GuidedMarkerType.aiPlan;
  }
}

extension GuidedMarkerTypeX on GuidedMarkerType {
  String get value {
    switch (this) {
      case GuidedMarkerType.introAiVideo:
        return 'intro_ai_video';
      case GuidedMarkerType.aiSequence:
        return 'ai_sequence';
      case GuidedMarkerType.userSequence:
        return 'user_sequence';
      case GuidedMarkerType.finalSequence:
        return 'final_sequence';
      case GuidedMarkerType.aiPlan:
        return 'ai_plan';
      case GuidedMarkerType.userPlan:
        return 'user_plan';
      case GuidedMarkerType.reactionShot:
        return 'reaction_shot';
      case GuidedMarkerType.transition:
        return 'transition';
      case GuidedMarkerType.introCinema:
        return 'intro_cinema';
      case GuidedMarkerType.finalShot:
        return 'final_shot';
      case GuidedMarkerType.userReply:
        return 'user_reply';
      case GuidedMarkerType.aiReply:
        return 'ai_reply';
    }
  }

  bool get requiresUserRecording {
    return this == GuidedMarkerType.userSequence ||
        this == GuidedMarkerType.userPlan ||
        this == GuidedMarkerType.userReply;
  }
}

class Take60AudioRules {
  const Take60AudioRules({
    this.hasGlobalAiAmbiance = true,
    this.keepAiAmbianceDuringUserPlans = true,
    this.normalizeVolumes = true,
    this.applyAudioFades = true,
  });

  final bool hasGlobalAiAmbiance;
  final bool keepAiAmbianceDuringUserPlans;
  final bool normalizeVolumes;
  final bool applyAudioFades;

  factory Take60AudioRules.fromMap(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return Take60AudioRules(
      hasGlobalAiAmbiance: data['hasGlobalAiAmbiance'] as bool? ??
          data['globalAiAmbiance'] as bool? ??
          true,
      keepAiAmbianceDuringUserPlans:
          data['keepAiAmbianceDuringUserPlans'] as bool? ??
              data['keepAiAudioOnUserPlans'] as bool? ??
              true,
      normalizeVolumes: data['normalizeVolumes'] as bool? ?? true,
      applyAudioFades: data['applyAudioFades'] as bool? ??
          data['applyShortAudioFades'] as bool? ??
          true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasGlobalAiAmbiance': hasGlobalAiAmbiance,
      'keepAiAmbianceDuringUserPlans': keepAiAmbianceDuringUserPlans,
      'normalizeVolumes': normalizeVolumes,
      'applyAudioFades': applyAudioFades,
      // Mapping vers le contrat backend (renderTake60GuidedScene).
      'keepAiAmbiance': keepAiAmbianceDuringUserPlans,
      'duckUserAudioOverAi': keepAiAmbianceDuringUserPlans,
      'normaliseLoudness': normalizeVolumes,
      'crossfadeMillis': applyAudioFades ? 120 : 0,
      'equalizer': true,
      'autoGain': true,
    };
  }
}

class Take60SceneMarker {
  const Take60SceneMarker({
    required this.id,
    required this.order,
    required this.type,
    required this.startSeconds,
    required this.endSeconds,
    required this.durationSeconds,
    required this.source,
    required this.character,
    required this.dialogue,
    required this.cameraPlan,
    required this.label,
    this.videoUrl,
    this.cueText = '',
    this.audioMode = '',
    this.status = 'ready',
  });

  final String id;
  final int order;
  final GuidedMarkerType type;
  final int startSeconds;
  final int endSeconds;
  final int durationSeconds;
  final String source;
  final String character;
  final String dialogue;
  final String cameraPlan;
  final String label;
  final String? videoUrl;
  final String cueText;
  final String audioMode;
  final String status;

  bool get requiresUserRecording {
    return type.requiresUserRecording || source == 'user_video';
  }

  bool get usesAiPlayback => !requiresUserRecording;

  factory Take60SceneMarker.fromMap(Map<String, dynamic> json) {
    final startSeconds = (json['startSeconds'] as num?)?.toInt() ??
      (json['startSecond'] as num?)?.toInt() ??
      (json['start'] as num?)?.toInt() ??
      0;
    final rawDuration = (json['durationSeconds'] as num?)?.toInt() ??
      (json['duration'] as num?)?.toInt();
    final endSeconds = (json['endSeconds'] as num?)?.toInt() ??
      (json['endSecond'] as num?)?.toInt() ??
      (json['end'] as num?)?.toInt() ??
        (rawDuration == null ? startSeconds : startSeconds + rawDuration);
    final durationSeconds = rawDuration ??
        (endSeconds > startSeconds ? endSeconds - startSeconds : 0);
    return Take60SceneMarker(
      id: json['id'] as String? ?? 'marker_${json['order'] ?? 0}',
      order: (json['order'] as num?)?.toInt() ?? 0,
      type: guidedMarkerTypeFromString(json['type'] as String?),
      startSeconds: startSeconds,
      endSeconds: endSeconds,
      durationSeconds: durationSeconds <= 0 ? 8 : durationSeconds,
      source: json['source'] as String? ?? 'ai_video',
      character: json['character'] as String? ?? '',
      dialogue: json['dialogue'] as String? ?? '',
      cameraPlan: json['cameraPlan'] as String? ?? '',
      label: json['label'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      cueText: json['cueText'] as String? ?? '',
      audioMode: json['audioMode'] as String? ??
          ((json['source'] as String?) == 'user_video'
              ? 'user_voice_with_optional_ai_ambiance'
              : 'ai_only'),
      status: json['status'] as String? ??
          ((json['source'] as String?) == 'user_video' ? 'pending' : 'ready'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'type': type.value,
      'start': startSeconds,
      'startSecond': startSeconds,
      'startSeconds': startSeconds,
      'end': endSeconds,
      'endSecond': endSeconds,
      'endSeconds': endSeconds,
      'duration': durationSeconds,
      'durationSeconds': durationSeconds,
      'source': source,
      'character': character,
      'dialogue': dialogue,
      'cameraPlan': cameraPlan,
      'label': label,
      'videoUrl': videoUrl,
      'cueText': cueText,
      'audioMode': audioMode,
      'status': status,
    };
  }
}

class Take60UserRecordingDraft {
  const Take60UserRecordingDraft({
    required this.recordingId,
    required this.projectId,
    required this.sceneId,
    required this.userId,
    required this.markerId,
    required this.startSecond,
    required this.endSecond,
    required this.localTempPath,
    required this.durationSeconds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.storagePath,
    this.uploadedVideoUrl,
  });

  final String recordingId;
  final String projectId;
  final String sceneId;
  final String userId;
  final String markerId;
  final int startSecond;
  final int endSecond;
  final String localTempPath;
  final String? storagePath;
  final String? uploadedVideoUrl;
  final int durationSeconds;
  final UserPlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isUploaded => (uploadedVideoUrl?.isNotEmpty ?? false);

  Take60UserRecordingDraft copyWith({
    String? projectId,
    int? startSecond,
    int? endSecond,
    String? localTempPath,
    String? storagePath,
    String? uploadedVideoUrl,
    int? durationSeconds,
    UserPlanStatus? status,
    DateTime? updatedAt,
  }) {
    return Take60UserRecordingDraft(
      recordingId: recordingId,
      projectId: projectId ?? this.projectId,
      sceneId: sceneId,
      userId: userId,
      markerId: markerId,
      startSecond: startSecond ?? this.startSecond,
      endSecond: endSecond ?? this.endSecond,
      localTempPath: localTempPath ?? this.localTempPath,
      storagePath: storagePath ?? this.storagePath,
      uploadedVideoUrl: uploadedVideoUrl ?? this.uploadedVideoUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Take60UserRecordingDraft.fromMap(Map<String, dynamic> json) {
    return Take60UserRecordingDraft(
      recordingId: json['recordingId'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      sceneId: json['sceneId'] as String? ?? '',
      userId: json['userId'] as String? ?? 'guest',
      markerId: json['markerId'] as String? ?? '',
      startSecond: (json['startSecond'] as num?)?.toInt() ??
        (json['start'] as num?)?.toInt() ??
        0,
      endSecond: (json['endSecond'] as num?)?.toInt() ??
        (json['end'] as num?)?.toInt() ??
        0,
      localTempPath: json['localTempPath'] as String? ?? '',
      storagePath: json['storagePath'] as String?,
      uploadedVideoUrl: json['uploadedVideoUrl'] as String?,
      durationSeconds: (json['duration'] as num?)?.toInt() ??
          (json['durationSeconds'] as num?)?.toInt() ??
          0,
      status: userPlanStatusFromString(json['status'] as String?),
      createdAt: _readTake60Date(json['createdAt']),
      updatedAt: _readTake60Date(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordingId': recordingId,
      'projectId': projectId,
      'sceneId': sceneId,
      'userId': userId,
      'markerId': markerId,
      'startSecond': startSecond,
      'endSecond': endSecond,
      'localTempPath': localTempPath,
      'storagePath': storagePath,
      'uploadedVideoUrl': uploadedVideoUrl,
      'duration': durationSeconds,
      'durationSeconds': durationSeconds,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Take60PlaybackSegment {
  const Take60PlaybackSegment({
    required this.markerId,
    required this.label,
    required this.videoUrl,
    required this.durationSeconds,
    required this.source,
    required this.audioMode,
  });

  final String markerId;
  final String label;
  final String videoUrl;
  final int durationSeconds;
  final String source;
  final String audioMode;

  factory Take60PlaybackSegment.fromMap(Map<String, dynamic> json) {
    return Take60PlaybackSegment(
      markerId: json['markerId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      audioMode: json['audioMode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'markerId': markerId,
      'label': label,
      'videoUrl': videoUrl,
      'durationSeconds': durationSeconds,
      'source': source,
      'audioMode': audioMode,
    };
  }
}

class Take60RenderResult {
  const Take60RenderResult({
    required this.finalVideoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.renderStatus,
    required this.segments,
  });

  final String finalVideoUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final String renderStatus;
  final List<Take60PlaybackSegment> segments;

  factory Take60RenderResult.fromMap(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List<dynamic>? ?? const [];
    return Take60RenderResult(
      finalVideoUrl: json['finalVideoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      durationSeconds: (json['duration'] as num?)?.toInt() ??
          (json['durationSeconds'] as num?)?.toInt() ??
          0,
      renderStatus: json['renderStatus'] as String? ??
          json['status'] as String? ??
          'preview_ready',
      segments: rawSegments
          .whereType<Map>()
          .map(
            (segment) => Take60PlaybackSegment.fromMap(
              Map<String, dynamic>.from(segment),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'finalVideoUrl': finalVideoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': durationSeconds,
      'renderStatus': renderStatus,
      'segments': segments.map((segment) => segment.toMap()).toList(),
    };
  }
}

class Take60GuidedFlowDraft {
  const Take60GuidedFlowDraft({
    required this.sceneId,
    required this.sceneTitle,
    required this.userId,
    required this.currentMarkerIndex,
    required this.status,
    required this.recordings,
    required this.updatedAt,
  });

  final String sceneId;
  final String sceneTitle;
  final String userId;
  final int currentMarkerIndex;
  final SceneRecordingStatus status;
  final List<Take60UserRecordingDraft> recordings;
  final DateTime updatedAt;

  factory Take60GuidedFlowDraft.fromMap(Map<String, dynamic> json) {
    final rawRecordings = json['recordings'] as List<dynamic>? ?? const [];
    return Take60GuidedFlowDraft(
      sceneId: json['sceneId'] as String? ?? '',
      sceneTitle: json['sceneTitle'] as String? ?? '',
      userId: json['userId'] as String? ?? 'guest',
      currentMarkerIndex: (json['currentMarkerIndex'] as num?)?.toInt() ?? 0,
      status: sceneRecordingStatusFromString(json['status'] as String?),
      recordings: rawRecordings
          .whereType<Map>()
          .map(
            (recording) => Take60UserRecordingDraft.fromMap(
              Map<String, dynamic>.from(recording),
            ),
          )
          .toList(),
      updatedAt: _readTake60Date(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sceneId': sceneId,
      'sceneTitle': sceneTitle,
      'userId': userId,
      'currentMarkerIndex': currentMarkerIndex,
      'status': status.value,
      'recordings': recordings.map((recording) => recording.toMap()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

DateTime _readTake60Date(dynamic raw) {
  if (raw is DateTime) {
    return raw;
  }
  if (raw is String) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return DateTime.now();
}

String _normalizeTake60Key(String? value) {
  return (value ?? '').trim().toLowerCase().replaceAll('-', '_');
}