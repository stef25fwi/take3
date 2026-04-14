import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Explorer',
      trailing: const TakeHeaderButton(icon: Icons.search_rounded),
      showBottomNav: true,
      activeTab: TakeTab.explore,
      children: [
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            TakePill(label: 'Tout', tone: TakePillTone.yellow),
            TakePill(label: 'Portrait', tone: TakePillTone.cyan),
            TakePill(label: 'Lifestyle', tone: TakePillTone.purple),
            TakePill(label: 'Nature', tone: TakePillTone.green),
          ],
        ),
        const SizedBox(height: 12),
        _ExploreCard(
          emoji: '🌃',
          title: 'Cuisine de nuit',
          description: 'Une scène urbaine et intime à découvrir. Appuyer pour voir les détails.',
          onTap: () => context.push(AppRouter.sceneDetail, extra: 'Cuisine de nuit'),
        ),
        const _ExploreCard(
          emoji: '📸',
          title: 'Portrait créatif',
          description: 'Jeu de lumière, plans serrés et ambiance studio.',
        ),
        const _ExploreCard(
          emoji: '🎥',
          title: 'Mini reportage',
          description: 'Une narration simple et percutante tournée en 25 minutes.',
        ),
      ],
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.emoji,
    required this.title,
    required this.description,
    this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TakeVideoPlaceholder(emoji: emoji, height: 120),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0x99FFFFFF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
