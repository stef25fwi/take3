import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/providers.dart';
import '../../../router/router.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class _UserProject {
  const _UserProject({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    required this.sceneId,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? updatedAt;
  final String sceneId;
}

final _userProjectsProvider =
    StreamProvider.family<List<_UserProject>, String>((ref, uid) {
  if (uid.isEmpty) {
    return const Stream<List<_UserProject>>.empty();
  }
  return FirebaseFirestore.instance
      .collection('take60_guided_projects')
      .where('userId', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            DateTime? readTime(dynamic v) {
              if (v is Timestamp) return v.toDate();
              if (v is DateTime) return v;
              return null;
            }

            return _UserProject(
              id: doc.id,
              title: (data['sceneTitle'] as String?)?.trim().isNotEmpty == true
                  ? data['sceneTitle'] as String
                  : (data['title'] as String? ?? 'Projet sans titre'),
              status: data['status'] as String? ?? 'draft',
              updatedAt: readTime(data['updatedAt'] ?? data['createdAt']),
              sceneId: data['sceneId'] as String? ?? '',
            );
          }).toList());
});

class Take60UserProjectsScreen extends ConsumerWidget {
  const Take60UserProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.id ?? '';

    if (uid.isEmpty) {
      return const Take60ProfileScreenScaffold(
        title: 'Mes projets Take60',
        subtitle: 'Connecte-toi pour suivre tes projets en cours.',
        children: [],
      );
    }

    final projectsAsync = ref.watch(_userProjectsProvider(uid));

    return Take60ProfileScreenScaffold(
      title: 'Mes projets Take60',
      subtitle:
          'Retrouve tes brouillons, segments enregistres et projets prets a etre rendus. Synchronises depuis ${_collectionPath()}.',
      icon: Icons.folder_copy_rounded,
      children: [
        projectsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.yellow),
            ),
          ),
          error: (error, _) => Take60InfoCard(
            icon: Icons.error_outline_rounded,
            title: 'Synchronisation impossible',
            description:
                'Erreur Firestore : $error. Verifie ta connexion ou reessaie dans quelques secondes.',
          ),
          data: (projects) {
            if (projects.isEmpty) {
              return Take60EmptyState(
                icon: Icons.movie_creation_outlined,
                title: 'Aucun projet enregistre',
                message:
                    'Lance un enregistrement guide pour generer ton premier projet Take60. Les brouillons et rendus apparaitront ici.',
                action: ElevatedButton(
                  onPressed: () => context.go(AppRouter.record),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Demarrer un enregistrement',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final project in projects) ...[
                  _ProjectTile(
                    project: project,
                    onTap: project.sceneId.isEmpty
                        ? null
                        : () =>
                            context.go(AppRouter.scenePath(project.sceneId)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _collectionPath() => 'take60_guided_projects';
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.onTap});

  final _UserProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);
    final accent = Theme.of(context).colorScheme.primary;
    final color = _statusColor(project.status, accent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(project.status), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(project.status),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (project.updatedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Mis a jour ${_formatDate(project.updatedAt!)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: secondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'rendered':
      case 'ready':
        return 'Rendu pret';
      case 'rendering':
        return 'Rendu en cours';
      case 'failed':
        return 'Erreur de rendu';
      case 'draft':
      default:
        return 'Brouillon';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'rendered':
      case 'ready':
        return Icons.check_circle_rounded;
      case 'rendering':
        return Icons.hourglass_top_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      case 'draft':
      default:
        return Icons.edit_note_rounded;
    }
  }

  Color _statusColor(String status, Color fallback) {
    switch (status) {
      case 'rendered':
      case 'ready':
        return AppColors.green;
      case 'rendering':
        return AppColors.cyan;
      case 'failed':
        return AppColors.red;
      case 'draft':
      default:
        return fallback;
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return 'le $day/$month/$year a $hour:$minute';
  }
}
