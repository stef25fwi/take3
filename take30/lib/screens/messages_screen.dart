import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../services/conversation_service.dart';
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
  String? _conversationId;
  bool _isPreparing = false;
  String? _setupError;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareConversation());
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _prepareConversation() async {
    if (_isPreparing || _conversationId != null) {
      return;
    }
    final authUser = ref.read(authProvider).user;
    if (authUser == null || authUser.id == widget.userId) {
      setState(() {
        _setupError = authUser == null
            ? 'Connecte-toi pour acceder a tes messages.'
            : 'Impossible de t\'envoyer un message a toi-meme.';
      });
      return;
    }

    setState(() {
      _isPreparing = true;
      _setupError = null;
    });

    try {
      final peer =
          ref.read(profileProvider(widget.userId)).user;
      final conversation = await ref
          .read(conversationServiceProvider)
          .getOrCreateConversation(
            currentUserId: authUser.id,
            peerId: widget.userId,
            currentUser: authUser,
            peerUser: peer,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _conversationId = conversation.id;
        _isPreparing = false;
      });
      await ref.read(conversationServiceProvider).markConversationRead(
            conversationId: conversation.id,
            uid: authUser.id,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _setupError = error.toString();
        _isPreparing = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _composerController.text.trim();
    final convoId = _conversationId;
    final authUser = ref.read(authProvider).user;
    if (text.isEmpty || convoId == null || authUser == null || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref.read(conversationServiceProvider).sendMessage(
            conversationId: convoId,
            senderId: authUser.id,
            receiverId: widget.userId,
            text: text,
          );
      _composerController.clear();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider(widget.userId));
    final authUser = ref.watch(authProvider).user;
    final user = profileState.user ??
        (authUser?.id == widget.userId ? authUser : null);

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
        Expanded(
          child: _ConversationView(
            conversationId: _conversationId,
            isPreparing: _isPreparing,
            setupError: _setupError,
            currentUserId: authUser?.id ?? '',
            composerController: _composerController,
            isSending: _isSending,
            onSend: _sendMessage,
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
                        context.go(AppRouter.messages);
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

class _ConversationView extends ConsumerWidget {
  const _ConversationView({
    required this.conversationId,
    required this.isPreparing,
    required this.setupError,
    required this.currentUserId,
    required this.composerController,
    required this.isSending,
    required this.onSend,
  });

  final String? conversationId;
  final bool isPreparing;
  final String? setupError;
  final String currentUserId;
  final TextEditingController composerController;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final surface = AppThemeTokens.surface(context);
    final border = AppThemeTokens.border(context);

    if (setupError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          setupError!,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
        ),
      );
    }

    if (isPreparing || conversationId == null) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
      );
    }

    final messagesAsync =
        ref.watch(conversationMessagesProvider(conversationId!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversation Take60',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Messages chiffres en transit, stockes dans Firestore et synchronises en temps reel.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.45,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.yellow),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Erreur de synchronisation : $error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun message pour le moment. Lance la conversation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isFromCurrentUser:
                          message.senderId == currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: composerController,
                  minLines: 1,
                  maxLines: 3,
                  enabled: !isSending,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ecrire un message...',
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
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(18),
                      ),
                      borderSide: BorderSide(color: AppColors.yellow),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 52,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSending ? null : onSend,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navy,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFromCurrentUser,
  });

  final ConversationMessage message;
  final bool isFromCurrentUser;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isFromCurrentUser
        ? AppColors.yellow
      : AppThemeTokens.surfaceMuted(context);
    final textColor = isFromCurrentUser
        ? AppColors.navy
      : AppThemeTokens.primaryText(context);

    return Align(
      alignment:
          isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
            border: isFromCurrentUser
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
                _formatTime(message.createdAt),
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

String _formatTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '...';
  }
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
