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
      await tester.pumpWidget(
        MaterialApp(
          home: AddScenePage(
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

      expect(find.text('Prompt VEO3'), findsOneWidget);
      expect(find.text('Valider et générer la preview'), findsOneWidget);

      await tester.tap(find.text('Valider et générer la preview'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Preview générée. Vérifie le raccord final puis valide la vidéo.'),
        findsOneWidget,
      );
      expect(find.text('Corriger le prompt'), findsOneWidget);
      expect(find.text('Valider cette vidéo'), findsOneWidget);

      await tester.tap(find.text('Valider cette vidéo'));
      await tester.pumpAndSettle();

      expect(find.text('Vidéo validée'), findsOneWidget);
      expect(
        find.text('16) Prévisualisation de la page détail de scène'),
        findsOneWidget,
      );
      expect(find.text('Intention de raccord'), findsOneWidget);
      expect(find.text('Modifier le prompt VEO3'), findsOneWidget);
    },
  );
}
