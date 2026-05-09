import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class Take60SubscriptionScreen extends ConsumerWidget {
  const Take60SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isPremium = user?.plan == UserPlan.premium;
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);

    return Take60ProfileScreenScaffold(
      title: 'Mon abonnement',
      subtitle: isPremium
          ? 'Plan Premium actif. Tu beneficies de la monetisation, des rendus prioritaires et de l\'audience etendue.'
          : 'Active Take60 Premium pour debloquer la monetisation, les rendus prioritaires et l\'acces aux scenes exclusives.',
      icon: Icons.workspace_premium_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPremium
                  ? const [Color(0xFFFFB800), Color(0xFFFF9C1A)]
                  : [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPremium ? Colors.transparent : AppThemeTokens.border(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPremium ? 'Take60 Premium' : 'Take60 Free',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isPremium ? AppColors.navy : primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPremium
                    ? 'Prochain renouvellement gere depuis le store mobile.'
                    : 'Plan gratuit. Audience standard et rendus dans la file partagee.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPremium
                      ? AppColors.navy.withValues(alpha: 0.8)
                      : secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Take60InfoCard(
          icon: Icons.check_circle_rounded,
          title: 'Monetisation des performances',
          description: isPremium
              ? 'Active. Les revenus sont consolides chaque vendredi.'
              : 'Reservee aux comptes Premium.',
        ),
        const SizedBox(height: 10),
        Take60InfoCard(
          icon: Icons.flash_on_rounded,
          title: 'Rendus IA prioritaires',
          description: isPremium
              ? 'Tes scenes passent en file rapide.'
              : 'Disponible avec le plan Premium pour reduire le temps de rendu.',
        ),
        const SizedBox(height: 10),
        Take60InfoCard(
          icon: Icons.audiotrack_rounded,
          title: 'Bibliotheque audio etendue',
          description: isPremium
              ? 'Acces complet aux ambiances et voix premium.'
              : 'Acces limite. Le plan Premium debloque les ambiances exclusives.',
        ),
        const SizedBox(height: 22),
        if (!isPremium)
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openSubscriptionFlow(context),
              icon: const Icon(Icons.upgrade_rounded),
              label: Text(
                'Passer Premium',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _openManageSubscription(context),
              icon: const Icon(Icons.manage_accounts_rounded),
              label: Text(
                'Gerer mon abonnement',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: AppThemeTokens.border(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openSubscriptionFlow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('https://take60.app/premium');
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      _showSnack(messenger, 'Impossible d\'ouvrir la page d\'abonnement.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openManageSubscription(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('https://take60.app/account/subscription');
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      _showSnack(
        messenger,
        'Impossible d\'ouvrir la gestion d\'abonnement.',
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
