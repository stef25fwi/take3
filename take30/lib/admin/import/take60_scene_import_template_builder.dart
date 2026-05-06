import 'dart:convert';
import 'dart:typed_data';

class Take60SceneImportTemplateBuilder {
  const Take60SceneImportTemplateBuilder();

  String buildOfficialJsonTemplate() {
    return const JsonEncoder.withIndent('  ').convert(_officialTemplate);
  }

  Uint8List buildOfficialJsonTemplateBytes() {
    return Uint8List.fromList(utf8.encode(buildOfficialJsonTemplate()));
  }

  String buildCsvTemplate() {
    const rows = <List<String>>[
      ['section', 'key', 'value', 'order', 'markerId'],
      ['sceneGeneral', 'title', '', '', ''],
      ['sceneGeneral', 'subtitle', '', '', ''],
      ['sceneGeneral', 'category', '', '', ''],
      ['sceneGeneral', 'genre', '', '', ''],
      ['sceneGeneral', 'difficulty', '', '', ''],
      ['sceneGeneral', 'sceneType', '', '', ''],
      ['sceneGeneral', 'country', '', '', ''],
      ['sceneGeneral', 'region', '', '', ''],
      ['sceneGeneral', 'targetDurationSeconds', '60', '', ''],
      ['sceneGeneral', 'synopsis', '', '', ''],
      ['sceneGeneral', 'actorObjective', '', '', ''],
      ['sceneGeneral', 'directorIntention', '', '', ''],
      ['sceneGeneral', 'mood', '', '', ''],
      ['sceneGeneral', 'visualStyle', '', '', ''],
      ['sceneGeneral', 'soundMood', '', '', ''],
      ['sceneGeneral', 'tags', '', '', ''],
      ['characters', 'id', 'character_1', '1', ''],
      ['characters', 'name', '', '1', ''],
      ['characters', 'role', '', '1', ''],
      ['characters', 'description', '', '1', ''],
      ['characters', 'emotionalState', '', '1', ''],
      ['veoIntroSegments', 'segmentId', 'intro_1', '1', ''],
      ['veoIntroSegments', 'order', '1', '1', ''],
      ['veoIntroSegments', 'title', '', '1', ''],
      ['veoIntroSegments', 'prompt', '', '1', ''],
      ['veoIntroSegments', 'desiredDurationSeconds', '8', '1', ''],
      ['veoIntroSegments', 'negativePrompt', '', '1', ''],
      ['veoIntroSegments', 'cameraDirection', '', '1', ''],
      ['guidedTimeline', 'sequenceType', 'ai', '1', 'm1'],
      ['guidedTimeline', 'startSecond', '16', '1', 'm1'],
      ['guidedTimeline', 'endSecond', '22', '1', 'm1'],
      ['guidedTimeline', 'source', 'ai', '1', 'm1'],
      ['guidedTimeline', 'userMustRecord', 'false', '1', 'm1'],
      ['guidedTimeline', 'aiAudioOnly', 'true', '1', 'm1'],
      ['guidedTimeline', 'userAudioEnabled', 'false', '1', 'm1'],
      ['guidedTimeline', 'sequenceType', 'user', '2', 'm2'],
      ['guidedTimeline', 'startSecond', '22', '2', 'm2'],
      ['guidedTimeline', 'endSecond', '32', '2', 'm2'],
      ['guidedTimeline', 'source', 'user', '2', 'm2'],
      ['guidedTimeline', 'userMustRecord', 'true', '2', 'm2'],
      ['guidedTimeline', 'userAudioEnabled', 'true', '2', 'm2'],
      ['dialogues', 'characterName', '', '1', 'm2'],
      ['dialogues', 'expectedDialogue', '', '1', 'm2'],
      ['dialogues', 'emotion', '', '1', 'm2'],
      ['dialogues', 'estimatedDurationSeconds', '10', '1', 'm2'],
      ['directorNotes', 'rhythm', '', '', ''],
      ['directorNotes', 'technicalAnchors', '', '', ''],
      ['directorNotes', 'spectatorFeeling', '', '', ''],
      ['directorNotes', 'finalNote', '', '', ''],
      ['publication', 'status', 'draft', '', ''],
      ['publication', 'adminWorkflow', 'true', '', ''],
      ['publication', 'visibility', 'admin', '', ''],
      ['publication', 'isPremium', 'false', '', ''],
      ['publication', 'batchId', '', '', ''],
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  Uint8List buildCsvTemplateBytes() {
    return Uint8List.fromList(utf8.encode(buildCsvTemplate()));
  }
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

const _officialTemplate = <String, dynamic>{
  'schemaVersion': 'take60_scene_import_v1',
  'sceneGeneral': {
    'title': '',
    'subtitle': '',
    'category': '',
    'genre': '',
    'difficulty': '',
    'sceneType': '',
    'country': '',
    'region': '',
    'targetDurationSeconds': 60,
    'synopsis': '',
    'actorObjective': '',
    'directorIntention': '',
    'mood': '',
    'visualStyle': '',
    'soundMood': '',
    'tags': [],
  },
  'characters': [
    {
      'id': 'character_1',
      'name': '',
      'role': '',
      'description': '',
      'emotionalState': '',
      'costume': '',
      'notes': '',
    }
  ],
  'veoIntroSegments': [
    {
      'segmentId': 'intro_1',
      'order': 1,
      'title': '',
      'prompt': '',
      'desiredDurationSeconds': 8,
      'visualStyle': '',
      'soundAmbience': '',
      'transitionOut': '',
      'negativePrompt': '',
      'cameraDirection': '',
    },
    {
      'segmentId': 'intro_2',
      'order': 2,
      'title': '',
      'prompt': '',
      'desiredDurationSeconds': 8,
      'visualStyle': '',
      'soundAmbience': '',
      'transitionOut': '',
      'negativePrompt': '',
      'cameraDirection': '',
    },
  ],
  'guidedTimeline': [
    {
      'markerId': 'm1',
      'order': 1,
      'sequenceType': 'ai',
      'startSecond': 16,
      'endSecond': 22,
      'source': 'ai',
      'userMustRecord': false,
      'cameraPlan': '',
      'framing': '',
      'movement': '',
      'transition': '',
      'montageNote': '',
      'expectedDialogue': '',
      'aiAudioOnly': true,
      'userAudioEnabled': false,
    },
    {
      'markerId': 'm2',
      'order': 2,
      'sequenceType': 'user',
      'startSecond': 22,
      'endSecond': 32,
      'source': 'user',
      'userMustRecord': true,
      'cameraPlan': '',
      'framing': '',
      'movement': '',
      'transition': '',
      'montageNote': '',
      'expectedDialogue': '',
      'aiAudioOnly': false,
      'userAudioEnabled': true,
    },
  ],
  'dialogues': [
    {
      'markerId': 'm2',
      'order': 1,
      'characterName': '',
      'expectedDialogue': '',
      'emotion': '',
      'intensity': '',
      'actingInstruction': '',
      'estimatedDurationSeconds': 10,
    }
  ],
  'directorNotes': {
    'rhythm': '',
    'technicalAnchors': '',
    'spectatorFeeling': '',
    'finalNote': '',
    'safetyNotes': '',
    'performanceTips': '',
  },
  'publication': {
    'status': 'draft',
    'adminWorkflow': true,
    'visibility': 'admin',
    'isPremium': false,
    'publishCountry': '',
    'publishRegion': '',
    'tags': [],
    'createdByFreelanceName': '',
    'batchId': '',
  },
};
