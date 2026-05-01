import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ranking_entry.dart';
import '../providers/explorer_providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

enum ExplorerRankingScope { regional, national }

class ExplorerRankingScreen extends ConsumerWidget {
  const ExplorerRankingScreen({super.key, required this.scope});

  final ExplorerRankingScope scope;

  String _formatScore(double score) {
    if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}K';
    return score.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(explorerLocationProvider).location;
    final country = loc?.countryCode ?? 'FR';
    final countryName = loc?.countryName ?? 'France';
    final region = loc?.regionCode ?? 'ile_de_france';
    final regionName = loc?.regionName ?? 'Île-de-France';

    final entries = scope == ExplorerRankingScope.regional
        ? ref.watch(
            regionalRankingProvider(
              (countryCode: country, regionCode: region),
            ),
          )
        : ref.watch(nationalRankingProvider(country));

    final title = scope == ExplorerRankingScope.regional
        ? 'Classement régional'
        : 'Classement national';
    final subtitle = scope == ExplorerRankingScope.regional
        ? '$regionName, $countryName'
        : countryName;

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemeTokens.pageGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppThemeTokens.primaryText(context),
                        size: 18,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRouter.explore);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              color: AppThemeTokens.primaryText(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.dmSans(
                              color: AppThemeTokens.secondaryText(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? _empty(context, scope)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppThemeTokens.pageHorizontalPadding,
                          8,
                          AppThemeTokens.pageHorizontalPadding,
                          24,
                        ),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RankingRow(
                          entry: entries[i],
                          scope: scope,
                          scoreText: _formatScore(entries[i].totalScore),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, ExplorerRankingScope scope) {
    final msg = scope == ExplorerRankingScope.regional
        ? 'Aucun classement régional pour le moment.\nSois le premier à jouer une scène dans ta région.'
        : 'Aucun classement national pour le moment.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: AppThemeTokens.secondaryText(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.entry,
    required this.scope,
    required this.scoreText,
  });

  final RankingEntry entry;
  final ExplorerRankingScope scope;
  final String scoreText;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentUser;
    final badgeLabel = scope == ExplorerRankingScope.regional
        ? 'Top régional'
        : 'Top national';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFF7DC)
            : AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? const Color(0xFFE8C56A)
              : AppThemeTokens.border(context),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.dmSans(
                color: AppThemeTokens.primaryText(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          UserAvatar(
            url: entry.avatarUrl,
            userId: entry.userId,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: AppThemeTokens.primaryText(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (entry.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF00B8FF),
                      ),
                    ],
                    if (entry.rank <= 3) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF0B1020),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  scope == ExplorerRankingScope.regional
                      ? entry.regionName
                      : entry.countryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: AppThemeTokens.secondaryText(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$scoreText pts',
                style: GoogleFonts.dmSans(
                  color: AppThemeTokens.primaryText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${entry.voteCount} votes · ${entry.submissionCount} prises',
                style: GoogleFonts.dmSans(
                  color: AppThemeTokens.secondaryText(context),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
