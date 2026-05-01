import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/explorer_providers.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/location_region_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedScenes = ref.watch(feedProvider).scenes;
    final locationState = ref.watch(explorerLocationProvider);
    final palette = _ExplorerPalette.of(context);
    final visiblePopular = _ExplorerMockData.popularScenes
        .map((scene) => scene.withResolvedSceneId(_resolveSceneId(scene, feedScenes)))
        .where(_matches)
        .toList();
    final visibleNew = _ExplorerMockData.newScenes
        .map((scene) => scene.withResolvedSceneId(_resolveSceneId(scene, feedScenes)))
        .where(_matches)
        .toList();

    return Scaffold(
      backgroundColor: palette.backgroundBase,
      body: Container(
        decoration: BoxDecoration(gradient: palette.pageGradient),
        child: Stack(
          children: [
            Positioned(
              top: -84,
              right: -54,
              child: _AmbientGlow(size: 240, color: palette.goldGlow),
            ),
            Positioned(
              top: 196,
              left: -48,
              child: _AmbientGlow(size: 186, color: palette.cyanGlow),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 118),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExplorerSearchBar(
                      controller: _searchController,
                      palette: palette,
                      onChanged: (value) => setState(() => _query = value),
                      onActionTap: _openFiltersSheet,
                    ),
                    const SizedBox(height: 14),
                    ExplorerLocationBanner(
                      onChange: _openLocationSheet,
                      onRedetect: _redetectLocation,
                      isDetecting: locationState.isResolving,
                    ),
                    const SizedBox(height: 12),
                    _QuickChipsBar(
                      palette: palette,
                      onResetCategory: () =>
                          setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(height: 16),
                    _RegionalRankingSection(palette: palette),
                    const SizedBox(height: 18),
                    _NationalRankingSection(palette: palette),
                    const SizedBox(height: 18),
                    _NewScenariosSection(
                      palette: palette,
                      onPlay: (id) => _openScene(id),
                    ),
                    const SizedBox(height: 18),
                    _TrendingScenesSection(
                      palette: palette,
                      onPlay: (id) => _openScene(id),
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(label: 'Catégories', palette: palette),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final tileWidth = (constraints.maxWidth - gap * 4) / 5;
                        return Row(
                          children: [
                            for (var index = 0; index < _ExplorerMockData.categories.length; index++) ...[
                              SizedBox(
                                width: tileWidth,
                                child: _CategoryTile(
                                  data: _ExplorerMockData.categories[index],
                                  palette: palette,
                                  selected: _selectedCategory ==
                                      _ExplorerMockData.categories[index].label,
                                  onTap: () {
                                    final tapped = _ExplorerMockData.categories[index];
                                    setState(() {
                                      if (tapped.isMoreTile) {
                                        _resetFilters();
                                        return;
                                      }
                                      _selectedCategory =
                                          _selectedCategory == tapped.label
                                              ? null
                                              : tapped.label;
                                    });
                                  },
                                ),
                              ),
                              if (index != _ExplorerMockData.categories.length - 1)
                                const SizedBox(width: gap),
                            ],
                          ],
                        );
                      },
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      _SectionTitle(label: 'Scènes populaires', palette: palette),
                      const SizedBox(height: 10),
                      if (visiblePopular.isEmpty)
                        _EmptyExplorerState(
                          label: 'Aucune scène populaire pour ce filtre.',
                          palette: palette,
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (var index = 0; index < visiblePopular.length; index++) ...[
                                _PopularSceneCard(
                                  scene: visiblePopular[index],
                                  palette: palette,
                                  onTap: () => _openScene(visiblePopular[index].resolvedSceneId),
                                ),
                                if (index != visiblePopular.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      _SectionTitle(label: 'Nouvelles scènes', palette: palette),
                      const SizedBox(height: 10),
                      if (visibleNew.isEmpty)
                        _EmptyExplorerState(
                          label: 'Aucune nouvelle scène pour ce filtre.',
                          palette: palette,
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (var index = 0; index < visibleNew.length; index++) ...[
                                _MiniSceneCard(
                                  scene: visibleNew[index],
                                  palette: palette,
                                  onTap: () => _openScene(visibleNew[index].resolvedSceneId),
                                ),
                                if (index != visibleNew.length - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(_ExplorerSceneData scene) {
    final normalizedQuery = _query.trim().toLowerCase();
    final categoryMatches = _selectedCategory == null || _selectedCategory == scene.category;
    final haystack = '${scene.title} ${scene.category} ${scene.subtitle}'.toLowerCase();
    final queryMatches = normalizedQuery.isEmpty || haystack.contains(normalizedQuery);
    return categoryMatches && queryMatches;
  }

  String? _resolveSceneId(_ExplorerSceneData mockScene, List<SceneModel> feedScenes) {
    if (feedScenes.isEmpty) {
      return null;
    }

    final keywordMatches = mockScene.matchKeywords.map((keyword) => keyword.toLowerCase());
    for (final feedScene in feedScenes) {
      final haystack = [
        feedScene.title,
        feedScene.category,
        feedScene.description,
        feedScene.dialogueText,
      ].join(' ').toLowerCase();
      if (keywordMatches.any(haystack.contains)) {
        return feedScene.id;
      }
    }

    final fallbackIndex = mockScene.fallbackFeedIndex;
    if (fallbackIndex >= 0 && fallbackIndex < feedScenes.length) {
      return feedScenes[fallbackIndex].id;
    }
    return feedScenes.first.id;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = null;
    });
    ref.read(explorerFilterProvider.notifier).reset();
  }

  void _openScene(String? sceneId) {
    if (sceneId == null || sceneId.isEmpty) {
      return;
    }
    context.go(AppRouter.scenePath(sceneId));
  }

  Future<void> _redetectLocation() async {
    final location = await ref.read(explorerLocationProvider.notifier).redetect();
    if (!mounted) return;

    if (location.requiresManualSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Localisation indisponible. Choisissez votre région manuellement.',
          ),
        ),
      );
      await _openLocationSheet();
      return;
    }

    ref.read(explorerFilterProvider.notifier).applyDetectedLocation(
          countryCode: location.countryCode,
          countryName: location.countryName,
          regionCode: location.regionCode,
          regionName: location.regionName,
          overrideUserSelection: true,
        );

    final label = location.hasRegion
        ? 'Région détectée : ${location.regionName}'
        : 'Pays détecté : ${location.countryName}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  Future<void> _openLocationSheet() async {
    final palette = _ExplorerPalette.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.backgroundBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const ExplorerLocationPickerSheet(),
    );
  }

  Future<void> _openFiltersSheet() async {
    final palette = _ExplorerPalette.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.backgroundBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _AdvancedFiltersSheet(onReset: _resetFilters),
    );
  }
}

class _ExplorerSearchBar extends StatelessWidget {
  const _ExplorerSearchBar({
    required this.controller,
    required this.palette,
    required this.onChanged,
    required this.onActionTap,
  });

  final TextEditingController controller;
  final _ExplorerPalette palette;
  final ValueChanged<String> onChanged;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: palette.isDark ? 12 : 6, sigmaY: palette.isDark ? 12 : 6),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.searchBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.searchBorder),
            boxShadow: [
              BoxShadow(
                color: palette.searchShadow,
                blurRadius: palette.isDark ? 18 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 16, color: palette.searchMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: GoogleFonts.dmSans(
                    color: palette.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: palette.primaryAccent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Rechercher une scène...',
                    hintStyle: GoogleFonts.dmSans(
                      color: palette.searchMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onActionTap,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB800).withValues(alpha: palette.isDark ? 0.24 : 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 12,
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
  const _SectionTitle({required this.label, required this.palette});

  final String label;
  final _ExplorerPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: palette.primaryText,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.18,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.data,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final _ExplorerCategoryData data;
  final _ExplorerPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFB800);
    final tileBackground = data.isMoreTile ? palette.moreTileBackground : yellow;
    final iconColor =
        data.isMoreTile ? palette.moreTileForeground : const Color(0xFF0B1020);
    final activeBorder = data.isMoreTile
        ? palette.tileSelectedBorder
        : const Color(0xFF0B1020);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 0.97 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: palette.primaryText,
                fontSize: data.label == 'Comédie' ? 10.4 : 11,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: tileBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? activeBorder : palette.tileBorder,
                  width: selected ? 1.6 : 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? activeBorder.withValues(alpha: 0.20)
                        : Colors.transparent,
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      data.icon,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularSceneCard extends StatelessWidget {
  const _PopularSceneCard({
    required this.scene,
    required this.palette,
    required this.onTap,
  });

  final _ExplorerSceneData scene;
  final _ExplorerPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FeaturedExplorerCard(scene: scene, palette: palette, onTap: onTap);
  }
}

class _MiniSceneCard extends StatelessWidget {
  const _MiniSceneCard({
    required this.scene,
    required this.palette,
    required this.onTap,
  });

  final _ExplorerSceneData scene;
  final _ExplorerPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FeaturedExplorerCard(scene: scene, palette: palette, onTap: onTap);
  }
}

class _FeaturedExplorerCard extends StatelessWidget {
  const _FeaturedExplorerCard({
    required this.scene,
    required this.palette,
    required this.onTap,
  });

  final _ExplorerSceneData scene;
  final _ExplorerPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 178,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SceneArtwork(assetPath: scene.assetPath, fallbackColor: scene.fallbackColor, palette: palette),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      palette.cardOverlaySoft,
                      palette.cardOverlayMid,
                      palette.cardOverlayStrong,
                    ],
                    stops: const [0.0, 0.30, 0.52, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: scene.badgeColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.cardChipBorder),
                  ),
                  child: Text(
                    scene.category,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: palette.cardChipText,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.08,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        UserAvatar(
                          url: scene.authorAvatarUrl,
                          userId: scene.authorName,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scene.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 4),
                        Text(
                          _formatCompact(scene.likesCount),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.play_circle_fill_rounded, size: 14, color: Color(0xFF47D7FF)),
                        const SizedBox(width: 4),
                        Text(
                          scene.duration,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.80),
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
}

class _SceneArtwork extends StatelessWidget {
  const _SceneArtwork({
    required this.assetPath,
    required this.fallbackColor,
    required this.palette,
  });

  final String assetPath;
  final Color fallbackColor;
  final _ExplorerPalette palette;

  @override
  Widget build(BuildContext context) {
    final background = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fallbackColor,
            Color.lerp(fallbackColor, palette.backgroundBase, palette.isDark ? 0.45 : 0.32)!,
          ],
        ),
      ),
    );

    if (assetPath.endsWith('.svg')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          background,
          Padding(
            padding: const EdgeInsets.all(16),
            child: SvgPicture.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EmptyExplorerState extends StatelessWidget {
  const _EmptyExplorerState({required this.label, required this.palette});

  final String label;
  final _ExplorerPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: palette.emptyBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.emptyBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: palette.secondaryText,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

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
              blurRadius: size * 0.44,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerPalette {
  const _ExplorerPalette._({
    required this.isDark,
    required this.backgroundBase,
    required this.pageGradient,
    required this.primaryText,
    required this.secondaryText,
    required this.searchBackground,
    required this.searchBorder,
    required this.searchShadow,
    required this.searchMuted,
    required this.primaryAccent,
    required this.moreTileBackground,
    required this.moreTileForeground,
    required this.tileBorder,
    required this.tileSelectedBorder,
    required this.cardBorder,
    required this.cardShadow,
    required this.cardChipBackground,
    required this.cardChipBorder,
    required this.cardChipText,
    required this.cardOverlaySoft,
    required this.cardOverlayMid,
    required this.cardOverlayStrong,
    required this.emptyBackground,
    required this.emptyBorder,
    required this.goldGlow,
    required this.cyanGlow,
  });

  final bool isDark;
  final Color backgroundBase;
  final Gradient pageGradient;
  final Color primaryText;
  final Color secondaryText;
  final Color searchBackground;
  final Color searchBorder;
  final Color searchShadow;
  final Color searchMuted;
  final Color primaryAccent;
  final Color moreTileBackground;
  final Color moreTileForeground;
  final Color tileBorder;
  final Color tileSelectedBorder;
  final Color cardBorder;
  final Color cardShadow;
  final Color cardChipBackground;
  final Color cardChipBorder;
  final Color cardChipText;
  final Color cardOverlaySoft;
  final Color cardOverlayMid;
  final Color cardOverlayStrong;
  final Color emptyBackground;
  final Color emptyBorder;
  final Color goldGlow;
  final Color cyanGlow;

  static _ExplorerPalette of(BuildContext context) {
    final dark = AppThemeTokens.isDark(context);
    if (dark) {
      return const _ExplorerPalette._(
        isDark: true,
        backgroundBase: Color(0xFF0B1020),
        pageGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1020), Color(0xFF111827)],
        ),
        primaryText: Colors.white,
        secondaryText: Color.fromRGBO(255, 255, 255, 0.72),
        searchBackground: Color.fromRGBO(255, 255, 255, 0.06),
        searchBorder: Color.fromRGBO(255, 255, 255, 0.08),
        searchShadow: Color.fromRGBO(0, 0, 0, 0.20),
        searchMuted: Color.fromRGBO(255, 255, 255, 0.48),
        primaryAccent: Color(0xFF00D4FF),
        moreTileBackground: Color(0xFFECEEF6),
        moreTileForeground: Color(0xFF0B1020),
        tileBorder: Color.fromRGBO(255, 255, 255, 0.10),
        tileSelectedBorder: Color.fromRGBO(255, 255, 255, 0.60),
        cardBorder: Color.fromRGBO(255, 255, 255, 0.10),
        cardShadow: Color.fromRGBO(0, 0, 0, 0.24),
        cardChipBackground: Color.fromRGBO(0, 0, 0, 0.34),
        cardChipBorder: Color.fromRGBO(255, 255, 255, 0.10),
        cardChipText: Colors.white,
        cardOverlaySoft: Color.fromRGBO(0, 0, 0, 0.14),
        cardOverlayMid: Color.fromRGBO(0, 0, 0, 0.28),
        cardOverlayStrong: Color.fromRGBO(0, 0, 0, 0.84),
        emptyBackground: Color.fromRGBO(255, 255, 255, 0.05),
        emptyBorder: Color.fromRGBO(255, 255, 255, 0.08),
        goldGlow: Color.fromRGBO(255, 184, 0, 0.08),
        cyanGlow: Color.fromRGBO(0, 212, 255, 0.06),
      );
    }
    return const _ExplorerPalette._(
      isDark: false,
      backgroundBase: Color(0xFFF7F9FD),
      pageGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FC)],
      ),
      primaryText: Color(0xFF111827),
      secondaryText: Color(0xFF667085),
      searchBackground: Color.fromRGBO(255, 255, 255, 0.88),
      searchBorder: Color.fromRGBO(17, 24, 39, 0.08),
      searchShadow: Color.fromRGBO(17, 24, 39, 0.08),
      searchMuted: Color.fromRGBO(17, 24, 39, 0.44),
      primaryAccent: Color(0xFF6C5CE7),
      moreTileBackground: Color(0xFFF4F6FA),
      moreTileForeground: Color(0xFF111827),
      tileBorder: Color.fromRGBO(17, 24, 39, 0.08),
      tileSelectedBorder: Color.fromRGBO(17, 24, 39, 0.18),
      cardBorder: Color.fromRGBO(17, 24, 39, 0.08),
      cardShadow: Color.fromRGBO(17, 24, 39, 0.10),
      cardChipBackground: Color.fromRGBO(11, 16, 32, 0.58),
      cardChipBorder: Color.fromRGBO(255, 255, 255, 0.12),
      cardChipText: Colors.white,
      cardOverlaySoft: Color.fromRGBO(11, 16, 32, 0.08),
      cardOverlayMid: Color.fromRGBO(11, 16, 32, 0.18),
      cardOverlayStrong: Color.fromRGBO(11, 16, 32, 0.76),
      emptyBackground: Color.fromRGBO(255, 255, 255, 0.90),
      emptyBorder: Color.fromRGBO(17, 24, 39, 0.08),
      goldGlow: Color.fromRGBO(255, 184, 0, 0.05),
      cyanGlow: Color.fromRGBO(0, 212, 255, 0.04),
    );
  }
}

