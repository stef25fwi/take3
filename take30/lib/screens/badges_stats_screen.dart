import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class BadgesStatsScreen extends ConsumerWidget {
  const BadgesStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    const badges = [
      _BadgeMedalData(
        label: 'Révélation du jour',
        emoji: '✦',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE07A), Color(0xFFFFB800), Color(0xFFFF9C1A)],
        ),
      ),
      _BadgeMedalData(
        label: 'Top 10 Semaine',
        emoji: '★',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFBE73), Color(0xFFCB7B34), Color(0xFF9E5928)],
        ),
      ),
      _BadgeMedalData(
        label: 'Meilleure Emotion',
        emoji: '◈',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8D6DFF), Color(0xFF6C5CE7), Color(0xFF4E39BF)],
        ),
      ),
      _BadgeMedalData(
        label: 'Scène la plus jouée',
        emoji: '⬢',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD46B), Color(0xFFE9A11F), Color(0xFFB16A10)],
        ),
      ),
    ];

    final stats = [
      _StatTileData(
        title: 'Vues totales',
        value: _formatCompact(user?.totalViews ?? 0),
        icon: Icons.play_circle_fill_rounded,
        iconColor: const Color(0xFFD5D8E3),
      ),
      _StatTileData(
        title: 'Taux d\'approbation',
        value: '${(user?.approvalRate ?? 0).toInt()}%',
        icon: Icons.verified_rounded,
        iconColor: const Color(0xFFFFB800),
      ),
      _StatTileData(
        title: 'Partages',
        value: _formatCompact(user?.sharesCount ?? 0),
        icon: Icons.sync_rounded,
        iconColor: const Color(0xFF00D4FF),
      ),
      _StatTileData(
        title: 'Scènes jouées',
        value: '${user?.scenesCount ?? 0}',
        icon: Icons.movie_creation_outlined,
        iconColor: const Color(0xFF7C67F8),
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
              top: -80,
              left: -60,
              child: _AmbientGlow(
                size: 200,
                color: Color.fromRGBO(124, 103, 248, 0.10),
              ),
            ),
            const Positioned(
              top: 120,
              right: -40,
              child: _AmbientGlow(
                size: 220,
                color: Color.fromRGBO(255, 184, 0, 0.08),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tes badges',
                                style: GoogleFonts.dmSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppThemeTokens.primaryText(context),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _showAllBadgesSheet(context, badges),
                                child: Text(
                                  'Voir tout',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemeTokens.secondaryText(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var index = 0; index < badges.length; index++) ...[
                                Expanded(
                                  child: _BadgeMedalItem(
                                    data: badges[index],
                                    onTap: () =>
                                        _showBadgeSheet(context, badges[index]),
                                  ),
                                ),
                                if (index != badges.length - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Stats',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppThemeTokens.primaryText(context),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (var index = 0; index < stats.length; index++) ...[
                            _StatCardTile(
                              data: stats[index],
                              onTap: () => _showStatSheet(context, stats[index]),
                            ),
                            if (index != stats.length - 1)
                              const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 22),
                          GestureDetector(
                            onTap: () => context.go(AppRouter.leaderboard),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFB800), Color(0xFFFF9C1A)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB800)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Voir le classement →',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B1020),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _BadgeMedalItem extends StatelessWidget {
  const _BadgeMedalItem({required this.data, required this.onTap});

  final _BadgeMedalData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: data.gradient,
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.18,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardTile extends StatelessWidget {
  const _StatCardTile({required this.data, required this.onTap});

  final _StatTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppThemeTokens.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppThemeTokens.border(context),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.18),
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: data.iconColor.withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        data.icon,
                        size: 20,
                        color: data.iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppThemeTokens.secondaryText(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.value,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppThemeTokens.primaryText(context),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppThemeTokens.tertiaryText(context),
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

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
  });

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

class _BadgeMedalData {
  const _BadgeMedalData({
    required this.label,
    required this.emoji,
    required this.gradient,
  });

  final String label;
  final String emoji;
  final Gradient gradient;
}

class _StatTileData {
  const _StatTileData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
}

String _formatCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return '$value';
}

void _showBadgeSheet(BuildContext context, _BadgeMedalData data) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: data.gradient),
              child: Center(
                child: Text(
                  data.emoji,
                  style: GoogleFonts.dmSans(
                    fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Badge debloque grace a tes performances recentes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAllBadgesSheet(BuildContext context, List<_BadgeMedalData> badges) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF111827),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tous tes badges',
                style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                children: [
                  for (final b in badges)
                    Column(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: b.gradient),
                          child: Center(
                            child: Text(
                              b.emoji,
                              style: GoogleFonts.dmSans(
                                fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            b.label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11, color: Colors.white,
                            ),
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

void _showStatSheet(BuildContext context, _StatTileData stat) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stat.iconColor.withValues(alpha: 0.18),
              ),
              child: Icon(stat.icon, color: stat.iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              stat.value,
              style: GoogleFonts.dmSans(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.title,
              style: GoogleFonts.dmSans(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Detail bientot disponible.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
