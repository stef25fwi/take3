import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/router.dart';
import '../services/mock_data.dart';

class BadgesStatsScreen extends StatelessWidget {
  const BadgesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.users.first;

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
        value: _formatCompact(user.totalViews),
        icon: Icons.play_circle_fill_rounded,
        iconColor: const Color(0xFFD5D8E3),
      ),
      _StatTileData(
        title: 'Taux d\'approbation',
        value: '${user.approvalRate.toInt()}%',
        icon: Icons.verified_rounded,
        iconColor: const Color(0xFFFFB800),
      ),
      _StatTileData(
        title: 'Partages',
        value: _formatCompact(user.sharesCount),
        icon: Icons.sync_rounded,
        iconColor: const Color(0xFF00D4FF),
      ),
      _StatTileData(
        title: 'Scènes jouées',
        value: '${user.scenesCount}',
        icon: Icons.movie_creation_outlined,
        iconColor: const Color(0xFF7C67F8),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1020), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tes badges',
                            style: GoogleFonts.dmSans(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Voir tout',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var index = 0; index < badges.length; index++) ...[
                            Expanded(child: _BadgeMedalItem(data: badges[index])),
                            if (index != badges.length - 1)
                              const SizedBox(width: 10),
                          ],
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Stats',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0; index < stats.length; index++) ...[
                        _StatCardTile(
                          data: stats[index],
                          onTap: () {},
                        ),
                        if (index != stats.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              const _BadgesBottomNav(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeMedalItem extends StatelessWidget {
  const _BadgeMedalItem({required this.data});

  final _BadgeMedalData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: data.gradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                child: Center(
                  child: Text(
                    data.emoji,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
              fontSize: 10.4,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.18,
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
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.iconColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    data.icon,
                    size: 19,
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
                          color: Colors.white.withValues(alpha: 0.66),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.value,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.34),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgesBottomNav extends StatelessWidget {
  const _BadgesBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1523).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.6,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                selected: false,
                onTap: () => context.go(AppRouter.home),
              ),
              _BottomNavItem(
                icon: Icons.explore_rounded,
                label: 'Explorer',
                selected: false,
                onTap: () => context.go(AppRouter.explore),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go(AppRouter.record),
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB800),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF0B1020),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _BottomNavItem(
                icon: Icons.notifications_rounded,
                label: 'Notifs',
                selected: true,
                onTap: () => context.go(AppRouter.notifications),
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profil',
                selected: false,
                onTap: () => context.go(AppRouter.profilePath('u1')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.48),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.48),
              ),
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