import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/providers.dart';
import '../../../router/router.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class _UserComment {
  const _UserComment({
    required this.id,
    required this.sceneId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String sceneId;
  final String text;
  final DateTime? createdAt;
}

final _userCommentsProvider =
    StreamProvider.family<List<_UserComment>, String>((ref, uid) {
  if (uid.isEmpty) {
    return const Stream<List<_UserComment>>.empty();
  }
  return FirebaseFirestore.instance
      .collectionGroup('comments')
      .where('authorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(80)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            DateTime? readTime(dynamic v) {
              if (v is Timestamp) return v.toDate();
              if (v is DateTime) return v;
              return null;
            }

            String? sceneId;
            final parent = doc.reference.parent.parent;
            if (parent != null) {
              sceneId = parent.id;
            }
            return _UserComment(
              id: doc.id,
              sceneId: sceneId ?? '',
              text: data['text'] as String? ?? '',
              createdAt: readTime(data['createdAt']),
            );
          }).toList());
});

class Take60CommentsScreen extends ConsumerWidget {
  const Take60CommentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.id ?? '';

    if (uid.isEmpty) {
      return Take60ProfileScreenScaffold(
        title: 'Mes commentaires',
        subtitle:
            'Connecte-toi pour retrouver et moderer tes commentaires Take60.',
        children: const [],
      );
    }

    final commentsAsync = ref.watch(_userCommentsProvider(uid));

    return Take60ProfileScreenScaffold(
      title: 'Mes commentaires',
      subtitle:
          'Tes commentaires publics, classes par date. Tape sur une carte pour rouvrir la scene concernee.',
      icon: Icons.mode_comment_rounded,
      children: [
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.yellow),
            ),
          ),
          error: (error, _) => Take60InfoCard(
            icon: Icons.error_outline_rounded,
            title: 'Lecture impossible',
            description:
                'Erreur Firestore : $error. Si tu n\'as encore rien commente, ce flux restera vide.',
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return Take60EmptyState(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Aucun commentaire publie',
                message:
                    'Tes interactions sur les scenes Take60 apparaitront ici. Demarre par une scene populaire.',
                action: ElevatedButton(
                  onPressed: () => context.go(AppRouter.explore),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Explorer les scenes',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final comment in comments) ...[
                  _CommentTile(
                    comment: comment,
                    onTap: comment.sceneId.isEmpty
                        ? null
                        : () =>
                            context.go(AppRouter.scenePath(comment.sceneId)),
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
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onTap});

  final _UserComment comment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.text.isEmpty ? '(message vide)' : comment.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    comment.createdAt == null
                        ? 'Date inconnue'
                        : _formatDate(comment.createdAt!),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondary,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null) ...[
                    Text(
                      'Voir la scene',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} a $hour:$minute';
  }
}
