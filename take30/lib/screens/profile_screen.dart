import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Profil',
      trailing: const TakeHeaderButton(icon: Icons.settings_outlined),
      showBottomNav: true,
      activeTab: TakeTab.profile,
      children: [
        const SizedBox(height: 6),
        const Center(child: TakeAvatar(label: 'S', size: 72)),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Stef',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text('@stef25 • Jan 2025', style: TextStyle(color: Color(0x99FFFFFF))),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: InfoStat(label: 'streak', value: '5')),
            SizedBox(width: 8),
            Expanded(child: InfoStat(label: 'takes', value: '12')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(child: InfoStat(label: 'score', value: '87%')),
            SizedBox(width: 8),
            Expanded(child: InfoStat(label: 'niveau', value: 'Inter')),
          ],
        ),
        const SizedBox(height: 10),
        const SectionCard(
          title: 'Prochain badge',
          subtitle: 'Maître du rythme',
          child: TakeProgressBar(value: 0.7, colors: [Color(0xFF00D4FF), Color(0xFF6C5CE7)]),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(AppRouter.badges),
                child: const Text('Badges'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(AppRouter.leaderboard),
                child: const Text('Classement'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
