import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class SceneDetailScreen extends ConsumerStatefulWidget {
  const SceneDetailScreen({
    super.key,
    required this.sceneId,
    this.scene,
  });

  final String sceneId;
  final SceneModel? scene;

  @override
  ConsumerState<SceneDetailScreen> createState() => _SceneDetailScreenState();
}

class _SceneDetailScreenState extends ConsumerState<SceneDetailScreen> {
  bool? _likedOverride;
  int? _likesCountOverride;

  bool _isDemoUser(UserModel? user) {
    if (user == null) {
      return false;
    }

    return user.username == 'demo_take30' ||
        user.displayName == 'Mode Demo' ||
        user.email == 'demo@take30.app';
  }

  @override
  void initState() {
    super.initState();
    if (widget.scene != null) {
      _likedOverride = widget.scene!.isLiked;
      _likesCountOverride = widget.scene!.likesCount;
    }
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.explore);
    }
  }

  Future<void> _toggleLike(SceneModel scene) async {
    final currentLiked = _likedOverride ?? scene.isLiked;
    final currentCount = _likesCountOverride ?? scene.likesCount;
    final nextLiked = !currentLiked;
    setState(() {
      _likedOverride = nextLiked;
      _likesCountOverride = nextLiked ? currentCount + 1 : currentCount - 1;
    });
    if (_isDemoUser(ref.read(authProvider).user)) {
      ref.read(demoSceneInteractionsStoreProvider).toggleLike(
        scene,
        ref.read(demoSceneCommentsProvider(scene.id)),
      );
      return;
    }
    await ref.read(apiServiceProvider).likeScene(scene.id);
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _CommentsSheet(sceneId: widget.sceneId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final isDemoMode = _isDemoUser(authUser);
    final sceneAsync = ref.watch(sceneProvider(widget.sceneId));
    final demoComments = isDemoMode
        ? ref.watch(demoSceneCommentsProvider(widget.sceneId))
        : const <CommentModel>[];
    final scene = sceneAsync.value ?? widget.scene;
    if (scene == null) {
      return Scaffold(
        backgroundColor: AppThemeTokens.pageBackground(context),
        appBar: AppBar(
          backgroundColor: AppThemeTokens.pageBackground(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppThemeTokens.primaryText(context),
              size: 20,
            ),
            onPressed: _onBack,
          ),
        ),
        body: sceneAsync.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.yellow),
              )
            : Center(
                child: Text(
                  'Scène introuvable',
                  style: TextStyle(color: AppThemeTokens.primaryText(context)),
                ),
              ),
      );
    }

    final isLiked = _likedOverride ?? scene.isLiked;
    final likesCount = _likesCountOverride ?? scene.likesCount;
    final commentsCount = isDemoMode ? demoComments.length : scene.commentsCount;

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      appBar: AppBar(
        backgroundColor: AppThemeTokens.pageBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppThemeTokens.primaryText(context),
            size: 20,
          ),
          onPressed: _onBack,
        ),
        title: Text(
          'Détail scène',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppThemeTokens.primaryText(context),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => ref.read(shareServiceProvider).shareScene(scene),
            icon: Icon(
              Icons.ios_share_rounded,
              color: AppThemeTokens.primaryText(context),
              size: 20,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppThemeTokens.pageHorizontalPadding,
          8,
          AppThemeTokens.pageHorizontalPadding,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: _SceneThumbnail(imageUrl: scene.thumbnailUrl),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_fill, color: AppColors.white, size: 62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              scene.title,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppThemeTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'par ${scene.author.displayName} • ${scene.category} • ${scene.durationFormatted}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in scene.tags.take(3))
                  _TagChip(label: tag, color: AppColors.yellow),
                if (scene.tags.isEmpty) ...const [
                  _TagChip(label: 'Take 60', color: AppColors.yellow),
                ],
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.55,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                const _StatBox(value: '4.8⭐', label: 'note'),
                _StatBox(value: '${scene.viewsCount}👁️', label: 'vues'),
                _StatBox(value: '$commentsCount💬', label: 'commentaires'),
                _StatBox(value: '$likesCount❤️', label: 'likes'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppThemeTokens.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppThemeTokens.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Une exploration chaleureuse des textures, du rythme et des petits gestes qui font vivre cette scene.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _toggleLike(scene),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isLiked ? AppColors.red : AppColors.borderSubtle,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isLiked ? 'Liké' : 'Liker',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isLiked
                            ? AppColors.red
                            : AppThemeTokens.primaryText(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openComments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Commenter',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(shareServiceProvider).shareScene(scene),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppThemeTokens.border(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Partager',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppThemeTokens.primaryText(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeTokens.surfaceMuted(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppThemeTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneThumbnail extends StatelessWidget {
  const _SceneThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceCard),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceCard),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.sceneId});

  final String sceneId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController _ctrl = TextEditingController();
  bool _isSubmitting = false;

  bool _isDemoUser(UserModel? user) {
    if (user == null) {
      return false;
    }

    return user.username == 'demo_take30' ||
        user.displayName == 'Mode Demo' ||
        user.email == 'demo@take30.app';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_isDemoUser(user)) {
      final scene = ref.read(sceneProvider(widget.sceneId)).value;
      if (scene != null) {
        ref.read(demoSceneInteractionsStoreProvider).addComment(
          scene,
          user,
          text,
          ref.read(demoSceneCommentsProvider(widget.sceneId)),
        );
      }
      _ctrl.clear();
      return;
    }

    setState(() => _isSubmitting = true);
    await ref.read(apiServiceProvider).comments.add(
          sceneId: widget.sceneId,
          author: user,
          text: text,
        );
    _ctrl.clear();
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final isDemoMode = _isDemoUser(authUser);
    final commentsAsync = isDemoMode
        ? AsyncValue.data(ref.watch(demoSceneCommentsProvider(widget.sceneId)))
        : ref.watch(sceneCommentsProvider(widget.sceneId));
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Commentaires',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Sois le premier à commenter cette scène.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final c = comments[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppThemeTokens.surfaceMuted(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppThemeTokens.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.authorDenorm.username,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cyan,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.text,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppThemeTokens.primaryText(context),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  ),
                  error: (_, __) => Text(
                    'Impossible de charger les commentaires.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: GoogleFonts.dmSans(
                        color: AppThemeTokens.primaryText(context),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ecris un commentaire...",
                        hintStyle: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppThemeTokens.surfaceMuted(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppThemeTokens.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppThemeTokens.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cyan),
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cyan,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: AppColors.cyan),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
