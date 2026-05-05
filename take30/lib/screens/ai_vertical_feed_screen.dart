import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AiVerticalFeedScreen extends ConsumerStatefulWidget {
  const AiVerticalFeedScreen({super.key});

  @override
  ConsumerState<AiVerticalFeedScreen> createState() => _AiVerticalFeedScreenState();
}

class _AiVerticalFeedScreenState extends ConsumerState<AiVerticalFeedScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  final _controllers = <int, VideoPlayerController>{};
  final _watchStarts = <String, DateTime>{};
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controllers[_currentIndex]?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controllers[_currentIndex]?.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _ensureController(int index, List<PersonalizedFeedItem> items) async {
    if (index < 0 || index >= items.length || _controllers.containsKey(index)) return;
    final url = items[index].scene.videoUrl;
    if (url == null || url.trim().isEmpty) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;
    await controller.initialize();
    controller
      ..setLooping(true)
      ..setVolume(0);
    if (mounted && index == _currentIndex) {
      await controller.play();
      setState(() {});
    }
  }

  void _prepareAround(int index, List<PersonalizedFeedItem> items) {
    unawaited(_ensureController(index, items));
    unawaited(_ensureController(index + 1, items));
    if (index > 0) unawaited(_ensureController(index - 1, items));
    final keep = {index - 1, index, index + 1};
    final toDispose = _controllers.keys.where((key) => !keep.contains(key)).toList();
    for (final key in toDispose) {
      _controllers.remove(key)?.dispose();
    }
  }

  void _onPageChanged(int index, List<PersonalizedFeedItem> items) {
    final previous = items[_currentIndex];
    _recordWatch(previous, FeedEventType.skip);
    _controllers[_currentIndex]?.pause();
    setState(() => _currentIndex = index);
    final item = items[index];
    _watchStarts[item.scene.id] = DateTime.now();
    ref.read(aiVerticalFeedProvider.notifier).recordEvent(
          postId: item.scene.id,
          eventType: FeedEventType.view,
        );
    _prepareAround(index, items);
    _controllers[index]?.play();
  }

  void _recordWatch(PersonalizedFeedItem item, FeedEventType fallbackType) {
    final start = _watchStarts.remove(item.scene.id);
    if (start == null) return;
    final watchTimeMs = DateTime.now().difference(start).inMilliseconds;
    final durationMs = item.scene.durationSeconds * 1000;
    final eventType = watchTimeMs >= durationMs * 0.85
        ? FeedEventType.complete
        : fallbackType;
    ref.read(aiVerticalFeedProvider.notifier).recordEvent(
          postId: item.scene.id,
          eventType: eventType,
          watchTimeMs: watchTimeMs,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiVerticalFeedProvider);
    final items = state.items;
    if (state.isLoading && items.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
      );
    }
    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              state.error ?? 'Aucune vidéo disponible pour le feed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ),
      );
    }
    _watchStarts.putIfAbsent(items[_currentIndex].scene.id, DateTime.now);
    _prepareAround(_currentIndex, items);
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: (index) => _onPageChanged(index, items),
        itemBuilder: (context, index) {
          return _FeedVideoPage(
            item: items[index],
            controller: _controllers[index],
            onLike: () {
              ref.read(feedProvider.notifier).toggleLike(items[index].scene.id);
              ref.read(aiVerticalFeedProvider.notifier).recordEvent(
                    postId: items[index].scene.id,
                    eventType: FeedEventType.like,
                  );
            },
            onShare: () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'Regarde cette scène Take60 : ${items[index].scene.title}',
                ),
              );
              ref.read(aiVerticalFeedProvider.notifier).recordEvent(
                    postId: items[index].scene.id,
                    eventType: FeedEventType.share,
                  );
            },
            onComment: () => context.go(AppRouter.scenePath(items[index].scene.id)),
            onProfile: () => context.go(AppRouter.profilePath(items[index].scene.author.id)),
            onPlayScene: () => context.go(AppRouter.record, extra: items[index].scene),
            onVote: items[index].isBattle && items[index].battleId != null
                ? () => context.go(AppRouter.battlePath(items[index].battleId!))
                : null,
          );
        },
      ),
    );
  }
}

class _FeedVideoPage extends StatelessWidget {
  const _FeedVideoPage({
    required this.item,
    required this.controller,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onProfile,
    required this.onPlayScene,
    this.onVote,
  });

  final PersonalizedFeedItem item;
  final VideoPlayerController? controller;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback onProfile;
  final VoidCallback onPlayScene;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    final scene = item.scene;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller?.value.isInitialized == true)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          )
        else
          _FallbackPoster(scene: scene),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.transparent, Colors.black87],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Chip(label: 'IA ${item.feedScore.toStringAsFixed(0)}'),
                    const SizedBox(width: 8),
                    _Chip(label: scene.category),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.go(AppRouter.home),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onProfile,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UserAvatar(
                                  url: scene.author.avatarUrl,
                                  userId: scene.author.id,
                                  size: 34,
                                  showBorder: true,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '@${scene.author.username}',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: onProfile,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Suivre'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            scene.title,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scene.description.isEmpty ? scene.dialogueText : scene.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: onPlayScene,
                            icon: const Icon(Icons.movie_creation_rounded),
                            label: const Text('Jouer cette scène'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.yellow,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ActionsRail(
                      scene: scene,
                      onLike: onLike,
                      onComment: onComment,
                      onShare: onShare,
                      onVote: onVote,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionsRail extends StatelessWidget {
  const _ActionsRail({
    required this.scene,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onVote,
  });

  final SceneModel scene;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(icon: Icons.favorite_rounded, label: '${scene.likesCount}', onTap: onLike),
        _ActionButton(icon: Icons.mode_comment_rounded, label: '${scene.commentsCount}', onTap: onComment),
        _ActionButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: onShare),
        if (onVote != null) _ActionButton(icon: Icons.how_to_vote_rounded, label: 'Voter', onTap: onVote!),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 5),
            Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _FallbackPoster extends StatelessWidget {
  const _FallbackPoster({required this.scene});

  final SceneModel scene;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (scene.thumbnailUrl.startsWith('http'))
          Image.network(scene.thumbnailUrl, fit: BoxFit.cover)
        else if (scene.thumbnailUrl.startsWith('assets/'))
          Image.asset(scene.thumbnailUrl, fit: BoxFit.cover)
        else
          Container(color: Colors.black),
        const Center(
          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 74),
        ),
      ],
    );
  }
}
