import 'package:cloud_firestore/cloud_firestore.dart';

enum AiIntroVideoStatus {
  draft,
  generating,
  generated,
  validated,
  failed,
}

DateTime? _readAiVideoDate(dynamic value) {
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

int? _readAiVideoInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

int? _readAiVideoProgress(dynamic value) {
  if (value is num) {
    final normalized = value <= 1 ? value * 100 : value;
    return normalized.round().clamp(0, 100);
  }
  if (value is String) {
    return _readAiVideoProgress(num.tryParse(value));
  }
  return null;
}

AiIntroVideoStatus aiIntroVideoStatusFromString(String? value) {
  switch (value) {
    case 'draft':
      return AiIntroVideoStatus.draft;
    case 'generating':
      return AiIntroVideoStatus.generating;
    case 'generated':
      return AiIntroVideoStatus.generated;
    case 'validated':
      return AiIntroVideoStatus.validated;
    case 'failed':
      return AiIntroVideoStatus.failed;
    default:
      return AiIntroVideoStatus.draft;
  }
}

extension AiIntroVideoStatusX on AiIntroVideoStatus {
  String get value => switch (this) {
        AiIntroVideoStatus.draft => 'draft',
        AiIntroVideoStatus.generating => 'generating',
        AiIntroVideoStatus.generated => 'generated',
        AiIntroVideoStatus.validated => 'validated',
        AiIntroVideoStatus.failed => 'failed',
      };

  String get label => switch (this) {
        AiIntroVideoStatus.draft => 'Brouillon',
        AiIntroVideoStatus.generating => 'Génération en cours',
        AiIntroVideoStatus.generated => 'Générée',
        AiIntroVideoStatus.validated => 'Validée',
        AiIntroVideoStatus.failed => 'Échec',
      };
}

class AiGeneratedVideo {
  const AiGeneratedVideo({
    required this.provider,
    required this.prompt,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.aspectRatio,
    required this.status,
    required this.generatedAt,
    required this.updatedAt,
    this.generationStatus,
    this.generationStartedAt,
    this.generationUpdatedAt,
    this.estimatedDurationSeconds,
    this.elapsedSeconds,
    this.progressPercent,
    this.veoOperationId,
    this.veoModel,
    this.errorMessage,
  });

  final String provider;
  final String prompt;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String aspectRatio;
  final AiIntroVideoStatus status;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final String? generationStatus;
  final DateTime? generationStartedAt;
  final DateTime? generationUpdatedAt;
  final int? estimatedDurationSeconds;
  final int? elapsedSeconds;
  final int? progressPercent;
  final String? veoOperationId;
  final String? veoModel;
  final String? errorMessage;

  bool get isValidated => status == AiIntroVideoStatus.validated;
  bool get hasPlayableVideo => videoUrl.trim().isNotEmpty;
  bool get isGenerating =>
      status == AiIntroVideoStatus.generating ||
      generationStatus == 'queued' ||
      generationStatus == 'generating';

  AiGeneratedVideo copyWith({
    String? provider,
    String? prompt,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    String? aspectRatio,
    AiIntroVideoStatus? status,
    DateTime? generatedAt,
    DateTime? updatedAt,
    String? generationStatus,
    DateTime? generationStartedAt,
    DateTime? generationUpdatedAt,
    int? estimatedDurationSeconds,
    int? elapsedSeconds,
    int? progressPercent,
    String? veoOperationId,
    String? veoModel,
    String? errorMessage,
  }) {
    return AiGeneratedVideo(
      provider: provider ?? this.provider,
      prompt: prompt ?? this.prompt,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      generationStatus: generationStatus ?? this.generationStatus,
      generationStartedAt: generationStartedAt ?? this.generationStartedAt,
      generationUpdatedAt: generationUpdatedAt ?? this.generationUpdatedAt,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      progressPercent: progressPercent ?? this.progressPercent,
      veoOperationId: veoOperationId ?? this.veoOperationId,
      veoModel: veoModel ?? this.veoModel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'prompt': prompt,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'aspectRatio': aspectRatio,
        'status': status.value,
        'generatedAt': generatedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'generationStatus': generationStatus,
        'generationStartedAt': generationStartedAt?.toIso8601String(),
        'generationUpdatedAt': generationUpdatedAt?.toIso8601String(),
        'estimatedDurationSeconds': estimatedDurationSeconds,
        'elapsedSeconds': elapsedSeconds,
        'progressPercent': progressPercent,
        'veoOperationId': veoOperationId,
        'veoModel': veoModel,
        'errorMessage': errorMessage,
      };

  factory AiGeneratedVideo.fromJson(Map<String, dynamic> json) {
    return AiGeneratedVideo(
      provider: json['provider'] as String? ?? 'veo3',
      prompt: json['prompt'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 8,
      aspectRatio: json['aspectRatio'] as String? ?? '16:9',
      status: aiIntroVideoStatusFromString(json['status'] as String?),
      generatedAt: _readAiVideoDate(json['generatedAt']) ?? DateTime.now(),
      updatedAt: _readAiVideoDate(json['updatedAt']) ?? DateTime.now(),
      generationStatus:
          json['generationStatus'] as String? ?? json['status'] as String?,
      generationStartedAt: _readAiVideoDate(
        json['generationStartedAt'] ?? json['startedAt'],
      ),
      generationUpdatedAt: _readAiVideoDate(
        json['generationUpdatedAt'] ?? json['updatedAt'],
      ),
      estimatedDurationSeconds: _readAiVideoInt(
        json['estimatedDurationSeconds'],
      ),
      elapsedSeconds: _readAiVideoInt(json['elapsedSeconds']),
      progressPercent: _readAiVideoProgress(
        json['progressPercent'] ?? json['progress'],
      ),
      veoOperationId: json['veoOperationId'] as String? ??
          json['operationId'] as String?,
      veoModel: json['veoModel'] as String? ?? json['modelId'] as String?,
      errorMessage:
          json['errorMessage'] as String? ?? json['veoError'] as String?,
    );
  }
}
