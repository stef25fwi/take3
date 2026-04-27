import 'dart:ui';

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

  bool _isDemoUser(UserModel? user) {
    if (user == null) {
      return false;
    }

    return user.username == 'demo_take30' ||
        user.displayName == 'Mode Demo' ||
        user.email == 'demo@take30.app';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemeTokens.pageGradient(context),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -72,
              left: -48,
              child: _AmbientGlow(
                size: 220,
                color: Color.fromRGBO(108, 92, 231, 0.12),
              ),
            ),
            const Positioned(
              top: 120,
              right: -36,
              child: _AmbientGlow(
                size: 180,
                color: Color.fromRGBO(255, 184, 0, 0.08),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppThemeTokens.pageHorizontalPadding,
                  12,
                  AppThemeTokens.pageHorizontalPadding,
                  0,
                ),
                child: Column(
                  children: [
                    _NotificationsTopBar(
                      unreadCount: unreadCount,
                      onBackTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRouter.home);
                        }
                      },
                      onMarkAllRead: unreadCount == 0
                          ? null
                          : () => _markAllRead(ref),
                    ),
                    const SizedBox(height: 18),
                    _NotificationsSummaryCard(unreadCount: unreadCount),
                    const SizedBox(height: 16),
                    Expanded(
                      child: notificationsAsync.when(
                        data: (notifications) {
                          if (notifications.isEmpty) {
                            return const _NotificationEmptyState(
                              label: 'Aucune notification pour le moment.',
                            );
                          }

                          return ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _NotificationCard(
                                notification: notification,
                                onTap: () =>
                                    _handleTap(context, ref, notification),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.yellow,
                          ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    final user = ref.read(authProvider).user;
    if (_isDemoUser(user)) {
      ref.read(demoNotificationsProvider.notifier).markAllRead();
      return;
    }

    final uid = user?.id;
    if (uid == null) return;
    await ref.read(apiServiceProvider).notifications.markAllRead(uid);
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    final user = ref.read(authProvider).user;
    if (_isDemoUser(user)) {
      if (!notification.isRead) {
        ref.read(demoNotificationsProvider.notifier).markRead(notification.id);
      }
    } else {
      final uid = user?.id;
      if (uid != null && !notification.isRead) {
      await ref.read(apiServiceProvider).notifications.markRead(
            uid,
            notification.id,
          );
      }
    }
    if (!context.mounted) return;

    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        if (notification.sceneId != null) {
          context.go(AppRouter.scenePath(notification.sceneId!));
        } else {
          context.go(AppRouter.explore);
        }
        break;
      case NotificationType.duel:
        context.go(AppRouter.battle);
        break;
      case NotificationType.achievement:
        context.go(AppRouter.badges);
        break;
      case NotificationType.follow:
        if (notification.userId != null) {
          context.go(AppRouter.profilePath(notification.userId!));
        } else {
          context.go(AppRouter.home);
        }
        break;
      case NotificationType.system:
        context.go(AppRouter.home);
        break;
    }
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar({
    required this.unreadCount,
    required this.onBackTap,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onBackTap;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBackTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppThemeTokens.softAction(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppThemeTokens.softBorder(context)),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppThemeTokens.primaryText(context),
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppThemeTokens.primaryText(context),
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unreadCount == 0
                    ? 'Tout est lu'
                    : '$unreadCount en attente',
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppThemeTokens.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onMarkAllRead,
          child: Text(
            'Tout lire',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: onMarkAllRead == null
                  ? AppThemeTokens.tertiaryText(context)
                  : AppColors.yellow,
            ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                        color: AppThemeTokens.primaryText(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Battles, badges, commentaires et activité récente.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppThemeTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread
                ? AppThemeTokens.surfaceMuted(context)
                : AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? const Color.fromRGBO(255, 184, 0, 0.22)
                  : AppThemeTokens.border(context),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.18),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
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
                  UserAvatar(
                    url: notification.avatarUrl,
                    userId: notification.userId,
                    size: 44,
                  ),
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
                            color: AppThemeTokens.primaryText(context),
                            letterSpacing: -0.1,
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
                              color: AppThemeTokens.secondaryText(context),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _formatRelativeTime(notification.time),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppThemeTokens.tertiaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor(notification.type)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _accentColor(notification.type)
                            .withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      _actionLabel(notification.type),
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _accentColor(notification.type),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          color: AppThemeTokens.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppThemeTokens.border(context)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppThemeTokens.secondaryText(context),
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.45,
              spreadRadius: size * 0.1,
            ),
          ],
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
      return 'Voir la vidéo';
    case NotificationType.follow:
      return 'Voir le profil';
    case NotificationType.system:
      return 'Ouvrir';
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
    case NotificationType.follow:
      return AppColors.orange;
    case NotificationType.system:
      return AppColors.greyLight;
  }
}