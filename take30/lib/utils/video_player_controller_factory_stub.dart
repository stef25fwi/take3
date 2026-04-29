import 'package:video_player/video_player.dart';

VideoPlayerController buildVideoPlayerController(String source) {
  return VideoPlayerController.networkUrl(Uri.parse(source));
}