import 'take60_scene_import_model.dart';

class Take60SceneImportValidator {
  const Take60SceneImportValidator();

  ImportValidationResult validate(Take60SceneImportDraft draft) {
    final errors = <String>[...draft.rawErrors];
    final warnings = <String>[...draft.rawWarnings];
    final normalized = <String>[];

    final general = draft.sceneGeneral;
    if (general.title.trim().isEmpty) {
      errors.add('Le titre de la scène est obligatoire.');
    }
    if (general.category.trim().isEmpty) {
      errors.add('La catégorie est obligatoire.');
    }
    if (general.genre.trim().isEmpty) {
      errors.add('Le genre est obligatoire.');
    }
    if (general.difficulty.trim().isEmpty) {
      errors.add('La difficulté est obligatoire.');
    }
    if (general.targetDurationSeconds <= 0) {
      errors.add('La durée cible doit être supérieure à 0 seconde.');
    }

    final hasVeoPrompt = draft.veoIntroSegments.any((segment) => segment.prompt.trim().isNotEmpty);
    final hasSceneIntent = general.directorIntention.trim().isNotEmpty || general.synopsis.trim().isNotEmpty;
    if (!hasVeoPrompt && !hasSceneIntent) {
      errors.add('Ajoutez au moins un prompt VEO ou une intention/synopsis de scène.');
    }

    if (general.country.trim().isEmpty) {
      warnings.add('Pays absent : la scène restera globale.');
    }
    if (general.region.trim().isEmpty) {
      warnings.add('Région absente : la scène restera globale.');
    }
    if (general.tags.isEmpty && draft.publication.tags.isEmpty) {
      warnings.add('Aucun tag fourni.');
    }
    if (draft.directorNotes.finalNote.trim().isEmpty &&
        draft.directorNotes.rhythm.trim().isEmpty &&
        draft.directorNotes.performanceTips.trim().isEmpty) {
      warnings.add('Notes réalisateur absentes.');
    }

    final seenMarkers = <String>{};
    var estimatedTimelineDuration = 0;
    for (final marker in draft.guidedTimeline) {
      final markerLabel = marker.markerId.trim().isEmpty ? 'ordre ${marker.order}' : marker.markerId;
      if (marker.markerId.trim().isNotEmpty && !seenMarkers.add(marker.markerId.trim())) {
        errors.add('Marker timeline dupliqué : ${marker.markerId}.');
      }
      if (marker.startSecond < 0 || marker.endSecond < 0) {
        errors.add('Durée négative interdite sur le marker $markerLabel.');
      }
      if (marker.endSecond <= marker.startSecond) {
        errors.add('Le marker $markerLabel doit avoir endSecond > startSecond.');
      }
      estimatedTimelineDuration += marker.durationSeconds;
    }

    if (draft.guidedTimeline.isNotEmpty &&
        general.targetDurationSeconds > 0 &&
        (estimatedTimelineDuration - general.targetDurationSeconds).abs() > 5) {
      warnings.add(
        'La durée totale estimée de la timeline ($estimatedTimelineDuration s) diffère de la durée cible (${general.targetDurationSeconds} s).',
      );
    }

    final markerIds = draft.guidedTimeline
        .map((marker) => marker.markerId.trim())
        .where((markerId) => markerId.isNotEmpty)
        .toSet();
    for (final dialogue in draft.dialogues) {
      if (dialogue.estimatedDurationSeconds < 0) {
        errors.add('Durée négative interdite sur un dialogue.');
      }
      if (dialogue.markerId.trim().isNotEmpty && markerIds.isNotEmpty && !markerIds.contains(dialogue.markerId.trim())) {
        errors.add('Dialogue rattaché à un marker inconnu : ${dialogue.markerId}.');
      }
    }

    for (final segment in draft.veoIntroSegments) {
      final label = segment.segmentId.trim().isEmpty ? 'ordre ${segment.order}' : segment.segmentId;
      if (segment.desiredDurationSeconds < 0) {
        errors.add('Durée négative interdite sur le segment VEO $label.');
      }
      if (segment.prompt.trim().isNotEmpty && segment.negativePrompt.trim().isEmpty) {
        warnings.add('Segment VEO $label sans negativePrompt.');
      }
    }

    for (final character in draft.characters) {
      if (character.name.trim().isNotEmpty && character.description.trim().isEmpty) {
        warnings.add('Personnage ${character.name} sans description.');
      }
    }

    if (draft.schemaVersion.trim().isEmpty) {
      normalized.add('schemaVersion → ${Take60SceneImportDraft.currentSchemaVersion}');
    }
    if (draft.publication.status.trim().toLowerCase() != 'draft') {
      normalized.add('publication.status forcé à draft pour validation admin.');
    }

    final summary = ImportValidationSummary(
      title: general.title,
      category: general.category,
      genre: general.genre,
      difficulty: general.difficulty,
      targetDurationSeconds: general.targetDurationSeconds,
      veoIntroSegmentCount: draft.veoIntroSegments.length,
      userSequenceCount: draft.guidedTimeline.where((marker) => marker.isUserSequence).length,
      dialogueCount: draft.dialogues.length,
      timelineMarkerCount: draft.guidedTimeline.length,
      proposedStatus: 'draft',
    );

    return ImportValidationResult(
      isValid: errors.isEmpty,
      blockingErrors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
      unknownFields: List.unmodifiable(draft.unknownFields),
      normalizedFields: List.unmodifiable(normalized),
      summary: summary,
    );
  }
}
