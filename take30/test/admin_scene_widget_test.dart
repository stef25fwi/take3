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
            enableAdminTools: true,
            veoVideoGenerationService: _FakeVeoVideoGenerationService(),
          ),
        ),
      );

      await tester.tap(
        find.text('Charger scène test — Interrogatoire police'),
      );
      await tester.pumpAndSettle();

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
            enableAdminTools: true,
            veoVideoGenerationService: _FakeVeoVideoGenerationService(),
          ),
        ),
      );

      await tester.tap(
        find.text('Charger scène test — Interrogatoire police'),
      );
      await tester.pumpAndSettle();

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
}
