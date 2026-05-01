import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.home)) return 0;
    if (location.startsWith(AppRouter.explore)) return 1;
    if (location.startsWith(AppRouter.record)) return 2;
    if (location.startsWith(AppRouter.battle)) return 3;
    if (location.startsWith(AppRouter.profile)) return 4;
    return -1;
  }

  void _go(BuildContext context, int index, String currentUserId) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
      case 1:
        context.go(AppRouter.explore);
      case 2:
        context.go(AppRouter.record);
      case 3:
        context.go(AppRouter.battle);
      case 4:
        context.go(AppRouter.profilePath(currentUserId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _indexForLocation(context);
    final currentUserId =
        ref.watch(authProvider.select((s) => s.user?.id)) ?? 'u1';
    final selectedColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = AppThemeTokens.tertiaryText(context);

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppThemeTokens.surface(context),
          border: Border(top: BorderSide(color: AppThemeTokens.border(context), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _Tab(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  selected: index == 0,
                  activeColor: selectedColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _go(context, 0, currentUserId),
                ),
                _Tab(
                  icon: Icons.explore_rounded,
                  label: 'Explorer',
                  selected: index == 1,
                  activeColor: selectedColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _go(context, 1, currentUserId),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _go(context, 2, currentUserId),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Image.asset(
                                '../take 30 images IA/clapback.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Text(
                          'Record',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: index == 2 ? selectedColor : inactiveColor,
                            fontWeight: index == 2 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _Tab(
                  icon: Icons.sports_mma_outlined,
                  label: 'Battle',
                  selected: index == 3,
                  activeColor: selectedColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _go(context, 3, currentUserId),
                ),
                _Tab(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  selected: index == 4,
                  activeColor: selectedColor,
                  inactiveColor: inactiveColor,
                  onTap: () => _go(context, 4, currentUserId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
