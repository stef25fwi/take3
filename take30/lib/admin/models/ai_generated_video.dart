enum AiIntroVideoStatus {
  draft,
  generating,
  generated,
  validated,
  failed,
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

  bool get isValidated => status == AiIntroVideoStatus.validated;

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
      };

  factory AiGeneratedVideo.fromJson(Map<String, dynamic> json) {
    return AiGeneratedVideo(
      provider: json['provider'] as String? ?? 'veo3',
      prompt: json['prompt'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 15,
      aspectRatio: json['aspectRatio'] as String? ?? '16:9',
      status: aiIntroVideoStatusFromString(json['status'] as String?),
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
