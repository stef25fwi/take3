import 'package:flutter_test/flutter_test.dart';
import 'package:take30/admin/models/ai_generated_video.dart';
import 'package:take30/admin/services/veo_video_generation_service.dart';
import 'package:take30/admin/take30_admin_scene_flow.dart';

void main() {
  group('AiGeneratedVideo', () {
    test('serializes and deserializes status and metadata', () {
      final now = DateTime(2026, 4, 27, 12, 0);
      final video = AiGeneratedVideo(
        provider: 'veo3',
        prompt: 'Rue dramatique en fin de journee',
        videoUrl: 'https://example.com/video.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        durationSeconds: 15,
        aspectRatio: '16:9',
        status: AiIntroVideoStatus.validated,
        generatedAt: now,
        updatedAt: now,
      );

      final decoded = AiGeneratedVideo.fromJson(video.toJson());

      expect(decoded.provider, 'veo3');
      expect(decoded.prompt, contains('Rue dramatique'));
      expect(decoded.status, AiIntroVideoStatus.validated);
      expect(decoded.durationSeconds, 15);
      expect(decoded.aspectRatio, '16:9');
      expect(decoded.isValidated, isTrue);
    });
  });

  group('MockVeoVideoGenerationService', () {
    test('returns a generated preview with expected metadata', () async {
      const service = MockVeoVideoGenerationService();

      final result = await service.generateSceneIntroVideo(
        sceneDraftId: 'scene_123',
        prompt: 'Camera travelling vers une porte, tension douce.',
      );

      expect(result.provider, 'veo3');
      expect(result.prompt, contains('Camera travelling'));
      expect(result.durationSeconds, 15);
      expect(result.aspectRatio, '16:9');
      expect(result.status, AiIntroVideoStatus.generated);
      expect(result.videoUrl, isNotEmpty);
    });
  });

  group('SceneFormData', () {
    test('stores the admin workflow payload for Firestore', () {
      final now = DateTime(2026, 4, 27, 14, 30);
      final video = AiGeneratedVideo(
        provider: 'veo3',
        prompt: 'Plan large avant entree de personnage',
        videoUrl: 'https://example.com/intro.mp4',
        thumbnailUrl: 'https://example.com/intro.jpg',
        durationSeconds: 15,
        aspectRatio: '16:9',
        status: AiIntroVideoStatus.validated,
        generatedAt: now,
        updatedAt: now,
      );

      final scene = SceneFormData(
        id: 'scene_admin_1',
        status: SceneStatus.pendingPublication,
        category: 'Audition',
        genre: 'Drame',
        recommendedLevel: 'intermédiaire',
        projectTitle: 'Projet test',
        sceneName: 'Confrontation devant la porte',
        sceneNumber: '12A',
        shootDate: '2026-04-27',
        location: 'Rue calme',
        director: 'Admin',
        targetDuration: '60 secondes',
        characterName: 'Mila',
        apparentAge: '28 ans',
        characterGender: 'Femme',
        profileRole: 'Role principal',
        relationship: 'Soeur',
        initialState: 'Retenue',
        characterSummary: 'Une femme sur le point de basculer.',
        previousMoment: 'Elle vient de recevoir un appel.',
        whereAreWe: 'Devant un immeuble ancien',
        withWho: 'Seule',
        whyImportant: 'Elle choisit si elle entre ou non.',
        contextSummary: 'Moment de decision intime.',
        mainObjective: 'convaincre',
        mainObstacle: 'La peur',
        stakes: 'Sauver sa relation',
        dominantEmotion: 'détermination',
        secondaryEmotion: 'fragilité',
        intensity: 'moyen',
        evolutionStart: 'Controler',
        evolutionMiddle: 'Fissure',
        evolutionEnd: 'Passage a l acte',
        emotionalNuance: 'Tremblement interieur',
        playStyles: const ['cinéma', 'intense'],
        actingDirection: 'Jouer la retenue avant la rupture.',
        references: 'Cinema indé',
        textType: 'texte exact à respecter',
        dialogueText: 'Je suis la, mais je ne sais pas si je peux entrer.',
        emphasizedWords: 'la, entrer',
        keyPhrase: 'je peux entrer',
        block1Intention: 'retenir',
        block1Energy: 'basse',
        block1Look: 'au loin',
        block1Rhythm: 'lent',
        block2Intention: 'hesiter',
        block2Energy: 'montee',
        block2Look: 'vers la porte',
        block2Rhythm: 'progressif',
        block3Intention: 'trancher',
        block3Energy: 'franche',
        block3Look: 'fixe',
        block3Rhythm: 'sec',
        startPosition: 'Face a la porte',
        plannedMovement: 'Un pas en avant',
        expectedGestures: 'Main sur la poignee',
        usedObjects: 'Sac a main',
        keyActionMoment: 'Quand elle touche la porte',
        bodyDirection: 'Corps de trois-quarts',
        framingType: 'plan poitrine',
        cameraRelation: 'légèrement hors caméra',
        gazePoint: 'Poignee',
        faceDirection: 'Profil gauche',
        globalTempo: 'progressif',
        silences: 'Avant la derniere phrase',
        dramaticRise: 'Montee jusqu au geste final',
        floorMark: 'Croix au sol',
        startCue: 'Top son',
        movementCue: 'Main sur la porte',
        exactEnd: 'Regard fixe et souffle coupe',
        idealTextDuration: '45 secondes',
        technicalConstraints: 'Pas de travelling acteur',
        spectatorFeeling: 'Suspendu a sa decision',
        directorFinalNote: 'La scene doit rester tres contenue.',
        requestedVideoFormat: '16:9',
        testedPrompts: const [
          'Prompt 1',
          'Prompt 2',
        ],
        aiIntroVideo: video,
        visualTransitionPoint: 'Cadre fixe sur la porte',
        emotionalTransitionPoint: 'Tension retenue',
        firstActorAction: 'Lever la main',
        firstExpectedEmotion: 'Hesitation',
        lastAiFrameDescription: 'Porte immobile dans la lumiere doree',
        createdAt: now,
        updatedAt: now,
        submittedAt: now,
        publishedAt: null,
        createdBy: 'admin_take30',
      );

      final firestore = scene.toFirestore();

      expect(firestore['adminWorkflow'], isTrue);
      expect(firestore['status'], 'pending_publication');
      expect(firestore['title'], 'Confrontation devant la porte');
      expect(firestore['genre'], 'Drame');
      expect(firestore['aiIntroVideo']['provider'], 'veo3');
      expect(firestore['aiIntroVideo']['status'], 'validated');
      expect(firestore['actorSheet']['characterName'], 'Mila');
      expect(
        firestore['raccord']['visualTransitionPoint'],
        'Cadre fixe sur la porte',
      );
      expect((firestore['testedPrompts'] as List<Object?>).length, 2);
    });
  });
}