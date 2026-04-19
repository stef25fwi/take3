import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class BadgesStatsScreen extends StatelessWidget {
  const BadgesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.users.first;
    const badges = MockData.badges;
    final stats = <_ProfileStatData>[
      _ProfileStatData(
        label: 'Vues totales',
        value: MockData.formatCount(user.totalViews),
        icon: Icons.play_circle_fill_rounded,
        color: AppColors.cyan,
      ),
      _ProfileStatData(
        label: 'Likes',
        value: MockData.formatCount(user.likesCount),
        icon: Icons.favorite_rounded,
        color: AppColors.red,
      ),
      _ProfileStatData(
        label: 'Partages',
        value: MockData.formatCount(user.sharesCount),
        icon: Icons.share_rounded,
        color: AppColors.yellow,
      ),
      _ProfileStatData(
        label: 'Scènes',
        value: '${user.scenesCount}',
        icon: Icons.movie_creation_outlined,
        color: AppColors.purple,
      ),
      _ProfileStatData(
        label: 'Abonnés',
        value: MockData.formatCount(user.followersCount),
        icon: Icons.groups_rounded,
        color: AppColors.white,
      ),
      _ProfileStatData(
        label: 'Approbation',
        value: '${user.approvalRate.toInt()}%',
        icon: Icons.verified_rounded,
        color: AppColors.yellow,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1020), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => context.go(AppRouter.home),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Badges & stats',
                            style: GoogleFonts.dmSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ton parcours Take30 en un coup d’oeil',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.64),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRouter.leaderboard),
                      child: Text(
                        'Classement',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.yellow,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileHeaderCard(user: user, badgeCount: badges.length),
                const SizedBox(height: 28),
                Text(
                  'Badges débloqués',
                  style: GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: badges.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.06,
                  ),
                  itemBuilder: (context, index) {
                    return _BadgeCard(badge: badges[index]);
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Statistiques',
                  style: GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 14),
                for (final stat in stats) ...[
                  _StatRow(stat: stat),
                  if (stat != stats.last) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.user, required this.badgeCount});

  final UserModel user;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.18),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            url: user.avatarUrl,
            userId: user.id,
            size: 64,
            showBorder: user.isVerified,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${user.username}',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio.isEmpty ? 'Talent Take30' : user.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniPill(
                      icon: Icons.workspace_premium_rounded,
                      label: '$badgeCount badges',
                    ),
                    const SizedBox(width: 8),
                    _MiniPill(
                      icon: Icons.groups_rounded,
                      label: MockData.formatCount(user.followersCount),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    final accent = switch (badge.type) {
      BadgeType.gold => AppColors.badgeGold,
      BadgeType.silver => AppColors.badgeSilver,
      BadgeType.bronze => AppColors.badgeBronze,
      BadgeType.special => AppColors.badgeBlue,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            alignment: Alignment.center,
            child: Text(
              badge.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const Spacer(),
          Text(
            badge.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: Colors.white.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final _ProfileStatData stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stat.color.withValues(alpha: 0.18),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stat.label,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
          Text(
            stat.value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.yellow),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatData {
  const _ProfileStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
