import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: ApiService().fetchLeaderboard(),
      builder: (context, snapshot) {
        final players = snapshot.data ?? const <LeaderboardEntry>[];

        if (snapshot.connectionState == ConnectionState.waiting && players.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageWrap(
          title: 'Classement',
          children: [
            for (var i = 0; i < players.length; i++)
              SectionCard(
                title: '#${i + 1} ${players[i].name}',
                subtitle: 'Score communauté : ${players[i].score}',
                icon: i == 0 ? Icons.emoji_events : Icons.person_outline,
              ),
          ],
        );
      },
    );
  }
}
