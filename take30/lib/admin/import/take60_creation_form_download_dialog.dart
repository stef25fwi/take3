import 'package:flutter/material.dart';

import 'take60_template_download_service.dart';

class Take60CreationFormDownloadDialog extends StatelessWidget {
  const Take60CreationFormDownloadDialog({
    super.key,
    this.downloadService = const Take60TemplateDownloadService(),
  });

  final Take60TemplateDownloadService downloadService;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.16),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.42),
                      ),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFFFDE68A),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formulaire de création Take60',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Télécharge le modèle officiel à transmettre aux freelances. Ils pourront le remplir hors application, puis l’admin pourra l’importer via Télécharger un scénario.',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    tooltip: 'Fermer',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Le fichier Excel est conseillé pour les freelances. Le fichier JSON est le format technique officiel utilisé par l’import Take60.',
                style: TextStyle(
                  color: Color(0xFFFDE68A),
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 620;
                  final cards = <Widget>[
                    Expanded(
                      child: _TemplateDownloadCard(
                        icon: Icons.table_chart_outlined,
                        title: 'Formulaire Excel freelance',
                        description:
                            'Modèle remplissable hors application pour préparer une ou plusieurs scènes.',
                        buttonLabel: 'Télécharger Excel',
                        accentColor: const Color(0xFF10B981),
                        onPressed: () => downloadService.downloadExcelTemplate(context),
                      ),
                    ),
                    Expanded(
                      child: _TemplateDownloadCard(
                        icon: Icons.data_object_rounded,
                        title: 'Modèle JSON Take60',
                        description: 'Format technique officiel pour l’import automatisé.',
                        buttonLabel: 'Télécharger JSON',
                        accentColor: const Color(0xFF60A5FA),
                        onPressed: () => downloadService.downloadJsonTemplate(context),
                      ),
                    ),
                  ];
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [cards[0], const SizedBox(width: 14), cards[1]],
                    );
                  }
                  return Column(
                    children: [
                      _TemplateDownloadCard(
                        icon: Icons.table_chart_outlined,
                        title: 'Formulaire Excel freelance',
                        description:
                            'Modèle remplissable hors application pour préparer une ou plusieurs scènes.',
                        buttonLabel: 'Télécharger Excel',
                        accentColor: const Color(0xFF10B981),
                        onPressed: () => downloadService.downloadExcelTemplate(context),
                      ),
                      const SizedBox(height: 14),
                      _TemplateDownloadCard(
                        icon: Icons.data_object_rounded,
                        title: 'Modèle JSON Take60',
                        description: 'Format technique officiel pour l’import automatisé.',
                        buttonLabel: 'Télécharger JSON',
                        accentColor: const Color(0xFF60A5FA),
                        onPressed: () => downloadService.downloadJsonTemplate(context),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateDownloadCard extends StatelessWidget {
  const _TemplateDownloadCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.accentColor,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(buttonLabel),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
