import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:take30/admin/import/take60_scene_import_model.dart';
import 'package:take30/admin/import/take60_scene_import_parser.dart';
import 'package:take30/admin/import/take60_scene_import_preview.dart';
import 'package:take30/admin/import/take60_scene_import_validator.dart';

const _validJson = <String, dynamic>{
  'schemaVersion': 'take60_scene_import_v1',
  'sceneGeneral': {
    'title': 'Interrogatoire sous tension',
    'category': 'policier',
    'genre': 'drame',
    'difficulty': 'Intermédiaire',
    'targetDurationSeconds': 60,
    'synopsis': 'Un suspect nie tout dans une salle froide.',
    'directorIntention': 'Installer une tension réaliste.',
    'tags': 'policier, tension, face-à-face',
  },
  'characters': [
    {
      'id': 'character_1',
      'name': 'Lina',
      'role': 'Suspecte',
      'description': 'Une femme sur la défensive.',
    }
  ],
  'veoIntroSegments': [
    {
      'segmentId': 'intro_1',
      'order': 1,
      'title': 'Couloir froid',
      'prompt': 'Plan réaliste d’un couloir de commissariat.',
      'desiredDurationSeconds': 8,
      'negativePrompt': 'texte, logo',
    },
    {
      'segmentId': 'intro_2',
      'order': 2,
      'title': 'Table vide',
      'prompt': 'Travelling lent vers une table métallique.',
      'desiredDurationSeconds': 8,
      'negativePrompt': 'texte, logo',
    }
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
      'aiAudioOnly': true,
      'userAudioEnabled': false,
    },
    {
      'markerId': 'm2',
      'order': 2,
      'sequenceType': 'user',
      'startSecond': 22,
      'endSecond': 60,
      'source': 'user',
      'userMustRecord': true,
      'expectedDialogue': 'Je n’ai rien vu.',
      'aiAudioOnly': false,
      'userAudioEnabled': true,
    }
  ],
  'dialogues': [
    {
      'markerId': 'm2',
      'order': 1,
      'characterName': 'Lina',
      'expectedDialogue': 'Je n’ai rien vu.',
      'emotion': 'tension',
      'intensity': 'moyen',
      'estimatedDurationSeconds': 10,
    }
  ],
  'directorNotes': {
    'rhythm': 'progressif',
    'finalNote': 'Rester sobre.',
  },
  'publication': {
    'status': 'draft',
    'adminWorkflow': true,
    'visibility': 'admin',
  },
};

