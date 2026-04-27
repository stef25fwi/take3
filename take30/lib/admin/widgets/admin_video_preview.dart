import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AdminVideoPreview extends StatefulWidget {
  const AdminVideoPreview({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;

  @override
  State<AdminVideoPreview> createState() => _AdminVideoPreviewState();
}

class _AdminVideoPreviewState extends State<AdminVideoPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant AdminVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _setupController();
    }
  }

  void _setupController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialization = _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _initialization = null;
    controller?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: const Color(0xFF111827),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<void>(
                future: _initialization,
                builder: (context, snapshot) {
                  final isReady = snapshot.connectionState == ConnectionState.done &&
                      controller != null &&
                      controller.value.isInitialized;
                  if (!isReady) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.thumbnailUrl != null &&
                            widget.thumbnailUrl!.isNotEmpty)
                          Image.network(
                            widget.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1F2937),
                            ),
                          )
                        else
                          Container(color: const Color(0xFF1F2937)),
                        Container(
                          color: Colors.black.withValues(alpha: 0.28),
                        ),
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ],
                    );
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _togglePlayback,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  controller.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.caption != null && widget.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Text(
                  widget.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
