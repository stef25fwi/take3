import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../providers/battle_providers.dart';
import '../../router/router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/battle/battle_preparing_card.dart';
import '../../widgets/battle/battle_published_card.dart';

class BattleListScreen extends ConsumerWidget {
  const BattleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredBattlesProvider);
    final trending = ref.watch(trendingBattlesProvider);
    final soonClosing = ref.watch(soonClosingBattlesProvider);
    final published = ref.watch(homePublishedBattlesProvider);
    final preparing = ref.watch(homePreparingBattlesProvider);
    final expected = ref.watch(mostExpectedBattlesProvider);
    final followed = ref.watch(followedCandidatesBattlesProvider);

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
              child: _BattleAmbientGlow(
                size: 220,
                color: Color.fromRGBO(108, 92, 231, 0.12),
              ),
            ),
            const Positioned(
              top: 96,
              right: -46,
              child: _BattleAmbientGlow(
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
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BattleHeader(),
                    const SizedBox(height: 18),
                    const _BattleIntro(),
                    _BattleSection(
                      title: 'Battles à la une',
                      state: featured,
                      showWhenEmpty: false,
                      itemBuilder: (battle) => BattlePublishedCard(
                        battle: battle,
                        onTap: () => context.go(AppRouter.battlePath(battle.id)),
                        onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                        onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                      ),
                    ),
                    _BattleSection(
                      title: 'Battles tendance',
                      state: trending,
                      showWhenEmpty: false,
                      itemBuilder: (battle) => battle.isPublished
                          ? BattlePublishedCard(
                              battle: battle,
                              onTap: () => context.go(AppRouter.battlePath(battle.id)),
                              onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                              onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                            )
                          : BattlePreparingCard(
                              battle: battle,
                              onTap: () => context.go(AppRouter.battlePath(battle.id)),
                              onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                              onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                            ),
                    ),
                    _BattleSection(
                      title: 'Fin de vote imminente',
                      state: soonClosing,
                      showWhenEmpty: false,
                      itemBuilder: (battle) => BattlePublishedCard(
                        battle: battle,
                        onTap: () => context.go(AppRouter.battlePath(battle.id)),
                        onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                        onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                      ),
                    ),
                    _BattleSection(
                      title: 'Battles en ligne',
                      state: published,
                      itemBuilder: (battle) => BattlePublishedCard(
                        battle: battle,
                        onTap: () => context.go(AppRouter.battlePath(battle.id)),
                        onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                        onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                      ),
                    ),
                    _BattleSection(
                      title: 'Battles en préparation',
                      state: preparing,
                      itemBuilder: (battle) => BattlePreparingCard(
                        battle: battle,
                        onTap: () => context.go(AppRouter.battlePath(battle.id)),
                        onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                        onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                      ),
                    ),
                    _BattleSection(
                      title: 'Battles les plus attendues',
                      state: expected,
                      itemBuilder: (battle) => BattlePreparingCard(
                        battle: battle,
                        onTap: () => context.go(AppRouter.battlePath(battle.id)),
                        onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                        onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                      ),
                    ),
                    _BattleSection(
                      title: 'Mes candidats suivis',
                      state: followed,
                      itemBuilder: (battle) => BattlePublishedCard(
                        battle: battle,
                        onTap: () => context.go(AppRouter.battlePath(battle.id)),
                        onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                        onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                      ),
                    ),
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

class _BattleHeader extends StatelessWidget {
  const _BattleHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Battles Take60',
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppThemeTokens.primaryText(context),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Même scène. Deux interprétations. Un seul gagnant.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppThemeTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRouter.battleLeaderboard),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppThemeTokens.softAction(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppThemeTokens.softBorder(context)),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: AppThemeTokens.primaryText(context),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _BattleIntro extends StatelessWidget {
  const _BattleIntro();

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeTokens.isDark(context);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFFFB800).withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              'MODE BATTLE',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppThemeTokens.primaryText(context),
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Duel d’interprétation',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppThemeTokens.primaryText(context),
              letterSpacing: -0.55,
              height: 1.03,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Défie un candidat, vote pour la meilleure performance et suis les duels qui montent.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w600,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go(AppRouter.battleLeaderboard),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppThemeTokens.softAction(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppThemeTokens.softBorder(context)),
                  ),
                  child: Center(
                    child: Text(
                      'Voir le classement Battle',
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
          ),
        ],
      ),
    );
  }
}

class _BattleSectionTitle extends StatelessWidget {
  const _BattleSectionTitle(this.label);

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

class _BattleLoadingPanel extends StatelessWidget {
  const _BattleLoadingPanel();

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

class _BattleEmptyPanel extends StatelessWidget {
  const _BattleEmptyPanel({required this.title, required this.subtitle});

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

class _BattleAmbientGlow extends StatelessWidget {
  const _BattleAmbientGlow({required this.size, required this.color});

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

class _BattleSection extends StatelessWidget {
  const _BattleSection({
    required this.title,
    required this.state,
    required this.itemBuilder,
    this.showWhenEmpty = true,
  });

  final String title;
  final AsyncValue<List<BattleModel>> state;
  final Widget Function(BattleModel battle) itemBuilder;
  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BattleLoadingPanel(),
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BattleSectionTitle(title),
            const SizedBox(height: 12),
            const _BattleEmptyPanel(
              title: 'Battles indisponibles',
              subtitle: 'Les duels Take60 réapparaîtront automatiquement.',
            ),
          ],
        ),
      ),
      data: (battles) {
        if (battles.isEmpty && !showWhenEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BattleSectionTitle(title),
              const SizedBox(height: 12),
              if (battles.isEmpty)
                const _BattleEmptyPanel(
                  title: 'Aucune Battle pour le moment',
                  subtitle: 'Défie ce candidat sur une scène Take60 de niveau équivalent.',
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (var index = 0; index < battles.length; index++) ...[
                        SizedBox(
                          width: 330,
                          child: itemBuilder(battles[index]),
                        ),
                        if (index != battles.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
