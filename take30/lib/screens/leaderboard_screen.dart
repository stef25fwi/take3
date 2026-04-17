import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/router.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0;

  static const _tabs = ['Semaine', 'Mois', 'All-time'];

  @override
  Widget build(BuildContext context) {
    final entries = MockData.leaderboard;

    return Scaffold(
      backgroundColor: LeaderboardTheme.background,
      appBar: AppBar(
        backgroundColor: LeaderboardTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => context.go(AppRouter.profilePath('u1')),
        ),
        title: Text(
          'Classement',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.white, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: List.generate(
                _tabs.length,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
                  child: _PeriodTab(
                    label: _tabs[index],
                    selected: index == _selectedTab,
                    onTap: () => setState(() => _selectedTab = index),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      ...entries.take(3).map(
                        (entry) => _LeaderboardRow(
                          entry: entry,
                          highlight: false,
                          onTap: () => context.go(AppRouter.profilePath(entry.user.id)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LeaderboardRow(
                        entry: entries.firstWhere((entry) => entry.user.id == 'u1'),
                        highlight: true,
                        onTap: () => context.go(AppRouter.profilePath('u1')),
                      ),
                    ],
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

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? LeaderboardTheme.tabActiveBg
              : LeaderboardTheme.tabInactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? LeaderboardTheme.tabActiveText
                : LeaderboardTheme.tabInactiveText,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.highlight,
    required this.onTap,
  });

  final dynamic entry;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rankLabel = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: highlight ? 0 : 2),
        padding: EdgeInsets.fromLTRB(10, 10, 10, highlight ? 12 : 10),
        decoration: BoxDecoration(
          color: highlight ? AppColors.yellow.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                rankLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            UserAvatar(url: entry.user.avatarUrl, userId: entry.user.id, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user.displayName + (highlight ? ' (toi)' : ''),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '${entry.score.toInt()}pts',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.score.toInt()}',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
