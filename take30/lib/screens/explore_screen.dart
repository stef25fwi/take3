import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _filters = ['Tout', 'Portrait', 'Lifestyle', 'Nature'];

  int _selectedFilter = 0;

  List<_ExploreCardData> get _cards {
    final scenes = MockData.scenes;
    return [
      _ExploreCardData(
        scene: scenes[0],
        emoji: '🌃',
        description: 'Une scene urbaine et intime a decouvrir. Appuyer pour voir les details.',
      ),
      _ExploreCardData(
        scene: scenes[2],
        emoji: '📸',
        description: 'Jeu de lumiere, plans serres et ambiance studio.',
      ),
      _ExploreCardData(
        scene: scenes[5],
        emoji: '🎥',
        description: 'Une narration simple et percutante tournee en 25 minutes.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExploreTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explorer',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ExploreTheme.searchBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ExploreTheme.searchBorder, width: 0.5),
                    ),
                    child: const Icon(Icons.search, color: AppColors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (_, index) {
                  final selected = index == _selectedFilter;
                  final label = _filters[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.yellow : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.navy : AppColors.white,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _filters.length,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: _cards.length,
                itemBuilder: (_, index) {
                  final card = _cards[index];
                  return _ExploreCard(
                    data: card,
                    onTap: () => context.go('/scene/${card.scene.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreCardData {
  const _ExploreCardData({
    required this.scene,
    required this.emoji,
    required this.description,
  });

  final SceneModel scene;
  final String emoji;
  final String description;
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.data, required this.onTap});

  final _ExploreCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: DecorationImage(
                  image: NetworkImage(data.scene.thumbnailUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0x66000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    data.emoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.scene.title,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.description,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
