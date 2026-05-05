import 'package:flutter_test/flutter_test.dart';

import 'package:take30/models/models.dart';
import 'package:take30/services/take60_video_service.dart';

void main() {
  test('free plan resolves 720p video URL first', () {
    final video = Take60VideoModel(
      id: '',
      ownerId: 'user_1',
      status: 'ready',
      qualityBase: '720p',
      premiumQuality: '1080p',
      isPremiumLocked: true,
      durationSec: 60,
      createdAt: DateTime(2026, 5, 5),
      hlsBaseUrl: 'https://cdn.example.com/720p.m3u8',
      hlsPremiumUrl: 'https://cdn.example.com/1080p.m3u8',
      hlsMasterUrl: 'https://cdn.example.com/master.m3u8',
    );

    const user = UserModel(
      id: 'user_1',
      username: 'luna',
      displayName: 'Luna',
      avatarUrl: '',
      plan: UserPlan.free,
    );

    expect(
      Take60VideoPlaybackService.fallbackUrlForVideo(video: video, user: user),
      'https://cdn.example.com/720p.m3u8',
    );
  });

  test('premium plan resolves master scene URL first', () {
    const user = UserModel(
      id: 'user_2',
      username: 'leo',
      displayName: 'Leo',
      avatarUrl: '',
      plan: UserPlan.premium,
    );

    final scene = SceneModel(
      id: 'scene_1',
      title: 'Interrogatoire',
      category: 'Drama',
      thumbnailUrl: '',
      videoUrl: 'https://cdn.example.com/raw.mp4',
      hlsBaseUrl: 'https://cdn.example.com/720p.m3u8',
      hlsPremiumUrl: 'https://cdn.example.com/1080p.m3u8',
      hlsMasterUrl: 'https://cdn.example.com/master.m3u8',
      author: user,
      createdAt: DateTime(2026, 5, 5),
      take60VideoId: 'video_1',
      isPremiumLocked: true,
    );

    expect(
      Take60VideoPlaybackService.fallbackUrlForScene(scene: scene, user: user),
      'https://cdn.example.com/master.m3u8',
    );
  });
}