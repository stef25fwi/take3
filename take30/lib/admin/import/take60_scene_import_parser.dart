import 'dart:convert';
import 'dart:typed_data';

import 'take60_scene_import_model.dart';

class Take60SceneImportParser {
  const Take60SceneImportParser();

  static const maxJsonOrCsvBytes = 2 * 1024 * 1024;
  static const maxXlsxBytes = 5 * 1024 * 1024;

  Take60SceneImportDraft parseBytes({
    required Uint8List bytes,
    required String fileName,
    String importedBy = '',
    DateTime? importedAt,
  }) {
    final extension = _extensionOf(fileName);
    final maxBytes = extension == 'xlsx' ? maxXlsxBytes : maxJsonOrCsvBytes;
    if (bytes.lengthInBytes > maxBytes) {
      final maxMb = extension == 'xlsx' ? 5 : 2;
      throw Take60SceneImportException(
        'Fichier trop volumineux. Taille maximale autorisée : $maxMb Mo.',
      );
    }

    if (extension == 'xlsx') {
      throw const Take60SceneImportException(
        'Le format XLSX sera activé après validation du package Excel. Utilisez le modèle JSON ou CSV officiel.',
      );
    }

    final raw = utf8.decode(bytes, allowMalformed: true).trim();
    if (raw.isEmpty) {
      throw const Take60SceneImportException('Le fichier sélectionné est vide.');
    }

    if (extension == 'csv') {
      return parseCsv(raw, importedBy: importedBy, importedAt: importedAt);
    }
    if (extension == 'json' || raw.startsWith('{')) {
      return parseOfficialJson(raw, importedBy: importedBy, importedAt: importedAt);
    }

    throw Take60SceneImportException(
      'Format de fichier non pris en charge : .$extension. Formats acceptés : .json, .csv.',
    );
  }

  Take60SceneImportDraft parseOfficialJson(
    String raw, {
    String importedBy = '',
    DateTime? importedAt,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const Take60SceneImportException('Le JSON officiel doit contenir un objet racine.');
    }
    final root = _mapOf(decoded);
    final unknown = _unknownKeys(root, const {
      'schemaVersion',
      'sceneGeneral',
      'characters',
      'dialogues',
      'guidedTimeline',
      'veoIntroSegments',
      'directorNotes',
      'publication',
    });

    final sceneGeneral = _readSceneGeneral(_readMap(root['sceneGeneral']));
    final publication = _readPublication(_readMap(root['publication']));

    return Take60SceneImportDraft(
      schemaVersion: _string(root['schemaVersion'], fallback: Take60SceneImportDraft.currentSchemaVersion),
      sourceFormat: 'json',
      importedAt: importedAt ?? DateTime.now(),
      importedBy: importedBy,
      sceneGeneral: sceneGeneral,
      characters: _readList(root['characters']).map(_readCharacter).toList(),
      dialogues: _readList(root['dialogues']).map(_readDialogue).toList(),
      guidedTimeline: _readList(root['guidedTimeline']).map(_readTimeline).toList(),
      veoIntroSegments: _readList(root['veoIntroSegments']).map(_readVeoSegment).toList(),
      directorNotes: _readDirectorNotes(_readMap(root['directorNotes'])),
      publication: publication,
      rawWarnings: const [],
      rawErrors: const [],
      unknownFields: unknown,
    );
  }

