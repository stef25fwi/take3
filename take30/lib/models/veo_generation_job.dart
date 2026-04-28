import 'package:cloud_firestore/cloud_firestore.dart';

enum VeoGenerationStatus {
  none,
  queued,
  generating,
  completed,
  failed,
}

VeoGenerationStatus veoGenerationStatusFromString(String? value) {
  switch (value) {
    case 'queued':
      return VeoGenerationStatus.queued;
    case 'generating':
      return VeoGenerationStatus.generating;
    case 'completed':
      return VeoGenerationStatus.completed;
    case 'failed':
      return VeoGenerationStatus.failed;
    case 'none':
    default:
      return VeoGenerationStatus.none;
  }
}

extension VeoGenerationStatusX on VeoGenerationStatus {
  String get value => switch (this) {
        VeoGenerationStatus.none => 'none',
        VeoGenerationStatus.queued => 'queued',
        VeoGenerationStatus.generating => 'generating',
        VeoGenerationStatus.completed => 'completed',
        VeoGenerationStatus.failed => 'failed',
      };

  String get label => switch (this) {
        VeoGenerationStatus.none => 'Aucun job',
        VeoGenerationStatus.queued => 'queued',
        VeoGenerationStatus.generating => 'generating',
        VeoGenerationStatus.completed => 'completed',
        VeoGenerationStatus.failed => 'failed',
      };

  bool get isTerminal =>
      this == VeoGenerationStatus.completed || this == VeoGenerationStatus.failed;
}

DateTime? _readJobDate(dynamic value) {
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

class VeoGenerationJob {
  const VeoGenerationJob({
    required this.sceneId,
    required this.prompt,
    required this.status,
    this.operationId,
    this.videoUrl,
    this.thumbnailUrl,
    this.errorMessage,
    this.updatedAt,
    this.durationSeconds = 15,
    this.aspectRatio = '16:9',
  });

  final String sceneId;
  final String prompt;
  final VeoGenerationStatus status;
  final String? operationId;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? errorMessage;
  final DateTime? updatedAt;
  final int durationSeconds;
  final String aspectRatio;

  bool get isCompleted => status == VeoGenerationStatus.completed;
  bool get isFailed => status == VeoGenerationStatus.failed;

  factory VeoGenerationJob.fromJson(
    Map<String, dynamic> json, {
    String? fallbackSceneId,
    String? fallbackPrompt,
    int fallbackDurationSeconds = 15,
    String fallbackAspectRatio = '16:9',
  }) {
    return VeoGenerationJob(
      sceneId: json['sceneId'] as String? ?? fallbackSceneId ?? '',
      prompt: json['prompt'] as String? ?? fallbackPrompt ?? '',
      status: veoGenerationStatusFromString(json['status'] as String?),
      operationId: json['operationId'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      errorMessage: json['errorMessage'] as String? ?? json['veoError'] as String?,
      updatedAt: _readJobDate(json['updatedAt']),
      durationSeconds:
          (json['durationSeconds'] as num?)?.toInt() ?? fallbackDurationSeconds,
      aspectRatio: json['aspectRatio'] as String? ?? fallbackAspectRatio,
    );
  }
}