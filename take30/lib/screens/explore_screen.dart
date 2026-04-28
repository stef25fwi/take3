import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ExplorerPage();
  }
}

class ExplorerPage extends ConsumerStatefulWidget {
  const ExplorerPage({super.key});

  @override
  ConsumerState<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends ConsumerState<ExplorerPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = ExplorerMockData.categories.first.label;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authProvider.select((state) => state.user?.id)) ?? 'u1';
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = mediaQuery.size.width < 380 ? 18.0 : 22.0;
    final cardWidth = ((mediaQuery.size.width - horizontalPadding * 2) - 24) / 3;

    return Scaffold(
      backgroundColor: ExplorerColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFCF6),
              ExplorerColors.background,
              Color(0xFFF7F1E6),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -20,
              child: _ExplorerGlow(
                size: 220,
                color: Color(0x20F7C53A),
              ),
            ),
            const Positioned(
              top: 220,
              left: -50,
              child: _ExplorerGlow(
                size: 180,
                color: Color(0x167A43D1),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  8,
                  horizontalPadding,
                  148,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MockStatusBar(),
                    const SizedBox(height: 18),
                    ExplorerSearchBar(
                      controller: _searchController,
                      onFilterTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _searchController.clear();
                          _selectedCategory = ExplorerMockData.categories.first.label;
                        });
                      },
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader(title: 'Catégories'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var index = 0;
                            index < ExplorerMockData.categories.length;
                            index++) ...[
                          Expanded(
                            child: CategoryTile(
                              category: ExplorerMockData.categories[index],
                              isSelected: _selectedCategory ==
                                  ExplorerMockData.categories[index].label,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCategory =
                                      ExplorerMockData.categories[index].label;
                                });
                              },
                            ),
                          ),
                          if (index != ExplorerMockData.categories.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(title: 'Scènes populaires'),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          for (var index = 0;
                              index < ExplorerMockData.popularScenes.length;
                              index++) ...[
                            SizedBox(
                              width: cardWidth.clamp(108.0, 132.0),
                              child: PopularSceneCard(
                                scene: ExplorerMockData.popularScenes[index],
                                onTap: () => _openScene(
                                  context,
                                  ExplorerMockData.popularScenes[index].linkedSceneId,
                                ),
                              ),
                            ),
                            if (index != ExplorerMockData.popularScenes.length - 1)
                              const SizedBox(width: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(title: 'Nouvelles scènes'),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          for (var index = 0;
                              index < ExplorerMockData.newScenes.length;
                              index++) ...[
                            SizedBox(
                              width: cardWidth.clamp(108.0, 132.0),
                              child: NewSceneCard(
                                scene: ExplorerMockData.newScenes[index],
                                onTap: () => _openScene(
                                  context,
                                  ExplorerMockData.newScenes[index].linkedSceneId,
                                ),
                              ),
                            ),
                            if (index != ExplorerMockData.newScenes.length - 1)
                              const SizedBox(width: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: mediaQuery.padding.bottom + 16,
              child: FloatingBottomNav(
                currentUserId: currentUserId,
                onHomeTap: () => context.go(AppRouter.home),
                onExploreTap: () => context.go(AppRouter.explore),
                onRecordTap: () => context.go(AppRouter.record),
                onBattleTap: () => context.go(AppRouter.battle),
                onProfileTap: () => context.go(AppRouter.profilePath(currentUserId)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openScene(BuildContext context, String? linkedSceneId) {
    if (linkedSceneId == null || linkedSceneId.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }
    context.go(AppRouter.scenePath(linkedSceneId));
  }
}

class ExplorerSearchBar extends StatelessWidget {
  const ExplorerSearchBar({
    super.key,
    required this.controller,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: ExplorerColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF2E7D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x08E8B623),
            blurRadius: 32,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F2E6),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: ExplorerColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Rechercher une scène...',
                hintStyle: GoogleFonts.dmSans(
                  color: ExplorerColors.textSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF232323), ExplorerColors.blackGlossy],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: ExplorerColors.gold,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: ExplorerColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const Spacer(),
        Text(
          'Tout voir',
          style: GoogleFonts.dmSans(
            color: ExplorerColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: ExplorerColors.textSecondary,
          size: 18,
        ),
      ],
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ExplorerCategoryData category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 108,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: ExplorerColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? category.accent.withValues(alpha: 0.55)
                : const Color(0xFFEDE4D4),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: category.accent.withValues(alpha: isSelected ? 0.18 : 0.08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  category.iconBuilder(),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: _CategoryBadge(category: category),
                  ),
                ],
              ),
            ),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: ExplorerColors.textPrimary,
                fontSize: category.label.length > 7 ? 11 : 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PopularSceneCard extends StatelessWidget {
  const PopularSceneCard({
    super.key,
    required this.scene,
    required this.onTap,
  });

  final ExplorerSceneCardData scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseSceneCard(
      scene: scene,
      onTap: onTap,
      badgeLabel: null,
    );
  }
}

class NewSceneCard extends StatelessWidget {
  const NewSceneCard({
    super.key,
    required this.scene,
    required this.onTap,
  });

  final ExplorerSceneCardData scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseSceneCard(
      scene: scene,
      onTap: onTap,
      badgeLabel: 'NOUVEAU',
    );
  }
}

class _BaseSceneCard extends StatelessWidget {
  const _BaseSceneCard({
    required this.scene,
    required this.onTap,
    required this.badgeLabel,
  });

  final ExplorerSceneCardData scene;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.63,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: ExplorerColors.navyCard,
            boxShadow: [
              BoxShadow(
                color: scene.accentColor.withValues(alpha: 0.16),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
              const BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                scene.artworkBuilder(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.84),
                      ],
                      stops: const [0.0, 0.35, 0.66, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _SceneTopBadge(
                    label: scene.tagLabel,
                    background: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                if (badgeLabel != null)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _SceneTopBadge(
                      label: badgeLabel!,
                      background: ExplorerColors.newPink,
                      textColor: Colors.white,
                    ),
                  ),
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scene.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            scene.duration,
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: scene.accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: scene.accentColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
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

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.currentUserId,
    required this.onHomeTap,
    required this.onExploreTap,
    required this.onRecordTap,
    required this.onBattleTap,
    required this.onProfileTap,
  });

  final String currentUserId;
  final VoidCallback onHomeTap;
  final VoidCallback onExploreTap;
  final VoidCallback onRecordTap;
  final VoidCallback onBattleTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: ExplorerColors.surface,
                borderRadius: BorderRadius.circular(38),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 32,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      label: 'Accueil',
                      icon: Icons.home_rounded,
                      active: false,
                      onTap: onHomeTap,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: 'Explorer',
                      icon: Icons.explore_rounded,
                      active: true,
                      onTap: onExploreTap,
                    ),
                  ),
                  const SizedBox(width: 76),
                  Expanded(
                    child: _NavItem(
                      label: 'Battle',
                      icon: Icons.sports_mma_outlined,
                      active: false,
                      onTap: onBattleTap,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: 'Profil',
                      icon: Icons.person_outline_rounded,
                      active: false,
                      onTap: onProfileTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: RecCenterButton(onTap: onRecordTap),
          ),
        ],
      ),
    );
  }
}