void main() {
  group('Take60SceneImportParser', () {
    test('parse le JSON officiel Take60', () {
      const parser = Take60SceneImportParser();
      final draft = parser.parseOfficialJson(jsonEncode(_validJson));

      expect(draft.schemaVersion, Take60SceneImportDraft.currentSchemaVersion);
      expect(draft.sceneGeneral.title, 'Interrogatoire sous tension');
      expect(draft.sceneGeneral.category, 'Policier');
      expect(draft.sceneGeneral.genre, 'Drame');
      expect(draft.sceneGeneral.difficulty, 'intermédiaire');
      expect(draft.veoIntroSegments, hasLength(2));
      expect(draft.guidedTimeline, hasLength(2));
      expect(draft.dialogues.single.markerId, 'm2');
    });

    test('normalise booléens oui/non et tags CSV', () {
      const parser = Take60SceneImportParser();
      final csv = [
        'section,key,value,order,markerId',
        'sceneGeneral,title,Face à face, , ',
        'sceneGeneral,category,Drame, , ',
        'sceneGeneral,genre,Thriller, , ',
        'sceneGeneral,difficulty,Confirmé, , ',
        'sceneGeneral,targetDurationSeconds,60, , ',
        'sceneGeneral,directorIntention,Tension froide, , ',
        'sceneGeneral,tags,"policier, tension, face-à-face", , ',
        'guidedTimeline,sequenceType,user,1,m1',
        'guidedTimeline,startSecond,0,1,m1',
        'guidedTimeline,endSecond,10,1,m1',
        'guidedTimeline,userMustRecord,oui,1,m1',
        'guidedTimeline,userAudioEnabled,1,1,m1',
        'guidedTimeline,aiAudioOnly,non,1,m1',
      ].join('\n');

      final draft = parser.parseCsv(csv);

      expect(draft.sceneGeneral.tags, containsAll(['policier', 'tension', 'face-à-face']));
      expect(draft.guidedTimeline.single.userMustRecord, isTrue);
      expect(draft.guidedTimeline.single.userAudioEnabled, isTrue);
      expect(draft.guidedTimeline.single.aiAudioOnly, isFalse);
    });

    test('rejette un fichier JSON trop gros', () {
      const parser = Take60SceneImportParser();
      final bytes = Uint8List(Take60SceneImportParser.maxJsonOrCsvBytes + 1);

      expect(
        () => parser.parseBytes(bytes: bytes, fileName: 'scenario.json'),
        throwsA(isA<Take60SceneImportException>()),
      );
    });
  });

  group('Take60SceneImportValidator', () {
    test('valide un scénario complet avec warnings non bloquants éventuels', () {
      const parser = Take60SceneImportParser();
      const validator = Take60SceneImportValidator();
      final draft = parser.parseOfficialJson(jsonEncode(_validJson));
      final result = validator.validate(draft);

      expect(result.isValid, isTrue);
      expect(result.blockingErrors, isEmpty);
      expect(result.summary.title, 'Interrogatoire sous tension');
      expect(result.summary.userSequenceCount, 1);
      expect(result.summary.veoIntroSegmentCount, 2);
    });

    test('détecte une erreur bloquante si le titre est vide', () {
      const parser = Take60SceneImportParser();
      const validator = Take60SceneImportValidator();
      final json = Map<String, dynamic>.from(_validJson);
      json['sceneGeneral'] = Map<String, dynamic>.from(_validJson['sceneGeneral']! as Map)
        ..['title'] = '';
      final draft = parser.parseOfficialJson(jsonEncode(json));
      final result = validator.validate(draft);

      expect(result.isValid, isFalse);
      expect(result.blockingErrors, contains('Le titre de la scène est obligatoire.'));
    });

    test('détecte une timeline incohérente', () {
      const parser = Take60SceneImportParser();
      const validator = Take60SceneImportValidator();
      final json = Map<String, dynamic>.from(_validJson);
      json['guidedTimeline'] = [
        {
          'markerId': 'm1',
          'order': 1,
          'sequenceType': 'user',
          'startSecond': 12,
          'endSecond': 10,
          'source': 'user',
          'userMustRecord': true,
        }
      ];
      final result = validator.validate(parser.parseOfficialJson(jsonEncode(json)));

      expect(result.isValid, isFalse);
      expect(result.blockingErrors.join('\n'), contains('endSecond > startSecond'));
    });

    test('conserve les warnings non bloquants', () {
      const parser = Take60SceneImportParser();
      const validator = Take60SceneImportValidator();
      final json = Map<String, dynamic>.from(_validJson);
      json['characters'] = [
        {'name': 'Personnage sans description'}
      ];
      final result = validator.validate(parser.parseOfficialJson(jsonEncode(json)));

      expect(result.isValid, isTrue);
      expect(result.warnings.join('\n'), contains('sans description'));
    });
  });

  testWidgets('la prévisualisation affiche les infos et désactive injection si erreurs', (tester) async {
    const parser = Take60SceneImportParser();
    const validator = Take60SceneImportValidator();
    final json = Map<String, dynamic>.from(_validJson);
    json['sceneGeneral'] = Map<String, dynamic>.from(_validJson['sceneGeneral']! as Map)
      ..['title'] = '';
    final draft = parser.parseOfficialJson(jsonEncode(json));
    final validation = validator.validate(draft);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Take60SceneImportPreview(
            draft: draft,
            validation: validation,
            onInject: () {},
          ),
        ),
      ),
    );

    expect(find.text('Prévisualisation de l’import'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);
    expect(find.text('Policier'), findsOneWidget);
    final injectButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Injecter dans le formulaire'),
    );
    expect(injectButton.onPressed, isNull);
  });
}
