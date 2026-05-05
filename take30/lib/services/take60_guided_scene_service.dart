import 'dart:convert';
import 'dart:io' show File;

import 'package:camera/camera.dart';
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
  final Map<String, DateTime> _projectCreatedAtCache = {};

  static const _uuid = Uuid();

  String get currentUserId => _auth.currentUser?.uid ?? 'guest';

  @visibleForTesting
  static String buildProjectId({
    required String userId,
    required String sceneId,
  }) {
    return '${userId}_$sceneId';
  }

  @visibleForTesting
  static String buildSegmentStoragePath({
    required String userId,
    required String projectId,
    required String markerId,
    DateTime? timestamp,
  }) {
    return StorageService.buildGuidedSegmentPath(
      uid: userId,
      projectId: projectId,
      markerId: markerId,
      timestampMillis:
          (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  @visibleForTesting
  static Map<String, dynamic> buildRenderPayload({
    required String projectId,
    required String userId,
    required SceneModel scene,
    required List<Take60SceneMarker> markers,
    required List<Take60UserRecordingDraft> recordings,
  }) {
    return {
      'projectId': projectId,
      'sceneId': scene.id,
      'userId': userId,
      'aiSegments': markers
          .where((marker) => !marker.requiresUserRecording)
          .map(
            (marker) => {
              'markerId': marker.id,
              'type': marker.type.value,
              'videoUrl': (marker.videoUrl?.isNotEmpty ?? false)
                  ? marker.videoUrl
                  : scene.videoUrl,
              'source': marker.source,
              'startSeconds': marker.startSeconds,
              'endSeconds': marker.endSeconds,
              'durationSeconds': marker.durationSeconds,
              'order': marker.order,
              'dialogue': marker.dialogue,
              'character': marker.character,
              'cameraPlan': marker.cameraPlan,
              'label': marker.label,
              'audioMode': marker.audioMode.isNotEmpty
                  ? marker.audioMode
                  : 'ai_only',
            },
          )
          .toList(),
      'userSegments': recordings
          .map(
            (recording) => {
              'markerId': recording.markerId,
              'type': GuidedMarkerType.userPlan.value,
              'videoUrl': recording.uploadedVideoUrl,
              'source': 'user_video',
              'startSeconds': recording.startSecond,
              'endSeconds': recording.endSecond,
              'durationSeconds': recording.durationSeconds,
              'audioMode': 'user_voice_with_optional_ai_ambiance',
            },
          )
          .toList(),
      'markers': markers
          .map(
            (marker) => {
              'markerId': marker.id,
              'type': marker.type.value,
              'source': marker.source,
              'order': marker.order,
              'startSeconds': marker.startSeconds,
              'endSeconds': marker.endSeconds,
              'durationSeconds': marker.durationSeconds,
              'videoUrl': marker.videoUrl,
              'dialogue': marker.dialogue,
              'character': marker.character,
              'cameraPlan': marker.cameraPlan,
              'label': marker.label,
              'audioMode': marker.audioMode.isNotEmpty
                  ? marker.audioMode
                  : (marker.requiresUserRecording
                      ? 'user_voice_with_optional_ai_ambiance'
                      : 'ai_only'),
              'status': marker.status,
            },
          )
          .toList(),
      'audioRules': scene.audioRules.toMap(),
      if ((scene.globalAiAmbianceAudioUrl?.trim().isNotEmpty ?? false))
        'audioBed': {
          'url': scene.globalAiAmbianceAudioUrl!.trim(),
          'durationSeconds': scene.durationSeconds > 0
              ? scene.durationSeconds
              : 60,
          'mode': 'ai_ambiance_only',
        },
      'maxDurationSeconds': scene.durationSeconds > 0
          ? scene.durationSeconds
          : 60,
    };
  }

  @visibleForTesting
  static Future<Take60RenderResult> resolvePersistentRenderUrls(
    Take60RenderResult renderResult, {
    required Future<String> Function(String storagePath) resolveDownloadUrl,
  }) async {
    var resolvedVideoUrl = renderResult.finalVideoUrl;
    var resolvedThumbnailUrl = renderResult.thumbnailUrl;

    final videoStoragePath = renderResult.videoStoragePath?.trim() ?? '';
    if (videoStoragePath.isNotEmpty) {
      try {
        resolvedVideoUrl = await resolveDownloadUrl(videoStoragePath);
      } catch (_) {
        // Keep the last known URL as a non-breaking fallback.
      }
    }

    final thumbnailStoragePath =
        renderResult.thumbnailStoragePath?.trim() ?? '';
    if (thumbnailStoragePath.isNotEmpty) {
      try {
        resolvedThumbnailUrl = await resolveDownloadUrl(thumbnailStoragePath);
      } catch (_) {
        // Keep the last known URL as a non-breaking fallback.
      }
    }

    return renderResult.copyWith(
      finalVideoUrl: resolvedVideoUrl,
      thumbnailUrl: resolvedThumbnailUrl,
    );
  }

  @visibleForTesting
  static List<Take60UserRecordingDraft> mergeProjectRecordings({
    required List<Take60UserRecordingDraft> existingRecordings,
    required Take60UserRecordingDraft latestRecording,
  }) {
    final recordingsByMarker = <String, Take60UserRecordingDraft>{
      for (final recording in existingRecordings) recording.markerId: recording,
    };
    recordingsByMarker[latestRecording.markerId] = latestRecording;
    return recordingsByMarker.values.toList()
      ..sort(
        (left, right) => left.startSecond.compareTo(right.startSecond),
      );
  }

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
      final fallbackAiVideoUrl = _resolveAiVideoUrl(scene.videoUrl);
      final markers = [...scene.markers]
        ..sort((left, right) => left.order.compareTo(right.order));
      return markers
          .map(
            (marker) => !marker.requiresUserRecording &&
                    (marker.videoUrl?.trim().isEmpty ?? true)
                ? marker.copyWith(videoUrl: fallbackAiVideoUrl)
                : marker,
          )
          .toList();
    }

    final userCharacter = scene.characterToPlay.isEmpty
        ? 'Utilisateur'
        : scene.characterToPlay;
    final aiCharacter = userCharacter.toLowerCase() == 'voyou'
        ? 'Policière'
        : 'Réplique IA';
    final dialogueLines = _extractDialogueLines(scene.dialogueText);
    const durations = <int>[8, 8, 8, 8, 8, 8, 8];
    final labels = <String>[
      'Vidéo IA d’introduction — segment 1/2',
      'Vidéo IA d’introduction — segment 2/2',
      'Plan utilisateur 1 — réplique',
      'Réaction IA',
      'Plan utilisateur 2 — réponse',
      'Séquence IA de tension',
      'Plan utilisateur final — dernière réplique',
    ];
    final markerTypes = <GuidedMarkerType>[
      GuidedMarkerType.introAiVideo,
      GuidedMarkerType.introAiVideo,
      GuidedMarkerType.userPlan,
      GuidedMarkerType.aiSequence,
      GuidedMarkerType.userPlan,
      GuidedMarkerType.aiSequence,
      GuidedMarkerType.userPlan,
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
            audioMode: requiresUserRecording
              ? 'user_voice_with_optional_ai_ambiance'
              : 'ai_only',
            status: requiresUserRecording ? 'pending' : 'ready',
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

  Future<Take60GuidedResumeState?> loadResumeState({
    required SceneModel scene,
  }) async {
    final fallbackMarkers = buildTimeline(scene);
    final localDraft = await loadDraft(sceneId: scene.id);
    final localState = localDraft == null
        ? null
        : Take60GuidedResumeState.fromLocalDraft(
            localDraft,
            markers: fallbackMarkers,
          );

    Take60GuidedResumeState? remoteState;
    if (currentUserId != 'guest') {
      try {
        final snapshot = await _firestore
            .collection('take60_guided_projects')
            .doc(projectIdForScene(scene))
            .get();
        final data = snapshot.data();
        if (snapshot.exists && data != null) {
          remoteState = Take60GuidedResumeState.fromProjectMap(
            data,
            fallbackMarkers: fallbackMarkers,
          );
        }
      } catch (_) {
        remoteState = null;
      }
    }

    final candidates = [localState, remoteState]
        .whereType<Take60GuidedResumeState>()
        .where(_isResumableState)
        .toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return candidates.isEmpty ? null : candidates.first;
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

  Future<void> saveGuidedProjectDraft({
    required String projectId,
    required SceneModel scene,
    required int currentMarkerIndex,
    required List<Take60SceneMarker> markers,
    required List<Take60UserRecordingDraft> recordings,
    required SceneRecordingStatus recordingStatus,
  }) async {
    final now = DateTime.now();
    final createdAt = await _resolveProjectCreatedAt(
      projectId: projectId,
      fallback: now,
    );
    final totalUserMarkersCount =
        markers.where((marker) => marker.requiresUserRecording).length;
    final completedUserMarkersCount = markers
        .where((marker) => marker.requiresUserRecording)
        .where((marker) => recordings.any(
              (recording) =>
                  recording.markerId == marker.id &&
                  recording.status == UserPlanStatus.validated,
            ))
        .length;
    final payload = <String, dynamic>{
      ..._projectPayload(
        projectId: projectId,
        scene: scene,
        status: completedUserMarkersCount >= totalUserMarkersCount &&
                totalUserMarkersCount > 0
            ? 'ready_to_render'
            : 'draft',
        createdAt: createdAt,
        updatedAt: now,
        currentMarkerIndex: currentMarkerIndex,
        markers: markers,
        recordings: recordings,
      ),
      'recordingStatus': recordingStatus.value,
    };

    if (currentUserId == 'guest') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _projectStorageKey(projectId),
        jsonEncode(payload),
      );
      return;
    }

    await _firestore
        .collection('take60_guided_projects')
        .doc(projectId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> clearDraft(String sceneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(sceneId));
  }

  Future<void> discardResumeState({required SceneModel scene}) async {
    await clearDraft(scene.id);
    final projectId = projectIdForScene(scene);
    _projectCreatedAtCache.remove(projectId);

    if (currentUserId == 'guest') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectStorageKey(projectId));
      return;
    }

    try {
      final docRef = _firestore
          .collection('take60_guided_projects')
          .doc(projectId);
      final snapshot = await docRef.get();
      final status = (snapshot.data()?['status'] as String? ?? '').trim();
      if (!snapshot.exists || status == 'published') {
        return;
      }
      await docRef.delete();
    } catch (_) {
      // Ignore discard failures and keep the local reset path working.
    }
  }

  Future<StorageUploadResult?> prepareBattleSubmissionAsset({
    required String projectId,
    required String finalVideoUrl,
    required Take60BattleRecordingContext battleContext,
  }) async {
    if (currentUserId == 'guest' || finalVideoUrl.trim().isEmpty) {
      return null;
    }

    final storagePath = StorageService.buildBattleRenderPath(
      battleId: battleContext.battleId,
      uid: currentUserId,
      participantRole: battleContext.participantRole,
      projectId: projectId,
    );

    try {
      return await _storage.mirrorRemoteVideo(
        sourceUrl: finalVideoUrl,
        storagePath: storagePath,
      );
    } catch (_) {
      // Keep the legacy take60_renders flow as a non-breaking fallback.
      return null;
    }
  }

  String projectIdForScene(SceneModel scene) {
    return buildProjectId(userId: currentUserId, sceneId: scene.id);
  }

  Future<Take60UserRecordingDraft> persistRecording({
    required String projectId,
    required SceneModel scene,
    required Take60SceneMarker marker,
    required XFile recordedFile,
    required String localTempPath,
    required int durationSeconds,
    required UserPlanStatus status,
    String? uploadedVideoUrl,
  }) async {
    final now = DateTime.now();
    String? finalUploadedUrl = uploadedVideoUrl;
    String? finalStoragePath;

    if (finalUploadedUrl == null &&
        currentUserId != 'guest' &&
        localTempPath.isNotEmpty &&
        !localTempPath.startsWith('http')) {
      try {
        final storagePath = buildSegmentStoragePath(
          userId: currentUserId,
          projectId: projectId,
          markerId: marker.id,
          timestamp: now,
        );
        if (kIsWeb) {
          final upload = await _storage.uploadGuidedSegmentBytes(
            storagePath: storagePath,
            bytes: await recordedFile.readAsBytes(),
          );
          finalStoragePath = upload.storagePath;
          finalUploadedUrl = upload.downloadUrl;
        } else {
          final file = File(localTempPath);
          if (await file.exists()) {
            final upload = await _storage.uploadGuidedSegment(
              storagePath: storagePath,
              file: file,
            );
            finalStoragePath = upload.storagePath;
            finalUploadedUrl = upload.downloadUrl;
          }
        }
      } catch (_) {
        // Upload failure is non-fatal during capture; render validation will
        // still block until a remote URL exists.
      }
    }

    final recording = Take60UserRecordingDraft(
      recordingId: _uuid.v4(),
      projectId: projectId,
      sceneId: scene.id,
      userId: currentUserId,
      markerId: marker.id,
      startSecond: marker.startSeconds,
      endSecond: marker.endSeconds,
      localTempPath: localTempPath,
      storagePath: finalStoragePath,
      uploadedVideoUrl: finalUploadedUrl,
      durationSeconds: durationSeconds,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    if (currentUserId != 'guest') {
      final timelineMarkers = buildTimeline(scene);
      final markerIndex = timelineMarkers.indexWhere(
        (timelineMarker) => timelineMarker.id == marker.id,
      );
      final projectRef = _firestore
          .collection('take60_guided_projects')
          .doc(projectId);
        Map<String, dynamic>? existingProjectData;
        try {
          final projectSnapshot = await projectRef.get();
          existingProjectData = projectSnapshot.data();
        } catch (_) {
          existingProjectData = null;
        }
      final mergedRecordings = mergeProjectRecordings(
          existingRecordings: _readProjectRecordings(existingProjectData),
        latestRecording: recording,
      );
      final createdAt = await _resolveProjectCreatedAt(
        projectId: projectId,
        fallback: now,
      );
      final batch = _firestore.batch();
      final segmentRef = projectRef.collection('segments').doc(marker.id);
      final legacyRef = _firestore
          .collection('take60_user_recordings')
          .doc(recording.recordingId);
      batch.set(
        projectRef,
        _projectPayload(
          projectId: projectId,
          scene: scene,
          status:
              finalUploadedUrl?.isNotEmpty == true ? 'ready_for_render' : 'recording',
          createdAt: createdAt,
          updatedAt: now,
          currentMarkerIndex: markerIndex >= 0 ? markerIndex : null,
          markers: timelineMarkers,
          recordings: mergedRecordings,
        ),
        SetOptions(merge: true),
      );
      batch.set(
        projectRef,
        {
          'recordingStatus': SceneRecordingStatus.previewUserPlan.value,
        },
        SetOptions(merge: true),
      );
      batch.set(
        segmentRef,
        _segmentPayload(recording),
        SetOptions(merge: true),
      );
      batch.set(
        legacyRef,
        recording.toMap(),
        SetOptions(merge: true),
      );
      await batch.commit().catchError((_) {});
    }

    return recording;
  }

  Future<Take60RenderResult> renderTake60GuidedScene({
    required String projectId,
    required SceneModel scene,
    required List<Take60UserRecordingDraft> recordings,
  }) async {
    final markers = buildTimeline(scene);
    validateTake60RenderRequest(
      scene: scene,
      markers: markers,
      recordings: recordings,
    );
    final payload = buildRenderPayload(
      projectId: projectId,
      userId: currentUserId,
      scene: scene,
      markers: markers,
      recordings: recordings,
    );

    try {
      await _updateProjectStatus(
        projectId: projectId,
        scene: scene,
        status: 'rendering',
      );
      final callable = _functions.httpsCallable('renderTake60GuidedScene');
      final result = await callable.call(payload);
      final renderResult = await resolvePersistentRenderUrls(
        Take60RenderResult.fromMap(
        Map<String, dynamic>.from(result.data as Map),
        ),
        resolveDownloadUrl: _storage.resolveDownloadUrl,
      );
      await _updateProjectStatus(
        projectId: projectId,
        scene: scene,
        status: 'completed',
        finalVideoUrl: renderResult.finalVideoUrl,
        renderResult: renderResult,
      );
      return renderResult;
    } on FirebaseFunctionsException catch (error) {
      await _updateProjectStatus(
        projectId: projectId,
        scene: scene,
        status: 'failed',
      );
      throw Take60GuidedSceneException(
        code: error.code,
        message: error.message ?? 'Le rendu final Take60 a échoué côté backend.',
      );
    } catch (_) {
      await _updateProjectStatus(
        projectId: projectId,
        scene: scene,
        status: 'failed',
      );
      throw const Take60GuidedSceneException(
        code: 'unknown',
        message: 'Le rendu final Take60 a échoué pour une raison inconnue.',
      );
    }
  }

  Future<void> saveRenderedProject({
    required String projectId,
    required SceneModel scene,
    required List<Take60UserRecordingDraft> recordings,
    required Take60RenderResult renderResult,
    required String status,
    required int currentMarkerIndex,
    Take60BattleRecordingContext? battleContext,
  }) async {
    final persistentRenderResult = await resolvePersistentRenderUrls(
      renderResult,
      resolveDownloadUrl: _storage.resolveDownloadUrl,
    );
    final now = DateTime.now();
    final createdAt = await _resolveProjectCreatedAt(
      projectId: projectId,
      fallback: now,
    );
    final payload = <String, dynamic>{
      ..._projectPayload(
        projectId: projectId,
        scene: scene,
        status: status == 'published' ? 'completed' : 'draft',
        createdAt: createdAt,
        updatedAt: now,
        currentMarkerIndex: currentMarkerIndex,
        finalVideoUrl: persistentRenderResult.finalVideoUrl,
        renderResult: persistentRenderResult,
        recordings: recordings,
      ),
      'status': status,
      'renderResult': persistentRenderResult.toMap(),
      'recordings': recordings.map((recording) => recording.toMap()).toList(),
      'updatedAt': now.toIso8601String(),
      'publishedAt': status == 'published' ? now.toIso8601String() : null,
      if (battleContext != null) ...battleContext.toMap(),
    };

    if (currentUserId == 'guest') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _projectStorageKey(projectId),
        jsonEncode(payload),
      );
      return;
    }

    await _firestore
        .collection('take60_guided_projects')
        .doc(projectId)
        .set(payload, SetOptions(merge: true));

    if (status == 'published' && persistentRenderResult.finalVideoUrl.isNotEmpty) {
      await _firestore.collection('takes').doc(projectId).set({
        'projectId': projectId,
        'sceneId': scene.id,
        'sceneTitle': scene.title,
        'category': scene.category,
        'sceneType': scene.sceneType,
        'userId': currentUserId,
        'videoUrl': persistentRenderResult.finalVideoUrl,
        'thumbnailUrl': persistentRenderResult.thumbnailUrl,
        'renderId': persistentRenderResult.renderId,
        'videoStoragePath': persistentRenderResult.videoStoragePath,
        'thumbnailStoragePath': persistentRenderResult.thumbnailStoragePath,
        'renderStatus': persistentRenderResult.renderStatus,
        'durationSeconds': persistentRenderResult.durationSeconds,
        'status': 'published',
        if (battleContext != null) ...battleContext.toMap(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Map<String, dynamic> _projectPayload({
    required String projectId,
    required SceneModel scene,
    required String status,
    required DateTime updatedAt,
    DateTime? createdAt,
    int? currentMarkerIndex,
    String? finalVideoUrl,
    Take60RenderResult? renderResult,
    List<Take60SceneMarker>? markers,
    List<Take60UserRecordingDraft>? recordings,
  }) {
    final shouldPersistTimelineMarkers = markers != null;
    final shouldPersistUserRecordings = recordings != null;
    final timelineMarkers = markers ?? buildTimeline(scene);
    final userRecordings = recordings ?? const <Take60UserRecordingDraft>[];
    final totalUserMarkersCount =
      timelineMarkers.where((marker) => marker.requiresUserRecording).length;
    final completedUserMarkersCount = timelineMarkers
      .where((marker) => marker.requiresUserRecording)
      .where((marker) => userRecordings.any(
          (recording) =>
            recording.markerId == marker.id &&
            recording.status == UserPlanStatus.validated,
        ))
      .length;
    final introAiDurationSeconds = timelineMarkers
      .where((marker) => marker.type == GuidedMarkerType.introAiVideo)
      .fold<int>(0, (total, marker) => total + marker.durationSeconds);
    return <String, dynamic>{
      'id': projectId,
      'projectId': projectId,
      'userId': currentUserId,
      'sceneId': scene.id,
      'sceneTitle': scene.title,
      'category': scene.category,
      'sceneType': scene.sceneType,
      'status': status,
      if (currentMarkerIndex != null) 'currentMarkerIndex': currentMarkerIndex,
      'introAiVideoUrl': scene.videoUrl,
      'globalAiAmbianceAudioUrl': scene.globalAiAmbianceAudioUrl,
      'introAiDurationSeconds': introAiDurationSeconds > 0
        ? introAiDurationSeconds
        : null,
      if (shouldPersistTimelineMarkers)
        'timelineMarkers': timelineMarkers.map((marker) => marker.toMap()).toList(),
      if (shouldPersistUserRecordings)
        'userRecordings': userRecordings.map((recording) => recording.toMap()).toList(),
      'completedUserMarkersCount': completedUserMarkersCount,
      'totalUserMarkersCount': totalUserMarkersCount,
      if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (renderResult != null && renderResult.renderId.isNotEmpty)
        'renderId': renderResult.renderId,
      if (renderResult?.videoStoragePath?.isNotEmpty ?? false)
        'finalVideoStoragePath': renderResult!.videoStoragePath,
      if (renderResult?.thumbnailStoragePath?.isNotEmpty ?? false)
        'thumbnailStoragePath': renderResult!.thumbnailStoragePath,
      if ((finalVideoUrl ?? renderResult?.finalVideoUrl ?? '').isNotEmpty)
        'finalVideoUrl': finalVideoUrl ?? renderResult!.finalVideoUrl,
      if ((renderResult?.thumbnailUrl ?? '').isNotEmpty)
        'thumbnailUrl': renderResult!.thumbnailUrl,
    };
  }

  Map<String, dynamic> _segmentPayload(Take60UserRecordingDraft recording) {
    return <String, dynamic>{
      'id': recording.markerId,
      'projectId': recording.projectId,
      'sceneId': recording.sceneId,
      'userId': recording.userId,
      'markerId': recording.markerId,
      'startSecond': recording.startSecond,
      'endSecond': recording.endSecond,
      'durationSeconds': recording.durationSeconds,
      'localPath': recording.localTempPath,
      'storagePath': recording.storagePath,
      'uploadedVideoUrl': recording.uploadedVideoUrl,
      'status': recording.isUploaded ? 'uploaded' : recording.status.value,
      'createdAt': recording.createdAt.toIso8601String(),
      'updatedAt': recording.updatedAt.toIso8601String(),
    };
  }

  Future<void> _updateProjectStatus({
    required String projectId,
    required SceneModel scene,
    required String status,
    String? finalVideoUrl,
    Take60RenderResult? renderResult,
  }) async {
    if (currentUserId == 'guest') {
      return;
    }
    final createdAt = await _resolveProjectCreatedAt(
      projectId: projectId,
      fallback: DateTime.now(),
    );
    await _firestore
        .collection('take60_guided_projects')
        .doc(projectId)
        .set(
          _projectPayload(
            projectId: projectId,
            scene: scene,
            status: status,
            createdAt: createdAt,
            updatedAt: DateTime.now(),
            finalVideoUrl: finalVideoUrl,
            renderResult: renderResult,
          ),
          SetOptions(merge: true),
        )
        .catchError((_) {});
  }

  bool _isResumableState(Take60GuidedResumeState state) {
    return state.recordings.isNotEmpty &&
        state.status != SceneRecordingStatus.published;
  }

  String _projectStorageKey(String projectId) =>
      'take60_guided_project_$projectId';

  List<Take60UserRecordingDraft> _readProjectRecordings(
    Map<String, dynamic>? projectData,
  ) {
    if (projectData == null || projectData.isEmpty) {
      return const [];
    }
    return Take60GuidedResumeState.fromProjectMap(
      projectData,
      fallbackMarkers: const [],
    ).recordings;
  }

  Future<DateTime> _resolveProjectCreatedAt({
    required String projectId,
    required DateTime fallback,
  }) async {
    final cached = _projectCreatedAtCache[projectId];
    if (cached != null) {
      return cached;
    }

    DateTime? createdAt;
    if (currentUserId == 'guest') {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_projectStorageKey(projectId));
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        createdAt = _readProjectDate(json['createdAt']);
      }
    } else {
      final snapshot = await _firestore
          .collection('take60_guided_projects')
          .doc(projectId)
          .get();
      createdAt = _readProjectDate(snapshot.data()?['createdAt']);
    }

    final resolved = createdAt ?? fallback;
    _projectCreatedAtCache[projectId] = resolved;
    return resolved;
  }

  DateTime? _readProjectDate(dynamic raw) {
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