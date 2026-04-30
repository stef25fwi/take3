import 'package:cloud_functions/cloud_functions.dart';

import '../models/veo_generation_job.dart';

class VeoSceneGenerationException implements Exception {
  const VeoSceneGenerationException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => message;
}

class VeoSceneGenerationService {
  VeoSceneGenerationService({FirebaseFunctions? functions})
    : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _resolvedFunctions =>
    _functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<VeoGenerationJob> requestVeoScenePreview({
    required String sceneId,
    required String prompt,
    int durationSeconds = 15,
    String aspectRatio = '16:9',
  }) async {
    try {
      final callable =
          _resolvedFunctions.httpsCallable('startVeoSceneGeneration');
      final result = await callable.call(<String, dynamic>{
        'sceneId': sceneId,
        'prompt': prompt,
        'durationSeconds': durationSeconds,
        'aspectRatio': aspectRatio,
      });
      return VeoGenerationJob.fromJson(
        _asMap(result.data),
        fallbackSceneId: sceneId,
        fallbackPrompt: prompt,
        fallbackDurationSeconds: durationSeconds,
        fallbackAspectRatio: aspectRatio,
      );
    } on FirebaseFunctionsException catch (error) {
      throw VeoSceneGenerationException(
        code: error.code,
        message: _messageForCode(error.code, error.message),
      );
    } catch (_) {
      throw const VeoSceneGenerationException(
        code: 'unknown',
        message: 'La génération VEO a échoué pour une raison inconnue.',
      );
    }
  }

  Future<VeoGenerationJob> checkVeoSceneGeneration({
    required String sceneId,
  }) async {
    try {
      final callable =
          _resolvedFunctions.httpsCallable('checkVeoSceneGeneration');
      final result = await callable.call(<String, dynamic>{'sceneId': sceneId});
      return VeoGenerationJob.fromJson(
        _asMap(result.data),
        fallbackSceneId: sceneId,
      );
    } on FirebaseFunctionsException catch (error) {
      throw VeoSceneGenerationException(
        code: error.code,
        message: _messageForCode(error.code, error.message),
      );
    } catch (_) {
      throw const VeoSceneGenerationException(
        code: 'unknown',
        message: 'Impossible de vérifier l’état de la génération VEO.',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<dynamic, dynamic>) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), entry),
      );
    }
    return const <String, dynamic>{};
  }

  static String _messageForCode(String code, String? fallback) {
    switch (code) {
      case 'unauthenticated':
        return 'Connexion requise pour lancer une génération VEO.';
      case 'permission-denied':
        return 'Accès refusé: le rôle admin est requis pour VEO.';
      case 'unavailable':
        return 'Le backend VEO est temporairement indisponible.';
      case 'internal':
        return 'Le backend VEO a rencontré une erreur interne.';
      case 'deadline-exceeded':
      case 'timeout':
        return 'Le backend VEO a dépassé le délai attendu.';
      case 'unknown':
        return fallback ?? 'Erreur inconnue pendant la génération VEO.';
      default:
        return fallback ?? 'Erreur VEO: $code';
    }
  }
}