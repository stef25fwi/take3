import 'package:flutter/material.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SceneIdea>>(
      future: ApiService().fetchScenes(),
      builder: (context, snapshot) {
        final scenes = snapshot.data ?? const <SceneIdea>[];

        if (snapshot.connectionState == ConnectionState.waiting && scenes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Explorer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Découvre des idées de scènes rapides à produire.'),
            const SizedBox(height: 12),
            for (final scene in scenes)
              SectionCard(
                title: scene.title,
                subtitle: '${scene.category} • ${scene.minutes} min\n${scene.description}',
                icon: Icons.movie_creation_outlined,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.sceneDetail,
                  arguments: scene.title,
                ),
              ),
          ],
        );
      },
    );
  }
}