class RecCenterButton extends StatelessWidget {
  const RecCenterButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF262626), ExplorerColors.blackGlossy],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4545),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'REC',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExplorerColors {
  static const background = Color(0xFFFAF8F4);
  static const surface = Color(0xFFFFFDF8);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const gold = Color(0xFFF7C53A);
  static const deepGold = Color(0xFFE8B623);
  static const blackGlossy = Color(0xFF111111);
  static const navyCard = Color(0xFF0F1A2C);
  static const dramaPurple = Color(0xFF7A43D1);
  static const comedyGold = Color(0xFFE0B12F);
  static const spotlightBlue = Color(0xFF36A6E9);
  static const newPink = Color(0xFFFF4F75);
  static const popOrange = Color(0xFFFF9D2F);
  static const topPink = Color(0xFFFF3F8F);
}

class ExplorerMockData {
  static const categories = <ExplorerCategoryData>[
    ExplorerCategoryData(
      label: 'Drame',
      accent: ExplorerColors.deepGold,
      badgeLabel: '',
      badgeBackground: ExplorerColors.gold,
      iconBuilder: _buildDramaIcon,
    ),
    ExplorerCategoryData(
      label: 'Comédie',
      accent: ExplorerColors.comedyGold,
      badgeLabel: 'NOUVEAU',
      badgeBackground: ExplorerColors.dramaPurple,
      iconBuilder: _buildComedyIcon,
    ),
    ExplorerCategoryData(
      label: 'Action',
      accent: ExplorerColors.popOrange,
      badgeLabel: 'POP',
      badgeBackground: ExplorerColors.popOrange,
      iconBuilder: _buildActionIcon,
    ),
    ExplorerCategoryData(
      label: 'Romance',
      accent: ExplorerColors.topPink,
      badgeLabel: 'TOP',
      badgeBackground: ExplorerColors.topPink,
      iconBuilder: _buildRomanceIcon,
    ),
    ExplorerCategoryData(
      label: 'Plus',
      accent: ExplorerColors.blackGlossy,
      badgeLabel: '+99',
      badgeBackground: ExplorerColors.blackGlossy,
      iconBuilder: _buildMoreIcon,
    ),
  ];

