import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tout';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final scenes = feedState.scenes;
    final categories = _buildCategories(scenes);
    final filteredScenes = _filterScenes(scenes);
    final popularScenes = [...filteredScenes]
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final latestScenes = [...filteredScenes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: SafeArea(
        bottom: false,
        child: feedState.isLoading && scenes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).loadFeed(refresh: true),
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Explorer',
                          style: GoogleFonts.dmSans(
                            color: AppThemeTokens.primaryText(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.search_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ExplorerSearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == _selectedCategory;
                          return _CategoryChip(
                            label: category,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'Scènes populaires',
                      actionLabel: filteredScenes.length > 3 ? 'Voir plus' : null,
                    ),
                    const SizedBox(height: 12),
                    if (popularScenes.isEmpty)
                      const _EmptyExplorerState()
                    else
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: popularScenes.take(3).length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final scene = popularScenes[index];
                            return SizedBox(
                              width: 180,
                              child: _PopularSceneCard(
                                scene: scene,
                                onTap: () => _openScene(scene.id),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    _SectionTitle(
                      title: 'Nouvelles scènes',
                      actionLabel: latestScenes.length > 3 ? 'Voir plus' : null,
                    ),
                    const SizedBox(height: 12),
                    if (latestScenes.isEmpty)
                      const _EmptyExplorerState()
                    else
                      Column(
                        children: [
                          for (final scene in latestScenes.take(6)) ...[
                            _MiniSceneCard(
                              scene: scene,
                              onTap: () => _openScene(scene.id),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    if (feedState.error != null && scenes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          feedState.error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: AppThemeTokens.tertiaryText(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  List<String> _buildCategories(List<SceneModel> scenes) {
    final unique = <String>{};
    for (final scene in scenes) {
      final category = scene.category.trim();
      if (category.isNotEmpty) {
        unique.add(_humanizeCategory(category));
      }
    }
    return ['Tout', ...unique.take(6)];
  }

  List<SceneModel> _filterScenes(List<SceneModel> scenes) {
    final query = _searchController.text.trim().toLowerCase();
    return scenes.where((scene) {
      final matchesCategory = _selectedCategory == 'Tout' ||
          _humanizeCategory(scene.category) == _selectedCategory;
      final haystack = [
        scene.title,
        scene.description,
        scene.category,
        scene.author.displayName,
        scene.author.username,
      ].join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  String _humanizeCategory(String raw) {
    if (raw.isEmpty) {
      return raw;
    }
    final normalized = raw.replaceAll('_', ' ').trim();
    return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
  }

  void _openScene(String sceneId) {
    context.go(AppRouter.scenePath(sceneId));
  }
}

class _ExplorerSearchBar extends StatelessWidget {
  const _ExplorerSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Rechercher une scène',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppThemeTokens.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppThemeTokens.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppThemeTokens.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: AppThemeTokens.primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: GoogleFonts.dmSans(
              color: AppThemeTokens.tertiaryText(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : AppThemeTokens.surface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? primary : AppThemeTokens.border(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: isSelected ? Colors.white : AppThemeTokens.primaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PopularSceneCard extends StatelessWidget {
  const _PopularSceneCard({required this.scene, required this.onTap});

  final SceneModel scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeTokens.surface(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SceneThumbnail(scene: scene)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppThemeTokens.primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scene.author.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: AppThemeTokens.tertiaryText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${scene.viewsCount} vues',
                      style: GoogleFonts.dmSans(
                        color: AppThemeTokens.tertiaryText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
  const _MiniSceneCard({required this.scene, required this.onTap});

  final SceneModel scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeTokens.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppThemeTokens.border(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _SceneThumbnail(scene: scene),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppThemeTokens.primaryText(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scene.description.isNotEmpty ? scene.description : scene.category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: AppThemeTokens.tertiaryText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${scene.viewsCount} vues • ${scene.durationSeconds}s',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: AppThemeTokens.tertiaryText(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class _SceneThumbnail extends StatelessWidget {
  const _SceneThumbnail({required this.scene});

  final SceneModel scene;

  @override
  Widget build(BuildContext context) {
    final thumbnail = scene.thumbnailUrl;
    if (thumbnail.startsWith('assets/')) {
      return Image.asset(
        thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _ThumbnailFallback(scene: scene),
      );
    }
    if (thumbnail.startsWith('http://') || thumbnail.startsWith('https://')) {
      return Image.network(
        thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _ThumbnailFallback(scene: scene),
      );
    }
    return _ThumbnailFallback(scene: scene);
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.scene});

  final SceneModel scene;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.90),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            scene.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyExplorerState extends StatelessWidget {
  const _EmptyExplorerState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.explore_off_rounded,
            color: AppThemeTokens.tertiaryText(context),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'Aucune scène à afficher pour le moment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppThemeTokens.primaryText(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}