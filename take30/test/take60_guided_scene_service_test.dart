import 'package:flutter_test/flutter_test.dart';
import 'package:take30/models/models.dart';
import 'package:take30/services/take60_guided_scene_service.dart';

void main() {
  const author = UserModel(
    id: 'user_1',
    username: 'user_1',
    displayName: 'User 1',
    avatarUrl: '',
  );

  SceneModel buildScene({
    required String? aiVideoUrl,
    String? globalAiAmbianceAudioUrl,
  }) {
    return SceneModel(
      id: 'scene_1',
      title: 'Scene test',
      category: 'Drame',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      videoUrl: aiVideoUrl,
      author: author,
      createdAt: DateTime(2026, 5, 1),
      adminWorkflow: true,
      globalAiAmbianceAudioUrl: globalAiAmbianceAudioUrl,
      markers: [
        Take60SceneMarker(
          id: 'ai_1',
          order: 1,
          type: GuidedMarkerType.aiPlan,
          startSeconds: 0,
          endSeconds: 10,
          durationSeconds: 10,
          source: 'ai_video',
          character: 'IA',
          dialogue: 'Intro',
          cameraPlan: 'wide',
          label: 'Plan IA',
          videoUrl: aiVideoUrl,
        ),
        const Take60SceneMarker(
          id: 'user_1',
          order: 2,
          type: GuidedMarkerType.userPlan,
          startSeconds: 10,
          endSeconds: 20,
          durationSeconds: 10,
          source: 'user_video',
          character: 'Utilisateur',
          dialogue: 'Réplique',
          cameraPlan: 'close_up',
          label: 'Plan utilisateur',
        ),
      ],
    );
  }

  Take60UserRecordingDraft buildRecording({String? uploadedVideoUrl}) {
    return Take60UserRecordingDraft(
      recordingId: 'rec_1',
      projectId: 'project_1',
      sceneId: 'scene_1',
      userId: 'user_1',
      markerId: 'user_1',
      startSecond: 10,
      endSecond: 20,
      localTempPath: '/tmp/local.mp4',
      uploadedVideoUrl: uploadedVideoUrl,
      durationSeconds: 10,
      status: UserPlanStatus.recorded,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
  }

  group('isTake60RenderableRemoteVideoUrl', () {
    test('rejects local, asset and mock URLs', () {
      expect(
        isTake60RenderableRemoteVideoUrl('assets/scenes/demo.mp4'),
        isFalse,
      );
      expect(
        isTake60RenderableRemoteVideoUrl('/tmp/local.mp4'),
        isFalse,
      );
      expect(
        isTake60RenderableRemoteVideoUrl(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        ),
        isFalse,
      );
    });

    test('accepts remote https URLs', () {
      expect(
        isTake60RenderableRemoteVideoUrl('https://example.com/video.mp4'),
        isTrue,
      );
    });

    test('rejects localhost and private network URLs', () {
      expect(
        isTake60RenderableRemoteVideoUrl('http://localhost:8080/video.mp4'),
        isFalse,
      );
      expect(
        isTake60RenderableRemoteVideoUrl('https://192.168.1.24/video.mp4'),
        isFalse,
      );
      expect(
        isTake60RenderableRemoteVideoUrl('https://10.0.0.1/video.mp4'),
        isFalse,
      );
    });

    test('allows debug mock URL only when explicitly enabled', () {
      const mockUrl =
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
      expect(
        isTake60RenderableRemoteVideoUrl(mockUrl, allowDebugMock: true),
        isTrue,
      );
      expect(
        isTake60RenderableRemoteVideoUrl(mockUrl, allowDebugMock: false),
        isFalse,
      );
    });
  });

  group('validateTake60RenderRequest', () {
    test('rejects missing required user segment', () {
      final scene = buildScene(aiVideoUrl: 'https://example.com/ai.mp4');

      expect(
        () => validateTake60RenderRequest(
          scene: scene,
          markers: scene.markers,
          recordings: const [],
        ),
        throwsA(
          isA<Take60GuidedSceneException>().having(
            (error) => error.code,
            'code',
            'missing-user-segment',
          ),
        ),
      );
    });

    test('rejects mock AI segment URLs outside debug fallback', () {
      final scene = buildScene(
        aiVideoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      );

      expect(
        () => validateTake60RenderRequest(
          scene: scene,
          markers: scene.markers,
          recordings: [
            buildRecording(uploadedVideoUrl: 'https://example.com/user.mp4'),
          ],
        ),
        throwsA(
          isA<Take60GuidedSceneException>().having(
            (error) => error.code,
            'code',
            'invalid-ai-segment',
          ),
        ),
      );
    });

    test('rejects user segments that are not uploaded to storage', () {
      final scene = buildScene(aiVideoUrl: 'https://example.com/ai.mp4');

      expect(
        () => validateTake60RenderRequest(
          scene: scene,
          markers: scene.markers,
          recordings: [buildRecording()],
        ),
        throwsA(
          isA<Take60GuidedSceneException>().having(
            (error) => error.code,
            'code',
            'segment-upload-required',
          ),
        ),
      );
    });

    test('accepts fully uploaded remote segments', () {
      final scene = buildScene(aiVideoUrl: 'https://example.com/ai.mp4');

      expect(
        () => validateTake60RenderRequest(
          scene: scene,
          markers: scene.markers,
          recordings: [
            buildRecording(uploadedVideoUrl: 'https://example.com/user.mp4'),
          ],
        ),
        returnsNormally,
      );
    });

    test('accepts debug mock AI URL when debug override is enabled', () {
      final scene = buildScene(
        aiVideoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      );

      expect(
        () => validateTake60RenderRequest(
          scene: scene,
          markers: scene.markers,
          recordings: [
            buildRecording(uploadedVideoUrl: 'https://example.com/user.mp4'),
          ],
          allowDebugMockAi: true,
        ),
        returnsNormally,
      );
    });

    test('builds storage path under take60_user_recordings project folder', () {
      final path = Take60GuidedSceneService.buildSegmentStoragePath(
        userId: 'user_1',
        projectId: 'project_1',
        markerId: 'marker_a',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1710000000000),
      );

      expect(
        path,
        'take60_user_recordings/user_1/project_1/marker_a_1710000000000.mp4',
      );
    });

    test('builds render project id from user and scene ids', () {
      expect(
        Take60GuidedSceneService.buildProjectId(
          userId: 'user_1',
          sceneId: 'scene_1',
        ),
        'user_1_scene_1',
      );
    });

    test('builds render payload with projectId and sceneId', () {
      final scene = buildScene(aiVideoUrl: 'https://example.com/ai.mp4');
      final payload = Take60GuidedSceneService.buildRenderPayload(
        projectId: 'project_1',
        userId: 'user_1',
        scene: scene,
        markers: scene.markers,
        recordings: [
          buildRecording(uploadedVideoUrl: 'https://example.com/user.mp4'),
        ],
      );

      expect(payload['projectId'], 'project_1');
      expect(payload['sceneId'], 'scene_1');
      expect(payload['userId'], 'user_1');

      final userSegments = payload['userSegments'] as List<dynamic>;
      expect(userSegments, hasLength(1));
      expect(
        (userSegments.first as Map<String, dynamic>)['videoUrl'],
        'https://example.com/user.mp4',
      );

      final markers = payload['markers'] as List<dynamic>;
      final firstMarker = markers.first as Map<String, dynamic>;
      expect(firstMarker['markerId'], 'ai_1');
      expect(firstMarker['source'], 'ai_video');
      expect(firstMarker['startSeconds'], 0);
      expect(firstMarker['endSeconds'], 10);
      expect(firstMarker['audioMode'], 'ai_only');
      expect(firstMarker['character'], isNotEmpty);

      final aiSegments = payload['aiSegments'] as List<dynamic>;
      final firstAi = aiSegments.first as Map<String, dynamic>;
      expect(firstAi['startSeconds'], 0);
      expect(firstAi['endSeconds'], 10);
      expect(firstAi['audioMode'], 'ai_only');

      final firstUser = userSegments.first as Map<String, dynamic>;
      expect(firstUser['source'], 'user_video');
      expect(firstUser['startSeconds'], 10);
      expect(firstUser['endSeconds'], 20);
      expect(firstUser['audioMode'], 'user_voice_with_optional_ai_ambiance');
    });

    test('adds audioBed when scene has a global AI ambience audio URL', () {
      final scene = buildScene(
        aiVideoUrl: 'https://example.com/ai.mp4',
        globalAiAmbianceAudioUrl: 'https://example.com/ambiance.m4a',
      );
      final payload = Take60GuidedSceneService.buildRenderPayload(
        projectId: 'project_1',
        userId: 'user_1',
        scene: scene,
        markers: scene.markers,
        recordings: [
          buildRecording(uploadedVideoUrl: 'https://example.com/user.mp4'),
        ],
      );

      final audioBed = payload['audioBed'] as Map<String, dynamic>;
      expect(audioBed['url'], 'https://example.com/ambiance.m4a');
      expect(audioBed['mode'], 'ai_ambiance_only');
      expect(audioBed['durationSeconds'], 60);
    });

    test('maps audio rules to backend controls', () {
      final rules = const Take60AudioRules(
        hasGlobalAiAmbiance: true,
        keepAiAmbianceDuringUserPlans: true,
        normalizeVolumes: true,
        applyAudioFades: true,
      ).toMap();

      expect(rules['keepAiAmbiance'], isTrue);
      expect(rules['duckUserAudioOverAi'], isTrue);
      expect(rules['normaliseLoudness'], isTrue);
      expect(rules['crossfadeMillis'], greaterThan(0));
    });
  });
}