import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class PreviewPublishScreen extends ConsumerStatefulWidget {
  const PreviewPublishScreen({super.key, required this.draft});

  final TakeDraft draft;

  @override
  ConsumerState<PreviewPublishScreen> createState() => _PreviewPublishScreenState();
}

class _PreviewPublishScreenState extends ConsumerState<PreviewPublishScreen> {
  @override
  void dispose() {
    ref.read(uploadServiceProvider).reset();
    super.dispose();
  }

  Future<void> _publish() async {
    final auth = ref.read(authServiceProvider);
    final upload = ref.read(uploadServiceProvider);

    final scene = await upload.uploadScene(
      videoPath: 'draft://${DateTime.now().millisecondsSinceEpoch}',
      title: widget.draft.title,
      category: widget.draft.sceneType,
      authorId: auth.currentUser?.id ?? 'u1',
      tags: [widget.draft.sceneType, widget.draft.mood],
    );

    if (!mounted) {
      return;
    }

    if (scene == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(upload.progress.error ?? 'La publication a échoué')),
      );
      return;
    }

    await ref.read(hapticsProvider).success();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Take publié dans le flux simulé')),
    );
  }

  Future<void> _sharePublishedScene(String sceneId, String sceneTitle) async {
    await ref.read(shareServiceProvider).shareAfterPublish(
          sceneTitle: sceneTitle,
          sceneId: sceneId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(uploadServiceProvider);
    final progress = upload.progress;
    final publishedScene = progress.result;

    return PageWrap(
      title: 'Prévisualisation',
      leading: TakeHeaderButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.pop(),
      ),
      children: [
        const TakeVideoPlaceholder(emoji: '▶️'),
        const SizedBox(height: 12),
        Text(
          widget.draft.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            TakePill(label: widget.draft.sceneType, tone: TakePillTone.yellow),
            TakePill(label: '${widget.draft.duration} min', tone: TakePillTone.cyan),
            TakePill(label: widget.draft.mood, tone: TakePillTone.purple),
          ],
        ),
        const SizedBox(height: 10),
        SectionCard(
          title: 'Description',
          subtitle: widget.draft.description,
        ),
        if (upload.isUploading || progress.message != null || progress.error != null)
          SectionCard(
            title: progress.error == null
                ? (progress.message ?? 'Publication en cours')
                : 'Erreur de publication',
            subtitle: progress.error ?? 'Progression ${(progress.progress * 100).round()}%',
            child: LinearProgressIndicator(value: upload.isUploading ? progress.progress : null),
          ),
        if (publishedScene != null)
          SectionCard(
            title: 'Publication prête',
            subtitle: '${publishedScene.title}\n${publishedScene.category} • ${publishedScene.durationFormatted}',
            icon: Icons.check_circle_outline,
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: upload.isUploading
                    ? null
                    : () {
                        ref.read(uploadServiceProvider).reset();
                        context.pop();
                      },
                child: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: upload.isUploading || publishedScene != null ? null : _publish,
                child: Text(upload.isUploading ? 'Publication...' : 'Publier'),
              ),
            ),
          ],
        ),
        if (publishedScene != null) ...[
          OutlinedButton(
            onPressed: () => _sharePublishedScene(publishedScene.id, publishedScene.title),
            child: const Text('Partager'),
          ),
          TextButton(
            onPressed: () {
              ref.read(uploadServiceProvider).reset();
              context.go(AppRouter.home);
            },
            child: const Text('Retour à l’accueil'),
          ),
        ],
      ],
    );
  }
}
