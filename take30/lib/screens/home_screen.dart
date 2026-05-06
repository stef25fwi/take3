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
import '../widgets/take30_logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final dailyChallenge = ref.watch(dailyChallengeProvider).value;
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
    final activities = <_ActivityData>[
      if (scenes.isNotEmpty)
        _ActivityData(
          user: scenes[0].author,
          description: 'a publié « ${scenes[0].title} » dans ${scenes[0].category}',
          timeLabel: 'À l’instant',
        ),
      if (scenes.length > 1)
        _ActivityData(
          user: scenes[1].author,
          description: 'fait grimper le classement avec une nouvelle performance',
          timeLabel: 'Il y a quelques minutes',
        ),
      if (scenes.length > 2)
        _ActivityData(
          user: scenes[2].author,
          description: dailyChallenge == null
              ? 'a rejoint le flux créatif du jour'
              : 'a relevé le défi du jour « ${dailyChallenge.sceneTitle} »',
          timeLabel: 'Aujourd’hui',
        ),
    ];

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
                      onNotificationsTap: () => context.go(AppRouter.notifications),
                    ),
                    const SizedBox(height: 18),
                    _HomeHeroCard(
                      user: currentUser,
                      onPrimaryTap: () => context.go(AppRouter.aiFeed),
                      onChallengeTap: () => context.go(AppRouter.challenge),
                    ),
                    const SizedBox(height: 20),
                    _LiveTrendingSection(
                      onSeeAll: () => context.go(AppRouter.battleLeaderboard),
                      onOpenTrend: () => context.go(AppRouter.aiFeed),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('À la une'),
                    const SizedBox(height: 12),
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
                                const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Battle chaude du moment'),
                    const SizedBox(height: 12),
                    _HomeBattleStrip(
                      battlesState: ref.watch(mostExpectedBattlesProvider),
                      preferPublishedCard: true,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Battles en ligne'),
                    const SizedBox(height: 12),
                    _HomeBattleStrip(
                      battlesState: ref.watch(homePublishedBattlesProvider),
                      preferPublishedCard: true,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Battles en préparation'),
                    const SizedBox(height: 12),
                    _HomeBattleStrip(
                      battlesState: ref.watch(homePreparingBattlesProvider),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Mes candidats suivis'),
                    const SizedBox(height: 12),
                    _HomeBattleStrip(
                      battlesState: ref.watch(followedCandidatesBattlesProvider),
                      preferPublishedCard: true,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Activité récente'),
                    const SizedBox(height: 12),
                    _ActivityPanel(
                      activities: activities,
                      onTapUser: (userId) => context.go(AppRouter.profilePath(userId)),
                    ),
                    if (feedState.error != null) ...[
                      const SizedBox(height: 16),
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
                if (index != visible.length - 1) const SizedBox(width: 12),
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
    required this.onNotificationsTap,
  });

  final int unreadCount;
  final bool canOpenAdmin;
  final VoidCallback onAdminTap;
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

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.user,
    required this.onPrimaryTap,
    required this.onChallengeTap,
  });

  final UserModel user;
  final VoidCallback onPrimaryTap;
  final VoidCallback onChallengeTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeTokens.isDark(context);
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color.fromRGBO(255, 184, 0, 0.20),
                  Color.fromRGBO(0, 212, 255, 0.12),
                  Color.fromRGBO(108, 92, 231, 0.18),
                ]
              : const [
                  Color(0xFFFFF7DA),
                  Color(0xFFEAF8FF),
                  Color(0xFFF2EEFF),
                ],
        ),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.20),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                url: user.avatarUrl,
                userId: user.id,
                size: 46,
                showBorder: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${user.displayName}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prêt à tourner une performance qui marque ?',
                      style: GoogleFonts.dmSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                        height: 1.05,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _HeroStat(value: '60s', label: 'Format'),
              const SizedBox(width: 18),
              _HeroStat(value: '${user.scenesCount}', label: 'Scènes'),
              const SizedBox(width: 18),
              _HeroStat(
                value: _formatCompact(user.likesCount),
                label: 'Likes',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HomePrimaryButton(
                  label: 'Nouvelle vidéo',
                  onTap: onPrimaryTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeGhostButton(
                  label: 'Voir le défi',
                  onTap: onChallengeTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppThemeTokens.primaryText(context),
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppThemeTokens.secondaryText(context),
          ),
        ),
      ],
    );
  }
}

class _HomePrimaryButton extends StatelessWidget {
  const _HomePrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD96A), Color(0xFFFFB800), Color(0xFFF2A600)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 184, 0, 0.20),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeGhostButton extends StatelessWidget {
  const _HomeGhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppThemeTokens.softAction(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeTokens.softBorder(context)),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppThemeTokens.primaryText(context),
                ),
              ),
            ),
          ),
        ),
      ),
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
        final sectionPadding = compact ? 16.0 : (medium ? 24.0 : 32.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(sectionPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF000000).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LiveTrendingHeader(onSeeAll: onSeeAll),
              SizedBox(height: compact ? 16 : 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width < 1024 ? 2 : 4;
                  final gap = width < 600 ? 10.0 : (width < 1024 ? 14.0 : 16.0);
                  final cardHeight = width < 600 ? 232.0 : (width < 1024 ? 286.0 : 320.0);
                  final cardWidth = (width - (gap * (columns - 1))) / columns;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final item in _items)
                        SizedBox(
                          width: cardWidth,
                          child: _LiveTrendCard(
                            data: item,
                            maxDuels: 2400,
                            height: cardHeight,
                            compact: width < 600,
                            onTap: onOpenTrend,
                          ),
                        ),
                    ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚔️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Tendances Live',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
              SizedBox(width: 8),
              _LiveBadge(),
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
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFFFFFFFF),
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
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.borderColor,
                    const Color(0xFFFACC15),
                    const Color(0xFF06B6D4),
                    const Color(0xFFA855F7),
                    data.borderColor,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
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
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _LiveTrendRankBadge(data: data),
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
  const _LiveTrendRankBadge({required this.data});

  final _LiveTrendData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: data.badgeColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${data.rank}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: data.badgeTextColor,
        ),
      ),
    );
  }
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, _hovered ? 1 : 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.10),
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(color: widget.accent.withValues(alpha: 0.12)),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 24,
          color: Color(0xFFFFFFFF),
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
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFFEF4444),
                        Color(0xFFF97316),
                        Color(0xFFFACC15),
                        Color(0xFF22C55E),
                        Color(0xFF06B6D4),
                        Color(0xFF3B82F6),
                        Color(0xFFA855F7),
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

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.activities, required this.onTapUser});

  final List<_ActivityData> activities;
  final ValueChanged<String> onTapUser;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _EmptyPanel(
        title: 'Pas encore d’activité',
        subtitle: 'Les interactions récentes apparaîtront ici quand Firestore commencera à se remplir.',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Column(
            children: activities
                .map(
                  (item) => _ActivityRow(
                    data: item,
                    onTap: () => onTapUser(item.user.id),
                  ),
                )
                .toList(),
          ),
        ),
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

class _ActivityData {
  const _ActivityData({
    required this.user,
    required this.description,
    required this.timeLabel,
  });

  final UserModel user;
  final String description;
  final String timeLabel;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.data, required this.onTap});

  final _ActivityData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(url: data.user.avatarUrl, userId: data.user.id, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.user.displayName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.description,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppThemeTokens.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.timeLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppThemeTokens.tertiaryText(context),
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