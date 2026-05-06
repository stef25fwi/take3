class Take60SceneImportDraft {
  const Take60SceneImportDraft({
    required this.schemaVersion,
    required this.sourceFormat,
    required this.importedAt,
    this.importedBy = '',
    required this.sceneGeneral,
    this.characters = const [],
    this.dialogues = const [],
    this.guidedTimeline = const [],
    this.veoIntroSegments = const [],
    this.directorNotes = const DirectorNotesImportData(),
    this.publication = const PublicationImportData(),
    this.rawWarnings = const [],
    this.rawErrors = const [],
    this.unknownFields = const [],
  });

  static const currentSchemaVersion = 'take60_scene_import_v1';

  final String schemaVersion;
  final String sourceFormat;
  final DateTime importedAt;
  final String importedBy;
  final SceneGeneralImportData sceneGeneral;
  final List<CharacterImportData> characters;
  final List<DialogueImportData> dialogues;
  final List<GuidedTimelineImportData> guidedTimeline;
  final List<VeoIntroSegmentImportData> veoIntroSegments;
  final DirectorNotesImportData directorNotes;
  final PublicationImportData publication;
  final List<String> rawWarnings;
  final List<String> rawErrors;
  final List<String> unknownFields;

  bool get hasBlockingParserError => rawErrors.isNotEmpty;

  Take60SceneImportDraft copyWith({
    String? schemaVersion,
    String? sourceFormat,
    DateTime? importedAt,
    String? importedBy,
    SceneGeneralImportData? sceneGeneral,
    List<CharacterImportData>? characters,
    List<DialogueImportData>? dialogues,
    List<GuidedTimelineImportData>? guidedTimeline,
    List<VeoIntroSegmentImportData>? veoIntroSegments,
    DirectorNotesImportData? directorNotes,
    PublicationImportData? publication,
    List<String>? rawWarnings,
    List<String>? rawErrors,
    List<String>? unknownFields,
  }) {
    return Take60SceneImportDraft(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sourceFormat: sourceFormat ?? this.sourceFormat,
      importedAt: importedAt ?? this.importedAt,
      importedBy: importedBy ?? this.importedBy,
      sceneGeneral: sceneGeneral ?? this.sceneGeneral,
      characters: characters ?? this.characters,
      dialogues: dialogues ?? this.dialogues,
      guidedTimeline: guidedTimeline ?? this.guidedTimeline,
      veoIntroSegments: veoIntroSegments ?? this.veoIntroSegments,
      directorNotes: directorNotes ?? this.directorNotes,
      publication: publication ?? this.publication,
      rawWarnings: rawWarnings ?? this.rawWarnings,
      rawErrors: rawErrors ?? this.rawErrors,
      unknownFields: unknownFields ?? this.unknownFields,
    );
  }
}

class SceneGeneralImportData {
  const SceneGeneralImportData({
    this.title = '',
    this.subtitle = '',
    this.category = '',
    this.genre = '',
    this.difficulty = '',
    this.sceneType = '',
    this.country = '',
    this.region = '',
    this.targetDurationSeconds = 0,
    this.synopsis = '',
    this.actorObjective = '',
    this.directorIntention = '',
    this.mood = '',
    this.visualStyle = '',
    this.soundMood = '',
    this.tags = const [],
  });

  final String title;
  final String subtitle;
  final String category;
  final String genre;
  final String difficulty;
  final String sceneType;
  final String country;
  final String region;
  final int targetDurationSeconds;
  final String synopsis;
  final String actorObjective;
  final String directorIntention;
  final String mood;
  final String visualStyle;
  final String soundMood;
  final List<String> tags;
}

