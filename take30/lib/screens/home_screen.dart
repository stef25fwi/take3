import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Accueil',
      trailing: TakeHeaderButton(
        icon: Icons.notifications_none_rounded,
        onPressed: () => context.push(AppRouter.notifications),
      ),
      showBottomNav: true,
      activeTab: TakeTab.home,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x33FFB800), Color(0x2400D4FF)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bonjour Stef',
                style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prêt à créer un nouveau Take ?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.go(AppRouter.record),
                child: const Text('🎬 Nouveau Take'),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Fil d\'activité',
          subtitle: '',
          child: Column(
            children: const [
              TakeFeedItem(
                avatar: TakeAvatar(label: 'M'),
                name: 'Marie L.',
                description: 'a publié « Cuisine de nuit » dans Lifestyle',
                time: 'Il y a 8 min',
              ),
              Divider(color: Color(0x14FFFFFF), height: 1),
              TakeFeedItem(
                avatar: TakeAvatar(label: 'T', colors: [Color(0xFF6C5CE7), Color(0xFF00D4FF)]),
                name: 'Thomas K.',
                description: 'a remporté une battle avec 58% des votes',
                time: 'Il y a 22 min',
              ),
              Divider(color: Color(0x14FFFFFF), height: 1),
              TakeFeedItem(
                avatar: TakeAvatar(label: 'S', colors: [Color(0xFFFFB800), Color(0xFFFF4D4F)]),
                name: 'Sara N.',
                description: 'a relevé le défi du jour « Lumière naturelle »',
                time: 'Il y a 1 h',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
