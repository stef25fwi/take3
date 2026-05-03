import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

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
  VeoSceneGenerationService({
    FirebaseFunctions? functions,
    fa.FirebaseAuth? auth,
  })  : _functions = functions,
        _auth = auth;

  final FirebaseFunctions? _functions;
  final fa.FirebaseAuth? _auth;

  FirebaseFunctions get _resolvedFunctions =>
      _functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  fa.FirebaseAuth get _resolvedAuth => _auth ?? fa.FirebaseAuth.instance;

  Future<fa.User> _requireFirebaseUserForVeo() async {
    final user = _resolvedAuth.currentUser;

    if (user == null) {
      throw const VeoSceneGenerationException(
        code: 'unauthenticated',
        message:
            'Connexion Firebase requise : connecte-toi avec ton compte admin avant de lancer VEO.',
      );
    }

    if (user.isAnonymous) {
      throw const VeoSceneGenerationException(
        code: 'unauthenticated',
        message: 'Compte invité non autorisé pour lancer une génération VEO.',
      );
    }

    await user.getIdToken(true);
    return user;
  }

  Future<VeoGenerationJob> requestVeoScenePreview({
    required String sceneId,
    required String prompt,
    int durationSeconds = 15,
    String aspectRatio = '16:9',
  }) async {
    try {
      await _requireFirebaseUserForVeo();

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
    } on VeoSceneGenerationException {
      rethrow;
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
      await _requireFirebaseUserForVeo();

      final callable =
          _resolvedFunctions.httpsCallable('checkVeoSceneGeneration');
      final result = await callable.call(<String, dynamic>{'sceneId': sceneId});
      return VeoGenerationJob.fromJson(
        _asMap(result.data),
        fallbackSceneId: sceneId,
      );
    } on VeoSceneGenerationException {
      rethrow;
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
    final safeFallback = _sanitizeBackendMessage(fallback);
    switch (code) {
      case 'unauthenticated':
        return safeFallback ??
            'Connexion Firebase requise : connecte-toi avec ton compte admin avant de lancer VEO.';
      case 'permission-denied':
        return 'Accès refusé: le rôle admin est requis pour VEO.';
      case 'unavailable':
        return safeFallback ??
            'VEO indisponible : modèle ou endpoint Vertex inaccessible. Vérifie la configuration serveur.';
      case 'internal':
        return safeFallback ??
            'VEO indisponible : modèle ou endpoint Vertex inaccessible. Vérifie la configuration serveur.';
      case 'deadline-exceeded':
      case 'timeout':
        return 'Le backend VEO a dépassé le délai attendu.';
      case 'unknown':
        return safeFallback ??
            'VEO indisponible : modèle ou endpoint Vertex inaccessible. Vérifie la configuration serveur.';
      default:
        return safeFallback ?? 'Erreur VEO: $code';
    }
  }

  static String? _sanitizeBackendMessage(String? fallback) {
    final message = fallback?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }
    final lower = message.toLowerCase();
    if (lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('responsepreview')) {
      return 'VEO indisponible : modèle ou endpoint Vertex inaccessible. Vérifie la configuration serveur.';
    }
    return message;
  }
}