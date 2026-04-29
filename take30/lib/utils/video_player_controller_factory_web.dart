import 'package:video_player/video_player.dart';

VideoPlayerController buildVideoPlayerController(String source) {
  final normalized = source.trim();
  final uri = normalized.startsWith('http://') ||
          normalized.startsWith('https://') ||
          normalized.startsWith('blob:') ||
          normalized.startsWith('data:')
      ? Uri.parse(normalized)
      : Uri.parse(normalized);
  return VideoPlayerController.networkUrl(uri);
}