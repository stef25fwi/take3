import 'dart:async';

import '../models/ai_generated_video.dart';
import '../../models/veo_generation_job.dart';
import '../../services/veo_scene_generation_service.dart';

abstract class VeoVideoGenerationService {
  Future<AiGeneratedVideo> generateSceneIntroVideo({
    required String sceneDraftId,
    required String prompt,
    int durationSeconds = 8,
    String aspectRatio = '16:9',
  });
}

class VeoVideoGenerationServiceFactory {
  static VeoVideoGenerationService createDefault() {
    return CloudFunctionsVeoVideoGenerationService();
  }
}

class VeoServiceException implements Exception {
  VeoServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudFunctionsVeoVideoGenerationService implements VeoVideoGenerationService {
  CloudFunctionsVeoVideoGenerationService({
    VeoSceneGenerationService? service,
    this.pollAttempts = 60,
    this.pollDelay = const Duration(seconds: 3),
  }) : _service = service ?? VeoSceneGenerationService();

  final VeoSceneGenerationService _service;
  final int pollAttempts;
  final Duration pollDelay;

  @override
  Future<AiGeneratedVideo> generateSceneIntroVideo({
    required String sceneDraftId,
    required String prompt,
    int durationSeconds = 8,
    String aspectRatio = '16:9',
  }) async {
    try {
      var job = await _service.requestVeoScenePreview(
        sceneId: sceneDraftId,
        prompt: prompt,
        durationSeconds: durationSeconds,
        aspectRatio: aspectRatio,
      );

      for (var attempt = 0; attempt < pollAttempts; attempt++) {
        if (job.isCompleted) {
          return _toAiGeneratedVideo(job, prompt, durationSeconds, aspectRatio);
        }
        if (job.isFailed) {
          throw VeoServiceException(
            job.errorMessage ?? 'Le backend VEO a retourné un échec.',
          );
        }
        await Future<void>.delayed(pollDelay);
        job = await _service.checkVeoSceneGeneration(sceneId: sceneDraftId);
      }

      throw VeoServiceException(
        'La génération vidéo IA continue côté backend. Vérifie à nouveau dans quelques instants.',
      );
    } on VeoSceneGenerationException catch (error) {
      throw VeoServiceException(
        error.message,
      );
    }
  }

  static AiGeneratedVideo _toAiGeneratedVideo(
    VeoGenerationJob job,
    String prompt,
    int durationSeconds,
    String aspectRatio,
  ) {
    final generatedAt = job.updatedAt ?? DateTime.now();
    return AiGeneratedVideo(
      provider: 'veo3',
      prompt: job.prompt.isEmpty ? prompt : job.prompt,
      videoUrl: job.videoUrl ?? '',
      thumbnailUrl: job.thumbnailUrl,
      durationSeconds: job.durationSeconds,
      aspectRatio: job.aspectRatio.isEmpty ? aspectRatio : job.aspectRatio,
      status: aiIntroVideoStatusFromString(job.status.value),
      generatedAt: generatedAt,
      updatedAt: generatedAt,
    );
  }
}

class MockVeoVideoGenerationService implements VeoVideoGenerationService {
  const MockVeoVideoGenerationService();

  static const String _mockVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
  static const String _mockThumbnailUrl =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80';

  @override
  Future<AiGeneratedVideo> generateSceneIntroVideo({
    required String sceneDraftId,
    required String prompt,
    int durationSeconds = 8,
    String aspectRatio = '16:9',
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final now = DateTime.now();

    return AiGeneratedVideo(
      provider: 'veo3',
      prompt: prompt,
      videoUrl: _mockVideoUrl,
      thumbnailUrl: _mockThumbnailUrl,
      durationSeconds: durationSeconds,
      aspectRatio: aspectRatio,
      status: AiIntroVideoStatus.generated,
      generatedAt: now,
      updatedAt: now,
    );
  }
}

// Ce mock reste utile pour les tests widget/admin. Le flux réel par défaut
// passe désormais par Firebase Cloud Functions, sans URL ni token dans Flutter.
