import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1020), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationsTopBar(
                  onBackTap: () => context.go(AppRouter.home),
                ),
                const SizedBox(height: 18),
                _NotificationsSummaryCard(unreadCount: unreadCount),
                const SizedBox(height: 18),
                Expanded(
                  child: notificationsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const _NotificationEmptyState(
                          label: 'Aucune notification pour le moment.',
                        );
                      }
                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = items[index];
                          return _NotificationCard(
                            notification: notification,
                            onTap: () => _openNotification(context, notification),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.yellow),
                    ),
                    error: (_, __) => const _NotificationEmptyState(
                      label: 'Impossible de charger les notifications.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNotification(BuildContext context, NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.duel:
        context.go(AppRouter.battle);
        return;
      case NotificationType.achievement:
        context.go(AppRouter.badges);
        return;
      case NotificationType.comment:
      case NotificationType.like:
        if (notification.sceneId != null && notification.sceneId!.isNotEmpty) {
          context.go(AppRouter.scenePath(notification.sceneId!));
          return;
        }
        context.go(AppRouter.home);
        return;
      case NotificationType.system:
        if (notification.userId != null && notification.userId!.isNotEmpty) {
          context.go(AppRouter.profilePath(notification.userId!));
          return;
        }
        context.go(AppRouter.home);
        return;
    }
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBackTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Commentaires, likes, défis et badges',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsSummaryCard extends StatelessWidget {
  const _NotificationsSummaryCard({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final label = unreadCount == 0
        ? 'Tout est à jour'
        : unreadCount == 1
            ? '1 notification non lue'
            : '$unreadCount notifications non lues';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 184, 0, 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.yellow,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ouvre une carte pour accéder directement à l’action.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: unread
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread
                ? const Color.fromRGBO(255, 184, 0, 0.22)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: unread ? AppColors.cyan : Colors.transparent,
                    shape: BoxShape.circle,
                    border: unread
                        ? null
                        : Border.all(color: AppColors.borderSubtle),
                  ),
                ),
                const SizedBox(width: 12),
                _NotificationLeading(notification: notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (notification.subMessage.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.subMessage,
                          style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.42,
                            color: Colors.white.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatRelativeTime(notification.time),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.44),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 184, 0, 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 184, 0, 0.22),
                  ),
                ),
                child: Text(
                  _actionLabel(notification.type),
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    if (notification.avatarUrl != null || notification.userId != null) {
      return UserAvatar(
        url: notification.avatarUrl,
        userId: notification.userId,
        size: 44,
      );
    }

    final color = _accentColor(notification.type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
      child: Icon(
        _leadingIcon(notification.type),
        size: 20,
        color: color,
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.66),
          ),
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) {
    return 'À l’instant';
  }
  if (diff.inHours < 1) {
    return 'Il y a ${diff.inMinutes} min';
  }
  if (diff.inDays < 1) {
    return 'Il y a ${diff.inHours} h';
  }
  return 'Il y a ${diff.inDays} j';
}

String _actionLabel(NotificationType type) {
  switch (type) {
    case NotificationType.duel:
      return 'Voir la battle';
    case NotificationType.achievement:
      return 'Voir les badges';
    case NotificationType.comment:
      return 'Voir le commentaire';
    case NotificationType.like:
      return 'Voir le take';
    case NotificationType.system:
      return 'Ouvrir';
  }
}

IconData _leadingIcon(NotificationType type) {
  switch (type) {
    case NotificationType.duel:
      return Icons.emoji_events_rounded;
    case NotificationType.achievement:
      return Icons.workspace_premium_rounded;
    case NotificationType.comment:
      return Icons.chat_bubble_rounded;
    case NotificationType.like:
      return Icons.favorite_rounded;
    case NotificationType.system:
      return Icons.notifications_rounded;
  }
}

Color _accentColor(NotificationType type) {
  switch (type) {
    case NotificationType.duel:
      return AppColors.yellow;
    case NotificationType.achievement:
      return AppColors.purple;
    case NotificationType.comment:
      return AppColors.cyan;
    case NotificationType.like:
      return AppColors.red;
    case NotificationType.system:
      return AppColors.greyLight;
  }
}
