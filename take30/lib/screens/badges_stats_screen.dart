import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/router.dart';
import '../theme/app_theme.dart';

class BadgesStatsScreen extends StatelessWidget {
  const BadgesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tiles = [
      ('🎬', 'Premier', false),
      ('🔥', 'Streak x5', false),
      ('⚔️', 'Duelliste active', false),
      ('🏆', 'Champion', false),
      ('🎨', 'Cinéaste', false),
      ('💎', 'Diamant', true),
    ];

    return Scaffold(
      backgroundColor: BadgesTheme.background,
      appBar: AppBar(
        backgroundColor: BadgesTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => context.go(AppRouter.profilePath('u1')),
        ),
        title: Text(
          'Badges & Stats',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: tiles
                  .map(
                    (tile) => Opacity(
                      opacity: tile.$3 ? 0.4 : 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tile.$1, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              tile.$2,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            const _ProgressCard(
              title: 'Takes',
              subtitle: '4/7 pour débloquer la prochaine récompense',
              progress: 0.57,
              color: AppColors.yellow,
            ),
            const _ProgressCard(
              title: 'Temps',
              subtitle: '5h42 de création cumulée',
              progress: 0.68,
              color: AppColors.cyan,
            ),
            const _ProgressCard(
              title: 'Battles',
              subtitle: '8/12 affrontements complétés',
              progress: 0.66,
              color: AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
