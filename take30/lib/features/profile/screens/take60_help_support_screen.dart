import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import 'take60_profile_screen_scaffold.dart';

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

const _faqItems = <_FaqItem>[
  _FaqItem(
    question: 'Comment publier une scene Take60 ?',
    answer:
        'Depuis l\'onglet Studio, choisis un script, lance l\'enregistrement guide puis publie depuis l\'ecran de previsualisation. Le rendu est genere par les Cloud Functions.',
  ),
  _FaqItem(
    question: 'Mes points de classement ne montent pas, que faire ?',
    answer:
        'Les classements se mettent a jour toutes les heures. Verifie ta region depuis l\'onglet Explore et publie au moins une scene avec audience publique.',
  ),
  _FaqItem(
    question: 'Comment activer la monetisation ?',
    answer:
        'Active le plan Premium depuis l\'ecran "Mon abonnement". Les revenus apparaissent ensuite dans "Monetisation" et sont verses chaque vendredi.',
  ),
  _FaqItem(
    question: 'Mon enregistrement est-il prive ?',
    answer:
        'Tu peux choisir une visibilite "publique", "abonnes uniquement" ou "privee" pour chaque video depuis Reglages > Visibilite des videos.',
  ),
];

class Take60HelpSupportScreen extends ConsumerWidget {
  const Take60HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);

    return Take60ProfileScreenScaffold(
      title: 'Aide et support',
      subtitle:
          'FAQ, contact direct et diagnostics rapides. Toutes les informations sont mises a jour avec chaque release Take60.',
      icon: Icons.support_agent_rounded,
      children: [
        Text(
          'FAQ',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in _faqItems) ...[
          _FaqTile(item: item),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        Text(
          'Contacter le support',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        const SizedBox(height: 10),
        Take60InfoCard(
          icon: Icons.email_rounded,
          title: 'support@take60.app',
          description:
              'Reponse sous 24h. Mentionne ton pseudo et ton numero de scene si pertinent.',
          trailing: IconButton(
            icon: const Icon(Icons.send_rounded),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => _sendSupportEmail(context, user?.id ?? ''),
          ),
        ),
        const SizedBox(height: 10),
        Take60InfoCard(
          icon: Icons.public_rounded,
          title: 'Centre d\'aide en ligne',
          description: 'Articles, statut des services et incidents.',
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () =>
                launchUrl(Uri.parse('https://take60.app/aide')),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Diagnostic rapide',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiagnosticRow(
                label: 'Identifiant utilisateur',
                value: user?.id ?? 'non connecte',
              ),
              const SizedBox(height: 8),
              _DiagnosticRow(
                label: 'Plan',
                value: user?.plan.value ?? 'inconnu',
              ),
              const SizedBox(height: 8),
              _DiagnosticRow(
                label: 'Email',
                value: user?.email?.trim().isEmpty ?? true
                    ? 'non renseigne'
                    : user!.email!,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _copyDiagnostics(context, user?.id ?? ''),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(
                    'Copier mes infos pour le support',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: AppThemeTokens.border(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Take60 est mise a jour reguliereement. Pense a maintenir l\'application a jour pour beneficier des derniers correctifs.',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _sendSupportEmail(BuildContext context, String uid) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@take60.app',
      query: Uri(queryParameters: {
        'subject': 'Support Take60',
        'body': 'Bonjour,\n\n[Decris ton probleme]\n\n— UID : $uid',
      }).query,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ouvre ton client mail manuellement.')),
      );
    }
  }

  Future<void> _copyDiagnostics(BuildContext context, String uid) async {
    await Clipboard.setData(ClipboardData(text: 'UID Take60 : $uid'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identifiants copies dans le presse-papiers.')),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    final primary = AppThemeTokens.primaryText(context);
    final secondary = AppThemeTokens.secondaryText(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        backgroundColor: AppThemeTokens.surface(context),
        collapsedBackgroundColor: AppThemeTokens.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppThemeTokens.border(context)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppThemeTokens.border(context)),
        ),
        iconColor: secondary,
        collapsedIconColor: secondary,
        title: Text(
          item.question,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        children: [
          Text(
            item.answer,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppThemeTokens.primaryText(context),
            ),
          ),
        ),
      ],
    );
  }
}
