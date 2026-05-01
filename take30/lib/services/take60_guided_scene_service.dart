import 'dart:convert';
import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'firebase/storage_service.dart';

class Take60GuidedSceneException implements Exception {
  const Take60GuidedSceneException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => message;
}

const _debugMockAiVideoUrl =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

final _privateIpv4Pattern = RegExp(
  r'^(10\.|127\.|0\.0\.0\.0|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)',
);

@visibleForTesting
bool isTake60RenderableRemoteVideoUrl(
  String? rawUrl, {
  bool allowDebugMock = false,
}) {
  final url = rawUrl?.trim() ?? '';
  if (url.isEmpty) {
    return false;
  }
  if (allowDebugMock && url == _debugMockAiVideoUrl) {
    return true;
  }
  if (url == _debugMockAiVideoUrl ||
      url.startsWith('assets/') ||
      url.startsWith('/') ||
      url.startsWith('file:') ||
      url.startsWith('content:') ||
      url.startsWith('blob:') ||
      url.startsWith('data:')) {
    return false;
  }

  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.host.trim().isEmpty ||
      (!uri.isScheme('http') && !uri.isScheme('https'))) {
    return false;
  }

  final host = uri.host.toLowerCase();
  if (host == 'localhost' || _privateIpv4Pattern.hasMatch(host)) {
    return false;
  }
  return true;
}

@visibleForTesting
void validateTake60RenderRequest({
  required SceneModel scene,
  required List<Take60SceneMarker> markers,
  required List<Take60UserRecordingDraft> recordings,
  bool allowDebugMockAi = false,
}) {
  final recordingsByMarker = <String, Take60UserRecordingDraft>{
    for (final recording in recordings) recording.markerId: recording,
  };

  for (final marker in markers) {
    if (marker.requiresUserRecording) {
      final recording = recordingsByMarker[marker.id];
      if (recording == null) {
        throw Take60GuidedSceneException(
          code: 'missing-user-segment',
          message:
              'Le plan utilisateur ${marker.label} doit être enregistré avant le rendu final.',
        );
      }
      if (!isTake60RenderableRemoteVideoUrl(recording.uploadedVideoUrl)) {
        throw Take60GuidedSceneException(
          code: 'segment-upload-required',
          message:
              'Le plan utilisateur ${marker.label} doit être téléversé sur Storage avant le rendu final.',
        );
      }
      continue;
    }

    final aiVideoUrl = (marker.videoUrl ?? scene.videoUrl)?.trim();
    if (!isTake60RenderableRemoteVideoUrl(
      aiVideoUrl,
      allowDebugMock: allowDebugMockAi,
    )) {
      throw Take60GuidedSceneException(
        code: 'invalid-ai-segment',
        message:
            'Le segment IA ${marker.label} n’a pas d’URL vidéo distante exploitable pour le rendu final.',
      );
    }
  }
}

class Take60GuidedSceneService {
  Take60GuidedSceneService._internal()
      : _functions = FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _firestore = FirebaseFirestore.instance,
        _auth = fa.FirebaseAuth.instance,
        _storage = StorageService(FirebaseStorage.instance);

  static final Take60GuidedSceneService instance =
      Take60GuidedSceneService._internal();

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final fa.FirebaseAuth _auth;
  final StorageService _storage;

  static const _uuid = Uuid();

  String get currentUserId => _auth.currentUser?.uid ?? 'guest';

  Future<List<SceneModel>> loadGuidedScenes({
    required UserModel fallbackAuthor,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('scenes')
          .where('adminWorkflow', isEqualTo: true)
          .where('status', isEqualTo: 'published')
          .limit(32)
          .get();

      final guidedScenes = snapshot.docs
          .map(SceneModel.fromFirestore)
          .where((scene) => scene.isGuidedRecordingReady)
          .toList();

      if (guidedScenes.isNotEmpty) {
        return guidedScenes;
      }
    } catch (_) {
      if (kDebugMode) {
        return fallbackScenes(author: fallbackAuthor);
      }
      return const [];
    }

    return kDebugMode ? fallbackScenes(author: fallbackAuthor) : const [];
  }

