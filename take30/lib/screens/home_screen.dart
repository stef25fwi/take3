import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/battle_providers.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/battle/battle_preparing_card.dart';
import '../widgets/battle/battle_published_card.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/take60_greeting_hero_card.dart';
import '../widgets/take30_logo.dart';
import '../widgets/take60_hero_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final authState = ref.watch(authProvider);
    final currentUser = ref.watch(authProvider).user ??
        const UserModel(
          id: 'anonymous',
          username: 'guest',
          displayName: 'Créateur',
          avatarUrl: '',
        );
    final scenes = feedState.scenes;
    final featuredScenes = scenes.take(3).toList();

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemeTokens.pageGradient(context),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -72,
              left: -48,
              child: _AmbientGlow(
                size: 220,
                color: Color.fromRGBO(108, 92, 231, 0.12),
              ),
            ),
            const Positioned(
              top: 96,
              right: -46,
              child: _AmbientGlow(
                size: 200,
                color: Color.fromRGBO(255, 184, 0, 0.08),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppThemeTokens.pageHorizontalPadding,
                  12,
                  AppThemeTokens.pageHorizontalPadding,
                  110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(
                      unreadCount: unreadCount,
                      canOpenAdmin: authState.user?.isAdmin ?? false,
                      onAdminTap: () => context.push(AppRouter.admin),
                      onLeaderboardTap: () => context.go(AppRouter.leaderboard),
                      onNotificationsTap: () => context.go(AppRouter.notifications),
                    ),
                    const SizedBox(height: 10),
                    Take60CinematicHero(
                      onNewVideoTap: () => context.go(AppRouter.record),
                      onChallengeTap: () => context.go(AppRouter.challenge),
                    ),
                    const SizedBox(height: 12),
                    Take60GreetingHeroCard(
                      user: currentUser,
                      scenesValue: '${currentUser.scenesCount}',
                      likesValue: _formatCompact(currentUser.likesCount),
                      onPrimaryTap: () => context.go(AppRouter.aiFeed),
                      onSecondaryTap: () => context.go(AppRouter.challenge),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle('À la une'),
                    const SizedBox(height: 8),
                    if (feedState.isLoading)
                      const _LoadingPanel()
                    else if (featuredScenes.isEmpty)
                      const _EmptyPanel(
                        title: 'Aucune scène publiée',
                        subtitle: 'Seed Firestore ou publie ta première vidéo pour remplir l’accueil.',
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            for (var index = 0; index < featuredScenes.length; index++) ...[
                              _FeaturedTakeCard(
                                scene: featuredScenes[index],
                                onTap: () => context.go(
                                  AppRouter.scenePath(featuredScenes[index].id),
                                ),
                              ),
                              if (index != featuredScenes.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    _BattleSection(
                      onSeeAll: () => context.go(AppRouter.battles),
                      onVoteNow: () => context.go(AppRouter.battles),
                    ),
                    const SizedBox(height: 12),
                    _LiveTrendingSection(
                      onSeeAll: () => context.go(AppRouter.battleLeaderboard),
                      onOpenTrend: () => context.go(AppRouter.aiFeed),
                    ),
                    const SizedBox(height: 12),
                    const _SectionTitle('Mes candidats suivis'),
                    const SizedBox(height: 8),
                    _HomeBattleStrip(
                      battlesState: ref.watch(followedCandidatesBattlesProvider),
                      preferPublishedCard: true,
                    ),
                    if (feedState.error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorPanel(message: feedState.error!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBattleStrip extends StatelessWidget {
  const _HomeBattleStrip({
    required this.battlesState,
    this.preferPublishedCard = false,
  });

  final AsyncValue<List<BattleModel>> battlesState;
  final bool preferPublishedCard;

  @override
  Widget build(BuildContext context) {
    return battlesState.when(
      loading: () => const _LoadingPanel(),
      error: (_, __) => const _EmptyPanel(
        title: 'Battles indisponibles',
        subtitle: 'Les duels Take60 réapparaîtront automatiquement.',
      ),
      data: (battles) {
        if (battles.isEmpty) {
          return const _EmptyPanel(
            title: 'Aucune Battle pour le moment',
            subtitle: 'Défie ce candidat sur une scène Take60 de niveau équivalent.',
          );
        }
        final visible = battles.take(4).toList();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var index = 0; index < visible.length; index++) ...[
                SizedBox(
                  width: 330,
                  child: preferPublishedCard || visible[index].isPublished
                      ? BattlePublishedCard(
                          battle: visible[index],
                          onTap: () => context.go(AppRouter.battlePath(visible[index].id)),
                          onTapChallenger: () => context.go(AppRouter.profilePath(visible[index].challengerId)),
                          onTapOpponent: () => context.go(AppRouter.profilePath(visible[index].opponentId)),
                        )
                      : BattlePreparingCard(
                          battle: visible[index],
                          onTap: () => context.go(AppRouter.battlePath(visible[index].id)),
                          onTapChallenger: () => context.go(AppRouter.profilePath(visible[index].challengerId)),
                          onTapOpponent: () => context.go(AppRouter.profilePath(visible[index].opponentId)),
                        ),
                ),
                if (index != visible.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.unreadCount,
    required this.canOpenAdmin,
    required this.onAdminTap,
    required this.onLeaderboardTap,
    required this.onNotificationsTap,
  });

  final int unreadCount;
  final bool canOpenAdmin;
  final VoidCallback onAdminTap;
  final VoidCallback onLeaderboardTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          height: 46,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Take30Logo(height: 46),
          ),
        ),
        Row(
          children: [
            if (canOpenAdmin) ...[
              GestureDetector(
                onTap: onAdminTap,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppThemeTokens.softAction(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppThemeTokens.softBorder(context),
                    ),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppThemeTokens.primaryText(context),
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            GestureDetector(
              onTap: onLeaderboardTap,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppThemeTokens.softAction(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppThemeTokens.softBorder(context),
                  ),
                ),
                child: Icon(
                  Icons.leaderboard_outlined,
                  color: AppThemeTokens.primaryText(context),
                  size: 21,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
            GestureDetector(
              onTap: onNotificationsTap,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppThemeTokens.softAction(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppThemeTokens.softBorder(context),
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppThemeTokens.primaryText(context),
                  size: 22,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -1,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C6C),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF0B1020), width: 1.4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppThemeTokens.primaryText(context),
        letterSpacing: -0.35,
      ),
    );
  }
}

class _LiveTrendingSection extends StatelessWidget {
  const _LiveTrendingSection({
    required this.onSeeAll,
    required this.onOpenTrend,
  });

  final VoidCallback onSeeAll;
  final VoidCallback onOpenTrend;

  static const _items = [
    _LiveTrendData(
      rank: 1,
      title: 'Interrogatoire',
      subtitle: 'Police Station',
      duelsLabel: '2.4K',
      duelsValue: 2400,
      badgeColor: Color(0xFFFBBF24),
      badgeTextColor: Color(0xFF000000),
      borderColor: Color(0xFFF59E0B),
      progressStart: Color(0xFFFBBF24),
      progressEnd: Color(0xFFD97706),
      imageAsset: 'assets/scenes/battle_player_a.png',
    ),
    _LiveTrendData(
      rank: 2,
      title: 'Trahison',
      subtitle: 'Entre amis',
      duelsLabel: '1.8K',
      duelsValue: 1800,
      badgeColor: Color(0xFF3B82F6),
      badgeTextColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFF3B82F6),
      progressStart: Color(0xFF60A5FA),
      progressEnd: Color(0xFF2563EB),
      imageAsset: 'assets/scenes/battle_player_b.png',
    ),
    _LiveTrendData(
      rank: 3,
      title: 'Dernière chance',
      subtitle: 'Avant le départ',
      duelsLabel: '1.2K',
      duelsValue: 1200,
      badgeColor: Color(0xFFF97316),
      badgeTextColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFFF97316),
      progressStart: Color(0xFFFB923C),
      progressEnd: Color(0xFFEA580C),
      imageAsset: 'assets/scenes/battle_player_a.png',
    ),
    _LiveTrendData(
      rank: 4,
      title: 'Règlements',
      subtitle: 'de comptes',
      duelsLabel: '998',
      duelsValue: 998,
      badgeColor: Color(0xFFEF4444),
      badgeTextColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFFEF4444),
      progressStart: Color(0xFFF87171),
      progressEnd: Color(0xFFDC2626),
      imageAsset: 'assets/scenes/battle_player_b.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final compact = outerConstraints.maxWidth < 600;
        final medium = outerConstraints.maxWidth < 1024;
        final sectionPadding = compact ? 10.0 : (medium ? 12.0 : 14.0);
        final isDark = AppThemeTokens.isDark(context);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(sectionPadding),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF000000).withValues(alpha: 0.92)
                : const Color(0xFFF7F8FC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFDCE2EE),
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.06),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveTrendingHeader(onSeeAll: onSeeAll),
              SizedBox(height: compact ? 12 : 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final visibleTiles = width < 600 ? 3 : 8;
                  final gap = width < 600 ? 8.0 : 6.0;
                  final cardWidth =
                      (width - (gap * (visibleTiles - 1))) / visibleTiles;
                  final cardHeight = width < 600 ? 196.0 : 208.0;
                  const compactCards = true;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var index = 0; index < _items.length; index++) ...[
                          SizedBox(
                            width: cardWidth,
                            child: _LiveTrendCard(
                              data: _items[index],
                              maxDuels: 2400,
                              height: cardHeight,
                              compact: compactCards,
                              onTap: onOpenTrend,
                            ),
                          ),
                          if (index != _items.length - 1)
                            SizedBox(width: gap),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveTrendingHeader extends StatelessWidget {
  const _LiveTrendingHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Tendances Live',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Voir toutes les tendances live',
          child: InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir tout',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: primaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

class _LiveTrendCard extends StatefulWidget {
  const _LiveTrendCard({
    required this.data,
    required this.maxDuels,
    required this.height,
    required this.compact,
    required this.onTap,
  });

  final _LiveTrendData data;
  final int maxDuels;
  final double height;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_LiveTrendCard> createState() => _LiveTrendCardState();
}

class _LiveTrendCardState extends State<_LiveTrendCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final progress = (data.duelsValue / widget.maxDuels).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: 'Tendance live ${data.rank}, ${data.title}, ${data.duelsLabel} duels',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedOpacity(
            opacity: _hovered ? 0.9 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: Container(
              height: widget.height,
              padding: const EdgeInsets.all(1.2),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: _hovered ? 0.34 : 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
                    blurRadius: 18,
                    spreadRadius: 0.5,
                  ),
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      data.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              data.borderColor.withValues(alpha: 0.55),
                              const Color(0xFF000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF000000).withValues(alpha: 0.4),
                            const Color(0xFF000000).withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _LiveTrendRankBadge(
                        data: data,
                        compact: widget.compact,
                      ),
                    ),
                    Center(child: _LiveTrendPlayButton(accent: data.borderColor)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _LiveTrendBottomContent(
                        data: data,
                        progress: progress,
                        compact: widget.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveTrendRankBadge extends StatelessWidget {
  const _LiveTrendRankBadge({required this.data, required this.compact});

  final _LiveTrendData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _PennantClipper(),
      child: Container(
        width: compact ? 44 : 52,
        height: compact ? 54 : 64,
        padding: EdgeInsets.only(bottom: compact ? 7 : 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(Colors.white.withValues(alpha: 0.22), data.badgeColor),
              data.badgeColor,
              data.borderColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: data.badgeColor.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.18),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: compact ? 22 : 26,
          height: compact ? 22 : 26,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.16),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${data.rank}',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: data.badgeColor,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _PennantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - (size.width * 0.34))
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height - (size.width * 0.34))
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LiveTrendPlayButton extends StatefulWidget {
  const _LiveTrendPlayButton({required this.accent});

  final Color accent;

  @override
  State<_LiveTrendPlayButton> createState() => _LiveTrendPlayButtonState();
}

class _LiveTrendPlayButtonState extends State<_LiveTrendPlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, _hovered ? 0.46 : 0.34),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.18),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: _hovered ? 0.26 : 0.18),
          ),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: Color(0xFFFFFFFF),
          shadows: [
            Shadow(
              color: Color.fromRGBO(0, 0, 0, 0.35),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrendBottomContent extends StatelessWidget {
  const _LiveTrendBottomContent({
    required this.data,
    required this.progress,
    required this.compact,
  });

  final _LiveTrendData data;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF000000),
            Color(0xCC000000),
            Color(0x00000000),
          ],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 14 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFFFFF),
              height: 1.25,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 11.5 : 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD1D5DB),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Color(0xFFF97316),
              ),
              const SizedBox(width: 8),
              Text(
                '${data.duelsLabel} duels',
                style: GoogleFonts.dmSans(
                  fontSize: compact ? 11.5 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              height: 6,
              color: const Color(0xFF374151),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFACC15),
                        Color(0xFFF97316),
                        Color(0xFFEF4444),
                        Color(0xFFFF2DF1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTrendData {
  const _LiveTrendData({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.duelsLabel,
    required this.duelsValue,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.borderColor,
    required this.progressStart,
    required this.progressEnd,
    required this.imageAsset,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String duelsLabel;
  final int duelsValue;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color borderColor;
  final Color progressStart;
  final Color progressEnd;
  final String imageAsset;
}

class _BattleSection extends StatelessWidget {
  const _BattleSection({
    required this.onSeeAll,
    required this.onVoteNow,
  });

  final VoidCallback onSeeAll;
  final VoidCallback onVoteNow;

  @override
  Widget build(BuildContext context) {
    return _BattleCard(
      onSeeAll: onSeeAll,
      onVoteNow: onVoteNow,
    );
  }
}

class _BattleCard extends StatefulWidget {
  const _BattleCard({
    required this.onSeeAll,
    required this.onVoteNow,
  });

  final VoidCallback onSeeAll;
  final VoidCallback onVoteNow;

  @override
  State<_BattleCard> createState() => _BattleCardState();
}

class _BattleCardState extends State<_BattleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final cardHeight = width < 640 ? 292.0 : (width < 1024 ? 316.0 : 340.0);
    const cardRadius = 16.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0094FF).withValues(alpha: 0.18 + (pulse * 0.12)),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFFFF4B2B).withValues(alpha: 0.16 + (pulse * 0.14)),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/IMG_1467.png',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: -28,
                  top: 16,
                  child: _BattleAura(
                    color: const Color(0xFF0094FF).withValues(alpha: 0.22 + (pulse * 0.12)),
                    size: compact ? 118 : 132,
                  ),
                ),
                Positioned(
                  right: -30,
                  top: 18,
                  child: _BattleAura(
                    color: const Color(0xFFFF7A1A).withValues(alpha: 0.20 + (pulse * 0.14)),
                    size: compact ? 118 : 132,
                  ),
                ),
                const Positioned.fill(child: _BattleGrain()),
                Positioned(
                  left: compact ? 16 : 24,
                  top: compact ? 56 : 58,
                  child: _BattlePlayer(
                    avatarAsset: 'assets/scenes/battle_player_a.png',
                    name: 'Luna Scene',
                    badge: 'Actrice',
                    score: '62%',
                    likes: '1.2K',
                    accent: const Color(0xFF0094FF),
                    scoreColor: const Color(0xFF2F9BFF),
                    compact: compact,
                    alignRight: false,
                  ),
                ),
                Positioned(
                  right: compact ? 16 : 24,
                  top: compact ? 56 : 58,
                  child: _BattlePlayer(
                    avatarAsset: 'assets/scenes/battle_player_b.png',
                    name: 'Max Shot',
                    badge: 'Acteur',
                    score: '38%',
                    likes: '983',
                    accent: const Color(0xFFFF7A1A),
                    scoreColor: const Color(0xFFFF5A36),
                    compact: compact,
                    alignRight: true,
                  ),
                ),
                Positioned(
                  left: compact ? 16 : 24,
                  right: compact ? 16 : 24,
                  bottom: compact ? 12 : 16,
                  child: _VsCenter(
                    compact: compact,
                    pulse: pulse,
                    onVoteNow: widget.onVoteNow,
                  ),
                ),
                Positioned(
                  left: compact ? 14 : 18,
                  right: compact ? 14 : 18,
                  top: compact ? 12 : 14,
                  child: _BattleCardHeader(onSeeAll: widget.onSeeAll),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BattleCardHeader extends StatelessWidget {
  const _BattleCardHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.28),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Text(
                'Hot Battles en cours',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.25,
                  shadows: const [
                    Shadow(
                      color: Color.fromRGBO(0, 0, 0, 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Voir toutes les hot battles en cours',
          child: InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir tout',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BattlePlayer extends StatelessWidget {
  const _BattlePlayer({
    required this.avatarAsset,
    required this.name,
    required this.badge,
    required this.score,
    required this.likes,
    required this.accent,
    required this.scoreColor,
    required this.compact,
    required this.alignRight,
  });

  final String avatarAsset;
  final String name;
  final String badge;
  final String score;
  final String likes;
  final Color accent;
  final Color scoreColor;
  final bool compact;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 58.0 : 76.0;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;
    final crossAxis = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return SizedBox(
      width: compact ? 96 : 132,
      child: Column(
        crossAxisAlignment: crossAxis,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.32),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(avatarAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          _BattleOutlinedName(
            name: name,
            textAlign: textAlign,
            fontSize: compact ? 14 : 18,
            outlineColor: scoreColor,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              badge,
              style: GoogleFonts.dmSans(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score,
            textAlign: textAlign,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 26 : 32,
              fontWeight: FontWeight.w800,
              color: scoreColor,
              height: 1,
            ),
          ),
          SizedBox(height: compact ? 34 : 38),
          Text(
            likes,
            textAlign: textAlign,
            style: GoogleFonts.dmSans(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleOutlinedName extends StatelessWidget {
  const _BattleOutlinedName({
    required this.name,
    required this.textAlign,
    required this.fontSize,
    required this.outlineColor,
  });

  final String name;
  final TextAlign textAlign;
  final double fontSize;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    final strokeStyle = GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = outlineColor.withValues(alpha: 0.95),
    );

    final fillStyle = GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: strokeStyle,
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: fillStyle,
        ),
      ],
    );
  }
}

class _VsCenter extends StatelessWidget {
  const _VsCenter({
    required this.compact,
    required this.pulse,
    required this.onVoteNow,
  });

  final bool compact;
  final double pulse;
  final VoidCallback onVoteNow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Fin dans 02:45:18',
            style: GoogleFonts.dmSans(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.95),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.85),
                  blurRadius: 18,
                  offset: Offset(0, 0),
                ),
                Shadow(
                  color: Color.fromRGBO(0, 0, 0, 0.6),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _VoteButton(onTap: onVoteNow, compact: compact, pulse: pulse),
        ],
      ),
    );
  }
}

class _VoteButton extends StatefulWidget {
  const _VoteButton({
    required this.onTap,
    required this.compact,
    required this.pulse,
  });

  final VoidCallback onTap;
  final bool compact;
  final double pulse;

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const height = 40.0;
    final width = widget.compact ? 138.0 : 168.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE066),
                  Color(0xFFFFC940),
                  Color(0xFFFFA31A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC940)
                      .withValues(alpha: 0.45 + (widget.pulse * 0.18)),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFFA31A).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment(-1 + (_controller.value * 2), 0),
                    child: Container(
                      width: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.24),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(255, 255, 255, 0.35),
                          blurRadius: 0,
                          offset: Offset(0, -1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Voter maintenant',
                      style: GoogleFonts.dmSans(
                        fontSize: widget.compact ? 13 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111111),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BattleAura extends StatelessWidget {
  const _BattleAura({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.45,
              spreadRadius: size * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleGrain extends StatelessWidget {
  const _BattleGrain();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BattleGrainPainter(),
    );
  }
}

class _BattleGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grainPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.035);
    final particlesPaint = Paint()..color = const Color(0xFFFFD84A).withValues(alpha: 0.12);

    final grainPoints = <Offset>[
      Offset(size.width * 0.08, size.height * 0.18),
      Offset(size.width * 0.17, size.height * 0.62),
      Offset(size.width * 0.34, size.height * 0.28),
      Offset(size.width * 0.41, size.height * 0.76),
      Offset(size.width * 0.56, size.height * 0.16),
      Offset(size.width * 0.63, size.height * 0.68),
      Offset(size.width * 0.78, size.height * 0.34),
      Offset(size.width * 0.88, size.height * 0.74),
    ];
    for (final point in grainPoints) {
      canvas.drawCircle(point, 1.2, grainPaint);
    }

    final particlePoints = <Offset>[
      Offset(size.width * 0.47, size.height * 0.22),
      Offset(size.width * 0.52, size.height * 0.64),
      Offset(size.width * 0.49, size.height * 0.82),
    ];
    for (final point in particlePoints) {
      canvas.drawCircle(point, 2.2, particlesPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeaturedTakeCard extends StatelessWidget {
  const _FeaturedTakeCard({required this.scene, required this.onTap});

  final SceneModel scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 178,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.22),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.84),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xCC6C5CE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    scene.category,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.08,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        UserAvatar(
                          url: scene.author.avatarUrl,
                          userId: scene.author.id,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scene.author.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 4),
                        Text(
                          _formatCompact(scene.likesCount),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.play_circle_fill_rounded, size: 14, color: Color(0xFF47D7FF)),
                        const SizedBox(width: 4),
                        Text(
                          scene.durationFormatted,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (scene.thumbnailUrl.startsWith('assets/')) {
      return Image.asset(
        scene.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceCard,
        ),
      );
    }

    return Image.network(
      scene.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceCard,
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppThemeTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCompact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.45,
              spreadRadius: size * 0.1,
            ),
          ],
        ),
      ),
    );
  }
}