import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_service.dart';

class Take60VideoPlaybackService {
  Take60VideoPlaybackService(this._api);

  final ApiService _api;

  Future<String> getPlayableUrl(Take60VideoModel video, UserModel? user) async {
    final localResolved = fallbackUrlForVideo(video: video, user: user);
    if (video.id.isEmpty) {
      return localResolved;
    }
    try {
      return await _api.getTake60PlayableUrl(videoId: video.id);
    } catch (_) {
      return localResolved;
    }
  }

  Future<String?> resolveScenePlaybackUrl(
    SceneModel scene, {
    UserModel? user,
  }) async {
    if (scene.take60VideoId?.trim().isNotEmpty == true) {
      try {
        return await _api.getTake60PlayableUrl(videoId: scene.take60VideoId!);
      } catch (_) {
        return fallbackUrlForScene(scene: scene, user: user);
      }
    }
    return fallbackUrlForScene(scene: scene, user: user);
  }

  @visibleForTesting
  static String fallbackUrlForVideo({
    required Take60VideoModel video,
    required UserModel? user,
  }) {
    if (user?.plan == UserPlan.premium) {
      return video.hlsMasterUrl?.trim().isNotEmpty == true
          ? video.hlsMasterUrl!
          : (video.hlsPremiumUrl?.trim().isNotEmpty == true
              ? video.hlsPremiumUrl!
              : (video.hlsBaseUrl ?? ''));
    }
    return video.hlsBaseUrl ?? video.hlsMasterUrl ?? video.hlsPremiumUrl ?? '';
  }

  @visibleForTesting
  static String? fallbackUrlForScene({
    required SceneModel scene,
    required UserModel? user,
  }) {
    if (user?.plan == UserPlan.premium) {
      return scene.hlsMasterUrl?.trim().isNotEmpty == true
          ? scene.hlsMasterUrl
          : (scene.hlsPremiumUrl?.trim().isNotEmpty == true
              ? scene.hlsPremiumUrl
              : scene.hlsBaseUrl ?? scene.videoUrl);
    }
    return scene.hlsBaseUrl ?? scene.videoUrl ?? scene.hlsMasterUrl;
  }
}