  List<Take60SceneMarker> buildTimeline(SceneModel scene) {
    if (scene.markers.isNotEmpty) {
      final markers = [...scene.markers]
        ..sort((left, right) => left.order.compareTo(right.order));
      return markers;
    }

    final userCharacter = scene.characterToPlay.isEmpty
        ? 'Utilisateur'
        : scene.characterToPlay;
    final aiCharacter = userCharacter.toLowerCase() == 'voyou'
        ? 'Policière'
        : 'Réplique IA';
    final dialogueLines = _extractDialogueLines(scene.dialogueText);
    const durations = <int>[12, 8, 10, 8, 12, 10];
    final labels = <String>[
      'Plan VO3 1 — intro cinéma',
      'Plan utilisateur 1 — réplique',
      'Plan VO3 2 — réaction',
      'Plan utilisateur 2 — réponse',
      'Plan VO3 3 — tension',
      'Plan utilisateur final — dernière réplique',
    ];
    final markerTypes = <GuidedMarkerType>[
      GuidedMarkerType.aiPlan,
      GuidedMarkerType.userPlan,
      GuidedMarkerType.reactionShot,
      GuidedMarkerType.userPlan,
      GuidedMarkerType.aiReply,
      GuidedMarkerType.finalShot,
    ];
    final markers = <Take60SceneMarker>[];
    var start = 0;

    for (var index = 0; index < durations.length; index++) {
      final duration = durations[index];
      final type = markerTypes[index];
      final requiresUserRecording = type.requiresUserRecording ||
          type == GuidedMarkerType.finalShot;
      markers.add(
        Take60SceneMarker(
          id: 'default_${scene.id}_$index',
          order: index + 1,
          type: type == GuidedMarkerType.finalShot
              ? GuidedMarkerType.userPlan
              : type,
          startSeconds: start,
          endSeconds: start + duration,
          durationSeconds: duration,
          source: requiresUserRecording ? 'user_video' : 'ai_video',
          character: requiresUserRecording ? userCharacter : aiCharacter,
          dialogue: dialogueLines[index % dialogueLines.length],
          cameraPlan: index.isEven ? 'medium_shot' : 'close_up',
          label: labels[index],
          videoUrl: requiresUserRecording
              ? null
              : (scene.videoUrl?.isNotEmpty == true
                  ? scene.videoUrl
                : _resolveAiVideoUrl(scene.videoUrl)),
          cueText: requiresUserRecording
              ? 'Joue ta réplique maintenant.'
              : 'Regarde la scène IA.',
        ),
      );
      start += duration;
    }

    return markers;
  }

