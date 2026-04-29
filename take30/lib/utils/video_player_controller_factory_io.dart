import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController buildVideoPlayerController(String source) {
  final normalized = source.trim();
  if (normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('blob:') ||
      normalized.startsWith('data:')) {
    return VideoPlayerController.networkUrl(Uri.parse(normalized));
  }
  return VideoPlayerController.file(File(normalized));
}