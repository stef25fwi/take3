import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class PreviewPublishScreen extends ConsumerStatefulWidget {
  const PreviewPublishScreen({super.key, this.videoPath, this.scene});

  final String? videoPath;
  final SceneModel? scene;

  @override
  ConsumerState<PreviewPublishScreen> createState() => _PreviewPublishScreenState();
}

class _PreviewPublishScreenState extends ConsumerState<PreviewPublishScreen> {
  SceneModel _fallbackScene(UserModel? user) {
    final author = user ??
        const UserModel(
          id: 'anonymous',
          username: 'guest',
          displayName: 'Invité',
          avatarUrl: '',
        );
    return SceneModel(
      id: 'draft-preview',
      title: 'Nouvelle scène',
      category: 'Impro',
      thumbnailUrl: '',
      author: author,
      createdAt: DateTime.now(),
      tags: const ['take30'],
      status: 'draft',
    );
  }

  @override
  void dispose() {
    ref.read(uploadServiceProvider).reset();
    super.dispose();
  }

  Future<void> _publish() async {
    final recordingState = ref.read(recordingProvider);
    final sceneSource = widget.scene ??
        recordingState.scene ??
        _fallbackScene(ref.read(authProvider).user);
    final tags = sceneSource.tags.isEmpty ? <String>['take30'] : sceneSource.tags;

    final scene = await ref.read(recordingProvider.notifier).publishScene(
      title: sceneSource.title,
      category: sceneSource.category,
      tags: tags,
    );

    if (!mounted) {
      return;
    }

    if (scene == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la publication'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    _showSuccessSheet(scene);
  }

  void _showSuccessSheet(SceneModel scene) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              'Publié avec succès !',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ta scène est visible par tous. Partage-la pour devenir viral !',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(shareServiceProvider).shareAfterPublish(
                        sceneTitle: scene.title,
                        sceneId: scene.id,
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Partager', style: AppTextStyles.buttonPrimary),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(recordingProvider.notifier).reset();
                  final currentUserId = ref.read(authProvider).user?.id;
                  context.go(
                    currentUserId == null
                        ? AppRouter.home
                        : AppRouter.profilePath(currentUserId),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Voir mon profil',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(recordingProvider.notifier).reset();
                context.go(AppRouter.home);
              },
              child: Text(
                'Retour à l\'accueil',
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadService = ref.watch(uploadServiceProvider);
    final uploadProgress = uploadService.progress;
    final isPublishing = uploadService.isUploading;
    final recordingState = ref.watch(recordingProvider);
    final scene = widget.scene ??
        recordingState.scene ??
        _fallbackScene(ref.watch(authProvider).user);
    final tags = <String>[
      scene.category,
      scene.durationFormatted,
      'Montage auto',
    ];

    return Scaffold(
      backgroundColor: PreviewTheme.background,
      appBar: AppBar(
        backgroundColor: PreviewTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: isPublishing ? null : () => context.go(AppRouter.record),
        ),
        title: Text(
          'Prévisualisation',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: Image.network(
                      scene.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceCard),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: PreviewTheme.videoOverlay),
                    ),
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_fill, color: AppColors.white, size: 62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              scene.title,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => _TagBadge(tag)).toList(),
            ),
            if (isPublishing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          uploadProgress.message ?? 'Publication...',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(uploadProgress.progress * 100).toInt()}%',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: uploadProgress.progress,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation(AppColors.yellow),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Une capsule rapide tournee avec une ambiance forte et un montage dynamique pret a etre publie.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isPublishing ? null : () => context.go(AppRouter.record),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Modifier',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPublishing ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PreviewTheme.publishBtnBg,
                      foregroundColor: PreviewTheme.publishBtnText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navy,
                            ),
                          )
                        : Text(
                            'Publier',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