class _ExplorerCategoryData {
  const _ExplorerCategoryData({
    required this.label,
    required this.color,
    required this.icon,
    this.isMoreTile = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool isMoreTile;
}

class _ExplorerSceneData {
  const _ExplorerSceneData({
    required this.title,
    required this.duration,
    required this.category,
    required this.assetPath,
    required this.fallbackColor,
    required this.badgeColor,
    required this.authorName,
    required this.likesCount,
    required this.matchKeywords,
    required this.fallbackFeedIndex,
    this.subtitle,
    this.authorAvatarUrl,
    this.resolvedSceneId,
  });

  final String title;
  final String duration;
  final String category;
  final String assetPath;
  final Color fallbackColor;
  final Color badgeColor;
  final String authorName;
  final int likesCount;
  final List<String> matchKeywords;
  final int fallbackFeedIndex;
  final String? subtitle;
  final String? authorAvatarUrl;
  final String? resolvedSceneId;

  _ExplorerSceneData withResolvedSceneId(String? sceneId) {
    return _ExplorerSceneData(
      title: title,
      duration: duration,
      category: category,
      assetPath: assetPath,
      fallbackColor: fallbackColor,
      badgeColor: badgeColor,
      authorName: authorName,
      likesCount: likesCount,
      matchKeywords: matchKeywords,
      fallbackFeedIndex: fallbackFeedIndex,
      subtitle: subtitle,
      authorAvatarUrl: authorAvatarUrl,
      resolvedSceneId: sceneId,
    );
  }
}

class _ExplorerMockData {
  static const categories = <_ExplorerCategoryData>[
    _ExplorerCategoryData(
      label: 'Drame',
      color: Color(0xFF6C5CE7),
      icon: Icons.theater_comedy_rounded,
    ),
    _ExplorerCategoryData(
      label: 'Comédie',
      color: Color(0xFF25C6A6),
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    _ExplorerCategoryData(
      label: 'Action',
      color: Color(0xFF00B8FF),
      icon: Icons.flash_on_rounded,
    ),
    _ExplorerCategoryData(
      label: 'Romance',
      color: Color(0xFFE95A74),
      icon: Icons.favorite_rounded,
    ),
    _ExplorerCategoryData(
      label: 'Plus',
      color: Color(0xFFECEEF6),
      icon: Icons.grid_view_rounded,
      isMoreTile: true,
    ),
  ];

  static const popularScenes = <_ExplorerSceneData>[
    _ExplorerSceneData(
      title: 'Rupture\nau téléphone',
      duration: '01:33',
      category: 'Drame',
      assetPath: 'assets/scenes/scene_rupture_telephone.svg',
      fallbackColor: Color(0xFF5A2D54),
      badgeColor: Color(0xCC6C5CE7),
      authorName: 'Luna Demo',
      likesCount: 1800,
      authorAvatarUrl: 'assets/scenes/battle_player_a.png',
      matchKeywords: ['rupture', 'telephone', 'drame'],
      fallbackFeedIndex: 0,
    ),
    _ExplorerSceneData(
      title: 'Interrogatoire\ntendu',
      duration: '01:15',
      category: 'Action',
      assetPath: 'assets/scenes/scene_interrogatoire.svg',
      fallbackColor: Color(0xFF1F4564),
      badgeColor: Color(0xCC00B8FF),
      authorName: 'Max Demo',
      likesCount: 1500,
      authorAvatarUrl: 'assets/scenes/battle_player_b.png',
      matchKeywords: ['interrogatoire', 'tendu', 'action'],
      fallbackFeedIndex: 1,
    ),
    _ExplorerSceneData(
      title: 'Déclaration\nd\'amour',
      duration: '01:25',
      category: 'Romance',
      assetPath: 'assets/scenes/scene_declaration_amour.svg',
      fallbackColor: Color(0xFF7C3854),
      badgeColor: Color(0xCCE95A74),
      authorName: 'Iris Demo',
      likesCount: 2100,
      authorAvatarUrl: 'assets/scenes/battle_player_a.png',
      matchKeywords: ['declaration', 'amour', 'romance'],
      fallbackFeedIndex: 2,
    ),
  ];

  static const newScenes = <_ExplorerSceneData>[
    _ExplorerSceneData(
      title: 'Confrontation',
      subtitle: 'Face à face sous pression',
      duration: '00:58',
      category: 'Action',
      assetPath: 'assets/scenes/scene_confrontation.svg',
      fallbackColor: Color(0xFF214669),
      badgeColor: Color(0xCC00B8FF),
      authorName: 'Max Demo',
      likesCount: 1200,
      authorAvatarUrl: 'assets/scenes/battle_player_b.png',
      matchKeywords: ['confrontation', 'face', 'action'],
      fallbackFeedIndex: 0,
    ),
    _ExplorerSceneData(
      title: 'Mauvaise\nnouvelle',
      subtitle: 'Annonce impossible à retenir',
      duration: '01:04',
      category: 'Drame',
      assetPath: 'assets/scenes/scene_mauvaise_nouvelle.svg',
      fallbackColor: Color(0xFF5A3658),
      badgeColor: Color(0xCC6C5CE7),
      authorName: 'Luna Demo',
      likesCount: 980,
      authorAvatarUrl: 'assets/scenes/battle_player_a.png',
      matchKeywords: ['mauvaise', 'nouvelle', 'drame'],
      fallbackFeedIndex: 1,
    ),
    _ExplorerSceneData(
      title: 'Spotlight\ndu jour',
      subtitle: 'Mise en avant premium',
      duration: '00:45',
      category: 'Comédie',
      assetPath: 'assets/scenes/daily_challenge_spotlight.svg',
      fallbackColor: Color(0xFF1E4C5A),
      badgeColor: Color(0xCC25C6A6),
      authorName: 'Take60 Studio',
      likesCount: 1450,
      matchKeywords: ['spotlight', 'challenge', 'comedie'],
      fallbackFeedIndex: 2,
    ),
  ];
}

String _formatCompact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

// ────────────────────────────────────────────────────────────────────────────
// Bandeau localisation auto-détectée + accès au sélecteur manuel.
// ────────────────────────────────────────────────────────────────────────────

class ExplorerLocationBanner extends ConsumerWidget {
  const ExplorerLocationBanner({
    super.key,
    required this.onChange,
    required this.onRedetect,
    required this.isDetecting,
  });

  final VoidCallback onChange;
  final VoidCallback onRedetect;
  final bool isDetecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _ExplorerPalette.of(context);
    final loc = ref.watch(explorerLocationProvider);
    final l = loc.location;
    final hasRegion = l?.hasRegion ?? false;
    final requiresManual = l == null || l.requiresManualSelection;
    final permissionDenied = l?.permissionDenied ?? false;
    final detectedLine = isDetecting && l == null
      ? 'Détection de votre région...'
      : requiresManual
        ? permissionDenied
          ? 'Localisation refusée. Vous pouvez choisir votre région manuellement.'
          : 'Choisissez votre pays et votre région pour voir les classements locaux.'
        : hasRegion
          ? 'Votre région détectée : ${l.regionName}'
          : 'Pays détecté : ${l.countryName}';
    final secondLine = requiresManual
      ? 'Utilisée uniquement pour afficher les scènes et classements proches de vous.'
      : 'Utilisée uniquement pour afficher les scènes et classements proches de vous.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.searchBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.searchBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF0B1020),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detectedLine,
                  style: GoogleFonts.dmSans(
                    color: palette.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondLine,
                  style: GoogleFonts.dmSans(
                    color: palette.secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: isDetecting ? null : onChange,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: palette.isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.08)
                      : const Color(0xFFFFF7DC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  requiresManual ? 'Choisir ma région' : 'Modifier',
                  style: GoogleFonts.dmSans(
                    color: palette.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: isDetecting ? null : onRedetect,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: palette.isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.05)
                      : const Color(0xFFF4F5F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isDetecting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: palette.primaryText,
                        ),
                      )
                    : Text(
                        requiresManual ? 'Auto-détecter' : 'Auto-détecter à nouveau',
                        style: GoogleFonts.dmSans(
                          color: palette.primaryText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bottom sheet : choix manuel pays + région.
// ────────────────────────────────────────────────────────────────────────────

class ExplorerLocationPickerSheet extends ConsumerStatefulWidget {
  const ExplorerLocationPickerSheet({super.key});

  @override
  ConsumerState<ExplorerLocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<ExplorerLocationPickerSheet> {
  CountryOption? _country;
  RegionOption? _region;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(explorerLocationProvider).location;
    if (loc != null) {
      _country = LocationRegionService.supportedCountries.firstWhere(
        (c) => c.code == loc.countryCode,
        orElse: () => const CountryOption('FR', 'France'),
      );
      final regions =
          LocationRegionService.regionsByCountry[_country!.code] ?? const [];
      if (loc.regionCode.isNotEmpty) {
        for (final r in regions) {
          if (r.code == loc.regionCode) {
            _region = r;
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(explorerLocationProvider);
    final palette = _ExplorerPalette.of(context);
    final regions =
        LocationRegionService.regionsByCountry[_country?.code ?? ''] ?? const [];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.searchBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ma région',
              style: GoogleFonts.dmSans(
                color: palette.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La localisation sert uniquement à afficher les classements et '
              'scènes proches de toi.',
              style: GoogleFonts.dmSans(
                color: palette.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text('Pays',
                style: GoogleFonts.dmSans(
                    color: palette.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<CountryOption>(
              initialValue: _country,
              items: [
                for (final c in LocationRegionService.supportedCountries)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() {
                _country = v;
                _region = null;
              }),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.searchBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.searchBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFFB800), width: 1.4),
                ),
              ),
            ),
            if (regions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Région',
                  style: GoogleFonts.dmSans(
                      color: palette.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<RegionOption?>(
                initialValue: _region,
                items: [
                  const DropdownMenuItem<RegionOption?>(
                    value: null,
                    child: Text('Sans région précise'),
                  ),
                  for (final r in regions)
                    DropdownMenuItem<RegionOption?>(
                      value: r,
                      child: Text(r.label),
                    ),
                ],
                onChanged: (v) => setState(() => _region = v),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.searchBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.searchBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFFFB800), width: 1.4),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: locationState.isResolving
                        ? null
                        : () async {
                      final location = await ref
                          .read(explorerLocationProvider.notifier)
                          .redetect();
                      if (!context.mounted) return;
                      if (location.requiresManualSelection) {
                        return;
                      }
                      ref.read(explorerFilterProvider.notifier).applyDetectedLocation(
                            countryCode: location.countryCode,
                            countryName: location.countryName,
                            regionCode: location.regionCode,
                            regionName: location.regionName,
                            overrideUserSelection: true,
                          );
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: palette.searchBackground,
                    ),
                    child: Text(
                      locationState.isResolving ? 'Détection...' : 'Auto-détecter',
                      style: GoogleFonts.dmSans(
                        color: palette.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _country == null
                        ? null
                        : () async {
                            final location = await ref
                                .read(explorerLocationProvider.notifier)
                                .setManual(country: _country!, region: _region);
                            ref.read(explorerFilterProvider.notifier).applyManualLocation(
                                  countryCode: location.countryCode,
                                  countryName: location.countryName,
                                  regionCode: location.regionCode,
                                  regionName: location.regionName,
                                );
                            if (context.mounted) Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: const Color(0xFF0B1020),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Enregistrer',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Barre de chips rapides.
// ────────────────────────────────────────────────────────────────────────────

class _QuickChipsBar extends ConsumerWidget {
  const _QuickChipsBar({required this.palette, required this.onResetCategory});

  final _ExplorerPalette palette;
  final VoidCallback onResetCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(explorerFilterProvider);
    final loc = ref.watch(explorerLocationProvider).location;
    final notifier = ref.read(explorerFilterProvider.notifier);

    final myRegionActive = filter.regionCode != null &&
        loc != null &&
        filter.regionCode == loc.regionCode;
    final myCountryActive = filter.countryCode != null &&
        loc != null &&
        filter.countryCode == loc.countryCode;

    final chips = <_ChipSpec>[
      _ChipSpec(
        label: 'Ma région',
        active: myRegionActive,
        onTap: () {
          if (loc?.regionCode != null) {
            notifier.setCountry(
              myRegionActive ? null : loc!.countryCode,
              name: myRegionActive ? null : loc.countryName,
            );
            notifier.setRegion(
              myRegionActive ? null : loc.regionCode,
              name: myRegionActive ? null : loc.regionName,
            );
          }
        },
      ),
      _ChipSpec(
        label: 'Mon pays',
        active: myCountryActive && !myRegionActive,
        onTap: () {
          if (loc != null) {
            notifier.setRegion(null, name: null);
            notifier.setCountry(
              myCountryActive ? null : loc.countryCode,
              name: myCountryActive ? null : loc.countryName,
            );
          }
        },
      ),
      _ChipSpec(
        label: 'Nouveaux scénarios',
        active: filter.onlyNew,
        onTap: notifier.toggleOnlyNew,
      ),
      _ChipSpec(
        label: 'Tendances',
        active: filter.onlyTrending,
        onTap: notifier.toggleOnlyTrending,
      ),
      for (final cat in const ['Drame', 'Comédie', 'Audition', 'Policier'])
        _ChipSpec(
          label: cat,
          active: filter.category?.toLowerCase() == cat.toLowerCase(),
          onTap: () {
            final isActive =
                filter.category?.toLowerCase() == cat.toLowerCase();
            notifier.setCategory(isActive ? null : cat);
          },
        ),
      _ChipSpec(
        label: 'Débutant',
        active: filter.difficulty?.toLowerCase() == 'débutant',
        onTap: () {
          final isActive = filter.difficulty?.toLowerCase() == 'débutant';
          notifier.setDifficulty(isActive ? null : 'Débutant');
        },
      ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == chips.length) {
            return _QuickChip(
              spec: _ChipSpec(
                label: 'Réinitialiser',
                active: false,
                onTap: () {
                  notifier.reset();
                  onResetCategory();
                },
              ),
              palette: palette,
              isReset: true,
            );
          }
          return _QuickChip(spec: chips[i], palette: palette);
        },
      ),
    );
  }
}

class _ChipSpec {
  const _ChipSpec({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.spec,
    required this.palette,
    this.isReset = false,
  });

  final _ChipSpec spec;
  final _ExplorerPalette palette;
  final bool isReset;

  @override
  Widget build(BuildContext context) {
    final active = spec.active;
    final bg = active
        ? const Color(0xFFFFB800)
        : (isReset
            ? Colors.transparent
            : palette.searchBackground);
    final fg = active ? const Color(0xFF0B1020) : palette.primaryText;
    return GestureDetector(
      onTap: spec.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? const Color(0xFFFFB800)
                : palette.searchBorder,
          ),
        ),
        child: Text(
          spec.label,
          style: GoogleFonts.dmSans(
            color: fg,
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bottom sheet filtres avancés.
// ────────────────────────────────────────────────────────────────────────────

class _AdvancedFiltersSheet extends ConsumerWidget {
  const _AdvancedFiltersSheet({required this.onReset});

  final VoidCallback onReset;

  static const _sceneTypes = [
    'Interrogatoire',
    'Dialogue',
    'Monologue',
    'Conflit',
    'Self-tape',
    'Stand-up',
  ];
  static const _categories = [
    'Drame',
    'Comédie',
    'Action',
    'Romance',
    'Policier',
    'Audition',
  ];
  static const _difficulties = ['Débutant', 'Intermédiaire', 'Avancé'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = _ExplorerPalette.of(context);
    final filter = ref.watch(explorerFilterProvider);
    final notifier = ref.read(explorerFilterProvider.notifier);

    Widget chipGroup(
      String label,
      List<String> options,
      String? currentValue,
      ValueChanged<String?> onChange,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: palette.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in options)
                _QuickChip(
                  palette: palette,
                  spec: _ChipSpec(
                    label: opt,
                    active: currentValue?.toLowerCase() == opt.toLowerCase(),
                    onTap: () {
                      final isActive =
                          currentValue?.toLowerCase() == opt.toLowerCase();
                      onChange(isActive ? null : opt);
                    },
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.searchBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Filtres',
                style: GoogleFonts.dmSans(
                  color: palette.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              chipGroup('Catégorie', _categories, filter.category,
                  notifier.setCategory),
              const SizedBox(height: 14),
              chipGroup('Type de scène', _sceneTypes, filter.sceneType,
                  notifier.setSceneType),
              const SizedBox(height: 14),
              chipGroup('Difficulté', _difficulties, filter.difficulty,
                  notifier.setDifficulty),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        notifier.reset();
                        onReset();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: palette.searchBackground,
                      ),
                      child: Text(
                        'Réinitialiser',
                        style: GoogleFonts.dmSans(
                          color: palette.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFFFB800),
                        foregroundColor: const Color(0xFF0B1020),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Appliquer',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
                      ),
                    ),
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

// ────────────────────────────────────────────────────────────────────────────
// Section : Classement régional (top 3 + CTA).
// ────────────────────────────────────────────────────────────────────────────

class _RegionalRankingSection extends ConsumerWidget {
  const _RegionalRankingSection({required this.palette});

  final _ExplorerPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(explorerLocationProvider).location;
    final entries = (loc != null && loc.hasRegion)
        ? ref.watch(regionalRankingProvider(
        (countryCode: loc.countryCode, regionCode: loc.regionCode)))
        : const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Classement dans ma région',
          subtitle: loc?.hasRegion == true
              ? 'Découvre les acteurs les mieux notés près de toi.'
              : 'Choisis ta région pour voir les classements près de toi.',
          ctaLabel: 'Voir tout',
          onCta: () => context.go(AppRouter.explorerRankingRegional),
          palette: palette,
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _EmptyExplorerState(
            label: 'Aucun classement régional pour le moment.',
            palette: palette,
          )
        else
          Column(
            children: [
              for (final e in entries.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RankingMiniRow(
                    entry: e,
                    palette: palette,
                    badge: 'Top régional',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section : Classement national.
// ────────────────────────────────────────────────────────────────────────────

class _NationalRankingSection extends ConsumerWidget {
  const _NationalRankingSection({required this.palette});

  final _ExplorerPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(explorerLocationProvider).location;
    final entries = loc != null
        ? ref.watch(nationalRankingProvider(loc.countryCode))
        : const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Classement national',
          subtitle: loc != null
              ? 'Compare ton niveau aux meilleurs acteurs de ${loc.countryName}.'
              : 'Compare ton niveau aux meilleurs acteurs du pays.',
          ctaLabel: 'Voir tout',
          onCta: () => context.go(AppRouter.explorerRankingNational),
          palette: palette,
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _EmptyExplorerState(
            label: 'Aucun classement national pour le moment.',
            palette: palette,
          )
        else
          Column(
            children: [
              for (final e in entries.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RankingMiniRow(
                    entry: e,
                    palette: palette,
                    badge: 'Top national',
                    showCountry: true,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _RankingMiniRow extends StatelessWidget {
  const _RankingMiniRow({
    required this.entry,
    required this.palette,
    required this.badge,
    this.showCountry = false,
  });

  final dynamic entry; // RankingEntry
  final _ExplorerPalette palette;
  final String badge;
  final bool showCountry;

  String _fmt(double s) {
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(1)}K';
    return s.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentUser as bool;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFF7DC)
            : palette.searchBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFFE8C56A)
              : palette.searchBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.dmSans(
                color: palette.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          UserAvatar(
            url: entry.avatarUrl as String,
            userId: entry.userId as String,
            size: 32,
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
                        entry.displayName as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: palette.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if ((entry.rank as int) <= 3) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF0B1020),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  showCountry
                      ? entry.countryName as String
                      : entry.regionName as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: palette.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(entry.totalScore as double)} pts',
                style: GoogleFonts.dmSans(
                  color: palette.primaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${entry.voteCount} votes',
                style: GoogleFonts.dmSans(
                  color: palette.secondaryText,
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

// ────────────────────────────────────────────────────────────────────────────
// Section : Nouveaux scénarios.
// ────────────────────────────────────────────────────────────────────────────

class _NewScenariosSection extends ConsumerWidget {
  const _NewScenariosSection({required this.palette, required this.onPlay});

  final _ExplorerPalette palette;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(explorerNewScenesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Nouveaux scénarios à jouer',
          subtitle:
              'Réponds rapidement aux scènes qui viennent d’être publiées.',
          palette: palette,
        ),
        const SizedBox(height: 10),
        if (scenes.isEmpty)
          _EmptyExplorerState(
            label: 'Aucun scénario disponible pour ce filtre.',
            palette: palette,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (var i = 0; i < scenes.length; i++) ...[
                  _ExplorerSceneCardV2(
                    scene: scenes[i],
                    palette: palette,
                    badge: 'Nouveau',
                    badgeColor: const Color(0xFFFFB800),
                    onPlay: () => onPlay(scenes[i].id),
                  ),
                  if (i != scenes.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section : Tendances.
// ────────────────────────────────────────────────────────────────────────────

class _TrendingScenesSection extends ConsumerWidget {
  const _TrendingScenesSection(
      {required this.palette, required this.onPlay});

  final _ExplorerPalette palette;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(explorerTrendingScenesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Scènes tendance',
          subtitle: 'Les scènes les plus jouées et partagées du moment.',
          palette: palette,
        ),
        const SizedBox(height: 10),
        if (scenes.isEmpty)
          _EmptyExplorerState(
            label: 'Aucune scène tendance pour ce filtre.',
            palette: palette,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (var i = 0; i < scenes.length; i++) ...[
                  _ExplorerSceneCardV2(
                    scene: scenes[i],
                    palette: palette,
                    badge: 'Tendance',
                    badgeColor: const Color(0xFFE95A74),
                    onPlay: () => onPlay(scenes[i].id),
                  ),
                  if (i != scenes.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.palette,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final String subtitle;
  final _ExplorerPalette palette;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: palette.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  color: palette.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (ctaLabel != null && onCta != null)
          TextButton(
            onPressed: onCta,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
            ),
            child: Text(
              ctaLabel!,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFFFB800),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Carte scène v2 — utilisée par les sections Nouveaux + Tendances.
// ────────────────────────────────────────────────────────────────────────────

class _ExplorerSceneCardV2 extends StatelessWidget {
  const _ExplorerSceneCardV2({
    required this.scene,
    required this.palette,
    required this.badge,
    required this.badgeColor,
    required this.onPlay,
  });

  final ExplorerScene scene;
  final _ExplorerPalette palette;
  final String badge;
  final Color badgeColor;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: palette.searchBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.searchBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: scene.thumbnailAsset.endsWith('.svg')
                        ? Container(
                            color: const Color(0xFF1F4564),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              scene.thumbnailAsset,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            scene.thumbnailAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1F4564),
                            ),
                          ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF0B1020),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${scene.durationSeconds}s',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: palette.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.15,
                    ),
                  ),
                  Text(
                    scene.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: palette.secondaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scene.category} · ${scene.genre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: palette.secondaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniPill(
                          '${scene.userPlanCount} plans', palette),
                      _miniPill(scene.sceneType, palette),
                      _miniPill(scene.difficulty, palette),
                      _miniPill(scene.regionName, palette),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1020),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Jouer cette scène',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _miniPill(String label, _ExplorerPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.isDark
            ? const Color.fromRGBO(255, 255, 255, 0.06)
            : const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: palette.primaryText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}