  Take60SceneImportDraft parseCsv(
    String raw, {
    String importedBy = '',
    DateTime? importedAt,
  }) {
    final rows = _parseCsvRows(raw);
    if (rows.isEmpty) {
      throw const Take60SceneImportException('Le CSV ne contient aucune ligne exploitable.');
    }
    final headers = rows.first.map((value) => _normalizeKey(value)).toList();
    final sectionIndex = headers.indexOf('section');
    final keyIndex = headers.indexOf('key');
    final valueIndex = headers.indexOf('value');
    final orderIndex = headers.indexOf('order');
    final markerIndex = headers.indexOf('markerid');
    if (sectionIndex < 0 || keyIndex < 0 || valueIndex < 0) {
      throw const Take60SceneImportException(
        'Le CSV doit contenir les colonnes section,key,value au minimum.',
      );
    }

    final general = <String, String>{};
    final director = <String, String>{};
    final publication = <String, String>{};
    final characters = <int, Map<String, String>>{};
    final dialogues = <int, Map<String, String>>{};
    final timeline = <int, Map<String, String>>{};
    final veo = <int, Map<String, String>>{};
    final unknown = <String>[];

    for (final row in rows.skip(1)) {
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }
      String cell(int index) => index >= 0 && index < row.length ? row[index].trim() : '';
      final section = _normalizeKey(cell(sectionIndex));
      final key = _normalizeKey(cell(keyIndex));
      final value = cell(valueIndex);
      final order = _int(cell(orderIndex), fallback: 1);
      final markerId = cell(markerIndex);
      if (section.isEmpty || key.isEmpty) {
        continue;
      }
      switch (section) {
        case 'scenegeneral':
        case 'general':
        case 'scene':
          general[key] = value;
        case 'directornotes':
        case 'director':
          director[key] = value;
        case 'publication':
          publication[key] = value;
        case 'characters':
        case 'character':
          characters.putIfAbsent(order, () => <String, String>{})[key] = value;
        case 'dialogues':
        case 'dialogue':
          final map = dialogues.putIfAbsent(order, () => <String, String>{});
          map[key] = value;
          if (markerId.isNotEmpty) map['markerid'] = markerId;
        case 'guidedtimeline':
        case 'timeline':
          final map = timeline.putIfAbsent(order, () => <String, String>{});
          map[key] = value;
          if (markerId.isNotEmpty) map['markerid'] = markerId;
        case 'veointrosegments':
        case 'veo':
        case 'intro':
          veo.putIfAbsent(order, () => <String, String>{})[key] = value;
        default:
          unknown.add('section:$section.$key');
      }
    }

    return Take60SceneImportDraft(
      schemaVersion: Take60SceneImportDraft.currentSchemaVersion,
      sourceFormat: 'csv',
      importedAt: importedAt ?? DateTime.now(),
      importedBy: importedBy,
      sceneGeneral: SceneGeneralImportData(
        title: _string(general['title']),
        subtitle: _string(general['subtitle']),
        category: _normalizeTitle(general['category']),
        genre: _normalizeTitle(general['genre']),
        difficulty: _normalizeDifficulty(general['difficulty']),
        sceneType: _string(general['scenetype']),
        country: _normalizeTitle(general['country']),
        region: _normalizeTitle(general['region']),
        targetDurationSeconds: _int(general['targetdurationseconds'] ?? general['duration']),
        synopsis: _string(general['synopsis']),
        actorObjective: _string(general['actorobjective']),
        directorIntention: _string(general['directorintention']),
        mood: _string(general['mood']),
        visualStyle: _string(general['visualstyle']),
        soundMood: _string(general['soundmood']),
        tags: normalizeTags(general['tags']),
      ),
      characters: characters.entries.map((entry) => _readCharacterStringMap(entry.value, entry.key)).toList(),
      dialogues: dialogues.entries.map((entry) => _readDialogueStringMap(entry.value, entry.key)).toList(),
      guidedTimeline: timeline.entries.map((entry) => _readTimelineStringMap(entry.value, entry.key)).toList(),
      veoIntroSegments: veo.entries.map((entry) => _readVeoSegmentStringMap(entry.value, entry.key)).toList(),
      directorNotes: DirectorNotesImportData(
        rhythm: _string(director['rhythm']),
        technicalAnchors: _string(director['technicalanchors']),
        spectatorFeeling: _string(director['spectatorfeeling']),
        finalNote: _string(director['finalnote']),
        safetyNotes: _string(director['safetynotes']),
        performanceTips: _string(director['performancetips']),
      ),
      publication: PublicationImportData(
        status: _string(publication['status'], fallback: 'draft'),
        adminWorkflow: normalizeBool(publication['adminworkflow'], fallback: true),
        visibility: _string(publication['visibility'], fallback: 'admin'),
        isPremium: normalizeBool(publication['ispremium']),
        publishCountry: _normalizeTitle(publication['publishcountry']),
        publishRegion: _normalizeTitle(publication['publishregion']),
        tags: normalizeTags(publication['tags']),
        createdByFreelanceName: _string(publication['createdbyfreelancename']),
        batchId: _string(publication['batchid']),
      ),
      unknownFields: unknown,
    );
  }
}