  static const popularScenes = <ExplorerSceneCardData>[
    ExplorerSceneCardData(
      title: 'Clash émotionnel explosif',
      duration: '01:00',
      tagLabel: 'drama',
      accentColor: ExplorerColors.dramaPurple,
      artworkBuilder: _buildPopularDramaArtwork,
      linkedSceneId: 's1',
    ),
    ExplorerSceneCardData(
      title: 'Réplique culte, version fun',
      duration: '01:00',
      tagLabel: 'comedy',
      accentColor: ExplorerColors.comedyGold,
      artworkBuilder: _buildPopularComedyArtwork,
      linkedSceneId: 's2',
    ),
    ExplorerSceneCardData(
      title: 'Ton premier take parfait',
      duration: '01:00',
      tagLabel: 'spotlight',
      accentColor: ExplorerColors.spotlightBlue,
      artworkBuilder: _buildPopularSpotlightArtwork,
      linkedSceneId: 's3',
    ),
  ];

  static const newScenes = <ExplorerSceneCardData>[
    ExplorerSceneCardData(
      title: 'Ton premier take peut déjà percer',
      duration: '01:00',
      tagLabel: 'NOUVEAU',
      accentColor: ExplorerColors.newPink,
      artworkBuilder: _buildNewClapArtwork,
      linkedSceneId: 's4',
    ),
    ExplorerSceneCardData(
      title: 'Clash émotionnel en 60 secondes',
      duration: '01:00',
      tagLabel: 'NOUVEAU',
      accentColor: ExplorerColors.spotlightBlue,
      artworkBuilder: _buildNewNeonPortraitArtwork,
      linkedSceneId: 's5',
    ),
    ExplorerSceneCardData(
      title: 'Réplique culte, version face cam',
      duration: '01:00',
      tagLabel: 'NOUVEAU',
      accentColor: ExplorerColors.popOrange,
      artworkBuilder: _buildNewCameraArtwork,
      linkedSceneId: 's2',
    ),
  ];
}

class ExplorerCategoryData {
  const ExplorerCategoryData({
    required this.label,
    required this.accent,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.iconBuilder,
  });

  final String label;
  final Color accent;
  final String badgeLabel;
  final Color badgeBackground;
  final Widget Function() iconBuilder;
}

class ExplorerSceneCardData {
  const ExplorerSceneCardData({
    required this.title,
    required this.duration,
    required this.tagLabel,
    required this.accentColor,
    required this.artworkBuilder,
    required this.linkedSceneId,
  });

  final String title;
  final String duration;
  final String tagLabel;
  final Color accentColor;
  final Widget Function() artworkBuilder;
  final String? linkedSceneId;
}

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '13:42',
          style: GoogleFonts.dmSans(
            color: ExplorerColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const _SignalBars(),
        const SizedBox(width: 8),
        const Icon(Icons.wifi_rounded, size: 17, color: ExplorerColors.textPrimary),
        const SizedBox(width: 8),
        const _BatteryIcon(),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE53B3B),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '9',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SceneTopBadge extends StatelessWidget {
  const _SceneTopBadge({
    required this.label,
    required this.background,
    this.textColor = Colors.white,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final ExplorerCategoryData category;

  @override
  Widget build(BuildContext context) {
    if (category.badgeLabel.isEmpty) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: ExplorerColors.gold,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: category.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: category.badgeBackground.withValues(alpha: 0.26),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        category.badgeLabel,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 7.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? ExplorerColors.gold : ExplorerColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final height in [5.0, 8.0, 11.0, 14.0])
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: ExplorerColors.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 12,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: ExplorerColors.textPrimary, width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ExplorerColors.textPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Container(
          width: 2,
          height: 6,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: ExplorerColors.textPrimary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class _ExplorerGlow extends StatelessWidget {
  const _ExplorerGlow({required this.size, required this.color});

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
              blurRadius: size * 0.46,
              spreadRadius: size * 0.12,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDramaIcon() {
  return Stack(
    alignment: Alignment.center,
    children: [
      Positioned(
        left: 10,
        child: Transform.rotate(
          angle: -0.18,
          child: _MaskShape(
            color: const Color(0xFF131313),
            accent: ExplorerColors.deepGold.withValues(alpha: 0.75),
          ),
        ),
      ),
      Positioned(
        right: 8,
        child: Transform.rotate(
          angle: 0.18,
          child: _MaskShape(
            color: const Color(0xFF2A1E09),
            accent: ExplorerColors.gold.withValues(alpha: 0.85),
          ),
        ),
      ),
    ],
  );
}

Widget _buildComedyIcon() {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFE56F), Color(0xFFF4B92A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text('🤣', style: TextStyle(fontSize: 24)),
        ),
      ),
      Positioned(
        right: 3,
        bottom: 5,
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star_rounded, color: ExplorerColors.gold, size: 11),
        ),
      ),
    ],
  );
}

