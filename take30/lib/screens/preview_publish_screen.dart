import 'package:flutter/material.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class PreviewPublishScreen extends StatelessWidget {
  const PreviewPublishScreen({super.key, required this.draft});

  final TakeDraft draft;

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Prévisualisation',
      children: [
        SectionCard(
          title: draft.title,
          subtitle: draft.description,
          icon: Icons.visibility_outlined,
        ),
        SectionCard(
          title: 'Type de scène',
          subtitle: draft.sceneType,
          icon: Icons.movie_outlined,
        ),
        SectionCard(
          title: 'Durée et ambiance',
          subtitle: '${draft.duration} min • ${draft.mood}',
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Modifier'),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publication simulée avec succès')),
            );
            Navigator.pushNamedAndRemoveUntil(context, AppRouter.shell, (route) => false);
          },
          child: const Text('Publier'),
        ),
      ],
    );
  }
}
