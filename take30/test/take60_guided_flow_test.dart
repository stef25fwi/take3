import 'package:flutter_test/flutter_test.dart';
import 'package:take30/models/take60_guided_flow.dart';

void main() {
  group('Take60UserRecordingDraft', () {
    test('roundtrips through toMap/fromMap', () {
      final original = Take60UserRecordingDraft(
        recordingId: 'rec_1',
        projectId: 'project_42',
        sceneId: 'scene_42',
        userId: 'user_abc',
        markerId: 'marker_user_1',
        startSecond: 12,
        endSecond: 19,
        localTempPath: '/tmp/a.mp4',
        storagePath: 'take60_user_recordings/user_abc/project_42/marker_user_1_1.mp4',
        uploadedVideoUrl: 'https://example.com/a.mp4',
        durationSeconds: 7,
        status: UserPlanStatus.recorded,
        createdAt: DateTime(2026, 4, 27, 10),
        updatedAt: DateTime(2026, 4, 27, 11),
      );

      final map = original.toMap();
      final restored = Take60UserRecordingDraft.fromMap(
        Map<String, dynamic>.from(map),
      );

      expect(restored.recordingId, original.recordingId);
  expect(restored.projectId, original.projectId);
      expect(restored.sceneId, original.sceneId);
      expect(restored.markerId, original.markerId);
  expect(restored.startSecond, original.startSecond);
  expect(restored.endSecond, original.endSecond);
      expect(restored.localTempPath, original.localTempPath);
  expect(restored.storagePath, original.storagePath);
      expect(restored.uploadedVideoUrl, original.uploadedVideoUrl);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.status, original.status);
    });

    test('copyWith updates uploadedVideoUrl while preserving identity', () {
      final draft = Take60UserRecordingDraft(
        recordingId: 'rec_1',
        projectId: 'project_1',
        sceneId: 'scene_1',
        userId: 'u',
        markerId: 'm',
        startSecond: 0,
        endSecond: 5,
        localTempPath: '/tmp/a.mp4',
        durationSeconds: 5,
        status: UserPlanStatus.recorded,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = draft.copyWith(
        storagePath: 'take60_user_recordings/u/project_1/m_1.mp4',
        uploadedVideoUrl: 'https://cdn/a.mp4',
        status: UserPlanStatus.recorded,
        updatedAt: DateTime(2026, 1, 2),
      );

      expect(updated.recordingId, 'rec_1');
      expect(updated.storagePath, 'take60_user_recordings/u/project_1/m_1.mp4');
      expect(updated.uploadedVideoUrl, 'https://cdn/a.mp4');
      expect(updated.localTempPath, '/tmp/a.mp4');
      expect(updated.updatedAt, DateTime(2026, 1, 2));
    });
  });

  group('Take60GuidedFlowDraft', () {
    test('roundtrips with nested recordings', () {
      final draft = Take60GuidedFlowDraft(
        sceneId: 'scene_42',
        sceneTitle: 'La rencontre',
        userId: 'user_abc',
        currentMarkerIndex: 2,
        status: SceneRecordingStatus.recordingUserPlan,
        recordings: [
          Take60UserRecordingDraft(
            recordingId: 'rec_1',
            projectId: 'project_42',
            sceneId: 'scene_42',
            userId: 'user_abc',
            markerId: 'marker_user_1',
            startSecond: 15,
            endSecond: 21,
            localTempPath: '/tmp/a.mp4',
            durationSeconds: 6,
            status: UserPlanStatus.recorded,
            createdAt: DateTime(2026, 4, 27, 10),
            updatedAt: DateTime(2026, 4, 27, 10),
          ),
        ],
        updatedAt: DateTime(2026, 4, 27, 12),
      );

      final restored = Take60GuidedFlowDraft.fromMap(
        Map<String, dynamic>.from(draft.toMap()),
      );

      expect(restored.sceneId, 'scene_42');
      expect(restored.sceneTitle, 'La rencontre');
      expect(restored.currentMarkerIndex, 2);
      expect(restored.status, SceneRecordingStatus.recordingUserPlan);
      expect(restored.recordings, hasLength(1));
      expect(restored.recordings.first.markerId, 'marker_user_1');
    });
  });

  group('sceneRecordingStatusFromString', () {
    test('parses known values and falls back to notStarted', () {
      expect(
        sceneRecordingStatusFromString('recording_user_plan'),
        SceneRecordingStatus.recordingUserPlan,
      );
      expect(
        sceneRecordingStatusFromString('published'),
        SceneRecordingStatus.published,
      );
      expect(
        sceneRecordingStatusFromString('unknown_value'),
        SceneRecordingStatus.notStarted,
      );
      expect(
        sceneRecordingStatusFromString(null),
        SceneRecordingStatus.notStarted,
      );
    });
  });

  group('Take60RenderResult', () {
    test('reads failed status from backend status fallback', () {
      final result = Take60RenderResult.fromMap(const {
        'status': 'failed',
        'finalVideoUrl': '',
        'thumbnailUrl': '',
        'durationSeconds': 0,
        'segments': [],
      });

      expect(result.renderStatus, 'failed');
      expect(result.finalVideoUrl, isEmpty);
    });
  });
}
