import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PROFIL TALENT — Page 9 Pixel-Perfect
// ──────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    final profileState = ref.watch(profileProvider(userId));
    final user = profileState.user ??
        (authUser?.id == userId ? authUser : null);
    final scenes = profileState.scenes;
    final pageBackground = AppThemeTokens.pageBackground(context);
    final primaryText = AppThemeTokens.primaryText(context);

    if (user == null && profileState.isLoading) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Profil introuvable.',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: _ProfileBody(userId: userId, user: user, scenes: scenes),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    required this.userId,
    required this.user,
    required this.scenes,
  });

  final String userId;
  final UserModel user;
  final List<SceneModel> scenes;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRouter.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveUser =
        ref.watch(profileProvider(widget.userId)).user ?? widget.user;
    final sceneCount = widget.scenes.length > 6 ? 6 : widget.scenes.length;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isDemoProfile = _isDemoProfile(liveUser);

    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeTokens.pageGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onLogout: _onLogout),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppThemeTokens.pageHorizontalPadding,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _IdentityBloc(user: liveUser),
                          const SizedBox(height: 18),
                          _StatsRow(user: liveUser),
                          const SizedBox(height: 18),
                          _ActionButtons(
                            isFollowing: liveUser.isFollowing,
                            onFollowTap: () {
                              ref
                                  .read(profileProvider(widget.userId).notifier)
                                  .toggleFollow();
                            },
                            onMessageTap: () {
                              context.go(AppRouter.messagesPath(widget.userId));
                            },
                            onShareTap: () {
                              ref
                                  .read(profileProvider(widget.userId).notifier)
                                  .shareProfile();
                            },
                          ),
                          if (isDemoProfile) ...[
                            const SizedBox(height: 14),
                            _ThemeToggleCard(
                              isDarkMode: isDarkMode,
                              onChanged: (value) {
                                ref.read(themeModeProvider.notifier).setMode(
                                      value ? ThemeMode.dark : ThemeMode.light,
                                    );
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(tabController: _tabCtrl),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppThemeTokens.pageHorizontalPadding,
                    ),
                    sliver: sceneCount == 0
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                'Aucune performance publiée pour l’instant.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.66),
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final scene = widget.scenes[index];
                                return _PerformanceCard(
                                  scene: scene,
                                  index: index,
                                  onTap: () =>
                                      context.go(AppRouter.scenePath(scene.id)),
                                );
                              },
                              childCount: sceneCount,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Top Bar
// ──────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final iconColor = AppThemeTokens.primaryText(context);
    final popupColor = AppThemeTokens.chromeSurface(context);
    final textColor = AppThemeTokens.primaryText(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRouter.home);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: iconColor,
                  size: 28,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => context.go(AppRouter.explore),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.search_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: iconColor,
                  size: 22,
                ),
                color: popupColor,
                onSelected: (value) {
                  switch (value) {
                    case 'leaderboard':
                      context.go(AppRouter.leaderboard);
                    case 'badges':
                      context.go(AppRouter.badges);
                    case 'logout':
                      onLogout();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'leaderboard',
                    child: Text(
                      'Voir le classement',
                      style: GoogleFonts.dmSans(color: textColor),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'badges',
                    child: Text(
                      'Badges & stats',
                      style: GoogleFonts.dmSans(color: textColor),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(
                      'Se déconnecter',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Identity Bloc
// ──────────────────────────────────────────────────────────────────────────────

class _IdentityBloc extends StatelessWidget {
  const _IdentityBloc({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileAvatar(user: user, size: 78),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppThemeTokens.primaryText(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DA1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Actrice / Créatrice',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppThemeTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Profile Avatar with warm cinema border
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.size});

  final UserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = avatarPhotoAssetForUserId(user.id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A42),
            Color(0xFFFFB800),
            Color(0xFFFF6B2C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9A42).withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: Container(
          color: const Color(0xFF111827),
          child: asset != null
              ? Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A2540),
                      child: Icon(
                        Icons.person,
                        size: size * 0.5,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                )
              : Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A2540),
                    child: Icon(
                      Icons.person,
                      size: size * 0.5,
                      color: Colors.white38,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stats Row
// ──────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatColumn(value: '${user.scenesCount}', label: 'Scènes'),
        ),
        Expanded(
          child: _StatColumn(
              value: _fmtK(user.followersCount), label: 'Followers'),
        ),
        Expanded(
          child:
              _StatColumn(value: _fmtK(user.likesCount), label: 'Likes'),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: AppThemeTokens.primaryText(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppThemeTokens.secondaryText(context),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ──────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isFollowing,
    required this.onFollowTap,
    required this.onMessageTap,
    required this.onShareTap,
  });

  final bool isFollowing;
  final VoidCallback onFollowTap;
  final VoidCallback onMessageTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: onFollowTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: isFollowing
                    ? AppThemeTokens.softAction(context)
                    : _C.purple,
                borderRadius: BorderRadius.circular(14),
                border: isFollowing
                    ? Border.all(
                        color: AppThemeTokens.softBorder(context))
                    : null,
              ),
              child: Center(
                child: Text(
                  isFollowing ? 'Abonné' : 'Suivre',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isFollowing
                        ? AppThemeTokens.primaryText(context)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: onMessageTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppThemeTokens.softAction(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppThemeTokens.softBorder(context),
                ),
              ),
              child: Center(
                child: Text(
                  'Message',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onShareTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppThemeTokens.softAction(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppThemeTokens.softBorder(context),
              ),
            ),
            child: Icon(
              Icons.ios_share_rounded,
              color: AppThemeTokens.secondaryText(context),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tab Bar Delegate (pinned)
// ──────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabController});

  final TabController tabController;

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppThemeTokens.pageBackgroundAlt(context),
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              controller: tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 2.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppThemeTokens.primaryText(context),
              labelStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelColor: AppThemeTokens.tertiaryText(context),
              unselectedLabelStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Performances'),
                Tab(text: 'Badges'),
                Tab(text: 'Favoris'),
              ],
            ),
          ),
          Container(
            height: 0.5,
            color: AppThemeTokens.border(context),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController;
}

// ──────────────────────────────────────────────────────────────────────────────
// Performance Card
// ──────────────────────────────────────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.scene,
    required this.index,
    required this.onTap,
  });

  final SceneModel scene;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final likeText = _fmtK(scene.likesCount);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            scene.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A2540)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.80),
                ],
                stops: const [0.0, 0.40, 0.70, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.90),
                ),
                const SizedBox(width: 4),
                Text(
                  likeText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.50),
                        blurRadius: 4,
                      ),
                    ],
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
}

class _ThemeToggleCard extends StatelessWidget {
  const _ThemeToggleCard({
    required this.isDarkMode,
    required this.onChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0x120B1020),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppThemeTokens.surfaceMuted(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème clair / sombre',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDarkMode
                      ? 'Ambiance cinéma premium activée'
                      : 'Mode clair lumineux activé',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppThemeTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Palette
// ──────────────────────────────────────────────────────────────────────────────

class _C {
  static const purple = Color(0xFF6C5CE7);
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

String _fmtK(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

bool _isDemoProfile(UserModel user) {
  return user.id == 'demo_local' ||
      user.email == 'demo@take30.app' ||
      user.username == 'demo_take30';
}
