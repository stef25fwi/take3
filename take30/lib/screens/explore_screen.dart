import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../services/mock_data.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String? _selectedCategory;

  static const List<_CategoryTileData> _categories = [
    _CategoryTileData(
      label: 'Drame',
      color: Color(0xFF7C67F8),
      icon: Icons.theater_comedy_rounded,
    ),
    _CategoryTileData(
      label: 'Comédie',
      color: Color(0xFF31C8A6),
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    _CategoryTileData(
      label: 'Action',
      color: Color(0xFF2F9CFF),
      icon: Icons.flash_on_rounded,
    ),
    _CategoryTileData(
      label: 'Romance',
      color: Color(0xFFE85F7E),
      icon: Icons.favorite_rounded,
    ),
    _CategoryTileData(
      label: 'Plus',
      color: Color(0xFFECEEF6),
      icon: Icons.grid_view_rounded,
      darkIcon: true,
    ),
  ];

  static final List<_SceneEntry> _popularEntries = [
    _SceneEntry(
      scene: MockData.scenes[0],
      displayTitle: 'Rupture\nau téléphone',
      durationLabel: '01:33',
      exploreCategory: 'Drame',
    ),
    _SceneEntry(
      scene: MockData.scenes[1],
      displayTitle: 'Interrogatoire\ntendu',
      durationLabel: '01:15',
      exploreCategory: 'Action',
    ),
    _SceneEntry(
      scene: MockData.scenes[2],
      displayTitle: 'Déclaration\nd\'amour',
      durationLabel: '01:25',
      exploreCategory: 'Romance',
    ),
  ];

  static final List<_SceneEntry> _newEntries = [
    _SceneEntry(
      scene: MockData.scenes[3],
      displayTitle: 'Mauvaise\nnouvelle',
      durationLabel: '01:29',
      exploreCategory: 'Drame',
    ),
    _SceneEntry(
      scene: MockData.scenes[4],
      displayTitle: 'Confrontation\nfamiliale',
      durationLabel: '01:28',
      exploreCategory: 'Comédie',
    ),
    _SceneEntry(
      scene: MockData.scenes[5],
      displayTitle: 'Monologue\ndu héros',
      durationLabel: '01:12',
      exploreCategory: 'Action',
    ),
    _SceneEntry(
      scene: MockData.scenes[0],
      displayTitle: 'Émotion\nbrute',
      durationLabel: '00:58',
      exploreCategory: 'Romance',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(_SceneEntry entry) {
    final normalizedQuery = _query.trim().toLowerCase();
    final matchesQuery = normalizedQuery.isEmpty ||
        entry.scene.title.toLowerCase().contains(normalizedQuery) ||
        entry.displayTitle.toLowerCase().contains(normalizedQuery) ||
        entry.exploreCategory.toLowerCase().contains(normalizedQuery);
    final matchesCategory =
        _selectedCategory == null || entry.exploreCategory == _selectedCategory;
    return matchesQuery && matchesCategory;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visiblePopular = _popularEntries.where(_matches).take(3).toList();
    final visibleNew = _newEntries.where(_matches).toList();

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExplorerSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onActionTap: _resetFilters,
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Catégories'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final tileWidth = (constraints.maxWidth - gap * 4) / 5;
                    return Row(
                      children: [
                        for (var index = 0; index < _categories.length; index++) ...[
                          SizedBox(
                            width: tileWidth,
                            child: _CategoryTile(
                              data: _categories[index],
                              selected: _selectedCategory == _categories[index].label,
                              onTap: () {
                                final label = _categories[index].label;
                                if (label == 'Plus') {
                                  _resetFilters();
                                  return;
                                }
                                setState(() {
                                  _selectedCategory =
                                      _selectedCategory == label ? null : label;
                                });
                              },
                            ),
                          ),
                          if (index != _categories.length - 1)
                            const SizedBox(width: gap),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Scènes populaires'),
                const SizedBox(height: 10),
                if (visiblePopular.isEmpty)
                  const _EmptyState(label: 'Aucune scène populaire pour ce filtre.')
                else
                  Row(
                    children: [
                      for (var index = 0; index < visiblePopular.length; index++) ...[
                        Expanded(
                          child: _PopularSceneCard(
                            entry: visiblePopular[index],
                            onTap: () => context.go(
                              AppRouter.scenePath(visiblePopular[index].scene.id),
                            ),
                          ),
                        ),
                        if (index != visiblePopular.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                const SizedBox(height: 16),
                const _SectionTitle('Nouvelles scènes'),
                const SizedBox(height: 10),
                if (visibleNew.isEmpty)
                  const _EmptyState(label: 'Aucune nouvelle scène pour ce filtre.')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var index = 0; index < visibleNew.length; index++) ...[
                          _MiniSceneCard(
                            entry: visibleNew[index],
                            onTap: () => context.go(
                              AppRouter.scenePath(visibleNew[index].scene.id),
                            ),
                          ),
                          if (index != visibleNew.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplorerSearchBar extends StatelessWidget {
  const _ExplorerSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onActionTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF171D2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.58),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Rechercher une scène...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onActionTap,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB800),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: Color(0xFF0B1020),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _CategoryTileData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = data.darkIcon ? const Color(0xFF0B1020) : Colors.white;
    final textColor = data.darkIcon ? const Color(0xFF0B1020) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 62,
        decoration: BoxDecoration(
          color: data.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.80)
                : Colors.white.withValues(alpha: data.darkIcon ? 0.10 : 0.18),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, size: 18, color: iconColor),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: data.label == 'Comédie' ? 9.4 : 10,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularSceneCard extends StatelessWidget {
  const _PopularSceneCard({required this.entry, required this.onTap});

  final _SceneEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.68,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                entry.scene.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A2234),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.84),
                    ],
                    stops: const [0.0, 0.40, 0.72, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 9,
                right: 8,
                bottom: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.durationLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
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
}

class _MiniSceneCard extends StatelessWidget {
  const _MiniSceneCard({required this.entry, required this.onTap});

  final _SceneEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 112,
        child: AspectRatio(
          aspectRatio: 0.86,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  entry.scene.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A2234),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.70),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.durationLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    entry.displayTitle.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

class _CategoryTileData {
  const _CategoryTileData({
    required this.label,
    required this.color,
    required this.icon,
    this.darkIcon = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool darkIcon;
}

class _SceneEntry {
  const _SceneEntry({
    required this.scene,
    required this.displayTitle,
    required this.durationLabel,
    required this.exploreCategory,
  });

  final SceneModel scene;
  final String displayTitle;
  final String durationLabel;
  final String exploreCategory;
}