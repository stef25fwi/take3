import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.home)) return 0;
    if (location.startsWith(AppRouter.explore)) return 1;
    if (location.startsWith(AppRouter.record)) return 2;
    if (location.startsWith(AppRouter.battle)) return 3;
    if (location.startsWith(AppRouter.profile)) return 4;
    return 0;
  }

  void _go(BuildContext context, int index) {
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
        context.go(AppRouter.profilePath('u1'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexForLocation(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBackground,
          border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _Tab(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  selected: index == 0,
                  onTap: () => _go(context, 0),
                ),
                _Tab(
                  icon: Icons.explore_rounded,
                  label: 'Explorer',
                  selected: index == 1,
                  onTap: () => _go(context, 1),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _go(context, 2),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4D4F), Color(0xFFFF6B6B)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4D4F).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fiber_manual_record,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Text(
                          'Record',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: index == 2 ? NavIconStates.active : NavIconStates.inactive,
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
                  onTap: () => _go(context, 3),
                ),
                _Tab(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  selected: index == 4,
                  onTap: () => _go(context, 4),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NavIconStates.active : NavIconStates.inactive;
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
