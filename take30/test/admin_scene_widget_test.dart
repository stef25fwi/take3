import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:take30/admin/models/ai_generated_video.dart';
import 'package:take30/admin/services/veo_video_generation_service.dart';
import 'package:take30/admin/take30_admin_scene_flow.dart';

class _FakeVeoVideoGenerationService implements VeoVideoGenerationService {
  @override
  Future<AiGeneratedVideo> generateSceneIntroVideo({
    required String sceneDraftId,
    required String prompt,
    int durationSeconds = 15,
    String aspectRatio = '16:9',
  }) async {
    final now = DateTime(2026, 4, 27, 18, 0);
    return AiGeneratedVideo(
      provider: 'veo3',
      prompt: prompt,
      videoUrl: 'https://example.com/preview.mp4',
      thumbnailUrl: 'https://example.com/preview.jpg',
      durationSeconds: durationSeconds,
      aspectRatio: aspectRatio,
      status: AiIntroVideoStatus.generated,
      generatedAt: now,
      updatedAt: now,
    );
  }
}

void main() {
  testWidgets(
    'step 15 generates then validates intro video and reveals detailed preview',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AddScenePage(
            initialData: SceneFormData.testPoliceInterrogation(),
            veoVideoGenerationService: _FakeVeoVideoGenerationService(),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('15) Vidéo IA d’introduction'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Prompt VEO3'), findsWidgets);
      expect(find.text('Valider et générer la preview'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Valider et générer la preview'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider et générer la preview'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.text('Preview générée. Vérifie le raccord final puis valide la vidéo.'),
        findsOneWidget,
      );
      expect(find.text('Corriger le prompt'), findsOneWidget);
      expect(find.text('Valider cette vidéo'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Valider cette vidéo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Valider cette vidéo'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Vidéo validée'), findsOneWidget);
      expect(
        find.text('16) Prévisualisation de la page détail de scène'),
        findsOneWidget,
      );
      expect(find.text('Intention de raccord'), findsOneWidget);
      expect(find.textContaining('Prompt VEO3'), findsWidgets);
      expect(find.textContaining('Timeline guidée — 60 secondes'), findsOneWidget);
      expect(find.textContaining('Plan 1 — Observation silencieuse'), findsOneWidget);
      expect(find.textContaining('Plan 2 — Réplique principale'), findsOneWidget);
      expect(find.textContaining('Plan 3 — Fissure finale'), findsOneWidget);
      expect(find.textContaining('Vidéo IA'), findsWidgets);
    },
  );

  testWidgets(
    'preview détail n\'écrase pas l\'écran si la timeline JSON est invalide',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AddScenePage(
            initialData: SceneFormData.testPoliceInterrogation(),
            veoVideoGenerationService: _FakeVeoVideoGenerationService(),
          ),
        ),
      );

      final dynamic state = tester.state(find.byType(AddScenePage));
      state.markersJsonCtrl.text = '{timeline_invalide:';
      state.setState(() {});
      await tester.pump();

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('16) Prévisualisation de la page détail de scène'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Prompt VEO3'), findsWidgets);
      expect(
        find.text('Timeline indisponible ou JSON invalide.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'importe un prompt scénario et remplit les champs clés sans casser la page',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AddScenePage(
            initialData: SceneFormData.testPoliceInterrogation(),
            veoVideoGenerationService: _FakeVeoVideoGenerationService(),
          ),
        ),
      );

      expect(find.text('Importer un prompt scénario'), findsOneWidget);
      await tester.tap(find.text('Insérer exemple police'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remplir automatiquement'));
      await tester.pump();

      expect(find.text('Champs remplis automatiquement.'), findsOneWidget);
      expect(find.textContaining('champs détectés'), findsOneWidget);
      expect(find.text('Timeline JSON détectée'), findsOneWidget);
      expect(find.text('Prompt VEO détecté'), findsOneWidget);
      expect(find.text('Dialogue détecté'), findsOneWidget);

      final dynamic state = tester.state(find.byType(AddScenePage));
      expect(state.sceneNameCtrl.text, 'Interrogatoire sous tension');
      expect(state.categoryCtrl.text, 'Policier');
      expect(state.genreCtrl.text, 'Drame / Thriller');
      expect(
        state.dialogueTextCtrl.text,
        contains('Je n\'ai rien vu, lieutenant.'),
      );
      expect(state.veoPromptCtrl.text, contains('salle d\'interrogatoire')); 
      expect(state.markersJsonCtrl.text, contains('intro_ai_001'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'objectif libre importé ne remplace pas l’obstacle et titre projet reste synchronisé si lié à la scène',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AddScenePage(
            initialData: SceneFormData.testPoliceInterrogation(),
            veoVideoGenerationService: _FakeVeoVideoGenerationService(),
          ),
        ),
      );

      final dynamic state = tester.state(find.byType(AddScenePage));
      state.projectTitleCtrl.text = state.sceneNameCtrl.text;
      state.importPromptCtrl.text = '''
TITRE DE LA SCÈNE
Interrogatoire sous tension

PERSONNAGE À JOUER PAR L’UTILISATEUR
Nom : Malik Darcel
Objectif : gagner du temps face au policier
État émotionnel : méfiance

TEXTE / DIALOGUE ACTEUR
Je n'ai rien vu.
''';
      state.setState(() {});
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remplir automatiquement'));
      await tester.pumpAndSettle();

      expect(state.sceneNameCtrl.text, 'Interrogatoire sous tension');
      expect(state.projectTitleCtrl.text, 'Interrogatoire sous tension');
      expect(
        state.mainObstacleCtrl.text,
        'Pression psychologique et preuves présentées par l’enquêteur.',
      );
      expect(state.selectedMainObjective, 'cacher la vérité');
      expect(state.referencesCtrl.text, contains('Objectif importé'));
    },
  );
}
