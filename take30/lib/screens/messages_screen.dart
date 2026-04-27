import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late final TextEditingController _composerController;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  bool _isDemoUser() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      return false;
    }

    return user.username == 'demo_take30' ||
        user.displayName == 'Mode Demo' ||
        user.email == 'demo@take30.app';
  }

  void _sendDemoMessage() {
    final text = _composerController.text;
    if (text.trim().isEmpty) {
      return;
    }

    ref.read(demoMessagesProvider(widget.userId).notifier).send(text);
    _composerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider(widget.userId));
    final authUser = ref.watch(authProvider).user;
    final user = profileState.user ??
        (authUser?.id == widget.userId ? authUser : null);
    final isDemoMode = _isDemoUser();
    final demoMessages = isDemoMode
        ? ref.watch(demoMessagesProvider(widget.userId))
        : const <DemoChatMessage>[];
    final List<Widget> contentWidgets;

    if (user == null && profileState.isLoading) {
      contentWidgets = const [
        Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.yellow),
          ),
        ),
      ];
    } else {
      contentWidgets = [
        Row(
          children: [
            UserAvatar(
              url: user?.avatarUrl,
              userId: user?.id,
              size: 56,
              showBorder: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Conversation',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user == null ? 'Profil indisponible.' : '@${user.username}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppThemeTokens.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isDemoMode && user != null)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              decoration: BoxDecoration(
                color: AppThemeTokens.surface(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppThemeTokens.border(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversation démo instantanée',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cette discussion est locale. Tu peux envoyer des messages sans réseau pour tester le flux complet.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.45,
                      color: AppThemeTokens.secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: demoMessages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final message = demoMessages[index];
                        return _MessageBubble(message: message);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _composerController,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendDemoMessage(),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppThemeTokens.primaryText(context),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Écrire un message démo...',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppThemeTokens.tertiaryText(context),
                            ),
                            filled: true,
                            fillColor: AppThemeTokens.surfaceMuted(context),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppThemeTokens.border(context),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppThemeTokens.border(context),
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                              borderSide: BorderSide(
                                color: AppColors.yellow,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _sendDemoMessage,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppColors.yellow,
                            foregroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppThemeTokens.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppThemeTokens.border(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canal prêt pour le prochain câblage',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La navigation est maintenant branchée. Cette surface servira à la messagerie privée dès que le modèle de conversation sera ajouté.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    height: 1.5,
                    color: AppThemeTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed:
                user == null ? null : () => context.go(AppRouter.profilePath(user.id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Voir le profil',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ];
    }

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(gradient: AppThemeTokens.pageGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppThemeTokens.pageHorizontalPadding,
              12,
              AppThemeTokens.pageHorizontalPadding,
              24,
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
                        context.go(AppRouter.profilePath(widget.userId));
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppThemeTokens.primaryText(context),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Messages',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppThemeTokens.primaryText(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...contentWidgets,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final DemoChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isFromCurrentUser
        ? AppColors.yellow
      : AppThemeTokens.surfaceMuted(context);
    final textColor = message.isFromCurrentUser
        ? AppColors.navy
      : AppThemeTokens.primaryText(context);

    return Align(
      alignment:
          message.isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: message.isFromCurrentUser
                ? null
                : Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(message.sentAt),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}