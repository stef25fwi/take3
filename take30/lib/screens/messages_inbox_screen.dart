import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../services/conversation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MessagesInboxScreen extends ConsumerWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    final viewerId = authUser?.id ?? '';
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final surface = AppThemeTokens.surface(context);
    final border = AppThemeTokens.border(context);

    Widget buildBody() {
      if (viewerId.isEmpty) {
        return const _EmptyInbox(
          message:
              'Connecte-toi pour acceder a tes conversations privees Take60.',
        );
      }

      final conversationsAsync =
          ref.watch(conversationsProvider(viewerId));

      return conversationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
        error: (error, _) => _ErrorInbox(message: error.toString()),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const _EmptyInbox(
              message:
                  'Aucune conversation pour le moment. Ouvre un profil et ecris un premier message pour demarrer.',
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: border,
                indent: 14,
                endIndent: 14,
              ),
              itemBuilder: (_, index) {
                final summary = conversations[index];
                return _ConversationTile(
                  summary: summary,
                  viewerId: viewerId,
                  onTap: () => context.go(
                    AppRouter.messagesPath(summary.peerIdFor(viewerId)),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    final conversationCountAsync = viewerId.isEmpty
        ? const AsyncValue<List<ConversationModel>>.data([])
        : ref.watch(conversationsProvider(viewerId));
    final count = conversationCountAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemeTokens.pageGradient(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppThemeTokens.pageHorizontalPadding,
              12,
              AppThemeTokens.pageHorizontalPadding,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRouter.home);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: primaryText,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Messages',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$count',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final secondaryText = AppThemeTokens.secondaryText(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_rounded,
              size: 36,
              color: secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorInbox extends StatelessWidget {
  const _ErrorInbox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Impossible de charger les conversations.\n$message',
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.summary,
    required this.viewerId,
    required this.onTap,
  });

  final ConversationModel summary;
  final String viewerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final unread = summary.unreadFor(viewerId);
    final preview = summary.lastMessage.isEmpty
        ? 'Demarrer la conversation'
        : summary.lastMessage;
    final peerId = summary.peerIdFor(viewerId);
    final peerName = summary.peerName(viewerId);
    final peerAvatar = summary.peerAvatar(viewerId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            UserAvatar(
              url: peerAvatar.isEmpty ? null : peerAvatar,
              userId: peerId,
              size: 48,
              showBorder: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight:
                          unread > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: unread > 0 ? primaryText : secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: secondaryText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