  Future<Take60GuidedFlowDraft?> loadDraft({required String sceneId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey(sceneId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return Take60GuidedFlowDraft.fromMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveDraft({
    required SceneModel scene,
    required int currentMarkerIndex,
    required SceneRecordingStatus status,
    required List<Take60UserRecordingDraft> recordings,
  }) async {
    final draft = Take60GuidedFlowDraft(
      sceneId: scene.id,
      sceneTitle: scene.title,
      userId: currentUserId,
      currentMarkerIndex: currentMarkerIndex,
      status: status,
      recordings: recordings,
      updatedAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey(scene.id), jsonEncode(draft.toMap()));
  }

  Future<void> clearDraft(String sceneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(sceneId));
  }

  Future<Take60UserRecordingDraft> persistRecording({
    required SceneModel scene,
    required Take60SceneMarker marker,
    required String localTempPath,
    required int durationSeconds,
    required UserPlanStatus status,
    String? uploadedVideoUrl,
  }) async {
    final now = DateTime.now();
    String? finalUploadedUrl = uploadedVideoUrl;

    // Try to upload the captured segment to Storage so that the backend
    // renderer can reach it. On web (no dart:io File) or if upload fails
    // we silently fall back to the local path — the UI still works in
    // demo / offline mode.
    if (finalUploadedUrl == null &&
        currentUserId != 'guest' &&
        !kIsWeb &&
        localTempPath.isNotEmpty &&
        !localTempPath.startsWith('http')) {
      try {
        final file = File(localTempPath);
        if (await file.exists()) {
          finalUploadedUrl = await _storage.uploadGuidedSegment(
            uid: currentUserId,
            sceneId: scene.id,
            markerId: marker.id,
            file: file,
          );
        }
      } catch (_) {
        // Upload failure is non-fatal — keep local path.
      }
    }

    final recording = Take60UserRecordingDraft(
      recordingId: _uuid.v4(),
      sceneId: scene.id,
      userId: currentUserId,
      markerId: marker.id,
      localTempPath: localTempPath,
      uploadedVideoUrl: finalUploadedUrl,
      durationSeconds: durationSeconds,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    if (currentUserId != 'guest') {
      await _firestore
          .collection('take60_user_recordings')
          .doc(recording.recordingId)
          .set(recording.toMap(), SetOptions(merge: true))
          .catchError((_) {});
    }

    return recording;
  }

  Future<Take60RenderResult> renderTake60GuidedScene({
    required SceneModel scene,
    required List<Take60UserRecordingDraft> recordings,
  }) async {
    final markers = buildTimeline(scene);
    validateTake60RenderRequest(
      scene: scene,
      markers: markers,
      recordings: recordings,
    );
    final payload = {
      'sceneId': scene.id,
      'userId': currentUserId,
      'aiSegments': markers
          .where((marker) => !marker.requiresUserRecording)
          .map(
            (marker) => {
              'markerId': marker.id,
              'type': marker.type.value,
              'videoUrl': (marker.videoUrl ?? scene.videoUrl)?.trim(),
              'durationSeconds': marker.durationSeconds,
              'order': marker.order,
            },
          )
          .toList(),
      'userSegments': recordings
          .map(
            (recording) => {
              'markerId': recording.markerId,
              'type': 'user_plan',
              'videoUrl': recording.uploadedVideoUrl,
              'durationSeconds': recording.durationSeconds,
            },
          )
          .toList(),
      'markers': markers
          .map(
            (marker) => {
              'markerId': marker.id,
              'type': marker.type.value,
              'order': marker.order,
              'durationSeconds': marker.durationSeconds,
            },
          )
          .toList(),
      'audioRules': scene.audioRules.toMap(),
      'maxDurationSeconds': scene.durationSeconds,
    };

    try {
      final callable = _functions.httpsCallable('renderTake60GuidedScene');
      final result = await callable.call(payload);
      return Take60RenderResult.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } on FirebaseFunctionsException catch (error) {
      throw Take60GuidedSceneException(
        code: error.code,
        message: error.message ?? 'Le rendu final Take60 a échoué côté backend.',
      );
    } catch (_) {
      throw const Take60GuidedSceneException(
        code: 'unknown',
        message: 'Le rendu final Take60 a échoué pour une raison inconnue.',
      );
    }
  }

  Future<void> saveRenderedProject({
    required SceneModel scene,
    required List<Take60UserRecordingDraft> recordings,
    required Take60RenderResult renderResult,
    required String status,
  }) async {
    final now = DateTime.now();
    final projectId = '${currentUserId}_${scene.id}';
    final payload = <String, dynamic>{
      'projectId': projectId,
      'sceneId': scene.id,
      'sceneTitle': scene.title,
      'category': scene.category,
      'sceneType': scene.sceneType,
      'userId': currentUserId,
      'status': status,
      'renderResult': renderResult.toMap(),
      'recordings': recordings.map((recording) => recording.toMap()).toList(),
      'updatedAt': now.toIso8601String(),
      'publishedAt': status == 'published' ? now.toIso8601String() : null,
    };

    if (currentUserId == 'guest') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'take60_guided_project_$projectId',
        jsonEncode(payload),
      );
      return;
    }

    await _firestore
        .collection('take60_guided_projects')
        .doc(projectId)
        .set(payload, SetOptions(merge: true));
  }

  List<SceneModel> fallbackScenes({required UserModel author}) {
    return [
      SceneModel(
        id: 'take60_scene_001',
        title: 'Contrôle sous tension',
        category: 'Policier',
        thumbnailUrl: 'assets/scenes/scene_interrogatoire.svg',
        sceneType: 'Dialogue',
        difficulty: 'Intermédiaire',
        durationSeconds: 60,
        editingMode: 'dialogue_auto_cut',
        ambiance: 'Tension urbaine réaliste',
        characterToPlay: 'Voyou',
        context:
            'Une policière interpelle un jeune homme après une infraction devant une école.',
        emotionalObjective: 'Jouer la provocation puis la peur.',
        directorInstructions:
            'Regarde la caméra comme si la policière était devant toi. Garde une attitude nerveuse.',
        dialogueText:
            'Non, j’ai rien fait moi.\nJ’étais pressé, c’est tout.\nD’accord… j’ai compris.',
        videoUrl: _debugMockAiVideoUrl,
        author: author,
        createdAt: DateTime.now(),
        tags: const ['Policier', 'Dialogue', 'Intermédiaire'],
        adminWorkflow: true,
        audioRules: const Take60AudioRules(),
        markers: const [
          Take60SceneMarker(
            id: 'marker_001',
            order: 1,
            type: GuidedMarkerType.aiPlan,
            startSeconds: 0,
            endSeconds: 15,
            durationSeconds: 15,
            source: 'ai_video',
            character: 'Policière',
            dialogue: 'Vous savez pourquoi je vous ai arrêté ?',
            cameraPlan: 'medium_shot',
            label: 'Plan IA 1 / 6',
            videoUrl: _debugMockAiVideoUrl,
            cueText: 'Prépare-toi, ton passage arrive après cette vidéo.',
          ),
          Take60SceneMarker(
            id: 'marker_002',
            order: 2,
            type: GuidedMarkerType.userPlan,
            startSeconds: 15,
            endSeconds: 23,
            durationSeconds: 8,
            source: 'user_video',
            character: 'Voyou',
            dialogue: 'Non, j’ai rien fait moi.',
            cameraPlan: 'close_up',
            label: 'Plan utilisateur 1 / 3',
            cueText: 'Joue ta réplique maintenant.',
          ),
          Take60SceneMarker(
            id: 'marker_003',
            order: 3,
            type: GuidedMarkerType.reactionShot,
            startSeconds: 23,
            endSeconds: 31,
            durationSeconds: 8,
            source: 'ai_video',
            character: 'Policière',
            dialogue: 'Vous venez de griller un feu rouge devant une école.',
            cameraPlan: 'reaction_shot',
            label: 'Plan IA 2 / 6',
            videoUrl: _debugMockAiVideoUrl,
            cueText: 'Regarde la scène IA.',
          ),
          Take60SceneMarker(
            id: 'marker_004',
            order: 4,
            type: GuidedMarkerType.userPlan,
            startSeconds: 31,
            endSeconds: 39,
            durationSeconds: 8,
            source: 'user_video',
            character: 'Voyou',
            dialogue: 'J’étais pressé, c’est tout.',
            cameraPlan: 'close_up',
            label: 'Plan utilisateur 2 / 3',
            cueText: 'Joue ta réplique maintenant.',
          ),
          Take60SceneMarker(
            id: 'marker_005',
            order: 5,
            type: GuidedMarkerType.aiReply,
            startSeconds: 39,
            endSeconds: 51,
            durationSeconds: 12,
            source: 'ai_video',
            character: 'Policière',
            dialogue:
                'Être pressé ne justifie pas de mettre des enfants en danger.',
            cameraPlan: 'close_up',
            label: 'Plan IA 3 / 6',
            videoUrl: _debugMockAiVideoUrl,
            cueText: 'Regarde la scène IA.',
          ),
          Take60SceneMarker(
            id: 'marker_006',
            order: 6,
            type: GuidedMarkerType.userPlan,
            startSeconds: 51,
            endSeconds: 60,
            durationSeconds: 9,
            source: 'user_video',
            character: 'Voyou',
            dialogue: 'D’accord… j’ai compris.',
            cameraPlan: 'final_shot',
            label: 'Plan utilisateur 3 / 3',
            cueText: 'Dernière réplique. Donne tout.',
          ),
        ],
      ),
      SceneModel(
        id: 'take60_scene_002',
        title: 'Dernière audition',
        category: 'Drame',
        thumbnailUrl: 'assets/scenes/scene_mauvaise_nouvelle.svg',
        sceneType: 'Audition',
        difficulty: 'Intense',
        durationSeconds: 60,
        editingMode: 'dialogue_auto_cut',
        ambiance: 'Pression sourde et émotion contenue',
        characterToPlay: 'Actrice',
        context:
            'Tu joues une actrice qui comprend qu’elle n’aura peut-être pas le rôle de sa vie.',
        emotionalObjective: 'Passer de l’espoir à la colère retenue.',
        directorInstructions:
            'Laisse le doute te traverser avant de reprendre le contrôle.',
        dialogueText:
            'Je croyais vraiment que c’était pour moi.\nVous auriez pu me prévenir plus tôt.\nJe vais quand même finir cette scène.',
        videoUrl: _debugMockAiVideoUrl,
        author: author,
        createdAt: DateTime.now(),
        tags: const ['Drame', 'Audition', 'Intense'],
        adminWorkflow: true,
      ),
      SceneModel(
        id: 'take60_scene_003',
        title: 'Déclaration impossible',
        category: 'Romance',
        thumbnailUrl: 'assets/scenes/scene_declaration_amour.svg',
        sceneType: 'Face caméra',
        difficulty: 'Facile',
        durationSeconds: 60,
        editingMode: 'dialogue_auto_cut',
        ambiance: 'Romance nerveuse au crépuscule',
        characterToPlay: 'Confident',
        context:
            'Tu hésites entre l’aveu sincère et la fuite au moment de parler.',
        emotionalObjective: 'Montrer la douceur puis le vertige.',
        directorInstructions:
            'Reste proche de la caméra, comme si tu cherchais enfin le courage.',
        dialogueText:
            'Je ne savais pas quand te le dire.\nChaque fois que tu souris, je perds mes mots.\nAlors je vais juste te le dire maintenant.',
        videoUrl: _debugMockAiVideoUrl,
        author: author,
        createdAt: DateTime.now(),
        tags: const ['Romance', 'Face caméra', 'Facile'],
        adminWorkflow: true,
      ),
    ];
  }

  String _draftKey(String sceneId) =>
      'take60_guided_draft_${currentUserId}_$sceneId';

  String? _resolveAiVideoUrl(String? sceneVideoUrl) {
    final trimmed = sceneVideoUrl?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return kDebugMode ? _debugMockAiVideoUrl : null;
  }

  List<String> _extractDialogueLines(String rawDialogue) {
    final normalized = rawDialogue
        .split(RegExp(r'[\n\r]+'))
        .expand((line) => line.split(RegExp(r'[.!?]')))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return const [
      'Prépare-toi, ton passage arrive.',
      'Joue ta réplique maintenant.',
      'Valide ce plan ou rejoue-le.',
    ];
  }
}