class Take60SceneImportException implements Exception {
  const Take60SceneImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

SceneGeneralImportData _readSceneGeneral(Map<String, dynamic> map) {
  return SceneGeneralImportData(
    title: _string(map['title']),
    subtitle: _string(map['subtitle']),
    category: _normalizeTitle(map['category']),
    genre: _normalizeTitle(map['genre']),
    difficulty: _normalizeDifficulty(map['difficulty']),
    sceneType: _string(map['sceneType']),
    country: _normalizeTitle(map['country']),
    region: _normalizeTitle(map['region']),
    targetDurationSeconds: _int(map['targetDurationSeconds']),
    synopsis: _string(map['synopsis']),
    actorObjective: _string(map['actorObjective']),
    directorIntention: _string(map['directorIntention']),
    mood: _string(map['mood']),
    visualStyle: _string(map['visualStyle']),
    soundMood: _string(map['soundMood']),
    tags: normalizeTags(map['tags']),
  );
}

CharacterImportData _readCharacter(Map<String, dynamic> map) => CharacterImportData(
      id: _string(map['id']),
      name: _string(map['name']),
      role: _string(map['role']),
      description: _string(map['description']),
      emotionalState: _string(map['emotionalState']),
      costume: _string(map['costume']),
      notes: _string(map['notes']),
    );

CharacterImportData _readCharacterStringMap(Map<String, String> map, int order) => CharacterImportData(
      id: _string(map['id'], fallback: 'character_$order'),
      name: _string(map['name']),
      role: _string(map['role']),
      description: _string(map['description']),
      emotionalState: _string(map['emotionalstate']),
      costume: _string(map['costume']),
      notes: _string(map['notes']),
    );

DialogueImportData _readDialogue(Map<String, dynamic> map) => DialogueImportData(
      markerId: _string(map['markerId']),
      order: _int(map['order']),
      characterName: _string(map['characterName']),
      expectedDialogue: _string(map['expectedDialogue']),
      emotion: _string(map['emotion']),
      intensity: _string(map['intensity']),
      actingInstruction: _string(map['actingInstruction']),
      estimatedDurationSeconds: _int(map['estimatedDurationSeconds']),
    );

DialogueImportData _readDialogueStringMap(Map<String, String> map, int order) => DialogueImportData(
      markerId: _string(map['markerid']),
      order: _int(map['order'], fallback: order),
      characterName: _string(map['charactername']),
      expectedDialogue: _string(map['expecteddialogue'] ?? map['dialogue']),
      emotion: _string(map['emotion']),
      intensity: _string(map['intensity']),
      actingInstruction: _string(map['actinginstruction']),
      estimatedDurationSeconds: _int(map['estimateddurationseconds']),
    );

GuidedTimelineImportData _readTimeline(Map<String, dynamic> map) => GuidedTimelineImportData(
      markerId: _string(map['markerId']),
      order: _int(map['order']),
      sequenceType: _string(map['sequenceType']),
      startSecond: _int(map['startSecond']),
      endSecond: _int(map['endSecond']),
      source: _string(map['source']),
      userMustRecord: normalizeBool(map['userMustRecord']),
      cameraPlan: _string(map['cameraPlan']),
      framing: _string(map['framing']),
      movement: _string(map['movement']),
      transition: _string(map['transition']),
      montageNote: _string(map['montageNote']),
      expectedDialogue: _string(map['expectedDialogue']),
      aiAudioOnly: normalizeBool(map['aiAudioOnly']),
      userAudioEnabled: normalizeBool(map['userAudioEnabled']),
    );

GuidedTimelineImportData _readTimelineStringMap(Map<String, String> map, int order) => GuidedTimelineImportData(
      markerId: _string(map['markerid'], fallback: 'm$order'),
      order: _int(map['order'], fallback: order),
      sequenceType: _string(map['sequencetype']),
      startSecond: _int(map['startsecond']),
      endSecond: _int(map['endsecond']),
      source: _string(map['source']),
      userMustRecord: normalizeBool(map['usermustrecord']),
      cameraPlan: _string(map['cameraplan']),
      framing: _string(map['framing']),
      movement: _string(map['movement']),
      transition: _string(map['transition']),
      montageNote: _string(map['montagenote']),
      expectedDialogue: _string(map['expecteddialogue']),
      aiAudioOnly: normalizeBool(map['aiaudioonly']),
      userAudioEnabled: normalizeBool(map['useraudioenabled']),
    );

VeoIntroSegmentImportData _readVeoSegment(Map<String, dynamic> map) => VeoIntroSegmentImportData(
      segmentId: _string(map['segmentId']),
      order: _int(map['order']),
      title: _string(map['title']),
      prompt: _string(map['prompt']),
      desiredDurationSeconds: _int(map['desiredDurationSeconds']),
      visualStyle: _string(map['visualStyle']),
      soundAmbience: _string(map['soundAmbience']),
      transitionOut: _string(map['transitionOut']),
      negativePrompt: _string(map['negativePrompt']),
      cameraDirection: _string(map['cameraDirection']),
    );

VeoIntroSegmentImportData _readVeoSegmentStringMap(Map<String, String> map, int order) => VeoIntroSegmentImportData(
      segmentId: _string(map['segmentid'], fallback: 'intro_$order'),
      order: _int(map['order'], fallback: order),
      title: _string(map['title']),
      prompt: _string(map['prompt']),
      desiredDurationSeconds: _int(map['desireddurationseconds']),
      visualStyle: _string(map['visualstyle']),
      soundAmbience: _string(map['soundambience']),
      transitionOut: _string(map['transitionout']),
      negativePrompt: _string(map['negativeprompt']),
      cameraDirection: _string(map['cameradirection']),
    );

DirectorNotesImportData _readDirectorNotes(Map<String, dynamic> map) => DirectorNotesImportData(
      rhythm: _string(map['rhythm']),
      technicalAnchors: _string(map['technicalAnchors']),
      spectatorFeeling: _string(map['spectatorFeeling']),
      finalNote: _string(map['finalNote']),
      safetyNotes: _string(map['safetyNotes']),
      performanceTips: _string(map['performanceTips']),
    );

PublicationImportData _readPublication(Map<String, dynamic> map) => PublicationImportData(
      status: _string(map['status'], fallback: 'draft'),
      adminWorkflow: normalizeBool(map['adminWorkflow'], fallback: true),
      visibility: _string(map['visibility'], fallback: 'admin'),
      isPremium: normalizeBool(map['isPremium']),
      publishCountry: _normalizeTitle(map['publishCountry']),
      publishRegion: _normalizeTitle(map['publishRegion']),
      tags: normalizeTags(map['tags']),
      createdByFreelanceName: _string(map['createdByFreelanceName']),
      batchId: _string(map['batchId']),
    );

List<String> normalizeTags(dynamic value) {
  if (value is List) {
    return value.map(_string).expand((part) => normalizeTags(part)).toSet().toList();
  }
  return _string(value)
      .split(RegExp(r'[,;\n]'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();
}

bool normalizeBool(dynamic value, {bool fallback = false}) {
  final raw = _string(value).toLowerCase();
  if (raw.isEmpty) return fallback;
  if (['true', '1', 'oui', 'yes', 'y', 'vrai'].contains(raw)) return true;
  if (['false', '0', 'non', 'no', 'n', 'faux'].contains(raw)) return false;
  return fallback;
}

String _extensionOf(String fileName) {
  final index = fileName.lastIndexOf('.');
  return index < 0 ? '' : fileName.substring(index + 1).trim().toLowerCase();
}

String _normalizeKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _normalizeTitle(dynamic value) {
  final raw = _string(value);
  if (raw.isEmpty) return '';
  return raw[0].toUpperCase() + raw.substring(1);
}

String _normalizeDifficulty(dynamic value) {
  final raw = _string(value).toLowerCase();
  if (raw.isEmpty) return '';
  if (raw.contains('debut') || raw.contains('début') || raw.contains('facile')) return 'débutant';
  if (raw.contains('inter') || raw.contains('moyen')) return 'intermédiaire';
  if (raw.contains('confirm')) return 'confirmé';
  if (raw.contains('avance') || raw.contains('avancé') || raw.contains('expert')) return 'avancé';
  return raw;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final raw = _string(value);
  if (raw.isEmpty) return fallback;
  final match = RegExp(r'-?\d+').firstMatch(raw);
  return int.tryParse(match?.group(0) ?? '') ?? fallback;
}

Map<String, dynamic> _mapOf(Map map) => map.map((key, value) => MapEntry(key.toString(), value));

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return _mapOf(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map>().map(_mapOf).toList();
}

List<String> _unknownKeys(Map<String, dynamic> map, Set<String> allowed) {
  return map.keys.where((key) => !allowed.contains(key)).toList();
}

List<List<String>> _parseCsvRows(String raw) {
  final rows = <List<String>>[];
  final current = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < raw.length; i++) {
    final char = raw[i];
    if (char == '"') {
      if (inQuotes && i + 1 < raw.length && raw[i + 1] == '"') {
        cell.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (char == ',' && !inQuotes) {
      current.add(cell.toString());
      cell.clear();
      continue;
    }
    if ((char == '\n' || char == '\r') && !inQuotes) {
      if (char == '\r' && i + 1 < raw.length && raw[i + 1] == '\n') i++;
      current.add(cell.toString());
      cell.clear();
      rows.add(List<String>.from(current));
      current.clear();
      continue;
    }
    cell.write(char);
  }
  current.add(cell.toString());
  if (current.any((value) => value.trim().isNotEmpty)) {
    rows.add(current);
  }
  return rows;
}
