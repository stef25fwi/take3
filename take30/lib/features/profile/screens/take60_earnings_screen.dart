import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class _EarningsBalance {
  const _EarningsBalance({
    required this.totalCents,
    required this.pendingCents,
    required this.payoutsCount,
    required this.lastUpdate,
  });

  final int totalCents;
  final int pendingCents;
  final int payoutsCount;
  final DateTime? lastUpdate;
}

final _earningsProvider =
    StreamProvider.family<_EarningsBalance?, String>((ref, uid) {
  if (uid.isEmpty) {
    return const Stream<_EarningsBalance?>.empty();
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('earnings')
      .doc('summary')
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final data = snap.data() ?? const <String, dynamic>{};
    DateTime? readTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return _EarningsBalance(
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      pendingCents: (data['pendingCents'] as num?)?.toInt() ?? 0,
      payoutsCount: (data['payoutsCount'] as num?)?.toInt() ?? 0,
      lastUpdate: readTime(data['updatedAt']),
    );
  });
});

class Take60EarningsScreen extends ConsumerWidget {
  const Take60EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.id ?? '';
    final isPremium = user?.plan == UserPlan.premium;

    if (uid.isEmpty) {
      return Take60ProfileScreenScaffold(
        title: 'Monetisation',
        subtitle: 'Connecte-toi pour suivre tes revenus Take60.',
        children: const [],
      );
    }

    final earningsAsync = ref.watch(_earningsProvider(uid));

    return Take60ProfileScreenScaffold(
      title: 'Monetisation',
      subtitle:
          'Suivi en temps reel de tes revenus, primes Take60 et virements. Donnees sourcees depuis Firestore (users/$uid/earnings).',
      icon: Icons.payments_rounded,
      children: [
        Take60InfoCard(
          icon: isPremium
              ? Icons.workspace_premium_rounded
              : Icons.lock_outline_rounded,
          title: isPremium ? 'Plan Premium actif' : 'Monetisation reservee Premium',
          description: isPremium
              ? 'Ton plan Premium debloque les revenus, primes hebdomadaires et virements automatiques.'
              : 'Active le plan Premium depuis l\'ecran "Mon abonnement" pour activer la monetisation et le suivi des revenus.',
        ),
        const SizedBox(height: 14),
        earningsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.yellow),
            ),
          ),
          error: (error, _) => Take60InfoCard(
            icon: Icons.error_outline_rounded,
            title: 'Synchronisation impossible',
            description: 'Erreur Firestore : $error.',
          ),
          data: (balance) {
            if (balance == null) {
              return Take60EmptyState(
                icon: Icons.payments_outlined,
                title: 'Aucun revenu enregistre',
                message:
                    'Les revenus sont calcules apres chaque cycle de monetisation Take60. Continue a publier pour generer ton premier solde.',
              );
            }

            return Column(
              children: [
                _AmountCard(
                  label: 'Solde verse',
                  amountCents: balance.totalCents,
                  highlight: true,
                ),
                const SizedBox(height: 10),
                _AmountCard(
                  label: 'En attente',
                  amountCents: balance.pendingCents,
                ),
                const SizedBox(height: 10),
                Take60InfoCard(
                  icon: Icons.account_balance_rounded,
                  title: '${balance.payoutsCount} virements traites',
                  description: balance.lastUpdate == null
                      ? 'Les virements sont consolides chaque vendredi par les Cloud Functions Take60.'
                      : 'Dernier point de synchro : ${_formatDate(balance.lastUpdate!)}.',
                ),
              ],
            );
          },
        ),
      ],
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

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.label,
    required this.amountCents,
    this.highlight = false,
  });

  final String label;
  final int amountCents;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);
    final accent = highlight
        ? AppColors.yellow
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              highlight
                  ? Icons.trending_up_rounded
                  : Icons.timelapse_rounded,
              color: accent,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCents(amountCents),
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCents(int cents) {
    final euros = cents / 100;
    return '${euros.toStringAsFixed(2)} EUR';
  }
}
