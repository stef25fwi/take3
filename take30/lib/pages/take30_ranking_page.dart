import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/mock_data.dart';

class Take30RankingPage extends ConsumerStatefulWidget {
  const Take30RankingPage({super.key});

  @override
  ConsumerState<Take30RankingPage> createState() => _Take30RankingPageState();
}

class _Take30RankingPageState extends ConsumerState<Take30RankingPage> {
  int selectedTab = 0;

  static const Color navy = Color(0xFF0B1020);

  final List<String> tabs = ['Jour', 'Semaine', 'Mois', 'Global'];

  String _formatFollowers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _onBottomTap(int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.explore);
        break;
      case 2:
        context.go(AppRouter.record);
        break;
      case 3:
        context.go(AppRouter.notifications);
        break;
      case 4:
        final userId = ref.read(authProvider).user?.id ?? 'u1';
        context.go(AppRouter.profilePath(userId));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = MockData.leaderboard;

    return Scaffold(
      backgroundColor: navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1020),
              Color(0xFF0F1523),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _RankingHeader(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouter.home);
                  }
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RankingTabs(
                  tabs: tabs,
                  selectedIndex: selectedTab,
                  onChanged: (index) {
                    setState(() => selectedTab = index);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _RankingRow(
                      entry: entry,
                      followersLabel: _formatFollowers(entry.user.followersCount),
                      onTap: () => context.go(AppRouter.profilePath(entry.user.id)),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: entries.length,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _Take30BottomNavBar(
        currentIndex: -1,
        onTap: _onBottomTap,
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _RankingHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          const Text(
            'Classement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _RankingTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final bool isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromRGBO(255, 255, 255, 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color.fromRGBO(255, 255, 255, 0.72),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final String followersLabel;
  final VoidCallback onTap;

  const _RankingRow({
    required this.entry,
    required this.followersLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // scoreLabel in mock looks like "245.2K ❤️". Keep it but split icon.
    final raw = entry.scoreLabel;
    final parts = raw.split(' ');
    final scoreText = parts.first;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                '${entry.rank}',
                style: const TextStyle(
                  color: Color(0xFFFFB800),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _RankingAvatar(imagePath: entry.user.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        followersLabel,
                        style: const TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.58),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 11,
                        color: Color.fromRGBO(255, 255, 255, 0.45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              scoreText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.favorite,
              color: Color(0xFFFF4D6D),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingAvatar extends StatelessWidget {
  final String imagePath;

  const _RankingAvatar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');

    Widget placeholder() {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB85A2B),
              Color(0xFF733A26),
              Color(0xFF2A2030),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.10),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: isNetwork
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder(),
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder(),
              ),
      ),
    );
  }
}

class _Take30BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _Take30BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home_outlined,
            label: 'Accueil',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _BottomItem(
            icon: Icons.search,
            label: 'Explorer',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _CenterCreateButton(onTap: () => onTap(2)),
          _BottomItem(
            icon: Icons.notifications_none,
            label: 'Notifs',
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'Profil',
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Colors.white
        : const Color.fromRGBO(255, 255, 255, 0.72);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterCreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterCreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFFFFB800),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF111827),
          size: 24,
        ),
      ),
    );
  }
}
