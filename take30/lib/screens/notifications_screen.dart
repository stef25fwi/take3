import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: NotificationsTheme.background,
      appBar: AppBar(
        backgroundColor: NotificationsTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => context.go(AppRouter.home),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: asyncNotifications.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (notifications) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: notifications.take(4).length,
          itemBuilder: (context, index) => _NotificationRow(
            notification: notifications[index],
            onTap: () {
              switch (notifications[index].type) {
                case NotificationType.duel:
                  context.go(AppRouter.battle);
                case NotificationType.achievement:
                  context.go(AppRouter.badges);
                default:
                  context.go(AppRouter.home);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: notification.isRead ? Colors.transparent : AppColors.cyan,
                shape: BoxShape.circle,
                border: notification.isRead
                    ? Border.all(color: AppColors.borderSubtle)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _body,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _when,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (notification.type) {
      case NotificationType.duel:
        return 'Battle terminée';
      case NotificationType.achievement:
        return 'Streak x5';
      case NotificationType.comment:
        return 'Commentaire';
      default:
        return 'Nouvelle battle';
    }
  }

  String get _body {
    switch (notification.type) {
      case NotificationType.duel:
        return 'Ton duel est clos. Consulte les résultats maintenant.';
      case NotificationType.achievement:
        return 'Bravo, tu as créé pendant 5 jours consécutifs.';
      case NotificationType.comment:
        return 'Marie L. a commenté ton dernier Take.';
      default:
        return 'Un nouveau thème est disponible pour ce soir.';
    }
  }

  String get _when {
    switch (notification.type) {
      case NotificationType.duel:
        return 'Il y a 5 min';
      case NotificationType.achievement:
        return 'Il y a 20 min';
      default:
        return 'Hier';
    }
  }
}
