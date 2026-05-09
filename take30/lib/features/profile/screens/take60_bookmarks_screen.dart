import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/providers.dart';
import '../../../router/router.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class _BookmarkItem {
  const _BookmarkItem({
    required this.id,
    required this.sceneId,
    required this.title,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  final String id;
  final String sceneId;
  final String title;
  final String thumbnailUrl;
  final DateTime? createdAt;
}

final _bookmarksProvider =
    StreamProvider.family<List<_BookmarkItem>, String>((ref, uid) {
  if (uid.isEmpty) {
    return const Stream<List<_BookmarkItem>>.empty();
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('bookmarks')
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            DateTime? readTime(dynamic v) {
              if (v is Timestamp) return v.toDate();
              if (v is DateTime) return v;
              return null;
            }

            return _BookmarkItem(
              id: doc.id,
              sceneId: data['sceneId'] as String? ?? doc.id,
              title: data['sceneTitle'] as String? ?? 'Scene Take60',
              thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
              createdAt: readTime(data['createdAt']),
            );
          }).toList());
});

class Take60BookmarksScreen extends ConsumerWidget {
  const Take60BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.id ?? '';

    if (uid.isEmpty) {
      return const Take60ProfileScreenScaffold(
        title: 'Mes favoris',
        subtitle: 'Connecte-toi pour retrouver tes scenes favorites.',
        children: [],
      );
    }

    final bookmarksAsync = ref.watch(_bookmarksProvider(uid));

    return Take60ProfileScreenScaffold(
      title: 'Mes favoris',
      subtitle:
          'Toutes les scenes que tu sauvegardes sont synchronisees ici via la collection users/{uid}/bookmarks.',
      icon: Icons.bookmark_rounded,
      children: [
        bookmarksAsync.when(
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
                'Erreur Firestore : $error. La collection sera disponible des qu\'un favori sera ajoute.',
          ),
          data: (items) {
            if (items.isEmpty) {
              return Take60EmptyState(
                icon: Icons.bookmark_border_rounded,
                title: 'Aucun favori enregistre',
                message:
                    'Tape sur l\'icone signet d\'une scene pour la sauvegarder. Tes favoris apparaitront ici en temps reel.',
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
                    'Explorer des scenes',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final bookmark in items) ...[
                  _BookmarkTile(
                    bookmark: bookmark,
                    onTap: () =>
                        context.go(AppRouter.scenePath(bookmark.sceneId)),
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

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark, required this.onTap});

  final _BookmarkItem bookmark;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: bookmark.thumbnailUrl.isEmpty
                      ? Container(
                          color: AppThemeTokens.surfaceMuted(context),
                          child: Icon(
                            Icons.movie_creation_outlined,
                            color: AppThemeTokens.tertiaryText(context),
                          ),
                        )
                      : Image.network(
                          bookmark.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppThemeTokens.surfaceMuted(context),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppThemeTokens.tertiaryText(context),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookmark.createdAt == null
                          ? 'Sauvegarde Take60'
                          : 'Sauvegarde le ${_formatDate(bookmark.createdAt!)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: secondary,
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
    return '$day/$month/${value.year}';
  }
}
