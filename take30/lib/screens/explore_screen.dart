import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                      onActionTap: _resetFilters,
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 16),
                    _SectionTitle(label: 'Scènes populaires', palette: palette),
                    const SizedBox(height: 10),
                    if (visiblePopular.isEmpty)
                      _EmptyExplorerState(
                        label: 'Aucune scène populaire pour ce filtre.',
                        palette: palette,
                      )
                    else
                      Row(
                        children: [
                          for (var index = 0; index < visiblePopular.length; index++) ...[
                            Expanded(
                              child: _PopularSceneCard(
                                scene: visiblePopular[index],
                                palette: palette,
                                onTap: () => _openScene(visiblePopular[index].resolvedSceneId),
                              ),
                            ),
                            if (index != visiblePopular.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
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
  }

  void _openScene(String? sceneId) {
    if (sceneId == null || sceneId.isEmpty) {
      return;
    }
    context.go(AppRouter.scenePath(sceneId));
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
    final tileBackground = data.isMoreTile
        ? palette.moreTileBackground
        : palette.isDark
            ? data.color
            : Color.lerp(data.color, Colors.white, 0.18)!;
    final contentColor = data.isMoreTile
        ? palette.moreTileForeground
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: tileBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? palette.tileSelectedBorder : palette.tileBorder,
              width: selected ? 1.4 : 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? tileBackground.withValues(alpha: 0.22) : Colors.transparent,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, size: 17, color: contentColor),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: contentColor,
                  fontSize: data.label == 'Comédie' ? 9.4 : 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.08,
                ),
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.64,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
                        Colors.transparent,
                        palette.cardOverlayMid,
                        palette.cardOverlayStrong,
                      ],
                      stops: const [0.0, 0.42, 0.72, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.cardChipBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.cardChipBorder),
                    ),
                    child: Text(
                      scene.category,
                      style: GoogleFonts.dmSans(
                        color: palette.cardChipText,
                        fontSize: 9.6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12.6,
                          fontWeight: FontWeight.w600,
                          height: 1.08,
                          letterSpacing: -0.12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scene.duration,
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 10.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 114,
        child: AspectRatio(
          aspectRatio: 0.90,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: palette.cardShadow.withValues(alpha: palette.isDark ? 0.82 : 0.50),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                          palette.cardOverlayStrong,
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.cardChipBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.cardChipBorder),
                      ),
                      child: Text(
                        scene.duration,
                        style: GoogleFonts.dmSans(
                          color: palette.cardChipText,
                          fontSize: 9.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      scene.subtitle ?? scene.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                        height: 1.12,
                        letterSpacing: -0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    required this.matchKeywords,
    required this.fallbackFeedIndex,
    this.subtitle,
    this.resolvedSceneId,
  });

  final String title;
  final String duration;
  final String category;
  final String assetPath;
  final Color fallbackColor;
  final List<String> matchKeywords;
  final int fallbackFeedIndex;
  final String? subtitle;
  final String? resolvedSceneId;

  _ExplorerSceneData withResolvedSceneId(String? sceneId) {
    return _ExplorerSceneData(
      title: title,
      duration: duration,
      category: category,
      assetPath: assetPath,
      fallbackColor: fallbackColor,
      matchKeywords: matchKeywords,
      fallbackFeedIndex: fallbackFeedIndex,
      subtitle: subtitle,
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
      matchKeywords: ['rupture', 'telephone', 'drame'],
      fallbackFeedIndex: 0,
    ),
    _ExplorerSceneData(
      title: 'Interrogatoire\ntendu',
      duration: '01:15',
      category: 'Action',
      assetPath: 'assets/scenes/scene_interrogatoire.svg',
      fallbackColor: Color(0xFF1F4564),
      matchKeywords: ['interrogatoire', 'tendu', 'action'],
      fallbackFeedIndex: 1,
    ),
    _ExplorerSceneData(
      title: 'Déclaration\nd\'amour',
      duration: '01:25',
      category: 'Romance',
      assetPath: 'assets/scenes/scene_declaration_amour.svg',
      fallbackColor: Color(0xFF7C3854),
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
      matchKeywords: ['spotlight', 'challenge', 'comedie'],
      fallbackFeedIndex: 2,
    ),
  ];
}