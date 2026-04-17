import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/mock_data.dart';
import '../widgets/shared_widgets.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PROFIL TALENT — Page 9 Pixel-Perfect
// ──────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider(userId));
    final user = profileState.user ?? MockData.users[0];
    final scenes = profileState.scenes.isNotEmpty
        ? profileState.scenes
        : MockData.scenes;

    return Scaffold(
      backgroundColor: _C.navy,
      body: _ProfileBody(user: user, scenes: scenes),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.user, required this.scenes});

  final UserModel user;
  final List<SceneModel> scenes;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _isFollowing = widget.user.isFollowing;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1020),
            Color(0xFF111827),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _IdentityBloc(user: widget.user),
                          const SizedBox(height: 18),
                          _StatsRow(user: widget.user),
                          const SizedBox(height: 18),
                          _ActionButtons(
                            isFollowing: _isFollowing,
                            onFollowTap: () {
                              setState(() => _isFollowing = !_isFollowing);
                            },
                          ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final scene =
                              widget.scenes[index % widget.scenes.length];
                          return _PerformanceCard(scene: scene, index: index);
                        },
                        childCount: 6,
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFFD0D5E0),
                  size: 28,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
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
                        color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.65),
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
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.55),
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
  });

  final bool isFollowing;
  final VoidCallback onFollowTap;

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
                    ? Colors.white.withValues(alpha: 0.08)
                    : _C.purple,
                borderRadius: BorderRadius.circular(14),
                border: isFollowing
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.12))
                    : null,
              ),
              child: Center(
                child: Text(
                  isFollowing ? 'Abonné' : 'Suivre',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
            onTap: () {},
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Center(
                child: Text(
                  'Message',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: Colors.white.withValues(alpha: 0.70),
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
      color: const Color(0xFF0E1525),
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              controller: tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              labelStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
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
            color: Colors.white.withValues(alpha: 0.08),
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
  const _PerformanceCard({required this.scene, required this.index});

  final SceneModel scene;
  final int index;

  @override
  Widget build(BuildContext context) {
    final demoCounts = ['12.4K', '8.3K', '6.1K', '5.8K', '4.2K', '3.9K'];
    final likeText = demoCounts[index % demoCounts.length];

    return ClipRRect(
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
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Palette
// ──────────────────────────────────────────────────────────────────────────────

class _C {
  static const navy = Color(0xFF0B1020);
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
