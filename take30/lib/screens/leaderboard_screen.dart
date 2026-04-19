import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

enum _RankingPeriod { day, week, month, global }

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  _RankingPeriod _period = _RankingPeriod.week;

  static const _tabs = <({_RankingPeriod id, String label})>[
    (id: _RankingPeriod.day, label: 'Jour'),
    (id: _RankingPeriod.week, label: 'Semaine'),
    (id: _RankingPeriod.month, label: 'Mois'),
    (id: _RankingPeriod.global, label: 'Global'),
  ];

  /// Applique un multiplicateur de score selon la période pour donner un
  /// filtrage visuel cohérent sans backend réel.
  List<LeaderboardEntry> _entriesForPeriod(_RankingPeriod p) {
    final base = MockData.leaderboard;
    final factor = switch (p) {
      _RankingPeriod.day => 0.05,
      _RankingPeriod.week => 1.0,
      _RankingPeriod.month => 4.2,
      _RankingPeriod.global => 12.7,
    };
    final scaled = base
        .map(
          (e) => LeaderboardEntry(
            rank: e.rank,
            user: e.user,
            score: e.score * factor,
            scoreLabel: e.scoreLabel,
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return [
      for (var i = 0; i < scaled.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          user: scaled[i].user,
          score: scaled[i].score,
          scoreLabel: scaled[i].scoreLabel,
        ),
    ];
  }

  String _formatScore(double score) {
    if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}K';
    return score.toStringAsFixed(0);
  }

  String _formatFollowers(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesForPeriod(_period);

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navy,
              Color(0xFF0F1523),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _RankingHeader(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouter.home);
                  }
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RankingTabs(
                  selected: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return SizedBox(
                      height: 74,
                      child: _RankingRow(
                        entry: entry,
                        scoreText: _formatScore(entry.score),
                        followersLabel:
                            _formatFollowers(entry.user.followersCount),
                        onTap: () =>
                            context.go(AppRouter.profilePath(entry.user.id)),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: entries.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _RankingHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.white, size: 18),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Text(
            'Classement',
            style: GoogleFonts.dmSans(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTabs extends StatelessWidget {
  final _RankingPeriod selected;
  final ValueChanged<_RankingPeriod> onChanged;

  const _RankingTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          for (final tab in _LeaderboardScreenState._tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(tab.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: tab.id == selected
                        ? const Color.fromRGBO(255, 255, 255, 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    style: GoogleFonts.dmSans(
                      color: tab.id == selected
                          ? AppColors.white
                          : const Color.fromRGBO(255, 255, 255, 0.72),
                      fontSize: 12,
                      fontWeight: tab.id == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      letterSpacing: -0.1,
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

class _RankingRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final String scoreText;
  final String followersLabel;
  final VoidCallback onTap;

  const _RankingRow({
    required this.entry,
    required this.scoreText,
    required this.followersLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                '${entry.rank}',
                style: GoogleFonts.dmSans(
                  color: AppColors.yellow,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            UserAvatar(
              userId: entry.user.id,
              url: entry.user.avatarUrl,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppColors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        followersLabel,
                        style: GoogleFonts.dmSans(
                          color: const Color.fromRGBO(255, 255, 255, 0.58),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 11,
                        color: Color.fromRGBO(255, 255, 255, 0.45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              scoreText,
              style: GoogleFonts.dmSans(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.favorite,
              color: Color(0xFFFF4D6D),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}
