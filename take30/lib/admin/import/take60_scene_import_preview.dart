import 'package:flutter/material.dart';

import 'take60_scene_import_model.dart';

class Take60SceneImportPreview extends StatelessWidget {
  const Take60SceneImportPreview({
    super.key,
    required this.draft,
    required this.validation,
    this.onInject,
  });

  final Take60SceneImportDraft draft;
  final ImportValidationResult validation;
  final VoidCallback? onInject;

  @override
  Widget build(BuildContext context) {
    final totalIntroDuration = draft.veoIntroSegments.fold<int>(
      0,
      (total, segment) => total + segment.desiredDurationSeconds,
    );
    final userSequences = draft.guidedTimeline.where((marker) => marker.isUserSequence).length;
    final aiSequences = draft.guidedTimeline.where((marker) => marker.isAiSequence).length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.fact_check_rounded, color: Color(0xFFFFB300)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prévisualisation de l’import',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text('Vérifiez les données avant injection en brouillon.'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoTile(label: 'Titre', value: draft.sceneGeneral.title),
                          _InfoTile(label: 'Catégorie', value: draft.sceneGeneral.category),
                          _InfoTile(label: 'Genre', value: draft.sceneGeneral.genre),
                          _InfoTile(label: 'Difficulté', value: draft.sceneGeneral.difficulty),
                          _InfoTile(label: 'Durée cible', value: '${draft.sceneGeneral.targetDurationSeconds}s'),
                          _InfoTile(label: 'Pays / Région', value: _countryRegionLabel()),
                          _InfoTile(label: 'Statut proposé', value: validation.summary.proposedStatus),
                          _InfoTile(label: 'Personnages', value: '${draft.characters.length}'),
                          _InfoTile(label: 'Dialogues', value: '${draft.dialogues.length}'),
                          _InfoTile(label: 'Segments intro IA', value: '${draft.veoIntroSegments.length}'),
                          _InfoTile(label: 'Durée intro IA', value: '${totalIntroDuration}s'),
                          _InfoTile(label: 'Markers timeline', value: '${draft.guidedTimeline.length}'),
                          _InfoTile(label: 'Séquences utilisateur', value: '$userSequences'),
                          _InfoTile(label: 'Séquences IA', value: '$aiSequences'),
                        ],
                      ),
                      if (draft.sceneGeneral.synopsis.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text('Synopsis', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(draft.sceneGeneral.synopsis),
                      ],
                      _MessageList(
                        title: 'Erreurs bloquantes',
                        messages: validation.blockingErrors,
                        color: const Color(0xFFB91C1C),
                        emptyText: 'Aucune erreur bloquante.',
                      ),
                      _MessageList(
                        title: 'Warnings',
                        messages: validation.warnings,
                        color: const Color(0xFF92400E),
                        emptyText: 'Aucun warning.',
                      ),
                      _MessageList(
                        title: 'Champs inconnus ignorés',
                        messages: validation.unknownFields,
                        color: const Color(0xFF475569),
                        emptyText: 'Aucun champ inconnu.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: validation.isValid ? onInject : null,
                      icon: const Icon(Icons.input_rounded),
                      label: const Text('Injecter dans le formulaire'),
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

  String _countryRegionLabel() {
    final country = draft.sceneGeneral.country.trim();
    final region = draft.sceneGeneral.region.trim();
    if (country.isEmpty && region.isEmpty) return 'Global';
    if (country.isEmpty) return region;
    if (region.isEmpty) return country;
    return '$country / $region';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.title,
    required this.messages,
    required this.color,
    required this.emptyText,
  });

  final String title;
  final List<String> messages;
  final Color color;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          if (messages.isEmpty)
            Text(emptyText, style: const TextStyle(color: Color(0xFF64748B)))
          else
            ...messages.map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 7, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(message)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
