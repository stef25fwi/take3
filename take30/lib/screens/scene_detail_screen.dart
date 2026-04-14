import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class SceneDetailScreen extends StatelessWidget {
  const SceneDetailScreen({
    super.key,
    required this.title,
    this.scene,
  });

  final String title;
  final SceneModel? scene;

  @override
  Widget build(BuildContext context) {
    final currentScene = scene;
    final sceneTitle = currentScene?.title ?? title;
    final author = currentScene?.author.displayName ?? 'Marie L.';
    final category = currentScene?.category ?? 'Lifestyle';
    final duration = currentScene?.durationFormatted ?? '25 min';
    final tags = currentScene?.tags.isNotEmpty == true
        ? currentScene!.tags
      : const ['Cinématique', 'Intérieur', 'Tendance'];
    final likes = currentScene?.likesCount ?? 56;
    final comments = currentScene?.commentsCount ?? 34;
    final views = currentScene?.viewsCount ?? 128;

    return PageWrap(
      title: 'Détail scène',
      leading: TakeHeaderButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.go(AppRouter.explore),
      ),
      children: [
        const TakeVideoPlaceholder(emoji: '🎬'),
        const SizedBox(height: 12),
        Text(sceneTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'par $author • $category • $duration',
          style: const TextStyle(color: Color(0x99FFFFFF)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var index = 0; index < tags.length && index < 3; index++)
              TakePill(
                label: tags[index],
                tone: index == 0
                    ? TakePillTone.yellow
                    : index == 1
                        ? TakePillTone.cyan
                        : TakePillTone.purple,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: InfoStat(label: 'note', value: '4.8⭐')),
            const SizedBox(width: 8),
            Expanded(child: InfoStat(label: 'vues', value: '${views}👁️')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: InfoStat(label: 'commentaires', value: '${comments}💬')),
            const SizedBox(width: 8),
            Expanded(child: InfoStat(label: 'likes', value: '${likes}❤️')),
          ],
        ),
        const SizedBox(height: 10),
        SectionCard(
          title: 'Description',
          subtitle: currentScene == null
              ? 'Une exploration chaleureuse des textures, du rythme et des petits gestes qui font vivre une cuisine de nuit.'
              : 'Une exploration chaleureuse des textures, du rythme et des petits gestes qui font vivre cette scène.',
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Liker'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Commenter'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