class CharacterImportData {
  const CharacterImportData({
    this.id = '',
    this.name = '',
    this.role = '',
    this.description = '',
    this.emotionalState = '',
    this.costume = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final String role;
  final String description;
  final String emotionalState;
  final String costume;
  final String notes;
}

class DialogueImportData {
  const DialogueImportData({
    this.markerId = '',
    this.order = 0,
    this.characterName = '',
    this.expectedDialogue = '',
    this.emotion = '',
    this.intensity = '',
    this.actingInstruction = '',
    this.estimatedDurationSeconds = 0,
  });

  final String markerId;
  final int order;
  final String characterName;
  final String expectedDialogue;
  final String emotion;
  final String intensity;
  final String actingInstruction;
  final int estimatedDurationSeconds;
}

class GuidedTimelineImportData {
  const GuidedTimelineImportData({
    this.markerId = '',
    this.order = 0,
    this.sequenceType = '',
    this.startSecond = 0,
    this.endSecond = 0,
    this.source = '',
    this.userMustRecord = false,
    this.cameraPlan = '',
    this.framing = '',
    this.movement = '',
    this.transition = '',
    this.montageNote = '',
    this.expectedDialogue = '',
    this.aiAudioOnly = false,
    this.userAudioEnabled = false,
  });

  final String markerId;
  final int order;
  final String sequenceType;
  final int startSecond;
  final int endSecond;
  final String source;
  final bool userMustRecord;
  final String cameraPlan;
  final String framing;
  final String movement;
  final String transition;
  final String montageNote;
  final String expectedDialogue;
  final bool aiAudioOnly;
  final bool userAudioEnabled;

  int get durationSeconds => endSecond > startSecond ? endSecond - startSecond : 0;
  bool get isUserSequence => userMustRecord || source.toLowerCase() == 'user' || sequenceType.toLowerCase().contains('user');
  bool get isAiSequence => !isUserSequence;
}

class VeoIntroSegmentImportData {
  const VeoIntroSegmentImportData({
    this.segmentId = '',
    this.order = 0,
    this.title = '',
    this.prompt = '',
    this.desiredDurationSeconds = 0,
    this.visualStyle = '',
    this.soundAmbience = '',
    this.transitionOut = '',
    this.negativePrompt = '',
    this.cameraDirection = '',
  });

  final String segmentId;
  final int order;
  final String title;
  final String prompt;
  final int desiredDurationSeconds;
  final String visualStyle;
  final String soundAmbience;
  final String transitionOut;
  final String negativePrompt;
  final String cameraDirection;
}

class DirectorNotesImportData {
  const DirectorNotesImportData({
    this.rhythm = '',
    this.technicalAnchors = '',
    this.spectatorFeeling = '',
    this.finalNote = '',
    this.safetyNotes = '',
    this.performanceTips = '',
  });

  final String rhythm;
  final String technicalAnchors;
  final String spectatorFeeling;
  final String finalNote;
  final String safetyNotes;
  final String performanceTips;
}

class PublicationImportData {
  const PublicationImportData({
    this.status = 'draft',
    this.adminWorkflow = true,
    this.visibility = 'admin',
    this.isPremium = false,
    this.publishCountry = '',
    this.publishRegion = '',
    this.tags = const [],
    this.createdByFreelanceName = '',
    this.batchId = '',
  });

  final String status;
  final bool adminWorkflow;
  final String visibility;
  final bool isPremium;
  final String publishCountry;
  final String publishRegion;
  final List<String> tags;
  final String createdByFreelanceName;
  final String batchId;
}

class ImportValidationSummary {
  const ImportValidationSummary({
    required this.title,
    required this.category,
    required this.genre,
    required this.difficulty,
    required this.targetDurationSeconds,
    required this.veoIntroSegmentCount,
    required this.userSequenceCount,
    required this.dialogueCount,
    required this.timelineMarkerCount,
    required this.proposedStatus,
  });

  final String title;
  final String category;
  final String genre;
  final String difficulty;
  final int targetDurationSeconds;
  final int veoIntroSegmentCount;
  final int userSequenceCount;
  final int dialogueCount;
  final int timelineMarkerCount;
  final String proposedStatus;
}

class ImportValidationResult {
  const ImportValidationResult({
    required this.isValid,
    required this.blockingErrors,
    required this.warnings,
    required this.unknownFields,
    required this.normalizedFields,
    required this.summary,
  });

  final bool isValid;
  final List<String> blockingErrors;
  final List<String> warnings;
  final List<String> unknownFields;
  final List<String> normalizedFields;
  final ImportValidationSummary summary;
}
