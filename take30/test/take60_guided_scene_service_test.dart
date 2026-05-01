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

  SceneModel buildScene({required String? aiVideoUrl}) {
    return SceneModel(
      id: 'scene_1',
      title: 'Scene test',
      category: 'Drame',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      videoUrl: aiVideoUrl,
      author: author,
      createdAt: DateTime(2026, 5, 1),
      adminWorkflow: true,
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
      sceneId: 'scene_1',
      userId: 'user_1',
      markerId: 'user_1',
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
  });

  group('validateTake60RenderRequest', () {
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
  });
}