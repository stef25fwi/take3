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
  bool _viewTracked = false;

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

  void _trackSceneView(SceneModel scene) {
    if (_viewTracked) {
      return;
    }
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }
    _viewTracked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileActivityHistoryServiceProvider)
          .recordSceneViewed(userId, scene);
    });
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

    _trackSceneView(scene);

    final isLiked = _likedOverride ?? scene.isLiked;
    final likesCount = _likesCountOverride ?? scene.likesCount;
    final commentsCount = isDemoMode ? demoComments.length : scene.commentsCount;
    final isCompact = MediaQuery.sizeOf(context).width < 380;

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
        padding: EdgeInsets.fromLTRB(
          AppThemeTokens.pageHorizontalPadding,
          isCompact ? 6 : 8,
          AppThemeTokens.pageHorizontalPadding,
          isCompact ? 18 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                scene.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppThemeTokens.primaryText(context),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 12 : 16),
            _SceneHeroCard(scene: scene),
            SizedBox(height: isCompact ? 8 : 10),
            _SceneMetaHeader(scene: scene, compact: isCompact),
            SizedBox(height: isCompact ? 8 : 10),
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
            SizedBox(height: isCompact ? 10 : 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: isCompact ? 6 : 8,
              mainAxisSpacing: isCompact ? 6 : 8,
              childAspectRatio: isCompact ? 2.15 : 1.95,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                const _StatBox(
                  value: '4.8',
                  label: 'note',
                  icon: Icons.workspace_premium_rounded,
                  accentColor: Color(0xFFFFB84D),
                  compact: false,
                ),
                _StatBox(
                  value: '${scene.viewsCount}',
                  label: 'vues',
                  icon: Icons.visibility_rounded,
                  accentColor: const Color(0xFF79B8FF),
                  compact: isCompact,
                ),
                _StatBox(
                  value: '$commentsCount',
                  label: 'commentaires',
                  icon: Icons.forum_rounded,
                  accentColor: const Color(0xFF5ED0B0),
                  compact: isCompact,
                ),
                _StatBox(
                  value: '$likesCount',
                  label: 'likes',
                  icon: Icons.favorite_rounded,
                  accentColor: const Color(0xFFFF7D8F),
                  compact: isCompact,
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 12),
            _SceneDescriptionCard(
              description: scene.description.isNotEmpty
                  ? scene.description
                  : 'Une exploration chaleureuse des textures, du rythme et des petits gestes qui font vivre cette scene.',
              compact: isCompact,
            ),
            SizedBox(height: isCompact ? 12 : 14),
            Row(
              children: [
                Expanded(
                  child: _SceneActionButton(
                    label: isLiked ? 'Liké' : 'Liker',
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    accentColor: const Color(0xFFFF7D8F),
                    onTap: () => _toggleLike(scene),
                    filled: false,
                    compact: isCompact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SceneActionButton(
                    label: 'Commenter',
                    icon: Icons.mode_comment_outlined,
                    accentColor: const Color(0xFF5ED0B0),
                    onTap: _openComments,
                    filled: true,
                    compact: isCompact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SceneActionButton(
                    label: 'Partager',
                    icon: Icons.ios_share_rounded,
                    accentColor: const Color(0xFF79B8FF),
                    onTap: () => ref.read(shareServiceProvider).shareScene(scene),
                    filled: false,
                    compact: isCompact,
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

class _SceneHeroCard extends StatelessWidget {
  const _SceneHeroCard({required this.scene});

  final SceneModel scene;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: isCompact ? 220 : 244,
              child: _SceneThumbnail(imageUrl: scene.thumbnailUrl),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.62),
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: isCompact ? 12 : 14,
              left: isCompact ? 12 : 14,
              right: isCompact ? 12 : 14,
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroMetaChip(
                              icon: Icons.auto_awesome_rounded,
                              label: scene.category,
                              accentColor: const Color(0xFFFFB84D),
                              compact: true,
                            ),
                            _HeroMetaChip(
                              icon: Icons.schedule_rounded,
                              label: scene.durationFormatted,
                              accentColor: const Color(0xFF79B8FF),
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _HeroMetaChip(
                            icon: Icons.visibility_rounded,
                            label: _formatSceneMetric(scene.viewsCount),
                            accentColor: const Color(0xFF5ED0B0),
                            compact: true,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _HeroMetaChip(
                          icon: Icons.auto_awesome_rounded,
                          label: scene.category,
                          accentColor: const Color(0xFFFFB84D),
                        ),
                        const SizedBox(width: 8),
                        _HeroMetaChip(
                          icon: Icons.schedule_rounded,
                          label: scene.durationFormatted,
                          accentColor: const Color(0xFF79B8FF),
                        ),
                        const Spacer(),
                        _HeroMetaChip(
                          icon: Icons.visibility_rounded,
                          label: _formatSceneMetric(scene.viewsCount),
                          accentColor: const Color(0xFF5ED0B0),
                        ),
                      ],
                    ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: isCompact ? 72 : 84,
                  height: isCompact ? 72 : 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: isCompact ? 54 : 62,
                      height: isCompact ? 54 : 62,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD36E),
                            Color(0xFFFF8A5B),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: isCompact ? 28 : 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: isCompact ? 12 : 16,
              right: isCompact ? 12 : 16,
              bottom: isCompact ? 12 : 14,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selection Take 60',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: isCompact ? 11 : 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        SizedBox(height: isCompact ? 2 : 4),
                        Text(
                          scene.author.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 10 : 12,
                      vertical: isCompact ? 7 : 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFFA1B0),
                          size: 15,
                        ),
                        SizedBox(width: isCompact ? 4 : 6),
                        Text(
                          _formatSceneMetric(scene.likesCount),
                          style: GoogleFonts.dmSans(
                            fontSize: isCompact ? 11 : 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: accentColor),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatSceneMetric(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

class _SceneMetaHeader extends StatelessWidget {
  const _SceneMetaHeader({required this.scene, this.compact = false});

  final SceneModel scene;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final accent = Theme.of(context).colorScheme.primary;
    final initials = scene.author.displayName.trim().isEmpty
        ? 'T'
        : scene.author.displayName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part.characters.first.toUpperCase())
            .join();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppThemeTokens.surfaceMuted(context),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.85),
                  const Color(0xFF5ED0B0),
                ],
              ),
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.dmSans(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  'Createur • ${scene.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 10,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: compact ? 13 : 14,
                  color: accent,
                ),
                SizedBox(width: compact ? 5 : 6),
                Text(
                  scene.durationFormatted,
                  style: GoogleFonts.dmSans(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneDescriptionCard extends StatelessWidget {
  const _SceneDescriptionCard({
    required this.description,
    this.compact = false,
  });

  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: compact ? 16 : 18,
                  color: accent,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.dmSans(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      'Intentions, ambiance et direction de jeu',
                      style: GoogleFonts.dmSans(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            description,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 12 : 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.compact = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppThemeTokens.surfaceMuted(context),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
              border: Border.all(color: accentColor.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: accentColor),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: compact ? 1 : 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneActionButton extends StatelessWidget {
  const _SceneActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    required this.filled,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final backgroundColor = filled
        ? accentColor.withValues(alpha: 0.16)
        : AppThemeTokens.surface(context);
    final borderColor = filled
        ? accentColor.withValues(alpha: 0.28)
        : AppThemeTokens.border(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 110;
            final height = isNarrow ? 46.0 : (compact ? 48.0 : 52.0);
            final horizontalPadding = isNarrow ? 8.0 : (compact ? 10.0 : 12.0);
            final iconBoxSize = isNarrow ? 24.0 : (compact ? 28.0 : 30.0);
            final iconSize = isNarrow ? 14.0 : (compact ? 15.0 : 16.0);
            final gap = isNarrow ? 6.0 : (compact ? 8.0 : 10.0);
            final fontSize = isNarrow ? 12.0 : (compact ? 13.0 : 14.0);

            return Ink(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: filled ? 0.12 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: filled ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: accentColor,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: GoogleFonts.dmSans(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: filled ? accentColor : primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
