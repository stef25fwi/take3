import 'dart:async';

import 'package:dio/dio.dart';

import '../models/ai_generated_video.dart';

const _kVeoBackendUrl = String.fromEnvironment(
  'TAKE30_VEO_BACKEND_URL',
  defaultValue: '',
);
const _kVeoBackendPath = String.fromEnvironment(
  'TAKE30_VEO_BACKEND_PATH',
  defaultValue: '/scene-intro',
);
const _kVeoBackendToken = String.fromEnvironment(
  'TAKE30_VEO_BACKEND_TOKEN',
  defaultValue: '',
);
const _kVeoBackendProvider = String.fromEnvironment(
  'TAKE30_VEO_PROVIDER',
  defaultValue: 'veo3',
);

abstract class VeoVideoGenerationService {
  Future<AiGeneratedVideo> generateSceneIntroVideo({
    required String sceneDraftId,
    required String prompt,
    int durationSeconds = 15,
    String aspectRatio = '16:9',
  });
}

class VeoVideoGenerationServiceFactory {
  static VeoVideoGenerationService createDefault() {
    if (_kVeoBackendUrl.trim().isEmpty) {
      return const MockVeoVideoGenerationService();
    }

    return RemoteVeoVideoGenerationService(
      baseUrl: _kVeoBackendUrl,
      path: _kVeoBackendPath,
      bearerToken: _kVeoBackendToken,
      providerName: _kVeoBackendProvider,
    );
  }
}

class VeoServiceException implements Exception {
  VeoServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RemoteVeoVideoGenerationService implements VeoVideoGenerationService {
  RemoteVeoVideoGenerationService({
    required this.baseUrl,
    required this.path,
    required this.providerName,
    this.bearerToken,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 45),
                headers: {
                  if (bearerToken != null && bearerToken.trim().isNotEmpty)
                    'Authorization': 'Bearer ${bearerToken.trim()}',
                },
              ),
            );

  final String baseUrl;
  final String path;
  final String providerName;
  final String? bearerToken;
  final Dio _dio;

  @override
  Future<AiGeneratedVideo> generateSceneIntroVideo({
    required String sceneDraftId,
    required String prompt,
    int durationSeconds = 15,
    String aspectRatio = '16:9',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'sceneDraftId': sceneDraftId,
          'prompt': prompt,
          'durationSeconds': durationSeconds,
          'aspectRatio': aspectRatio,
          'style': 'cinematic realistic',
          'usage': 'intro_scene',
        },
      );

      final root = response.data ?? const <String, dynamic>{};
      final payload = _extractVideoPayload(root);
      final videoUrl = _readString(payload, const [
        'videoUrl',
        'url',
        'assetUrl',
      ]);

      if (videoUrl.isEmpty) {
        throw VeoServiceException(
          'Réponse VEO invalide: videoUrl manquant.',
        );
      }

      final generatedAt = _readDate(
        payload['generatedAt'] ?? root['generatedAt'],
      );

      return AiGeneratedVideo(
        provider: _readString(payload, const ['provider']).isEmpty
            ? providerName
            : _readString(payload, const ['provider']),
        prompt: prompt,
        videoUrl: videoUrl,
        thumbnailUrl: _readNullableString(payload, const [
          'thumbnailUrl',
          'posterUrl',
          'thumbnail',
        ]),
        durationSeconds: _readInt(
          payload,
          const ['durationSeconds', 'duration'],
          durationSeconds,
        ),
        aspectRatio: _readString(payload, const ['aspectRatio']).isEmpty
            ? aspectRatio
            : _readString(payload, const ['aspectRatio']),
        status: aiIntroVideoStatusFromString(
          _readNullableString(payload, const ['status']) ?? 'generated',
        ),
        generatedAt: generatedAt,
        updatedAt: generatedAt,
      );
    } on DioException catch (error) {
      throw VeoServiceException(
        'Impossible de contacter le backend VEO3: ${error.message ?? 'erreur réseau'}',
      );
    }
  }

  static Map<String, dynamic> _extractVideoPayload(Map<String, dynamic> root) {
    final nested = root['data'];
    if (nested is Map<String, dynamic>) {
      final video = nested['video'];
      if (video is Map<String, dynamic>) {
        return video;
      }
      return nested;
    }

    final video = root['video'];
    if (video is Map<String, dynamic>) {
      return video;
    }

    return root;
  }

  static String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String? _readNullableString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _readString(map, keys);
    return value.isEmpty ? null : value;
  }

  static int _readInt(
    Map<String, dynamic> map,
    List<String> keys,
    int fallback,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  static DateTime _readDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
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
    int durationSeconds = 15,
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

// Ce mock isole le workflow admin tant que le connecteur backend VEO3 réel
// n'est pas branché. Si TAKE30_VEO_BACKEND_URL est fourni au build, la factory
// bascule automatiquement vers RemoteVeoVideoGenerationService.