Widget _buildActionIcon() {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              ExplorerColors.gold.withValues(alpha: 0.28),
              ExplorerColors.popOrange.withValues(alpha: 0.18),
            ],
          ),
        ),
      ),
      ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFFF19B), ExplorerColors.popOrange],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
        child: const Icon(
          Icons.bolt_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    ],
  );
}

Widget _buildRomanceIcon() {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              ExplorerColors.topPink.withValues(alpha: 0.25),
              ExplorerColors.newPink.withValues(alpha: 0.14),
            ],
          ),
        ),
      ),
      ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFFFF90B1), ExplorerColors.topPink],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    ],
  );
}

Widget _buildMoreIcon() {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: ExplorerColors.blackGlossy,
      borderRadius: BorderRadius.circular(16),
    ),
    child: GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(11),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: List.generate(
        4,
        (_) => Container(
          decoration: const BoxDecoration(
            color: ExplorerColors.gold,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

Widget _buildPopularDramaArtwork() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF28182F), Color(0xFF533055), Color(0xFF1B213B)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          left: -12,
          top: 22,
          child: Container(
            width: 80,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        Positioned(
          right: -6,
          top: 12,
          child: Container(
            width: 86,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(42),
            ),
          ),
        ),
        Positioned(
          left: 22,
          top: 24,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5AE),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 26,
          top: 18,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF0CBA9),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPopularComedyArtwork() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF20232E), Color(0xFF46321C), Color(0xFF111827)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 18,
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE56F), ExplorerColors.comedyGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text('😄', style: TextStyle(fontSize: 34)),
              ),
            ),
          ),
        ),
        for (final offset in [18.0, 40.0, 62.0, 84.0])
          Positioned(
            left: offset,
            bottom: 54,
            child: Container(
              width: 10,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildPopularSpotlightArtwork() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0C172D), Color(0xFF1F304B), Color(0xFF0B0E16)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -8,
          left: 36,
          child: Transform.rotate(
            angle: -0.1,
            child: Container(
              width: 62,
              height: 118,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 24,
          bottom: 64,
          child: Icon(Icons.chair_alt_rounded, color: Colors.white70, size: 44),
        ),
        const Positioned(
          right: 12,
          top: 34,
          child: Icon(Icons.videocam_rounded, color: Color(0xFFC7DDF8), size: 38),
        ),
      ],
    ),
  );
}

Widget _buildNewClapArtwork() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B2132), Color(0xFF283249), Color(0xFF111827)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: const Center(
      child: Icon(Icons.movie_creation_rounded, color: Color(0xFFF3F4F6), size: 62),
    ),
  );
}

Widget _buildNewNeonPortraitArtwork() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B2541), Color(0xFF253C7C), Color(0xFF5A1F5F)],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4EDBFF).withValues(alpha: 0.18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4EDBFF).withValues(alpha: 0.28),
                blurRadius: 26,
              ),
            ],
          ),
        ),
        const Icon(Icons.face_retouching_natural_rounded,
            color: Color(0xFFFFB0D1), size: 54),
      ],
    ),
  );
}

Widget _buildNewCameraArtwork() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3C2E20), Color(0xFF70513A), Color(0xFF1A1C24)],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 36,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
        const Icon(Icons.photo_camera_back_rounded,
            color: Color(0xFFF7E2C7), size: 54),
      ],
    ),
  );
}

class _MaskShape extends StatelessWidget {
  const _MaskShape({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 4, height: 5, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
              Container(width: 4, height: 5, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 10,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}