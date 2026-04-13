import 'package:flutter/material.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserStats>(
      future: ApiService().fetchProfileStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting && stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final userStats = stats ?? const UserStats(
          level: 'Intermédiaire',
          streakDays: 5,
          publishedCount: 12,
          communityScore: 87,
          nextBadge: 'Maître du rythme',
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
            const SizedBox(height: 12),
            const Center(
              child: Text('Créateur Take30', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: InfoStat(label: 'Niveau', value: userStats.level)),
                const SizedBox(width: 8),
                Expanded(child: InfoStat(label: 'Série', value: '${userStats.streakDays} jours')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: InfoStat(label: 'Takes', value: '${userStats.publishedCount}')),
                const SizedBox(width: 8),
                Expanded(child: InfoStat(label: 'Score', value: '${userStats.communityScore}%')),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Prochain badge',
              subtitle: userStats.nextBadge,
              icon: Icons.workspace_premium_outlined,
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.badges),
              child: const Text('Voir badges et stats'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.leaderboard),
              child: const Text('Voir le classement'),
            ),
          ],
        );
      },
    );
  }
}
