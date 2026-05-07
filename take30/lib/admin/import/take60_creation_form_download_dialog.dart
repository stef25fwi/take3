import 'package:flutter/material.dart';

import 'take60_template_download_service.dart';

class Take60CreationFormDownloadDialog extends StatelessWidget {
  const Take60CreationFormDownloadDialog({
    super.key,
    this.downloadService = const Take60TemplateDownloadService(),
  });

  final Take60TemplateDownloadService downloadService;

  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceAlt = Color(0xFFF8FAFC);
  static const Color _primaryText = Color(0xFF0F172A);
  static const Color _secondaryText = Color(0xFF475569);
  static const Color _mutedText = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _amber = Color(0xFFD97706);
  static const Color _green = Color(0xFF059669);
  static const Color _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _amber,
          brightness: Brightness.light,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primaryText),
        ),
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: _amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formulaire de création Take60',
                              style: TextStyle(
                                color: _primaryText,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Modèles prêts à transmettre aux freelances ou à réimporter côté admin.',
                              style: TextStyle(
                                color: _secondaryText,
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                        color: _mutedText,
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      'Excel conseillé pour la saisie freelance · JSON conseillé pour l’import technique Take60.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;
                      final excelCard = _TemplateDownloadCard(
                        icon: Icons.table_chart_outlined,
                        title: 'Excel freelance',
                        description:
                            'Formulaire clair à remplir hors application, idéal pour préparer une scène complète.',
                        buttonLabel: 'Télécharger Excel',
                        accentColor: _green,
                        softColor: const Color(0xFFECFDF5),
                        onPressed: () => downloadService.downloadExcelTemplate(context),
                      );
                      final jsonCard = _TemplateDownloadCard(
                        icon: Icons.data_object_rounded,
                        title: 'JSON Take60',
                        description:
                            'Format officiel compact pour importer automatiquement un scénario validé.',
                        buttonLabel: 'Télécharger JSON',
                        accentColor: _blue,
                        softColor: const Color(0xFFEFF6FF),
                        onPressed: () => downloadService.downloadJsonTemplate(context),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: excelCard),
                            const SizedBox(width: 10),
                            Expanded(child: jsonCard),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          excelCard,
                          const SizedBox(height: 10),
                          jsonCard,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
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
    required this.softColor,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final Color accentColor;
  final Color softColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Take60CreationFormDownloadDialog._surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Take60CreationFormDownloadDialog._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: accentColor, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Take60CreationFormDownloadDialog._primaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Take60CreationFormDownloadDialog._secondaryText,
                        fontSize: 12.2,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.download_for_offline_outlined, size: 17),
              label: Text(
                buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
